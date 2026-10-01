# Modelo de Dados (MySQL)

> Atualizado em 2026-09-19, conferido campo a campo contra o banco de produção (13 tabelas, sem divergência). Fonte de verdade estrutural: **[schema.sql](schema.sql)** e **`server/prisma/schema.prisma`** (os dois espelham um ao outro). Este documento é só a descrição conceitual — para tipos/tamanhos exatos, ver o SQL.

## Entidades — fidelidade

### `empresas`
A empresa cliente (Empresa X) que contrata o ACUMULAAI.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| nome, cnpj (unique), email (unique), senha_hash | cadastro/login da empresa na Web |
| codigo_loja (unique) | código curto usado no QR Code / digitado manualmente pelo cliente pra vincular |
| categoria | livre, ex: "Cafeteria" |
| empresa_pai_id → empresas, nullable | agrupamento matriz/filiais só para gestão comercial/cobrança da 2RL (ver seção "Matriz e filiais" abaixo) — controlado exclusivamente pelo admin interno, não pela própria empresa |
| tipo_fidelidade | `MARCACOES` ou `PONTOS` — escolhido uma vez no cadastro, fixo depois (ver [MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md)) |
| meta_fidelidade | nº de marcações ou pontos pra liberar a recompensa padrão da loja |
| descricao_recompensa | texto livre (ex: "1 esmalte grátis") |
| icone_url, logo_qrcode_url, logo_promocao_url | caminho/URL das imagens de marca (binário fica no servidor, nunca no banco — ver [SPEC.md](SPEC.md) seção 7) |
| cor_principal, cor_destaque | identidade visual (`#RRGGBB`), refletida no cartão do cliente |
| nome_programa, mensagem_boas_vindas, mensagem_resgate, texto_botao_resgate | textos personalizados que o cliente final vê no app |
| created_at / updated_at | |

### `clientes`
O consumidor final, dono do app.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| nome, senha_hash | |
| cpf (unique) | login no app **e** usado pela empresa pra localizar/marcar na Web |
| telefone | canal de contato |
| email | opcional |
| notificacoes_push, notificacoes_email, login_biometrico | preferências (booleanas) — sem infraestrutura de envio de push/e-mail por trás ainda, mas os campos já persistem de verdade |
| created_at | |

### `vinculos`
O "cartão fidelidade" — relação entre um cliente e uma empresa. Um cliente pode ter vários vínculos (uma empresa cada), suportando múltiplas lojas no mesmo app.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| cliente_id → clientes, empresa_id → empresas | |
| saldo_atual | default 0 — contador de marcações (zera ao resgatar) ou saldo de pontos (resgate desconta só a meta), conforme `empresas.tipo_fidelidade` |
| data_vinculo | quando o cliente escaneou/digitou o código |
| unique(cliente_id, empresa_id) | um cliente só tem 1 cartão por empresa — garantido a nível de banco |

### `campanhas`
Promoção com validade própria, criada pela empresa. Sempre herda o `tipo_fidelidade` da empresa (sem coluna de tipo própria). Aprovação é automática — só `ATIVA`/`EXPIRADA`, sem estado de moderação. **A tela "Promoções" (web e mobile) é só outra vitrine desta mesma entidade, não um recurso separado** (ver [SPEC.md](SPEC.md) seção 14).

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| empresa_id → empresas | |
| nome, descricao | |
| meta | meta própria da campanha (marcações ou pontos, conforme o tipo da empresa) |
| data_validade | |
| status | `ATIVA` ou `EXPIRADA` |
| created_at | |

### `regras_pontuacao`
Só relevante para empresas com `tipo_fidelidade = PONTOS`: define quantos pontos uma marcação concede. Múltiplas regras podem coexistir.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| empresa_id → empresas | |
| descricao, pontos | |
| criterio | texto livre — **critério exato de quando cada regra se aplica ainda em aberto** (ver [MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md) seção 4); por ora, aprovar uma marcação sempre usa a primeira regra ativa cadastrada (`server/src/utils/fidelidade.js`) |
| ativo | |
| created_at | |

### `marcacoes`
Histórico de cada compra marcada — fonte da verdade da contagem/pontuação (auditoria).

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| vinculo_id → vinculos | |
| campanha_id → campanhas, nullable | nulo quando é do programa contínuo padrão da loja |
| regra_pontuacao_id → regras_pontuacao, nullable | nulo quando o tipo da loja é `MARCACOES` |
| pontos_gerados | nullable — só preenchido no tipo `PONTOS` |
| data_hora | |

### `solicitacoes_marcacao`
Pedido do cliente pra empresa validar uma compra (com ou sem cupom fiscal) — fila de pendências da tela "Aprovação" (ver [MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md) seção 9). Aprovar gera a `marcacao` real e credita o vínculo; rejeitar só muda o status, sem efeito no saldo. A empresa também pode marcar uma compra manualmente por CPF, sem passar por aqui.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| vinculo_id → vinculos | |
| cupom_fiscal | opcional |
| status | `PENDENTE`, `APROVADA` ou `REJEITADA` |
| created_at, resolved_at | `resolved_at` nulo enquanto pendente |

### `resgates`
Histórico de recompensas liberadas.

| Campo | Observação |
|---|---|
| id | PK (UUID) |
| vinculo_id → vinculos | |
| campanha_id → campanhas, nullable | |
| data_hora | |
| saldo_no_momento | saldo total no instante do resgate |
| saldo_descontado | igual a `saldo_no_momento` no tipo `MARCACOES` (zera tudo); só a meta no tipo `PONTOS` |
| saldo_restante | default 0 — sobra do saldo no tipo `PONTOS` quando o cliente tinha mais que a meta |

### Matriz e filiais

Uma empresa pode apontar `empresa_pai_id` para outra empresa, formando um agrupamento comercial simples (matriz → N filiais). Decisão de 2026-09-19:

- **Só afeta gestão comercial/cobrança da 2RL** (visão agrupada de empresas relacionadas no admin interno). Não existe entidade própria — é só um campo auto-referenciado em `empresas`.
- **Login, configuração e cartão fidelidade continuam 100% independentes por filial** — cada empresa (matriz ou filial) mantém seu próprio login, `codigo_loja`, mecânica de fidelidade, saldo de clientes, campanhas etc., sem nenhum compartilhamento entre si.
- Só o admin interno da 2RL define/altera esse vínculo (`PATCH /admin/empresas/:id`), nunca a própria empresa pelo painel Web dela.
- Uma cadeia mais profunda (filial de filial) não é bloqueada, mas o ciclo mais simples (A matriz de B, B matriz de A) é rejeitado pela API.
- Implicações de cobrança (2RL cobrar por filial ou só da matriz) ainda **não foram definidas** — em aberto, ver SPEC.md seção 8.

## Entidades — gestão comercial 2RL

Ver [SPEC.md](SPEC.md) seção 11 para o contexto completo (licenciamento/bloqueio por inadimplência).

### `admins_2rl`
Usuário interno da 2RL (equipe comercial/suporte). Sem autocadastro — criado só via `server/scripts/seed-admin.js`.

### `planos`
Plano comercial oferecido às empresas-clientes: `nome`, `valor_mensal`, `descricao`, `ativo`.

### `licencas`
Controla o acesso da empresa ao sistema conforme pagamento/contrato — `empresa_id`, `plano_id`, `status` (`ATIVA`/`INADIMPLENTE`/`BLOQUEADA`/`CANCELADA`), `data_inicio`, `data_vencimento`, `dias_tolerancia`, campos `gateway_*` (nulos até a 2RL escolher um gateway de pagamento). O status **efetivo** (usado pra liberar/bloquear login da empresa) é calculado por data (`data_vencimento` + `dias_tolerancia`), não só pelo campo `status` gravado — ver `server/src/utils/licenca.js`.

### `contratos`
Contrato entre a 2RL e a empresa-cliente — `empresa_id`, `licenca_id` (nullable), `status` (`RASCUNHO`/`AGUARDANDO_ASSINATURA`/`ASSINADO`/`CANCELADO`), `documento_url`/`assinatura_*` (nulos até a 2RL escolher provedor de assinatura eletrônica).

## Entidades — telemetria

### `requisicoes_api`
Log de cada chamada à API — base da tela de monitoramento do admin interno. Sem FK de propósito (registro de auditoria, não deve travar nem cascatear com exclusões): `metodo`, `rota`, `status_code`, `duracao_ms`, `empresa_id`/`admin_id`/`ip` (nullable), `created_at`.

## Relacionamentos

```
empresas (1) ──< vinculos >── (1) clientes
empresas (1) ──< campanhas
empresas (1) ──< regras_pontuacao
empresas (1) ──< licencas
empresas (1) ──< contratos
licencas  (1) ──< contratos (opcional)
vinculos  (1) ──< marcacoes >── (0..1) campanhas
vinculos  (1) ──< marcacoes >── (0..1) regras_pontuacao
vinculos  (1) ──< solicitacoes_marcacao
vinculos  (1) ──< resgates  >── (0..1) campanhas
```

## Regras de negócio implícitas no modelo

- Ao aprovar uma solicitação (ou marcar manualmente): insere em `marcacoes` + incrementa `vinculos.saldo_atual` (1 no tipo `MARCACOES`, os pontos da regra ativa no tipo `PONTOS`).
- Ao atingir `saldo_atual >= empresas.meta_fidelidade`: sistema libera a recompensa automaticamente (registra em `resgates`) — zera o saldo no tipo `MARCACOES`, ou desconta só a meta e mantém o residual no tipo `PONTOS`.
- `codigo_loja` é o valor codificado no QR Code e também o que o cliente digita manualmente — mesmo dado, dois canais de entrada no app.
- `unique(cliente_id, empresa_id)` em `vinculos` é garantida a nível de banco, não só na aplicação.

## Arquivo SQL

DDL completo em [schema.sql](schema.sql), pronto para rodar no MySQL da hospedagem. Mudanças de schema sempre passam por `prisma db push` rodado **localmente** contra o banco remoto (nunca no servidor cPanel — trava por falta de memória no schema-engine WASM do Prisma 7) — ver [CLAUDE.md](../CLAUDE.md) e [SPEC.md](SPEC.md) seção 10.
