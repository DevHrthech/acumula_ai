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

### ⚠️ Lição de um incidente real (registrado em SPEC.md seção 14)

Um deploy parcial (só os arquivos "óbvios") deixou a API inteira fora do ar por ~30 min — faltava um módulo (`middleware/rateLimiters`) de uma leva de arquivos nunca totalmente sincronizada numa sessão anterior. `node_modules` em produção é um **symlink** para fora do diretório do FTP, então uma checagem de "o pacote X está instalado?" via FTP dá falso-negativo. Diagnóstico real só foi possível rodando `node src/index.js` direto no terminal do cPanel (mais confiável que caçar logs do Passenger). **Regra prática:** depois de qualquer sessão que alterou `server/src/` só localmente sem deployar, o próximo deploy deve ressincronizar a árvore inteira, não só os arquivos que "parecem" ter mudado.

## `landing/` — página comercial estática

Site estático puro (HTML/CSS, sem build step, sem framework JS) — vive na raiz do repo, fora de `web/`. Arquivos: `index.html`, `privacidade.html`, `robots.txt`, `sitemap.xml`, `assets/`.

Deploy: envie o conteúdo de `landing/` direto pra raiz do doc-root da conta `web@acumulaai.com.br` (**não** para dentro de `app/`). Como é HTML/CSS puro, não tem passo de build — é FTP direto dos arquivos.

⚠️ Antes de publicar, confira que não sobrou nenhum placeholder visível no código (ex.: número de WhatsApp nos CTAs de `index.html`) — o texto do plano original marcava isso explicitamente como bloqueio de publicação.

## `web/` — painéis Flutter Web

```bash
cd web
flutter build web --target=lib/main.dart --base-href /app/   # painel Empresa (raiz do domínio é a landing, não o painel)
# ou
flutter build web --target=lib/main_admin.dart                # painel admin (subdomínio próprio, sem landing, base-href padrão "/")
```

Cada build sobrescreve `web/build/web/` — **um só pode existir por vez**, então gere e publique um de cada vez se precisar dos dois.

Envie via FTPS para a conta do domínio correspondente:
- Painel Empresa (`main.dart`, `--base-href /app/`) → conta `web@`, dentro da subpasta **`app/`** do doc-root (não na raiz — a raiz é a `landing/`).
- Painel admin (`main_admin.dart`) → conta `admin@`, na raiz do doc-root do subdomínio (sem landing nesse domínio).

No mínimo: `index.html`, `main.dart.js`, `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `manifest.json`, `version.json`, `favicon.png`, `assets/**`. Os arquivos de `canvaskit/` e `icons/` só precisam ser reenviados se a versão do Flutter SDK mudou desde o último deploy (raramente).

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
