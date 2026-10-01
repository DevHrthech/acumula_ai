# Arquitetura — ACUMULAAI

## 1. Visão geral

```
                         ┌──────────────────────────┐
                         │   MySQL (remoto, cPanel)  │
                         └────────────┬─────────────┘
                                      │ Prisma 7 (driver adapter mariadb)
                                      │
                         ┌────────────▼─────────────┐
                         │  server/  — API REST      │
                         │  Node.js + Express        │
                         │  api.acumulaai.com.br     │
                         └──┬───────┬───────┬────────┘
                            │       │       │
              JWT (empresa) │       │ JWT (admin)
                            │       │       │ JWT (cliente)
              ┌─────────────▼──┐ ┌──▼────────────┐ ┌▼──────────────────┐
              │ web/ (main.dart)│ │web/(main_admin)│ │ mobile/ (Android) │
              │ Painel Empresa  │ │ Painel Admin   │ │ App do Cliente    │
              │ acumulaai.com.br│ │admin.acumulaai.│ │ (não publicado)   │
              │                 │ │   com.br       │ │                   │
              └─────────────────┘ └────────────────┘ └───────────────────┘
```

Não existe ambiente de staging — todo desenvolvimento local aponta direto para o banco MySQL remoto de produção (ver [SETUP.md](SETUP.md)), e o deploy é manual via FTP (ver [DEPLOYMENT.md](DEPLOYMENT.md)).

## 2. Stack

| Camada | Tecnologia | Observações |
|---|---|---|
| Backend | Node.js 20.20.2 (LTS) + Express 4 | Hospedado via Passenger no cPanel |
| ORM | Prisma 7 (`@prisma/adapter-mariadb`) | Driver adapter, não o engine binário clássico |
| Banco | MySQL 5.7.44 | Hospedagem compartilhada (Hostmídia/cPanel), sem `JSON` nativo completo nem `CHECK constraints` |
| Autenticação | JWT (HS256), `jsonwebtoken` | 3 tipos de token independentes — ver seção 4 |
| Client Web | Flutter Web | 2 entrypoints (`main.dart`, `main_admin.dart`) no mesmo projeto `web/` |
| Client Mobile | Flutter (Android) | iOS nunca testado |
| CDN/edge | Cloudflare | Cache agressivo de assets estáticos — ver nota de cache no `DEPLOYMENT.md` |

## 3. Estrutura de pastas

```
2RL/
├── server/            API REST — EM PRODUÇÃO
│   ├── src/
│   │   ├── routes/        um arquivo por recurso (ver API.md)
│   │   ├── middleware/     authEmpresa, authAdmin, authCliente, rateLimiters, logRequisicao
│   │   ├── utils/          validação (cpf.js, cnpj.js), regra de negócio (fidelidade.js, licenca.js)
│   │   ├── generated/prisma/  Prisma Client gerado — precisa ser re-deployado a cada mudança de schema
│   │   └── index.js        monta rotas, CORS, helmet, rate limit, error handler
│   └── prisma/schema.prisma   fonte de verdade do schema (espelhado em docs/schema.sql)
│
├── web/               Flutter Web — foco ativo. Tem .git PRÓPRIO (github.com/DevHrthech/acumula_ai) —
│   │                  não commitar/dar push nessa pasta sem pedido explícito.
│   └── lib/
│       ├── main.dart          entrypoint: painel da Empresa-cliente
│       ├── main_admin.dart    entrypoint: painel admin interno 2RL
│       ├── screens/           telas do painel da Empresa
│       ├── screens/admin/     telas do painel admin
│       ├── services/          clientes HTTP (empresa_api.dart, admin_api.dart)
│       └── state/             estado reativo (ChangeNotifier + InheritedWidget custom)
│
└── mobile/            Flutter Android — app do consumidor final (não publicado em loja ainda)
    └── lib/
        ├── screens/            Login, Cadastro, Vincular loja, Início, Promoções, Perfil, Configurações
        ├── services/cliente_api.dart
        └── state/cliente_session.dart
```

## 4. Modelo de autenticação

Não existe um único sistema de login — são **três tokens JWT independentes**, cada um validado por um middleware próprio, todos assinados com o mesmo `JWT_SECRET` mas com `tipo` diferente no payload:

| Token (`payload.tipo`) | Middleware | Quem usa | Particularidade |
|---|---|---|---|
| `empresa` | `authEmpresa.js` | painel da Empresa (`web/main.dart`) | Verifica também o status da licença — **bloqueia acesso (403)** se `BLOQUEADA`/`CANCELADA`, mesmo com token válido |
| `admin` | `authAdmin.js` | painel admin interno (`web/main_admin.dart`) | Sem checagem extra |
| `cliente` | `authCliente.js` | app mobile | Sem checagem extra |

Um token de um tipo nunca funciona nas rotas de outro tipo (o middleware rejeita com 401 se `payload.tipo` não bater). Todos expiram (7 dias para empresa/admin, 30 dias para cliente) e não há refresh token — expirado, é preciso logar de novo.

CORS libera explicitamente `acumulaai.com.br`, `admin.acumulaai.com.br` e qualquer `localhost:*` (dev local) — ver `server/src/index.js`.

## 5. Mecânica de fidelidade

Cada empresa escolhe, uma única vez (fixo após o cadastro), entre dois modos (`tipo_fidelidade`):

- **MARCACOES** — contador simples. Atinge a meta → zera o saldo e libera a recompensa.
- **PONTOS** — saldo acumulado por regra de pontuação. Atinge a meta → desconta só a meta do saldo (mantém o excedente).

A lógica de crédito é centralizada em `server/src/utils/fidelidade.js` (`creditarVinculo`), reaproveitada tanto na aprovação de solicitação do cliente quanto na marcação manual pela empresa — **nunca duplicar essa lógica em outro lugar**. Detalhes completos: [`MECANICA_FIDELIDADE.md`](../MECANICA_FIDELIDADE.md).

## 6. Gestão comercial 2RL (licenciamento e matriz/filiais)

- Cada empresa-cliente tem `Licenca`(s) com `status` + `data_vencimento` + `dias_tolerancia`. O **status efetivo** (usado para bloquear login) é calculado por data em `server/src/utils/licenca.js`, não só pelo campo `status` gravado.
- Empresas podem se agrupar sob uma matriz via `empresa_pai_id` (auto-referência simples, sem entidade nova) — **só para gestão comercial/cobrança da 2RL**, controlado exclusivamente pelo admin interno. Login, configuração e saldo de fidelidade continuam 100% independentes por filial. Detalhes: `SPEC.md` seção 16.

## 7. Restrições de infraestrutura conhecidas

Estas não são escolhas de design — são limitações reais do ambiente de hospedagem que moldam como o projeto é operado:

- **`prisma generate`/`db push` só rodam localmente** contra o banco remoto — o schema-engine WASM do Prisma 7 trava por OOM no cPanel.
- **Sem deploy automático.** Todo arquivo alterado em `server/src/` precisa ser enviado via FTP manualmente. Ver [DEPLOYMENT.md](DEPLOYMENT.md).
- **`node_modules` em produção é um symlink** para fora do diretório raiz do FTP — checagens de "o pacote X está instalado?" via FTP dão falso-negativo.
- **MySQL 5.7** (não 8.x) — evitar features mais recentes de JSON/CHECK constraints.
- **Cloudflare cacheia agressivamente** os builds Flutter Web — um deploy sem purge de cache pode parecer "não aplicado" para o usuário.
