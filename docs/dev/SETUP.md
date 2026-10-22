# Setup do ambiente local — ACUMULAAI

Não existe ambiente de staging: o desenvolvimento local do `server/` conecta direto no **MySQL remoto de produção**. Não há dados fictícios em massa — tenha cuidado ao rodar scripts que criam/alteram dados, e sempre limpe dados de teste descartáveis depois (ver convenção em `server/scripts/`).

## Pré-requisitos

| Ferramenta | Versão usada no projeto | Nota |
|---|---|---|
| Node.js | 20.x LTS | Mesma versão da hospedagem (20.20.2) |
| Flutter | 3.44.x (Dart 3.12.x) | `flutter --version` para conferir |
| MySQL | acesso ao banco remoto (Hostmídia) | Sem banco local — todo dev aponta pro remoto |
| Java JDK/JRE | necessário só para assinar builds Android (`keytool`) | Ver [DEPLOYMENT.md](DEPLOYMENT.md#mobile) |

## `server/`

```bash
cd server
npm install
cp .env.example .env   # preencher DATABASE_URL e JWT_SECRET reais (pedir ao responsável do projeto)
npm run dev             # node --watch src/index.js — reinicia sozinho a cada alteração
```

Verifique que subiu: `curl http://localhost:3000/health` → `{"status":"ok"}`.

Variáveis opcionais além do `.env.example`: `MAIL_MODE=console` (imprime os e-mails no log em vez de enviar — use ao testar a recuperação de senha localmente), `GOOGLE_CLIENT_ID` (sobrescreve o Web Client ID padrão em `src/utils/google.js`) e `GOOGLE_TOKENINFO_URL` (aponta para um servidor falso nos testes do login com Google). Os limites de requisição são por processo e por IP: se um teste local devolver 429, reinicie o servidor. Encerre servidores de teste **pela porta ou PID**, nunca com `taskkill` por nome de imagem (mata todos os `node.exe`).

### Alterando o schema do banco

**Nunca rode `prisma db push`/`generate` no servidor de produção** — o schema-engine WASM do Prisma 7 trava por falta de memória no cPanel. O fluxo correto é sempre local:

```bash
cd server
# edite prisma/schema.prisma
npx prisma validate
PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION=1 npx prisma db push   # aditivo — não use --force-reset sem certeza absoluta
npx prisma generate
```

Isso regenera `src/generated/prisma/` (~20 arquivos) — **esses arquivos também precisam ser reenviados ao servidor** no próximo deploy (ver [DEPLOYMENT.md](DEPLOYMENT.md)). Depois de qualquer mudança de schema, atualize também `docs/schema.sql` e `docs/MODELO_DADOS.md` manualmente (não há geração automática desses dois a partir do Prisma).

### Criando um admin interno para testes

Não existe autocadastro de admin. Use o script dedicado:

```bash
node server/scripts/seed-admin.js "Nome" email@2rl.com.br "senhaForte123"
```

## `web/`

Dois entrypoints no mesmo projeto Flutter Web:

```bash
cd web
flutter pub get
flutter run -d chrome -t lib/main.dart          # painel da Empresa-cliente
flutter run -d chrome -t lib/main_admin.dart    # painel admin interno 2RL
```

Os dois falam com a API em `https://api.acumulaai.com.br` por padrão (`baseUrl` hardcoded nos arquivos `lib/services/*_api.dart`) — não há variável de ambiente/flavor para apontar pra um backend local; se precisar testar contra `localhost:3000`, edite temporariamente o `baseUrl` e **reverta antes de buildar para produção** (o CORS do servidor já libera `localhost:*` para esse caso).

> **Atenção:** `web/` tem um repositório git próprio, conectado a `github.com/DevHrthech/acumula_ai`, com histórico e mudanças não commitadas. Não rode `git add`/`commit`/`push`/reorganização nessa pasta sem pedido explícito de quem gerencia o projeto.

## `mobile/`

```bash
cd mobile
flutter pub get
flutter run   # com um dispositivo Android conectado (adb devices) ou emulador
```

Mesmo esquema de `baseUrl` fixo em `lib/services/cliente_api.dart`. iOS nunca foi configurado/testado nesse projeto.

Para gerar um build de release assinado (App Bundle para a Play Store), ver [DEPLOYMENT.md](DEPLOYMENT.md#mobile).

## Convenções do projeto

- **Idioma:** nomes de campo, mensagens de erro e comentários em português — mantenha consistência.
- **Sem comentários óbvios:** só comente o que não é evidente pelo código (uma decisão não-óbvia, uma limitação da hospedagem, um workaround).
- **Validação de CPF/CNPJ:** sempre via `server/src/utils/cpf.js`/`cnpj.js` — nunca duplicar a lógica de dígito verificador.
- **Lógica de crédito de fidelidade:** sempre via `server/src/utils/fidelidade.js` (`creditarVinculo`) — usada tanto na aprovação de solicitação quanto na marcação manual.
- **Nunca commitar/dar push em `web/`** sem autorização explícita (repositório real, gerenciado por outra pessoa/equipe).
- **Nunca fazer deploy/restart de produção de forma autônoma** — sempre confirmar com quem está pedindo o trabalho antes de publicar ou reiniciar o Passenger.
