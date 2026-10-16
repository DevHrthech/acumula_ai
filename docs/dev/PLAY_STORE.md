# Publicação na Google Play — ficha do app "Acumula Aí"

> Roteiro operacional, tela a tela, em [PLAY_CONSOLE_PASSO_A_PASSO.md](PLAY_CONSOLE_PASSO_A_PASSO.md).

Material pronto para preencher no Play Console. Itens marcados **[PENDENTE]** dependem de decisão ou ação de quem gerencia o projeto.

## 1. Artefato

- **Arquivo:** `mobile/build/app/outputs/bundle/release/app-release.aab` (`flutter build appbundle --release`)
- **Pacote:** `br.com.acumulaai.cliente` · **Versão:** `1.0.0+1` (a cada novo upload o número depois do `+` precisa subir — editar `version:` em `mobile/pubspec.yaml`)
- **Assinatura:** keystore de upload em `mobile/android/app/upload-keystore.jks` (fora do git). Recomenda-se ativar o **Play App Signing** no primeiro upload, para o Google guardar a chave de assinatura definitiva.

## 2. Ficha principal (pt-BR)

| Campo | Limite | Texto |
|---|---|---|
| Nome do app | 30 | `Acumula Aí – Fidelidade` |
| Descrição curta | 80 | `Seu cartão fidelidade digital: acumule marcações e pontos nas suas lojas.` |
| Categoria | — | Compras (alternativa: Estilo de vida) |
| E-mail de contato | — | `privacidade@acumulaai.com.br` (o mesmo da política; criar a caixa se ainda não existe) |
| Site | — | `https://acumulaai.com.br` |
| Política de privacidade | — | `https://acumulaai.com.br/privacidade.html` (já publicada) |

### Descrição completa (limite 4000)

```
Acabou o cartãozinho de papel esquecido na carteira.

O Acumula Aí reúne os cartões fidelidade das suas lojas favoritas em um só lugar. Você se vincula à loja, acompanha seu progresso em tempo real e sabe exatamente quanto falta para a próxima recompensa.

COMO FUNCIONA
• Crie sua conta com CPF e senha.
• Vincule-se a uma loja participante digitando o código que ela divulga.
• A cada compra, a loja registra a sua marcação (ou pontos). Você também pode solicitar a marcação pelo próprio app, informando o cupom fiscal.
• Ao atingir a meta, a recompensa é liberada automaticamente.

O QUE VOCÊ ENCONTRA NO APP
• Todas as suas lojas e seus saldos na tela inicial
• Progresso de cada cartão com a identidade visual da própria loja
• Promoções e campanhas ativas das lojas em que você está vinculado
• Resumo do seu histórico: saldo, marcações e resgates

PRIVACIDADE
Seus dados ficam protegidos e só são compartilhados com a loja à qual você se vincula. Não vendemos dados. Política completa em acumulaai.com.br/privacidade.html

Tem uma loja e quer fidelizar seus clientes? Conheça o ACUMULAAI em acumulaai.com.br
```

## 3. Imagens exigidas

| Item | Especificação | Status |
|---|---|---|
| Ícone do app | PNG 512×512, sem transparência | **RASCUNHO PRONTO** em `docs/play-store/assets/icone-512.png` (triângulo amarelo sobre o roxo da marca, o mesmo símbolo da tela de login). **Já aplicado também no app** (ícone adaptativo + legado em `mobile/android/app/src/main/res/mipmap-*`). Substituir os dois (arquivo da ficha e ícones do app) se o responsável tiver o logo definitivo. |
| Imagem de destaque | PNG/JPG 1024×500 | **RASCUNHO PRONTO** em `docs/play-store/assets/destaque-1024x500.png` (símbolo + "Acumula Aí" + slogan). Substituir se houver arte definitiva. |
| Capturas de tela de celular | mínimo 2, máximo 8; lado maior até 2× o menor | **FEITO** — 6 capturas em `docs/play-store/screenshots/` (1080×2160, proporção 2:1, sem barra de status): Início, Detalhe do cartão, Buscar loja, Promoções, Perfil, Configurações. Tiradas do celular com o cliente de revisão; refazer se a interface mudar. |

## 4. Declarações do Play Console

- **Anúncios:** não contém.
- **Compras no app:** não.
- **Público-alvo:** 18+ (evita os requisitos da política de Famílias).
- **Classificação indicativa (questionário IARC):** sem violência, sexo, linguagem imprópria, drogas, jogos de azar ou interação entre usuários → resultado esperado: Livre.
- **Acesso ao app para revisão:** o app exige login. Fornecer credenciais de teste no campo "Instruções de acesso": criar um cliente de revisão dedicado (CPF válido + senha) já vinculado a uma loja de teste. **[PENDENTE]** criar antes do envio (não usar o cliente de testes atual).
- **Permissões:** `INTERNET`, `USE_BIOMETRIC` e `USE_FINGERPRINT` (as duas últimas vêm de uma biblioteca do login com Google; o app não coleta biometria). Sem permissão de anúncio (`AD_ID`): declarar que **não** usa ID de publicidade.

### Segurança dos dados (Data safety)

| Categoria | Coleta | Compartilha | Finalidade | Obrigatório |
|---|---|---|---|---|
| Nome | Sim | Sim (loja vinculada) | Funcionalidade do app, conta | Sim |
| Telefone | Sim | Sim (loja vinculada) | Funcionalidade do app, conta | Sim |
| E-mail | Sim | Não | Conta, recuperação de senha | Não (opcional) |
| CPF (declarar em "Outras informações pessoais") | Sim | Sim (loja vinculada) | Identificação do cliente na loja, autenticação | Sim |
| Atividade no app (marcações, saldo, resgates, solicitações) | Sim | Sim (loja vinculada) | Funcionalidade do app | Sim |

- Dados criptografados em trânsito: **sim** (HTTPS).
- Usuário pode solicitar exclusão dos dados: **sim** — no app (Configurações > Excluir minha conta) e por URL pública `https://acumulaai.com.br/excluir-conta.html` (informar essa URL no campo de exclusão de dados do Console).
- Sem SDKs de anúncio ou analytics de terceiros no app.

## 5. Checklist para a publicação oficial

Legenda: **FEITO** (verificado), **VOCÊ** (depende de ação/decisão do responsável), **EU** (posso preparar no repositório). As regras da Google mudam — confirmar os valores e prazos no próprio Play Console antes de agir.

### A. Conta de desenvolvedor — VOCÊ
- [ ] Criar/validar a conta no Play Console (taxa única de US$ 25) e concluir a **verificação de identidade** (documento, endereço, telefone).
- [ ] Decidir o **tipo de conta**: *pessoal* ou *organização*. A organização (ex.: a empresa dona do produto) exige CNPJ e **número D-U-N-S**, mas costuma ficar fora da regra de teste de 12 testadores (item E). Contas pessoais novas passam por ela. Não dá para trocar o tipo depois sem recriar a conta.
- [ ] Proteger a conta com verificação em duas etapas e **nunca compartilhar a senha** (nem em chat nem com ferramentas).

### B. Artefato técnico — FEITO
- [x] Pacote definitivo `br.com.acumulaai.cliente` (sem `com.example`), `minSdk 24`, `targetSdk 36` (atende ao nível-alvo exigido para apps novos).
- [x] Android App Bundle (`.aab`) assinado com chave de release própria (`flutter build appbundle --release`), 64-bit incluído pelo Flutter.
- [x] Permissão única: `INTERNET`. Sem SDKs de anúncio/analytics.
- [x] Exclusão de conta dentro do app **e** página pública — **publicadas em produção** (`DELETE /clientes/me`, `acumulaai.com.br/excluir-conta.html`).
- [x] Política de privacidade publicada: `https://acumulaai.com.br/privacidade.html` (inclui o link para a exclusão de conta).
- [ ] A cada novo envio, subir o número da versão em `mobile/pubspec.yaml` (`1.0.0+1` → `1.0.0+2`...). **EU**
- [x] **Ícone do app:** símbolo da marca aplicado (provisório). Se houver logo definitivo: **VOCÊ** envia, **EU** aplico e rebuildo.

### C. Ficha da loja — texto pronto (seções 2 e 4), imagens pendentes
- [x] Capturas de tela do celular (6, ver seção 3). [ ] Ícone 512×512 PNG e imagem de destaque 1024×500 — **VOCÊ** (logo/arte).
- [ ] Informar telefone/e-mail/site de contato do desenvolvedor (e-mail aparece na ficha pública).
- [ ] **A caixa `privacidade@acumulaai.com.br` precisa existir e ser lida** — está publicada na política e na ficha. **VOCÊ**
- [ ] Conferir a política de privacidade: está com a razão social "HR THECH LTDA"/2RL; confirmar CNPJ e razão social corretos. **VOCÊ**

### D. Declarações no Console — texto pronto (seção 4), a preencher
- [ ] Segurança dos dados (tabela da seção 4), classificação indicativa (IARC), público-alvo 18+, anúncios: não, compras no app: não, app não é de notícias/saúde/finanças.
- [x] **Acesso ao app** (o login é obrigatório): **cliente de revisão criado em produção** ("Revisor Google Play", CPF `390.533.447-05`, vinculado à Loja Teste com 3/10 marcações). A senha não é versionada — está só na conversa com o responsável; informar CPF + senha no campo "Instruções de acesso" do Console. Não apagar enquanto o app estiver em revisão.
- [ ] Preencher a URL de exclusão de dados: `https://acumulaai.com.br/excluir-conta.html`.

### E. Teste e liberação — VOCÊ
- [ ] Enviar o `.aab` em **Teste interno** primeiro (até 100 testadores, sem revisão longa) para validar a instalação.
- [ ] Se a conta for **pessoal e nova**: manter um **Teste fechado com pelo menos 12 testadores por 14 dias seguidos** antes de poder pedir acesso à produção. (Confirmar a regra vigente no Console.)
- [ ] Pedir **acesso à produção**, escolher países (Brasil) e enviar para revisão. A primeira análise pode levar alguns dias.
- [ ] Ativar o **Play App Signing** no primeiro upload e fazer **backup do `upload-keystore.jks` e das senhas** fora deste PC.

### F. Depois de publicado
- [ ] Monitorar o Console (crashes/ANRs, avaliações) e responder a pedidos de exclusão enviados ao e-mail de contato.
- [ ] Cada atualização: subir `version`, gerar novo `.aab`, enviar. Mudanças em dados coletados exigem atualizar a seção "Segurança dos dados" e a política.

### Riscos conhecidos
- A **conta de desenvolvedor** (verificação de identidade/D-U-N-S) é o item mais provável de atrasar.
- A **revisão da Google** testa o fluxo de login: sem cliente de revisão válido o app é reprovado por "não foi possível acessar".
- O app depende da API em produção (`api.acumulaai.com.br`); se estiver fora do ar durante a revisão, a análise falha.
- **QR Code no app:** a tela "Buscar" tem um visor de câmera **ilustrativo** — o vínculo funciona só digitando o código (a leitura real de QR exigiria o pacote `mobile_scanner` + permissão de câmera, que mudaria também a declaração de permissões e de dados). Os textos do app e da ficha já foram ajustados para não prometer isso (tela Buscar: "Digite o código divulgado pela loja" + "Leitura de QR Code em breve"; estado vazio do Início; descrição da ficha).
- **Login com Google:** **funcionando e validado em produção** (login real no celular). Detalhes e pendências em [LOGIN_GOOGLE.md](LOGIN_GOOGLE.md). Pendente: depois do primeiro upload na loja, cadastrar no Google Cloud um cliente Android com o SHA-1 da chave de assinatura do Play App Signing (senão o login falha nos apps instalados pela loja). O botão da **Apple foi escondido** (decisão do responsável).
- **Recuperação de senha:** implementada e **validada em produção** (e-mail real recebido, código de uso único, reuso recusado, login com a senha redefinida). Depende de o cliente ter e-mail cadastrado (campo opcional no cadastro + "E-mail de recuperação" em Configurações). Envio via `sendmail` da hospedagem — se a caixa de entrada de algum provedor rejeitar/mandar para spam, migrar para SMTP autenticado (`server/src/utils/mailer.js`).
- **Push/biometria:** as preferências de notificação e "login biométrico" em Configurações **só gravam o valor** — ainda não há envio de push nem biometria de verdade por trás. Os subtítulos no app agora dizem "Preferência salva — será ativado em breve" e a ficha não menciona esses recursos. Implementar antes de divulgá-los como funcionalidade.
