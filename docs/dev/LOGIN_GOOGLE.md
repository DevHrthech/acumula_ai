# Login com Google — configuração

O código (app + servidor) já está pronto. Falta só criar as credenciais no Google Cloud e colocar **um identificador público** (o Web Client ID) em dois lugares.

## Como funciona

1. O app abre a seleção de conta do Google e recebe um **ID token** (assinado pelo Google).
2. Envia o token para `POST /auth/cliente/google`. O servidor confere o token no endpoint oficial `tokeninfo` do Google e valida: público-alvo (`aud` = Web Client ID), emissor, validade e **e-mail verificado**.
3. Se o `sub` do Google já está vinculado a um cliente (`clientes.google_id`) → entra. Se existe um cliente com o mesmo e-mail e sem Google vinculado → vincula e entra. Senão → o app pede **CPF e telefone** (obrigatórios no sistema) e conclui com `POST /auth/cliente/google/completar`.
4. Contas criadas pelo Google não têm senha conhecida; podem definir uma pelo "Esqueceu a senha?" (usa o e-mail).

Vincular por e-mail confia no e-mail verificado pelo Google. O e-mail de contas criadas com CPF e senha não é verificado pelo sistema — risco baixo (exigiria alguém cadastrar o e-mail de outra pessoa antes dela), aceito por ora.

## Passo a passo no Google Cloud Console (feito por quem é dono da conta Google)

1. Acesse `console.cloud.google.com` e crie um projeto (ex.: "Acumula Aí").
2. Abra **Google Auth Platform** (a interface nova do Google; se aparecer "Vamos começar", faça essa configuração inicial primeiro) e preencha os menus, nesta ordem:
   - **Branding:** nome "Acumula Aí"; e-mail de suporte (só aceita o e-mail da conta Google logada ou um Grupo do Google); link da política `https://acumulaai.com.br/privacidade.html`; domínio autorizado `acumulaai.com.br`; e-mail de contato do desenvolvedor (aceita qualquer endereço, ex.: `privacidade@acumulaai.com.br`).
   - **Público-alvo:** tipo **Externo**; clique em **Publicar app** para sair do modo "Teste" (em "Teste" só entram os e-mails cadastrados como testadores).
   - **Acesso a dados:** escopos básicos `openid`, `email` e `profile` — o Google já os inclui por padrão e eles não exigem verificação.
3. No menu **Clientes → Criar cliente** (duas vezes):
   - **Aplicativo da Web** (qualquer nome). **Copie o "ID do cliente"** (termina em `.apps.googleusercontent.com`) — é o **Web Client ID**.
   - **Android**: nome de pacote `br.com.acumulaai.cliente` e impressão digital **SHA-1** da chave de upload:
     `3C:44:98:A2:D3:49:BB:F6:55:A2:9A:76:0D:DB:12:79:B3:06:9D:D5`
     Depois do primeiro upload na Play Store, crie **mais um** cliente Android com o mesmo pacote e o **SHA-1 da chave de assinatura do app** (Play Console → Integridade do app → Assinatura de apps) — é com ele que o app instalado pela loja funciona.
4. Envie o **Web Client ID** (não é segredo).

## Onde o Web Client ID entra (2 lugares, mesmo valor)

| Onde | Arquivo | Efeito |
|---|---|---|
| App | `mobile/lib/config/google.dart` → `googleWebClientId` | enquanto vazio, o botão "Google" avisa que o login está indisponível |
| Servidor | variável `GOOGLE_CLIENT_ID` no `.env` de produção, ou o padrão em `server/src/utils/google.js` | enquanto vazio, `/auth/cliente/google` responde 503 |

Depois: rebuildar o app (`flutter build appbundle --release`), enviar o servidor por FTP e reiniciar o Passenger.

## Testes feitos (servidor, com o `tokeninfo` simulado)

Token desconhecido, audiência errada e e-mail não verificado → 401; sem configuração → 503; usuário novo → `precisaCadastro`; completar sem CPF/CPF inválido/token adulterado/token de login reaproveitado → 400/401; cadastro concluído → 201 com sessão válida; mesmo Google de novo → entra direto; e-mail já cadastrado → vincula e entra; CPF já existente → 409.
**Validado em produção (2026-10-09):** projeto Google Cloud configurado (Web Client ID `954272668229-hrcersad8banluij7r90eis9t2jbp2u6.apps.googleusercontent.com`, já no app e no servidor; cliente Android `954272668229-6se7knrj7djssfqiini3p09kg59hlfe8…` com o SHA-1 da chave de upload). Login real no celular com a conta `hydro157@gmail.com`: entrou direto e o servidor vinculou o `google_id` ao cliente que já tinha esse e-mail.
**Ainda não testado com o Google real:** o primeiro acesso de um e-mail sem conta (tela "Concluir cadastro") — só com o Google simulado.
**Feito em 2026-10-09:** criado o cliente Android "Cliente Android Play Store" com o SHA-1 abaixo. **Branding completado e app OAuth publicado ("Em produção") em 2026-10-09**, então qualquer conta Google pode entrar. (Referência do que foi criado:) criar um cliente Android no Google Cloud com o pacote `br.com.acumulaai.cliente` e o SHA-1 da chave de **assinatura do Play App Signing**: `CA:13:AB:53:E0:64:1B:87:E6:24:C0:06:D8:FE:25:43:97:29:E3:59` (obtido no Play Console → Assinatura de apps em 2026-10-09). Sem isso o login com Google falha nos apps instalados pela loja.
