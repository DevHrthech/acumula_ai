# Deploy — ACUMULAAI

Não existe deploy automático (CI/CD) em nenhuma das três frentes. Tudo é manual, via FTP/FTPS, para uma hospedagem cPanel (Hostmídia). **Sempre peça confirmação explícita antes de publicar ou reiniciar produção** — nenhum deploy deve acontecer de forma autônoma.

## Contas e domínios

| Domínio | Serve | Conta FTP (doc-root) |
|---|---|---|
| `api.acumulaai.com.br` | `server/` (Node via Passenger) | `acumulaai_app@acumulaai.com.br` → `/home/acumulaai/server` |
| `acumulaai.com.br` (raiz, `/`) | `landing/` — página comercial estática (SEO) + `privacidade.html` | `web@acumulaai.com.br` → doc-root do domínio principal |
| `acumulaai.com.br/app/` | `web/` build (`main.dart`, painel Empresa) | mesma conta `web@acumulaai.com.br`, subpasta `app/` do doc-root |
| `admin.acumulaai.com.br` | `web/` build (`main_admin.dart`, painel admin) | `admin@acumulaai.com.br` → doc-root do subdomínio |

**Desde 2026-09-30:** o domínio principal foi dividido por path — a raiz (`/`) passou a servir a landing comercial estática (`landing/`, fora do build Flutter), pensada pra ser indexável pelo Google (SPA Flutter não é). O painel da Empresa (antes na raiz) foi pro subcaminho `/app/`. Motivo: dar contexto comercial pra quem chega no domínio sem ser cliente ainda, sem precisar de subdomínio novo (evita mexer em DNS/CORS). Ver seção "`landing/`" abaixo.

Servidor: FTPS explícito, porta 21, IP `107.161.183.117`. As três contas compartilham a mesma senha (confirmado em produção) — pedir a quem gerencia as credenciais, nunca versionar.

**Certificado TLS do FTP:** é um Let's Encrypt emitido para **`r200us.hmservers.net`**, não para o IP nem para `acumulaai.com.br`. Conecte por esse nome (com `--resolve r200us.hmservers.net:21:107.161.183.117` no `curl`) e a verificação funciona; pelo IP dá `SEC_E_WRONG_PRINCIPAL` — **não use `-k`**. No Git Bash exporte `MSYS_NO_PATHCONV=1` (senão `/` vira `C:/Program Files/Git/`). O `curl --netrc-file` com várias contas no mesmo host não escolhe a linha certa (pede senha): use um helper que leia o `.netrc` e passe `user = "login:senha"` ao `curl` por stdin (`-K -`), assim a senha não aparece em linha de comando nem em log. Vários arquivos podem ir numa só conexão com pares `upload-file`/`url` num arquivo de config do curl (`--ftp-create-dirs`). Depois de enviar, **compare o tamanho** de cada arquivo remoto (`LIST`) com o local e, nos painéis, o tamanho do `main.dart.js` servido pelo site.

## `server/` — backend

1. Faça as mudanças e teste localmente (`npm run dev`, ver [SETUP.md](SETUP.md)).
2. Se o schema do Prisma mudou, rode `db push`/`generate` **localmente** primeiro (nunca no cPanel).
3. Envie via FTPS **todo arquivo novo ou alterado** em `server/src/`, incluindo:
   - O(s) arquivo(s) de rota/middleware/util alterado(s)
   - **Todo o diretório `src/generated/prisma/`** (~20 arquivos) se o schema mudou — client desatualizado quebra em runtime
   - `package.json`/`package-lock.json` se dependências mudaram
4. Peça para reiniciar a aplicação Node no cPanel (Setup Node.js App → Restart) — **isso não pode ser feito por FTP**, é uma ação do painel cPanel.
5. **Sempre** valide depois do restart: `curl https://api.acumulaai.com.br/health` → `{"status":"ok"}`.
6. Idealmente, teste o endpoint específico alterado com uma chamada real antes de considerar o deploy concluído (dado de teste descartável, sempre limpo depois).

### Ordem quando o lote muda o schema do Prisma

`prisma db push` **primeiro** (só adição de coluna/tabela, nunca `--force-reset`/`--accept-data-loss`), **depois `npx prisma generate`** (o `db push` NÃO regenera o client — esquecer isso derrubou todas as rotas autenticadas do cliente em 2026-10-15; `npm test` agora falha se o client estiver desatualizado), depois enviar `server/src/` (árvore inteira, incluindo `src/generated/prisma/`). Se `package.json`/`package-lock.json` mudaram, enviar também e rodar **"Run NPM Install"** no Node.js App do cPanel (o `node_modules` de produção é um symlink; por FTP não dá pra instalar). Depois reiniciar o Passenger e conferir `/health` **e uma rota autenticada de verdade** (o `/health` e um 401 sem token não pegam erro de client/schema): por exemplo rodar a API local contra o banco com um token de teste e chamar `GET /clientes/me`, ou testar pelo próprio app/painel logado. Defina `NODE_ENV=production` no Node.js App para fechar o CORS de `localhost`.

### Cobrança via Asaas (desde 2026-10-27)

- **Variáveis no `.env` do servidor** (File Manager do cPanel, editando o arquivo existente — nunca sobrescrever com o `.env` local): `ASAAS_API_KEY`, `ASAAS_BASE_URL` (`https://api-sandbox.asaas.com/v3` ou `https://api.asaas.com/v3`) e `ASAAS_WEBHOOK_TOKEN` (**idêntico** ao do `.env` local, porque o script de webhook lê o local). Sem o token, `POST /webhooks/asaas` responde **503**; com token errado, **401**. Sem `ASAAS_API_KEY`/`ASAAS_BASE_URL`, o cadastro funciona mas não replica no Asaas (`asaas_sincronizado: false`).
- **Sem dependência nova:** a integração usa `fetch` nativo do Node 20 — não precisa "Run NPM Install".
- **Webhook no Asaas:** só **depois** de a rota estar no ar (a fila pausa após 15 falhas seguidas). Cadastre/atualize com `cd server && node scripts/asaas-webhook.js https://api.acumulaai.com.br/webhooks/asaas <email-de-alerta>` (o Asaas exige e-mail; o ambiente é o da chave do `.env`: sandbox cria webhook no sandbox, produção no de produção). Confira no painel do Asaas (Integrações → Webhooks → logs) que as entregas voltam 2xx. Se usar Cloudflare com regras de bots/WAF, a rota `POST /webhooks/asaas` não pode ser desafiada.
- **Ordem de um lote com schema novo + Asaas** (a usada em 2026-10-27): 1) `prisma db push` aditivo + `prisma generate` locais; 2) backup do que está no servidor (baixar `src/` e os `index.html`/`flutter_bootstrap.js`/`main.dart.js` dos painéis); 3) `server/src/` inteiro (com `generated/prisma/`); 4) `.env` de produção + **reiniciar o Passenger** (só o responsável, no cPanel); 5) `GET /health`, `GET /planos`, `POST /webhooks/asaas` sem token (**401**) e rotas autenticadas novas sem token (**401**), e uma chamada de webhook **com** o token (200, grava e apaga um evento de teste) para provar que o token do servidor bate com o local; 6) painéis (`index.html` por último em cada um) e **purge do Cloudflare**; 7) cadastrar o webhook; 8) teste ponta a ponta (cadastro → fatura no Asaas → baixa no sandbox com `receiveInCash` usando a data de Brasília → licença renovada) e limpeza. Enviar os painéis **logo depois** do servidor: o painel antigo falha no cadastro (400) contra o servidor novo, e o painel novo precisa de `/planos` e `/empresas/me/assinatura`.
- **Trocar do sandbox para a produção do Asaas:** conta aprovada → chave `$aact_prod_` → `ASAAS_BASE_URL=https://api.asaas.com/v3` no `.env` do servidor **e** no local (o script lê o local) → reiniciar o Passenger → rodar o script do webhook para criar o webhook de produção (o do sandbox continua existindo, separado) → testar com uma empresa de teste real e baixa/estorno conforme a política → só então divulgar o cadastro. Faturas do sandbox não migram para a produção.
- **Dados de teste e o webhook de produção:** o `.env` local usa o banco de produção e o webhook aponta para a API de produção; ao apagar uma assinatura de teste, o Asaas dispara `PAYMENT_DELETED` e o servidor grava a cobrança de volta. Na limpeza: apague no Asaas (assinatura e cliente), **espere ~10 s**, apague `cobrancas` → `licencas` → `empresas` (repetindo se a FK `cobrancas → licencas` reclamar) e remova os `asaas_eventos` do período. Empresas de teste levam "(teste)" no nome.

### ⚠️ Lição de um incidente real (registrado em SPEC.md seção 14)

Um deploy parcial (só os arquivos "óbvios") deixou a API inteira fora do ar por ~30 min — faltava um módulo (`middleware/rateLimiters`) de uma leva de arquivos nunca totalmente sincronizada numa sessão anterior. `node_modules` em produção é um **symlink** para fora do diretório do FTP, então uma checagem de "o pacote X está instalado?" via FTP dá falso-negativo. Diagnóstico real só foi possível rodando `node src/index.js` direto no terminal do cPanel (mais confiável que caçar logs do Passenger). **Regra prática:** depois de qualquer sessão que alterou `server/src/` só localmente sem deployar, o próximo deploy deve ressincronizar a árvore inteira, não só os arquivos que "parecem" ter mudado.

## `landing/` — página comercial estática

Site estático puro (HTML/CSS, sem build step, sem framework JS) — vive na raiz do repo, fora de `web/`. Arquivos: `index.html`, `privacidade.html`, `robots.txt`, `sitemap.xml`, `assets/`.

Deploy: envie o conteúdo de `landing/` direto pra raiz do doc-root da conta `web@acumulaai.com.br` (**não** para dentro de `app/`). Como é HTML/CSS puro, não tem passo de build — é FTP direto dos arquivos.

⚠️ Antes de publicar, confira que não sobrou nenhum placeholder visível no código (ex.: número de WhatsApp nos CTAs de `index.html`) — o texto do plano original marcava isso explicitamente como bloqueio de publicação.

### CORS (quais sites podem chamar a API pelo navegador)

Regra em `server/src/utils/cors.js`: liberados `https://acumulaai.com.br`, `https://www.acumulaai.com.br` e `https://admin.acumulaai.com.br`; `localhost`/`127.0.0.1` (qualquer porta) só **fora** de produção (`NODE_ENV=production` fecha). Para liberar um domínio de teste/homologação do QA **sem mexer no código**, defina no Node.js App do cPanel a variável `CORS_ORIGENS_EXTRAS` (origens exatas separadas por vírgula, ex.: `https://qa.exemplo.com,https://outro.exemplo.com:8443`; curinga e caminho são ignorados) e reinicie o Passenger. Origem não liberada recebe **403** `{"erro":"Origem não permitida pela API.","origem":"..."}` — o navegador mostra isso como erro de CORS, mas a aba Network deixa claro qual origem foi recusada. O app do celular não é afetado (não envia `Origin`).

### Itens que persistem entre deploys (não apagar pelo FTP)
- `server/uploads/` — imagens de marca enviadas pelas empresas (criada pela própria API).
- `server/.env` — segredos de produção; nunca sobrescrever com o `.env` local.
- O envio de e-mail (recuperação de senha) usa o `sendmail` da hospedagem — não depende de nada para fazer deploy.

## `web/` — painéis Flutter Web

```bash
cd web
flutter build web --target=lib/main.dart --base-href /app/   # painel Empresa (raiz do domínio é a landing, não o painel)
# ou
flutter build web --target=lib/main_admin.dart                # painel admin (subdomínio próprio, sem landing, base-href padrão "/")
```

Cada build sobrescreve `web/build/web/` — **um só pode existir por vez**, então gere e publique um de cada vez se precisar dos dois. Alternativa usada em 2026-10-27: `--output build/deploy-app` e `--output build/deploy-admin` (cada painel na sua pasta, `web/build/` é ignorado pelo git), aplicando o carimbo `?v=` em cada uma. **Não passe `--dart-define=API_URL=...` em builds de produção:** o padrão já é `https://api.acumulaai.com.br`; o define serve só para apontar um build de teste para a API local (confira com `grep -c localhost main.dart.js` = 0 antes de enviar).

Cache dos ícones: a fonte `assets/fonts/MaterialIcons-Regular.otf` não leva carimbo `?v=` (só o `main.dart.js`), e o Flutter ainda usa service worker. Depois de um deploy que adiciona ícones novos, o navegador de quem já abriu o painel pode mostrar o texto sem o ícone até um **Ctrl+Shift+R** (ou limpar os dados do site) — o arquivo publicado está correto; o purge do Cloudflare acelera.

Envie via FTPS para a conta do domínio correspondente:
- Painel Empresa (`main.dart`, `--base-href /app/`) → conta `web@`, dentro da subpasta **`app/`** do doc-root (não na raiz — a raiz é a `landing/`).
- Painel admin (`main_admin.dart`) → conta `admin@`, na raiz do doc-root do subdomínio (sem landing nesse domínio).

No mínimo: `index.html`, `main.dart.js`, `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `manifest.json`, `version.json`, `favicon.png`, `assets/**`. Os arquivos de `canvaskit/` e `icons/` só precisam ser reenviados se a versão do Flutter SDK mudou desde o último deploy (raramente).

### Cabeçalhos de segurança dos painéis (`deploy/`)

`deploy/htaccess-web.txt` → `.htaccess` da raiz da conta `web@` (vale para a landing e para `/app/`); `deploy/htaccess-admin.txt` → `.htaccess` da raiz da conta `admin@`; `deploy/admin-robots.txt` → `robots.txt` do admin. Os arquivos antigos do servidor só tinham o bloco de cache (continua dentro dos novos). Depois de enviar, confira com `curl -I` que os cabeçalhos aparecem e que o site responde 200 (um `.htaccess` com erro derruba o site com 500 — se acontecer, reenvie o antigo).

### Passo obrigatório depois do `flutter build web`: carimbo de versão (cache busting)

O Cloudflare impõe `Cache-Control: max-age=14400` (4 h) nos `.js` do domínio, ignorando o `.htaccess`, e o navegador do usuário respeita isso — então, sem este passo, quem visitou nas últimas horas **não vê o deploy novo**. O `index.html` é a única peça que nunca fica em cache, então ele passa a apontar para versões com carimbo. Rode dentro de `web/build/web/` antes de enviar (use `MSYS_NO_PATHCONV=1` no Git Bash ao passar `--base-href /app/`):

```bash
TS=$(date +%s)
sed -i "s#<script src=\"flutter_bootstrap.js\" async>#<script src=\"flutter_bootstrap.js?v=$TS\" async>#" index.html
sed -i "s#\"mainJsPath\":\"main.dart.js\"#\"mainJsPath\":\"main.dart.js?v=$TS\"#" flutter_bootstrap.js
```

Confira com `grep -c "v=$TS" index.html flutter_bootstrap.js` (deve dar 1 em cada). Vale para os dois apps (`/app/` e o admin). Com isso, um F5 normal já traz a versão nova.

### ⚠️ Três camadas de cache — leia antes de "isso não atualizou"

1. **Origem/Apache** — `.htaccess` já configurado com `Cache-Control: no-cache` para `.html`/`.js`, então revalida a cada acesso.
2. **Cloudflare (CDN)** — pode cachear agressivamente dependendo da configuração da zona (já observado `Cache-Control: public, max-age=31536000` — 1 ano — em pelo menos um domínio). **Sempre peça um purge do Cloudflare** depois de publicar um novo build. Verifique com `curl -I <url>/main.dart.js` e olhe o header `cf-cache-status`/`Age`.
3. **Cache HTTP do navegador de quem está testando** — mesmo com origem e CDN corretos, uma aba que visitou o domínio há pouco pode continuar servindo a versão antiga do próprio cache local. Para confirmar que a origem está correta independente disso, use `fetch(url, {cache: 'no-store'})` no console do navegador.

## `mobile/`

### Build de desenvolvimento/teste
```bash
cd mobile
flutter run   # dispositivo físico via adb, ou emulador
```

### Build de release (App Bundle para a Play Store)

O projeto já está configurado com `applicationId`/`namespace` = `br.com.acumulaai.cliente` e assinatura de release própria (não usa mais a chave de debug):

- Keystore: `mobile/android/app/upload-keystore.jks` (PKCS12, RSA 2048, validade ~27 anos)
- Config: `mobile/android/key.properties` (senhas — **nunca versionar**, já coberto pelo `.gitignore` padrão do Flutter)
- Alias: `acumulaai_upload`

```bash
cd mobile
flutter build appbundle --release
# gera build/app/outputs/bundle/release/app-release.aab
```

Para verificar que o build está assinado com a chave certa (não a de debug), compare o fingerprint:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -storepass <senha> -alias acumulaai_upload | grep SHA256
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk | grep SHA-256
# os dois valores devem ser idênticos
```

**⚠️ O keystore + senhas são a única chave que permite publicar atualizações do app depois do primeiro upload na Play Store.** Se perdidos, não há como recuperar nem trocar (exceto usando o "Play App Signing" do Google, que delega essa responsabilidade ao Google). Faça backup do `.jks` e das senhas em um cofre/gerenciador de senhas, fora do PC de desenvolvimento.

**Pendências antes da primeira publicação** (ver `SPEC.md` seção 8):
- Conta de desenvolvedor Google Play (ainda não criada)
- Ícone/logo definitivo do app (hoje usa o ícone padrão do Flutter)
- Política de privacidade pública: já preenchida e pronta em `landing/privacidade.html` (2026-09-30) — só falta publicar (vai junto com o deploy da `landing/`, ver seção acima).
