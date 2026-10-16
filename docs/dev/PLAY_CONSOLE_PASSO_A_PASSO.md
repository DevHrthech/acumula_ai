# Play Console — passo a passo da publicação (conta pessoal nova)

Guia para **quem opera o Play Console** (a conta é pessoal e recente, então vale a regra do teste fechado com 12 testadores por 14 dias). Os textos prontos para colar estão em [PLAY_STORE.md](PLAY_STORE.md). Os nomes de menu abaixo seguem o console em português e podem mudar um pouco — se algo não bater, procure pelo termo parecido ou me envie a mensagem da tela.

> **Achado em 2026-10-09 (visto no console):** a conta de desenvolvedor "Hr Thech" é **conta de organização** (e já tem outros apps, um deles em Produção). Na página Produção do Acumula Aí o botão **"Criar nova versão" está liberado**, sem a exigência de teste fechado com 12 testadores. Se for assim, as **Etapas 5 e 6 deste guia podem ser puladas** e o `.aab` vai direto para a Produção (ou primeiro para o Teste interno, que continua útil para obter o SHA-1 da assinatura do Google). Confirmar na hora de enviar: se o console exigir o teste, seguir as etapas 5 e 6.

**Linha do tempo realista (no pior caso, com teste fechado):** verificação da conta (horas a dias) → criar app e preencher tudo (1 a 2 horas) → teste fechado (**mínimo 14 dias**) → pedido de produção (análise do Google, em geral alguns dias) → app público. Conte com **3 a 4 semanas** no total.

---

## Etapa 1 — Concluir a verificação da conta

1. Entre em `play.google.com/console`. Se aparecer **"Verifique sua conta"** ou tarefas pendentes no **Painel**, conclua todas:
   - **Verificação de identidade:** foto do documento (RG/CNH) e dados iguais aos do documento.
   - **Telefone** (código por SMS) e **e-mail de contato** (código por e-mail).
   - **Aparelho Android:** instale o app **"Google Play Console"** no celular, entre com a mesma conta e confirme o aparelho, se o console pedir.
2. Aguarde o e-mail de aprovação. Enquanto a verificação estiver pendente, você não consegue publicar, mas normalmente já consegue **criar o app e preencher as telas**.

> Perdeu o prazo ou foi recusado? O console explica o motivo e permite reenviar. Não crie outra conta: isso pode atrapalhar a análise.

---

## Etapa 2 — Criar o app

1. No Painel, clique em **Criar app**.
2. Preencha:
   - **Nome do app:** `Acumula Aí – Fidelidade` (aparece na loja; máx. 30 caracteres).
   - **Nome do pacote:** `br.com.acumulaai.cliente` — clique em **Ver disponibilidade**. É **definitivo** (não muda depois) e precisa ser igual ao do `.aab`.
   - **Idioma padrão:** Português (Brasil) — pt-BR.
   - **App ou jogo:** App.
   - **Gratuito ou pago:** Gratuito (não dá para mudar de gratuito para pago depois).
3. Marque as **declarações** (política de conteúdo para desenvolvedores e leis de exportação dos EUA) e clique em **Criar app**.

---

## Etapa 3 — Configurar o app (menu lateral: "Painel" → tarefas) e **Conteúdo do app**

Preencha cada item de **Política → Conteúdo do app** (em alguns consoles aparece como "Configurar seu app" no Painel). Respostas prontas:

| Item | O que responder |
|---|---|
| **Política de Privacidade** | `https://acumulaai.com.br/privacidade.html` |
| **Acesso ao app** | "Todas ou algumas funções estão restritas" → **Adicionar instruções**. Nome: `Cliente de revisão`. Usuário (CPF): `390.533.447-05`. Senha: a do cliente de revisão (você tem). Instruções: "Entre com o CPF e a senha. A conta já está vinculada a uma loja de teste." |
| **Anúncios** | **Não**, o app não contém anúncios |
| **Classificação do conteúdo** | Preencha o questionário (e-mail de contato; categoria **"Utilitário, produtividade, comunicação ou outro"**). Responda **Não** para violência, conteúdo sexual, linguagem imprópria, drogas, jogos de azar, interação/compartilhamento de localização entre usuários e compras digitais. Resultado esperado: **Livre**. |
| **Público-alvo e conteúdo** | Faixa etária: **18 anos ou mais** (só). Apelo para crianças: Não. |
| **Apps de notícias** | Não é app de notícias |
| **Apps de rastreamento de contatos / status de COVID-19** | Não |
| **Segurança dos dados** | Veja a tabela abaixo |
| **Apps do governo** | Não |
| **Recursos financeiros** | Nenhum (o app não oferece empréstimo, pagamento, criptomoeda etc.) |
| **Saúde** | Não é app de saúde |
| **ID de publicidade** | **Não** usa (o app não tem anúncios nem SDK de publicidade) |

### Segurança dos dados — respostas

- **Seu app coleta ou compartilha dados do usuário?** Sim.
- **Todos os dados são criptografados em trânsito?** Sim (HTTPS).
- **Você oferece forma de o usuário solicitar a exclusão dos dados?** Sim. **URL para exclusão de conta:** `https://acumulaai.com.br/excluir-conta.html` (e dentro do app: Configurações → Excluir minha conta).
- **Tipos de dados coletados** (marque e, para cada um, indique "Coletado", propósito e se é compartilhado):

| Categoria no Console | Item | Compartilhado? | Obrigatório? | Finalidade |
|---|---|---|---|---|
| Informações pessoais | **Nome** | Sim (com a loja em que o cliente se vincula) | Obrigatório | Funcionalidade do app, Gerenciamento de conta |
| Informações pessoais | **Endereço de e-mail** | Não | Opcional | Gerenciamento de conta (recuperação de senha) |
| Informações pessoais | **Número de telefone** | Sim (com a loja vinculada) | Obrigatório | Funcionalidade do app, Gerenciamento de conta |
| Informações pessoais | **Outras informações** (declarar o **CPF**) | Sim (com a loja vinculada) | Obrigatório | Funcionalidade do app, Gerenciamento de conta |
| Informações pessoais | **IDs de usuário** (identificador da conta Google, quando usa o login com Google) | Não | Opcional | Gerenciamento de conta |
| Atividade no app | **Interações com o app** (marcações, saldo, resgates, solicitações) | Sim (com a loja vinculada) | Obrigatório | Funcionalidade do app |

- Não coleta localização, contatos, fotos, arquivos, dados financeiros, saúde nem dados de dispositivo.
- "Compartilhado" = enviado a outra empresa; aqui a loja (cliente do ACUMULAAI) recebe os dados do próprio cliente para operar o cartão fidelidade. Se o console perguntar sobre exceções, a finalidade é "funcionalidade do app" a pedido do próprio usuário.

> **Permissões do app:** `INTERNET`, `USE_BIOMETRIC` e `USE_FINGERPRINT` (esta vem de uma biblioteca do login com Google; o app **não coleta biometria**). Se o console perguntar, não é preciso declarar nada além do já dito.

---

## Etapa 4 — Página da loja (menu: **Presença na loja → Página principal da loja**)

1. **Detalhes do app:**
   - **Nome do app:** `Acumula Aí – Fidelidade`
   - **Breve descrição (80):** `Seu cartão fidelidade digital: acumule marcações e pontos nas suas lojas.`
   - **Descrição completa (4000):** copie de `PLAY_STORE.md`, seção 2.
2. **Recursos gráficos:**
   - **Ícone do app (512×512):** `docs/play-store/assets/icone-512.png`
   - **Imagem de destaque (1024×500):** `docs/play-store/assets/destaque-1024x500.png`
   - **Capturas de tela de celular (mín. 2):** envie as 6 de `docs/play-store/screenshots/` (1080×2160) na ordem: Início, Detalhe do cartão, Buscar loja, Promoções, Perfil, Configurações.
3. **Salvar.**
4. Em **Presença na loja → Configurações da loja** (ou "Categoria e informações de contato"):
   - **Categoria:** Compras (ou Estilo de vida)
   - **E-mail de contato:** `privacidade@acumulaai.com.br` (**a caixa precisa existir** — crie no cPanel antes)
   - **Site:** `https://acumulaai.com.br`

---

## Etapa 5 — Teste fechado (obrigatório para esta conta)

1. Menu **Testes e lançamento → Teste fechado → Criar faixa** (ou use a faixa "Teste fechado" padrão).
2. **Testadores:** crie uma **lista de e-mails** com **pelo menos 12 contas Google** (junte uns 15–20 para ter folga). Cada pessoa precisa de conta Google e de um celular Android.
3. **Países/regiões:** Brasil.
4. **Criar nova versão:**
   - Quando pedir, **ative o Play App Signing** e aceite a chave gerada pelo Google (padrão).
   - **Enviar o `.aab`:** `mobile/build/app/outputs/bundle/release/app-release.aab`.
   - **Nome da versão** (automático) e **Notas da versão** em pt-BR: `Primeira versão do Acumula Aí.`
5. **Revisar a versão → Iniciar lançamento para o teste fechado.** O Google faz uma análise inicial (pode levar de horas a alguns dias).
6. Quando aprovado, abra **Teste fechado → Testadores** e copie o **link de adesão** ("Como os testadores participam"). Envie o link aos testadores. Cada um deve:
   1. Abrir o link **no celular Android**, logado na conta Google que você cadastrou.
   2. Tocar em **"Tornar-se testador"**.
   3. Instalar o app pelo link da Play Store que aparece em seguida.
   4. **Abrir o app** de vez em quando durante os 14 dias, e **não sair do teste**.
7. **Contagem:** o Console mostra quantos testadores estão ativos e há quantos dias. É preciso **12 testadores inscritos por 14 dias seguidos**. Se alguém sair e o número cair abaixo de 12, a contagem pode ser prejudicada — por isso a folga.

> **Logo depois do primeiro envio**, abra **Configuração → Integridade do app → Assinatura de apps** e copie o **"Certificado da chave de assinatura do app"** (SHA-1). **Me envie esse SHA-1**: eu o cadastro no Google Cloud (login com Google). Sem isso, o login com Google falha nos aparelhos que instalam pela loja.

---

## Etapa 6 — Pedir acesso à produção (após 14 dias)

1. No Painel (ou em **Testes e lançamento → Produção**), clique em **Solicitar acesso à produção** / **Inscrever-se para produção**.
2. Responda ao questionário (em português):
   - **Sobre o app:** "Aplicativo de cartão fidelidade digital: o consumidor se vincula às lojas parceiras e acompanha suas marcações e recompensas."
   - **Sobre o teste:** quantos testadores, como foi o teste e o que você corrigiu com o feedback. Seja honesto e específico (ex.: ajustes de textos, correção de tela, login).
   - **Preparação para produção:** o app está estável, cumpre a política e já tem política de privacidade e exclusão de conta.
3. O Google analisa (em geral até 7 dias). Você recebe e-mail com a resposta.

---

## Etapa 7 — Publicar na produção

1. **Testes e lançamento → Produção → Criar nova versão.** Você pode reaproveitar o `.aab` do teste ("Adicionar da biblioteca") ou subir um novo (com `versionCode` maior — veja abaixo).
2. Países: Brasil (ou mais). Notas da versão em pt-BR.
3. **Revisar a versão → Iniciar lançamento para a produção.**
4. Aguarde a análise. Depois que for aprovado, o app fica público na Play Store.

**Número da versão:** o `versionCode` precisa **crescer a cada upload**. Está em `mobile/pubspec.yaml` (`version: 1.0.0+1`; o número depois do `+` é o `versionCode`). Antes de um novo `.aab`, mude para `1.0.0+2`, `+3`... e me peça para rebuildar.

---

## Cuidados importantes

- **Não apague** o cliente de revisão ("Revisor Google Play") enquanto o app estiver em análise.
- **A API precisa estar no ar** durante as análises (`https://api.acumulaai.com.br/health`).
- **Backup da chave de upload:** `mobile/android/app/upload-keystore.jks` + senhas em `mobile/android/key.properties` — guarde cópia em local seguro. O Play App Signing protege a chave definitiva, mas você precisa da de upload para enviar atualizações.
- Mudou algo que o app coleta? Atualize a **Segurança dos dados** e a **política de privacidade**.
- **Nunca compartilhe a senha da conta Google/Play Console** (nem comigo): se precisar de ajuda com alguma tela, cole só a mensagem de erro ou descreva o que aparece.

## Tabela rápida: quem faz o quê

| Tarefa | Quem |
|---|---|
| Verificação, pagamentos, cliques no Play Console | Você |
| Textos, imagens, capturas, `.aab`, SHA-1, backend, rebuilds | Eu (já prontos / sob demanda) |
| Lista de 12+ testadores e convite | Você |
| Cadastrar o SHA-1 da Play no Google Cloud | Eu (depois que você enviar o SHA-1) |
