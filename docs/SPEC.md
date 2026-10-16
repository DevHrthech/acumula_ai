# ACUMULAAI — Spec do Produto

> Documento vivo. Atualizar sempre que decisões de escopo, fluxo ou modelo de negócio mudarem.

## 1. Empresa e Produto

- **Empresa:** 2RL
- **Produto:** ACUMULAAI — sistema de fidelização digital (substitui o cartão de fidelidade de papel/carimbo)
- **Modelo de negócio:** B2B2C
  - 2RL vende o sistema para **empresas clientes** (Empresa X — ex: loja de maquiagem, cafeteria, salão, etc.)
  - A empresa cliente usa o sistema para fidelizar seus **próprios clientes finais (consumidores)**

## 2. Problema que resolve

Empresas (geralmente pequeno/médio varejo e serviços) querem fidelizar clientes com programas de pontos/carimbos, mas hoje isso é manual (cartão de papel, carimbo, planilha) — fácil de perder, falsificar ou esquecer. O ACUMULAAI digitaliza esse processo com um cartão fidelidade digital vinculado ao cliente, e dá à empresa uma marca própria (customização visual) dentro do app.

## 3. Perfis de usuário

| Perfil | Onde atua | O que faz |
|---|---|---|
| **Empresa (Empresa X)** | Plataforma **Web** | Cadastra-se, configura seu programa de fidelidade, customiza aparência, gera QR Code/código da loja, faz a marcação de compras dos clientes |
| **Cliente final (consumidor)** | **App Mobile** (iOS/Android) | Baixa o app, vincula-se a uma ou mais lojas (via QR Code ou código), acompanha seu cartão fidelidade, resgata recompensas |

## 4. Fluxo principal

### 4.1 Onboarding da Empresa (Web)
1. Empresa se cadastra na plataforma Web do ACUMULAAI.
2. Configura o programa de fidelidade:
   - Quantidade de compras/marcações necessárias para a recompensa (ex: 10 compras → 1 brinde/desconto)
   - Tipo de recompensa (desconto, brinde, etc.) — *a definir se pode ter múltiplas regras/níveis*
   - Customização visual: cor do layout do cartão que o cliente final vê no app (ex: identidade visual da marca)
3. Sistema gera um **QR Code / código único da loja**, que a empresa expõe fisicamente no ponto de venda.

### 4.2 Onboarding do Cliente Final (Mobile)
1. Cliente baixa o app ACUMULAAI (iOS/Android).
2. Escaneia o QR Code da loja **ou** digita o código da loja manualmente.
3. Fica vinculado à loja e recebe seu cartão de fidelidade digital (já customizado com a cor/identidade da empresa).

### 4.3 Ciclo de uso (recorrente)
1. Cliente faz uma compra na loja física.
2. Empresa acessa a plataforma **Web**, localiza o cliente e faz a marcação (+1 na contagem do cartão fidelidade).
3. Ao atingir a meta configurada (ex: 10 marcações), o sistema libera a recompensa para o cliente.
4. Cliente acompanha o progresso do cartão pelo app.

## 5. Diferencial / foco principal

- **Customização por empresa** é o principal diferencial do produto:
  - **Cores da loja (cor principal + cor de destaque)** — reaberto em 2026-09-15, ver seção 10 "Item novo — Cores da loja". Escolha entre uma paleta pré-definida (não é um seletor livre RGB/hex).
  - Customização visual **completa** (layout do cartão além de cor) continua fora do escopo do MVP.
  - **Upload de imagens da marca (ícone, logo no QR Code, logo de promoções)** — **entra no MVP**, ver seção 7.
  - Regras de fidelidade configuráveis por empresa (quantidade de marcações, tipo de recompensa).
- Multi-tenant desde o início: um mesmo cliente final pode estar vinculado a **múltiplas empresas/cartões** dentro do mesmo app.

## 6. Plataformas

- **App Mobile** (iOS + Android) — uso do cliente final (consumidor)
- **Plataforma Web** — uso da empresa cliente (dashboard de gestão, marcação de compras, configuração/customização)

## 7. Decisões fechadas

- **Regra de recompensa (MVP):** fixa e simples. Cada empresa configura um número N de marcações (ex: 10). Ao atingir N, o cliente ganha a recompensa e a contagem do cartão reinicia do zero. Sem níveis progressivos por enquanto.
- **Identificação do cliente na Web:** a empresa localiza/marca o cliente pelo **CPF**.
- **Stack mobile + web:** **Flutter** para o app mobile (iOS/Android) e **Flutter Web** para o painel da empresa — mesma linguagem (Dart) em todo o client, um único time/codebase de UI.
- **Banco de dados:** **MySQL remoto**, hospedado no domínio Web que a 2RL já possui (hospedagem compartilhada cPanel). Motivo: custo e infraestrutura já existentes, sem depender de serviços de terceiros.
- **Backend:** API própria em **Node.js + Express + Prisma** (ORM), rodando no mesmo domínio/hospedagem, fazendo a ponte entre os apps Flutter (mobile e web) e o MySQL. O Flutter nunca acessa o banco diretamente — sempre via essa API (REST), por segurança (credenciais de banco não podem ficar no cliente) e para centralizar regras de negócio (ex: validar marcação, calcular quando a recompensa é liberada). Express fixado na versão 4 (não a 5) por compatibilidade com a versão mais antiga de Node disponível na hospedagem (ver seção 8).
- **Estrutura de pastas do projeto:** 3 pastas na raiz, cada uma seu próprio projeto/repo de stack:
  - `web/` — projeto Flutter (Flutter Web), painel da empresa.
  - `mobile/` — projeto Flutter (Android/iOS), app do cliente final.
  - `server/` — projeto Node.js + Express + Prisma, a API.
- **Vinculação cliente ↔ loja:** QR Code **e** código digitado, ambos disponíveis desde o MVP.
- **Escopo do MVP:** o mais enxuto possível, para validar com **1 empresa piloto**. Inclui o fluxo completo (cadastro da empresa, geração de QR Code/código da loja, app do cliente com vinculação e cartão fidelidade, marcação de compra via CPF na Web, liberação de recompensa ao atingir N marcações), mas **sem customização de cor/layout** nesta primeira versão — a empresa piloto usa o layout padrão do ACUMULAAI (cores fixas), personalizado apenas pelas imagens de marca (ver item abaixo).

- **Upload de imagens da marca (MVP):** a empresa pode enviar, na tela de Configurações, no mínimo 3 imagens:

  | Imagem | Onde é usada | Formato recomendado | Tamanho/proporção recomendado | Tamanho máx. de arquivo |
  |---|---|---|---|---|
  | **Ícone** | Avatar/identificação da loja no app do cliente e em listas | PNG, fundo transparente | Quadrado, mín. 512×512px | 2MB |
  | **Logo para o QR Code** | Exibida junto/sobreposta ao QR Code (impresso na loja e na tela do app) | PNG, fundo transparente ou branco | Quadrado, mín. 512×512px | 2MB |
  | **Logo para promoções** | Banners/cards de promoções divulgadas pela empresa dentro do app | PNG ou JPG | Paisagem, mín. 1200×630px | 5MB |

  *(Specs acima são uma recomendação inicial para dar um padrão de qualidade nas telas — ajustável antes da implementação real do upload.)*

  **Armazenamento:** os arquivos ficam salvos no sistema de arquivos do próprio servidor (mesma hospedagem cPanel), servidos como arquivos estáticos pelo domínio já existente; o MySQL guarda apenas o caminho/URL de cada imagem (colunas `icone_url`, `logo_qrcode_url`, `logo_promocao_url` na tabela `empresas` — ver [MODELO_DADOS.md](MODELO_DADOS.md)), nunca o binário da imagem.

## 8. Perguntas em aberto / decisões pendentes

- [x] **Versão do Node na hospedagem cPanel confirmada: 20.20.2** (2026-09-17) — é LTS ("Iron"), bem acima do mínimo. Isso libera usar **Express 5** (só funcionava com Node 18+); o `server/` está atualmente pinado em Express 4 por precaução com a versão antiga — pode ser atualizado agora que a versão real é conhecida (resolve também o alerta de segurança do `npm audit` sobre `qs`/`body-parser`, registrado na seção 10).
- [x] **MySQL na hospedagem confirmado: 5.7.44 (cll-lve, CloudLinux)** (2026-09-17) — via cPanel "Informações do servidor". Servidor: `r200us`, IP compartilhado `107.161.183.117`, cPanel 110.0, kernel CloudLinux/LVE (ambiente com CageFS — shell restrito, sem acesso a arquivos reais do sistema). MySQL 5.7 é mais antigo (não tem `JSON` nativo completo nem `CHECK constraints` funcionais como no 8.x) — considerar ao usar features do Prisma/schema. **Acesso remoto/SSH ainda não confirmado**: plano é "Básico"; tentativas de SSH direto (porta 22 e 2222, IP e domínio) deram timeout — sintoma de bloqueio no firewall do provedor pra esse pacote, não porta errada. Pendente: perguntar à hostmidia se SSH é liberado externamente pra esse plano e qual porta.
- [x] ORM Node.js: **Prisma** (com Express). Motivo: tipagem/autocomplete a partir do schema, migrations versionadas, boa integração com MySQL.
- [ ] A marcação da compra pode ter valor monetário mínimo, ou é sempre "1 compra = 1 marcação"?
- [ ] Cliente pode perder/expirar marcações (validade do cartão)?
- [x] Cadastro/autenticação do cliente final no app: **CPF + senha** — mesmo CPF usado pela empresa na Web para marcar compras, evitando duplicidade de identificação.
- [x] **Modelo de monetização da 2RL sobre a empresa cliente — decidido (2026-09-17):** assinatura recorrente por plano, com contrato formal e licença de uso que bloqueia acesso em caso de inadimplência. Gateway de pagamento específico ainda não escolhido. Ver seção 11.
- [x] **Multi-loja / filiais — decidido e implementado (2026-09-19):** cada unidade/filial continua sendo uma linha independente em `empresas`, com login, configuração, mecânica e saldo de clientes 100% próprios (nada compartilhado). Agrupamento comercial simples via campo `empresa_pai_id` (auto-referência em `empresas`, sem entidade nova), controlado só pelo admin interno 2RL. Detalhes completos na seção 16.
- [ ] Nome/identidade do app para a loja de aplicativos, contas de desenvolvedor (Apple/Google) já existentes? — **Atualização 2026-10-09:** nome definido ("Acumula Aí – Fidelidade", pacote `br.com.acumulaai.cliente`); a conta Google Play ainda precisa ser criada/verificada pelo responsável (passo a passo em [dev/PLAY_STORE.md](dev/PLAY_STORE.md)); Apple/iOS segue fora de escopo.
- [ ] Confirmar espaço em disco disponível no plano de hospedagem cPanel para armazenar as imagens de marca de todas as empresas.
- [ ] Definir se haverá redimensionamento/otimização automática das imagens no upload (ex: lib `sharp` no Node) para garantir os tamanhos recomendados mesmo se a empresa enviar um arquivo fora do padrão.

## 9. Ordem de desenvolvimento

Para agilizar, o projeto será construído nesta ordem:

1. **Web** (painel da empresa) — mockup visual primeiro, depois código Flutter Web com dados mockados (sem backend real ainda).
2. **Mobile** (app do cliente) — mesma lógica: mockup/telas primeiro, depois código Flutter com dados mockados.
3. **Persistência real** — por último, conectar Web e Mobile à API Node.js + MySQL (schema já definido em [schema.sql](schema.sql)), substituindo os dados mockados.

### Telas do Web (MVP, fluxo mínimo)
- Login (empresa)
- Dashboard/Home
- Cadastro/Configuração da empresa (meta de marcações, descrição da recompensa, código da loja/QR Code, upload de imagens da marca)
- Marcar compra (buscar cliente por CPF e registrar marcação)

### Telas do Mobile (MVP, fluxo mínimo)
- Cadastro/Login (CPF + senha)
- Vincular loja (escanear QR Code ou digitar código da loja)
- Meus cartões (lista dos cartões fidelidade do cliente — suporta múltiplas lojas desde já, mesmo com só 1 empresa piloto ativa)
- Detalhe do cartão fidelidade (progresso, recompensa, logo/ícone da loja)
- Perfil (dados do cliente, sair)

## 10. Status atual do projeto

**Fase: mockups entregues + esqueleto dos 3 projetos criado.** Implementação das telas/funcionalidades ainda não começou.

### Mockups visuais
- **Web:** [acumulaai-web-mockup.html](../design/web/acumulaai-web-mockup.html) (arquivo local) — canvas publicado: https://claude.ai/code/artifact/010cf774-4436-44e3-9a12-d35221e8c740 — 4 telas (Login, Dashboard, Configurações com upload de imagens de marca, Marcar compra). **Aprovado pelo usuário.**
- **Mobile:** [acumulaai-mobile-mockup.html](../design/mobile/acumulaai-mobile-mockup.html) (arquivo local) — canvas publicado: https://claude.ai/code/artifact/47d44e50-00ea-4b1b-92e7-679e7618e92c — 6 telas (Login, Cadastro, Vincular loja, Meus cartões, Detalhe do cartão, Perfil). Entregue, sem ajustes pedidos.

### Estrutura de pastas / esqueleto dos projetos (criado em 2026-09-06)
- **`web/`** — projeto Flutter Web inicializado (`flutter create --platforms=web`, package Dart `acumulaai_web`). Só o esqueleto padrão do Flutter, nenhuma tela do mockup implementada ainda.
- **`mobile/`** — projeto Flutter inicializado para Android + iOS (package Dart `acumulaai_mobile`). Idem: só esqueleto padrão, nenhuma tela implementada.
- **`server/`** — projeto Node.js iniciado (`npm init`), setup do Prisma concluído:
  - `express` (fixado na v4, não v5 — ver seção 7) e `dotenv` instalados e funcionando.
  - `src/index.js` com um servidor Express mínimo (`GET /health`).
  - `prisma` (CLI) e `@prisma/client`, ambos pinados na versão **7.10.0** (a tag `latest` do pacote `prisma` no npm apontava para um release candidate da v8 no momento — evitado de propósito para não ficar em versões diferentes entre CLI e client).
  - `prisma/schema.prisma` escrito espelhando o [schema.sql](schema.sql) (mesmas tabelas/colunas: `empresas`, `clientes`, `vinculos`, `marcacoes`, `resgates`) — validado com `npx prisma validate`.
  - `prisma7.config.ts` gerado pelo `prisma init` (Prisma 7 lê a `DATABASE_URL` daqui, não mais diretamente do `schema.prisma`) + `.env` com placeholder de conexão MySQL.
  - Nota: o `prisma init` desta versão também gerou pastas `.claude/skills/`, `.windsurf/skills/`, `.agents/skills/` com documentação oficial do Prisma para assistentes de IA — inofensivo, apenas referência, não requer ação.
  - **Pendente:** `npx prisma migrate dev` (cria a migration inicial e as tabelas de fato) — só deve rodar quando houver uma `DATABASE_URL` real (aguardando acesso à hospedagem, ver seção 8) e conforme a ordem da seção 9 (persistência é a última etapa).
  - **Alerta de segurança (aceito por ora):** `npm audit` aponta vulnerabilidades transitivas — (1) `qs`/`body-parser` via Express 4, corrigível só subindo para Express 5 (evitado por compatibilidade de Node, ver seção 7); (2) `mysql2`/`deepmerge-ts` nas dependências internas do Prisma CLI. Nenhuma delas afeta código próprio ainda (sem tráfego real nem migration rodada); reavaliar quando a versão do Node na hospedagem for confirmada.

Modelagem de dados concluída e já implementada como schema Prisma — [MODELO_DADOS.md](MODELO_DADOS.md), [schema.sql](schema.sql) (documentação/referência) e `server/prisma/schema.prisma` (fonte de verdade para migrations).

### Atualização — 2026-09-15: código real substituiu os mockups (fora desta sessão) e foi reconciliado
Entre a sessão anterior e esta, o usuário desenvolveu (fora desta sessão, aparentemente com GitHub Copilot) um app Flutter real e bem mais completo que o MVP original, num repositório próprio (`github.com/DevHrthech/acumula_ai`). Esse código apareceu solto na raiz de `C:\2RL`, substituindo temporariamente nossa estrutura de pastas. O usuário reorganizou manualmente (devolveu `CLAUDE.md`/`docs/`/`design/`/`mobile/`/`server/` ao lugar, moveu o app Flutter para dentro de `web/`) e pediu para reconciliar.

**Decisões tomadas nessa reconciliação:**
- **Arquitetura:** mantida a decisão original de **2 projetos Flutter separados** (não um app único responsivo). O código encontrado era um único app com breakpoint (`kMobileBreakpoint`) que trocava entre telas mobile e web — foi **dividido**:
  - Telas puramente Web (`web_dashboard_screen`, `web_campanhas_screen`, `web_cadastro_campanha_screen`, `web_promocoes_screen`, `web_postar_promo_screen`, `web_aprovacao_screen`, `web_relatorio_clientes_screen`, `web_root_screen`, `web_sidebar`) ficaram em `web/`.
  - Telas puramente Mobile (`mobile_home_screen`, `mobile_root_screen`, `promocoes_screen`, `detalhe_promo_screen`, `perfil_screen`, `configuracoes_screen`, `lojas_screen`, `mobile_bottom_nav`, `campaign_models`, `campaign_widgets`, `promo_catalog`, `section_label`, imagens em `assets/images/`) foram **movidas** para `mobile/`.
  - `theme/` (cores + `ThemeProvider`/`ThemeScope`) e `login_screen.dart` eram compartilhados — foram **duplicados** em ambos os projetos (cada um com sua própria cópia); o `login_screen.dart` de cada projeto foi simplificado para navegar direto pra raiz do seu app (sem o `kIsWeb`/breakpoint que decidia pra onde ir).
  - Nomes dos pacotes Dart corrigidos: `web/pubspec.yaml` estava com o nome genérico `acumula_ai` (herdado do projeto original) → renomeado para `acumulaai_web`. `mobile/` já estava correto (`acumulaai_mobile`).
  - Bug corrigido: as imagens em `assets/images/` eram referenciadas via `Image.asset` no código mas nunca declaradas no `pubspec.yaml` — declaração adicionada em `mobile/pubspec.yaml` (único projeto que usa essas imagens).
  - `flutter analyze` limpo (0 issues) em ambos os projetos após a divisão. Testes padrão (`widget_test.dart`) corrigidos pra refletir o app real (antes ainda testavam o contador padrão do `flutter create`).
- **Escopo:** em revisão "parte a parte" — ver a fila de itens logo abaixo. Até cada item ser fechado, considerar as seções 1-9 deste documento como a base ainda vigente (exceto onde um item já resolvido as substitui explicitamente), e o restante do código em `web/`/`mobile/` como candidato a ser revisado/incorporado, não como substituto automático.
- **Git:** `web/` contém um repositório git próprio (`.git`) conectado a `github.com/DevHrthech/acumula_ai` (remoto real, com histórico prévio). **Não mexer no git** (sem commits, sem push, sem reorganizar) até o usuário decidir como consolidar isso — ver pendência abaixo. Há mudanças não commitadas no working tree desse repo (arquivos removidos/movidos na divisão acima).

### Pendências desta reconciliação
- [ ] Decidir o que fazer com o repositório git em `web/` (github.com/DevHrthech/acumula_ai): manter separado, mover pra raiz do projeto unificando tudo, etc. **Não tocar até o usuário decidir.**
- [ ] Revisar escopo tela por tela (campanhas, promoções, aprovação, relatório de clientes) e atualizar as seções 1-9 do SPEC conforme o que for aprovado.
- [ ] `server/` não tem nenhuma integração com o código Flutter ainda — os dois projetos Flutter usam só dado fixo/mockado no código (sem HTTP, sem state management além de `ThemeProvider`).

### Próximos passos
1. Revisar com o usuário, parte a parte, cada tela/funcionalidade nova encontrada em `web/` e `mobile/`, decidindo o que fica, o que muda e o que sai — atualizando o SPEC junto.
2. Só depois seguir para conectar `server/` (API + Prisma + MySQL) aos dois apps, substituindo os dados mockados — conforme a ordem original da seção 9.

### Revisão "parte a parte" — fila de itens

**Item 1 — mecânica de fidelidade: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** Todas as decisões fechadas (mecânica configurável por loja, campanhas sempre herdam o tipo, aprovação automática, resgate em pontos desconta só a meta, campanha expirada perde progresso, mecânica fixa após cadastro). Implementado: `schema.prisma` (server/, não migrado), tela **Configurações** nova em `web/` (dados da loja, imagens de marca, escolha de mecânica, meta, cadastro de regras de pontuação), campos **Meta**/**Validade** adicionados ao cadastro de campanha, tela de Aprovação removida. Testado rodando o app real no navegador. Detalhes completos e checklist em **[MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md)** seção 8. Essa decisão **substitui** a regra de recompensa fixa da seção 7 (mantida ali só como registro histórico do MVP original).

**Item 2 — tela de configuração da loja no Web: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** A tela **Configurações** cobre nome, categoria, imagens de marca e a mecânica de fidelidade — ver [MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md) seção 8.

**Item novo — tela "Aprovação" de compras: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** Fila de solicitações do cliente (com/sem cupom fiscal), busca por CPF ou cupom fiscal, aprovar/rejeitar, e marcação manual pela loja via CPF. Substitui o que seria "Marcar compra" do MVP original (nunca chegou a ser implementada em código real). Detalhes em [MECANICA_FIDELIDADE.md](MECANICA_FIDELIDADE.md) seção 9.

**Item 3 — nenhum dado real conectado ainda: ⏳ na fila, não iniciado (esperado nesta fase).** Tanto `web/` quanto `mobile/` usam só dado fixo no código (sem HTTP, sem Prisma, sem persistência) — condizente com a ordem de desenvolvimento da seção 9 (telas mockadas primeiro, persistência por último), não é uma pendência "quebrada", só um lembrete de que a conexão com `server/` ainda não começou.

**Item novo — Cores da loja: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** Card "Cores da loja" na tela Configurações: cor principal + cor de destaque, com **seletor RGB/HEX livre** (não é mais uma paleta fixa — dialog com sliders R/G/B + campo hexadecimal, ambos sincronizados), prévia ao vivo do cartão fidelidade. **As cores refletem no app inteiro em tempo real** (sidebar, dashboard, todas as telas Web) assim que a loja clica "Salvar alterações", sem precisar navegar — ver detalhes técnicos abaixo. Guardado em `EmpresaConfig.corPrincipal`/`corDestaque` (`web/lib/state/empresa_config.dart`) e replicado nos campos mutáveis `AppColors.primary`/`accent`/`primaryDark` (`web/lib/theme/app_colors.dart`). **Persistência em banco:** `cor_principal`/`cor_destaque` (VARCHAR(7), formato `#RRGGBB`) adicionadas em `empresas` no `schema.prisma` e `schema.sql` — schema pronto, mas **ainda sem conexão real** (server/ fora de escopo desta rodada; a loja continua salvando só em memória até a etapa 3 da seção 9 conectar a API de verdade). `mobile/` ainda não lê essas cores. Isso reabre parcialmente a customização visual que a seção 5 marcava como fora do MVP — só cor, não o layout completo do cartão.

**Detalhe técnico da propagação de cores (relevante pra quem mexer nessas telas depois):** `AppColors.primary`/`accent`/`primaryDark` deixaram de ser `const` (são `static Color` mutáveis) pra permitir troca em runtime — isso exigiu remover `const` de ~30 usos espalhados pelas telas Web (onde o widget continha uma dessas cores). A reatividade (telas atualizarem sem precisar navegar) vem de dois `ListenableBuilder` escutando `EmpresaConfig`: um em `WebShell` (`web_sidebar.dart`, cobre a sidebar) e outro em `WebRootScreen` (`web_root_screen.dart`, reconstrói a tela atual inteira). Sem isso, o padrão existente no projeto (`ThemeScope.of(context)`/`EmpresaConfigScope.of(context)` via `findAncestorStateOfType`, sem `InheritedWidget` de verdade) **não propaga muda mudanças automaticamente** — é preciso um `ListenableBuilder` explícito em algum ponto acima do que precisa reagir.

**Item novo — Textos personalizados: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** Escopo fechado com o usuário: "banners" = as telas de Campanhas/Promoções já existentes (nada novo criado ali); "textos" = foco no que o **cliente final** vê no app (painel Web fica pra depois); "botões" = o texto do CTA de resgate (a cor dos botões já é coberta por Cores da loja).

Card **"Textos personalizados"** adicionado em Configurações, logo após Cores da loja:
- Nome do programa de fidelidade (ex: "Cartão Fidelidade" → pode virar "Clube Bela Cores")
- Mensagem de boas-vindas (mostrada ao cliente ao vincular à loja)
- Mensagem de resgate (mostrada ao resgatar a recompensa)
- Texto do botão de resgate (CTA)

Com prévia ao vivo (usa `AnimatedBuilder` escutando os `TextEditingController`s diretamente — não precisa de `setState` a cada tecla). Guardado em `EmpresaConfig.nomePrograma`/`mensagemBoasVindas`/`mensagemResgate`/`textoBotaoResgate`. Schema atualizado (`nome_programa`, `mensagem_boas_vindas`, `mensagem_resgate`, `texto_botao_resgate` em `empresas`, no `schema.prisma` e `schema.sql`) — mesma ressalva das cores: sem conexão real ainda. `mobile/` ainda não lê esses textos. `flutter analyze` limpo; testado no navegador (editei o nome do programa, vi a prévia atualizar ao vivo, salvei, naveguei pra Dashboard e voltei confirmando que persistiu na sessão).

**Ainda não abordado desta rodada (fica pra quando chegarmos lá):** textos do próprio painel Web (rótulos que a loja vê, não o cliente) e a customização de textos/botões dentro do app mobile em si (mobile/ segue fora de escopo).

**Item novo — Cartão de exemplo: ✅ CONCLUÍDO (aprovado pelo usuário em 2026-09-15).** A pedido do usuário, criado um card dedicado no final de Configurações — formato de cartão real (não mais um preview pequeno dentro de outro card), reunindo tudo que foi configurado: ícone, nome do programa, nome da loja, cor principal/destaque, barra de progresso (com valor de exemplo — 60% da meta, rotulada "marcações" ou "pontos" conforme a mecânica), descrição da recompensa e o texto do botão de resgate. Atualiza ao vivo (`AnimatedBuilder` escutando os `TextEditingController`s relevantes) conforme a loja digita ou muda cor/mecânica. As duas prévias pequenas que já existiam dentro de "Cores da loja" e "Textos personalizados" foram **mantidas como estavam** (usuário pediu explicitamente pra não mexer nelas) — o cartão de exemplo é adicional, não substitui. `flutter analyze` limpo; testado no navegador (editei o texto do botão e confirmei que o cartão de exemplo atualizou em tempo real).

### Atualização — 2026-09-17/18: deploy real em produção + início da API (server/)

**Infraestrutura em produção (cPanel/Hostmídia), tudo testado e no ar:**
- **Web:** `https://acumulaai.com.br` servindo o build de produção do Flutter Web (`flutter build web`), enviado via FTP (conta `web@acumulaai.com.br`, diretório `public_html`). HTTPS funcionando (certificado do domínio principal).
- **API:** `https://api.acumulaai.com.br` — subdomínio criado no cPanel, DNS propagado sozinho no Cloudflare (que gerencia o DNS do domínio), HTTPS via proxy Cloudflare funcionando. App Node rodando via "Setup Node.js App" (Passenger) apontando pra `/home/acumulaai/server` (raiz do documento do subdomínio é uma pasta separada auto-criada pelo cPanel — normal, é só a "ponte" do Passenger). `GET /health` responde `{"status":"ok"}`.
- **Banco:** MySQL remoto (`107.161.183.117:3306`, banco `acumulaai_app`) com o schema aplicado via `npx prisma db push`.
- **Deploy por FTP:** contas dedicadas criadas — `acumulaai_app@acumulaai.com.br` → `/home/acumulaai/server`, `web@acumulaai.com.br` → `/home/acumulaai/public_html`. Usadas via `curl --ftp-ssl` (FTPS explícito, porta 21) direto do terminal, sem precisar de SSH (que segue bloqueado pelo provedor, pendência da seção 8).

**Descoberta técnica importante — Prisma 7 na hospedagem:** rodar `npx prisma generate`/`db push` **no servidor** cPanel trava com `RangeError: WebAssembly.Instance(): Out of memory` — o plano "Básico" tem um limite de memória (LVE/CloudLinux, mais baixo que o `ulimit -a` do SO reporta) insuficiente pro schema-engine WASM do Prisma 7. **Solução adotada:** rodar o CLI do Prisma **localmente** (máquina de desenvolvimento), apontando `DATABASE_URL` pro MySQL remoto (acesso liberado via "MySQL remoto" no cPanel, host `%`). O servidor cPanel nunca precisa rodar o CLI do Prisma — só a aplicação Node em si (que não usa o WASM em runtime, ver abaixo). Regra prática: **todo `prisma generate`/`db push`/`migrate` roda local, contra o banco remoto; o deploy do servidor só recebe código já pronto.**

**Descoberta técnica importante — Prisma 7 exige driver adapter:** o gerador padrão (`prisma-client`) do Prisma 7 emite só TypeScript (incompatível com o `server/` que é Node/CommonJS puro, sem toolchain TS) — trocado para o gerador clássico `prisma-client-js`, que gera CommonJS de verdade. Além disso, o Prisma 7 **removeu o engine nativo/Rust**: não basta mais só `DATABASE_URL`, é obrigatório passar um **driver adapter** (`@prisma/adapter-mariadb`, compatível com MySQL) na instantiação do `PrismaClient`. Detalhe de implementação: o pacote `mariadb` exige esquema `mariadb://` em strings de conexão, mas o Prisma exige `mysql://` no `DATABASE_URL` — por isso `src/prisma.js` faz o parse manual da URL e monta um objeto de config em vez de passar a string direto pro adapter.

**Autenticação da Empresa: implementada, testada e já em produção (aguardando aprovação final do usuário).** `POST /auth/empresa/registrar` (valida CNPJ com dígito verificador, e-mail/CNPJ únicos, gera `codigo_loja` aleatório), `POST /auth/empresa/login`, `GET /empresas/me` (protegida por JWT, `src/middleware/authEmpresa.js`). Senha com `bcryptjs` (custo 12). Testado: registro, login, acesso sem token (401), senha errada (401), CNPJ duplicado (409) — todos corretos.

**Pegadinha de deploy descoberta nesta rodada:** todo o desenvolvimento de `server/` até aqui rodou **localmente** contra o banco remoto (ver acima) — inclusive os testes de autenticação. Ao atualizar só o `src/index.js` do servidor (pra adicionar CORS) sem notar que rotas/middlewares/utils/`src/prisma.js`/o Prisma Client gerado **nunca tinham sido enviados** pro servidor, o app quebrou em produção (`MODULE_NOT_FOUND`). Corrigido enviando os ~32 arquivos faltantes via FTP. **Lição:** qualquer novo arquivo `.js` criado em `server/src/` precisa ser enviado ao servidor explicitamente (não existe deploy automático/CI ainda) — checklist mental: rota nova → nunca esquecer de subir o arquivo antes de tocar no `index.js` que a referencia. Também aprendido: `touch tmp/restart.txt` via FTP **não reinicia** o app Node gerenciado pelo "Setup Node.js App" do cPanel de forma confiável — usar o botão "Restart" da própria interface.

Ver seção 11 para o módulo de gestão comercial (admin interno, planos, licenças, contratos) construído na mesma sessão.

## 11. Gestão comercial 2RL — licenciamento, contratos e cobrança

Decisão do usuário (2026-09-17): além do produto em si, a 2RL precisa de um **painel interno** para controlar as empresas-clientes contratantes do serviço, gerar contratos e cobrar por assinatura — no molde de como a TecnoSpeed licencia módulos a softwares parceiros.

**Decisões fechadas:**
- **Ator novo:** `AdminInterno` (equipe 2RL) — login próprio (`/auth/admin/login`), **sem rota pública de cadastro**; criado só via `server/scripts/seed-admin.js` (rodado manualmente, nunca exposto via HTTP).
- **Licença bloqueia acesso por inadimplência com período de tolerância:** ao vencer (`Licenca.data_vencimento`), a empresa entra em estado `INADIMPLENTE` durante `dias_tolerancia` (padrão 5 dias); passado esse prazo, bloqueia **todo** o acesso da Empresa (login/API), não só ações específicas. O status "efetivo" é **calculado por data** (`server/src/utils/licenca.js`), não depende de um cron job — o campo `status` gravado só existe pra permitir override manual (`BLOQUEADA`/`CANCELADA` sempre prevalecem sobre o cálculo por data).
- **Contrato com geração de documento + assinatura eletrônica** (decisão do usuário) — modelo `Contrato` já tem os campos (`documento_url`, `assinatura_provedor`, `assinatura_id`), mas a **integração de verdade com um provedor (Clicksign/D4Sign ou similar) ainda não foi escolhida** — por ora o ciclo de vida do contrato (`RASCUNHO` → `AGUARDANDO_ASSINATURA` → `ASSINADO`/`CANCELADO`) é atualizado manualmente pelo admin via API.
- **Gateway de pagamento: ainda não escolhido** (usuário decidiu deixar em aberto) — schema modelado de forma agnóstica (`Licenca.gateway_provedor`/`gateway_assinatura_id` nulos até então); cobrança/renovação de licença é **manual** (admin atualiza `data_vencimento`/`status` via `PATCH /admin/licencas/:id`) até um gateway ser integrado.

**Implementado e testado localmente (contra o banco de produção), aguardando aprovação/deploy:**
- Schema: `AdminInterno`, `Plano`, `Licenca`, `Contrato` (ver `schema.prisma`/`schema.sql`), já aplicado no MySQL de produção via `prisma db push`.
- Rotas: `POST /auth/admin/login`; `GET /admin/empresas` (lista + status de licença); `GET /admin/empresas/:id` (detalhe + licenças + contratos); `GET`/`POST /admin/planos`; `POST /admin/empresas/:id/licencas`; `PATCH /admin/licencas/:id`; `POST /admin/empresas/:id/contratos`; `PATCH /admin/contratos/:id` — todas protegidas por `authAdmin` (JWT próprio, `tipo: 'admin'`, distinto do token de Empresa).
- Testado: login admin, listagem de empresas com status de licença, criação de plano, atribuição de licença vencida (confirma bloqueio automático — `status_efetivo: 'BLOQUEADA'`), confirmação de que `GET /empresas/me` retorna 403 nesse caso, renovação da licença (empurra vencimento, `status_efetivo` volta a `'ATIVA'`) e confirmação de que o acesso volta a funcionar, criação/atualização de contrato.
- **Dados de teste no banco de produção (mantidos a pedido do usuário, 2026-09-17):** empresa "Loja Teste" (CNPJ fictício válido), plano "Plano Básico" (R$99,90), 1 licença e 1 contrato de teste vinculados a ela. Admin real criado: `admin@2rl.com.br` (senha definida fora deste documento).

**Painel Web do admin interno: implementado, publicado e testado em produção (aguardando aprovação final do usuário).** Dentro do próprio `web/` (decisão do usuário: mesmo projeto Flutter, não um projeto separado), mas com **entrypoint próprio** (`lib/main_admin.dart`, bundle JS isolado do painel da Empresa) — telas: `AdminLoginScreen`, `AdminShell` (sidebar Empresas/Planos), `AdminEmpresasScreen` (lista + status de licença), `AdminEmpresaDetalheScreen` (dados da empresa, licenças com nova/renovar/bloquear/cancelar, contratos com novo/avançar status), `AdminPlanosScreen` (lista + criar). Cliente HTTP em `lib/services/admin_api.dart`, sessão em `lib/state/admin_session.dart`. Testado primeiro localmente (porta 5552) contra a API real de produção, depois publicado em `https://admin.acumulaai.com.br` (ver abaixo) e retestado ao vivo: login, listagem de empresas, detalhe — confirmados no navegador direto na URL de produção.

**Decisão de segurança aplicada (usuário, 2026-09-17):** achar o painel só por um parâmetro de URL no domínio público (`?admin=1`) foi identificado como fraco (descobrível inspecionando o JS, sem nenhuma barreira de infraestrutura). Decisão: publicar o bundle do admin (`flutter build web -t lib/main_admin.dart -o build/admin`) em um **subdomínio dedicado**, não linkado do site público — feito: **`https://admin.acumulaai.com.br`**, no ar.

**Deploy do subdomínio admin — passo a passo que funcionou (registrar pra próxima vez):**
1. Registro DNS **A** criado manualmente no **Cloudflare** (`admin` → `107.161.183.117`) — confirmado de novo que criar um subdomínio só no cPanel não propaga pro Cloudflare sozinho (mesma pegadinha do `api.`, ver acima); aqui o usuário criou o registro direto no Cloudflare.
2. Subdomínio criado no **cPanel → Domínios** (`admin` + `acumulaai.com.br`) — isso cria a pasta/document root que o Apache serve.
3. Conta FTP dedicada: login `admin@acumulaai.com.br` (⚠️ domínio do login precisa ser `acumulaai.com.br`, **não** `admin.acumulaai.com.br` — errar isso muda o login final), diretório `admin.acumulaai.com.br` (nome exato da pasta que o cPanel criou — digitar path errado nesse campo cria uma pasta nova no lugar errado, aconteceu 2x até acertar).
4. Upload dos 39 arquivos do build via `curl --ftp-ssl`, igual ao `web/`.
5. **Cache do Cloudflare mascarou o primeiro teste:** a primeira tentativa de acesso bateu no Cloudflare *antes* do upload do `main.dart.js` terminar, e o Cloudflare **cacheou o 404** daquele instante — mesmo depois do arquivo estar 100% no servidor (confirmado batendo direto no IP de origem, sem Cloudflare, retornando 200), o navegador continuava recebendo 404 do edge. Resolvido com **Cloudflare → Caching → Purge Everything**. Lição: depois de subir um build nesse domínio pela primeira vez, purgar o cache do Cloudflare antes de testar, ou esperar a origem responder 200 direto (`curl -H "Host: ..." http://<ip>/...`) antes de testar pelo domínio.
6. Confirmado com CORS (`Origin: https://admin.acumulaai.com.br` → header `access-control-allow-origin` correto) e login real funcionando ao vivo na URL de produção.

**Também descoberto nesta rodada — CORS:** a API não tinha CORS habilitado; qualquer painel Web chamando-a de um domínio diferente (`localhost` em dev, ou os domínios de produção) era bloqueado pelo navegador. Adicionado `cors` no Express (`server/src/index.js`) com allowlist explícita (`acumulaai.com.br`, `admin.acumulaai.com.br`, `localhost:*`) — não usa cookies, só Bearer token, então o risco de CORS aberto é baixo, mas a allowlist evita chamadas de origens arbitrárias mesmo assim.

**Ainda não construído:** geração automática de documento de contrato a partir de modelo, integração real com provedor de assinatura eletrônica, integração real com gateway de pagamento, e qualquer automação de cobrança recorrente (hoje é 100% manual pelo admin, via API/painel).

### Atualização — 2026-09-18: chaves primárias em UUID + monitoramento de uso da API

**UUID em todas as tabelas (decisão do usuário, 2026-09-18):** todas as PKs/FKs do `schema.prisma`/`schema.sql` migraram de `INT AUTO_INCREMENT` para `String @default(uuid()) @db.VarChar(36)` — boa prática pra não expor contagem/sequência via ID nem deixar IDs previsíveis em URLs/tokens. Como não dá pra converter `INT`→UUID preservando os dados, o banco de produção foi resetado (`prisma db push --force-reset`, com confirmação explícita do usuário — o Prisma bloqueia esse comando por padrão quando detecta que quem está rodando é um agente de IA, exigindo consentimento direto na hora). Dados de teste recriados do zero (empresa, plano, licença, contrato, admin). Ajustado em `server/src/routes/admin.js` (removidos os `Number(req.params.id)`, IDs agora são strings) e no painel Flutter admin (todos os `int`/`as int` viraram `String`/`as String`). Testado ponta a ponta local e em produção.

**Monitoramento de uso da API (decisão do usuário: visibilidade agora, limite de uso fica pra depois):** nova tabela `requisicoes_api` (sem `@relation` de propósito — é telemetria, não deve travar/cascatear com exclusão de Empresa/Admin) registrada por um middleware global (`src/middleware/logRequisicao.js`) no evento `finish` de cada resposta — grava método, rota (normalizada, ex: `/admin/empresas/:id`, não a URL com o ID de verdade), status, duração, e quem fez a chamada (`empresa_id`/`admin_id`, se autenticado). Gravação é *fire-and-forget* (nunca bloqueia nem derruba a resposta real). Endpoints agregados em `src/routes/adminMonitoramento.js`: `GET /admin/monitoramento/resumo` (volume 24h/7d, taxa de erro por classe de status, latência média, top 5 endpoints) e `GET /admin/monitoramento/uso-por-empresa` (chamadas por empresa nos últimos 7 dias). Tela nova no painel admin (`AdminMonitoramentoScreen`, item "Monitoramento" na sidebar) consumindo isso. Tudo protegido pelo mesmo `authAdmin` (mesmo login do admin, sem sistema de acesso separado — confirmado com o usuário).

**Bug de robustez encontrado e corrigido nesta rodada:** a primeira versão da rota de monitoramento não tinha `try/catch`, e um timeout transitório de conexão com o banco remoto (instabilidade de rede já conhecida nesta sessão) virou uma *unhandled promise rejection* que **derrubou o processo Node inteiro** (Express 4 não captura rejeições de handlers `async` sozinho — só a partir do Express 5). Corrigido de forma geral, não só nessa rota: criado `src/utils/asyncHandler.js` (encaminha qualquer erro pro Express via `next(err)`) e um error handler global no fim de `index.js`; todas as rotas de `admin.js`, `adminMonitoramento.js`, `empresa.js`, e o próprio middleware `authEmpresa` (que faz uma consulta ao banco) foram envolvidos nisso. Testado forçando o mesmo tipo de erro de novo: agora responde 500 genérico e o servidor continua no ar.

**Pegadinha de deploy repetida nesta rodada:** de novo esqueci de subir um arquivo novo (`src/middleware/logRequisicao.js`) junto com o resto — o app quebrou em produção com `MODULE_NOT_FOUND` até eu perceber e completar o upload. Reforça a lição já registrada acima: **sempre conferir a lista completa de arquivos novos/modificados antes de declarar um deploy pronto**, idealmente com um `find` comparando local vs. servidor em vez de montar a lista de memória.

### Atualização — 2026-09-17/18 (madrugada): segurança e boas práticas (Bloco A — código)

Contexto: usuário pediu pra tratar segurança/contramedidas contra invasão, priorizado em blocos (A: código do servidor: eu faço direto; B: rotação de credenciais expostas no chat: ação do usuário; C: infraestrutura cPanel/Cloudflare: te guio; D: decisões maiores como refresh token/CAPTCHA: discutir antes). Trabalho abaixo é só o Bloco A. **Feito e testado só localmente** (usuário foi dormir e pediu explicitamente pra eu não fazer deploy nem pedir restart em produção sem ele por perto — ver `feedback_no_unattended_prod_deploys` na memória). Sessão contínua via `CronCreate` local (a cada 30 min, expira em 7 dias ou quando a sessão fechar) — agendamento em nuvem (`/schedule`) foi avaliado e descartado: roda isolado sem acesso ao `C:\2RL` local nem ao `.env`, e `server/` nem tem repositório Git ainda.

**Aplicado:**
- **`express-rate-limit`**: `limiteLogin` (10 tentativas/15min, **compartilhado** entre `/auth/empresa/login` e `/auth/admin/login` — mesma instância de middleware nos dois arquivos, então o balde é por IP através dos dois endpoints, não dá pra burlar trocando de rota) e `limiteRegistro` (5/hora em `/auth/empresa/registrar`, pra dificultar cadastro em massa automatizado, já que não tem CAPTCHA). `limiteGeral` (300/15min) aplicado global como rede de segurança básica contra abuso/DoS. `app.set('trust proxy', 1)` necessário porque a API fica atrás do Cloudflare — sem isso o rate limit contaria todo mundo pelo mesmo IP (o do proxy).
- **`helmet`**: headers de segurança padrão (`Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, CSP básica, etc). Único ajuste necessário: `crossOriginResourcePolicy: { policy: 'cross-origin' }` — o padrão do helmet (`same-origin`) bloquearia os painéis Web/Admin (subdomínios diferentes) de consumir a API mesmo com CORS liberado, já que são camadas de proteção independentes no navegador. Testado que CORS + helmet continuam funcionando juntos.
- **JWT com `algorithms`/`algorithm` explícitos** (`HS256`) tanto no `jwt.verify` (middlewares `authEmpresa`/`authAdmin`) quanto no `jwt.sign` (rotas de login) — defesa contra ataques de confusão de algoritmo (ex: um token forjado com `alg: none` sendo aceito). Testado que login/rotas protegidas continuam funcionando.
- **Limite de tamanho do payload JSON**: `express.json({ limit: '100kb' })` — nenhuma rota hoje precisa de payload grande (sem upload de arquivo via JSON).
- **`npm audit` — driver `mariadb` corrigido:** a versão fixada pelo `@prisma/adapter-mariadb` (3.4.5) tinha 3 vulnerabilidades **altas**, incluindo vazamento de senha em texto claro mesmo com `ssl:true` e um SQL injection em certos charsets (big5/gbk/sjis/cp932/gb18030). Forçado via `overrides` no `package.json` do `server/` pra `^3.5.4` (fora do range vulnerável) — funciona normalmente, testado.
- **`npm audit fix` (não-destrutivo):** corrigiu `qs`/`body-parser` (moderado, DoS) sem tocar na versão major do Express.
- **Risco aceito e documentado:** `mysql2`/`deepmerge-ts` (altas) são dependências só do **CLI** do Prisma (`devDependencies`, nunca rodam no servidor em produção — só quando eu rodo `prisma generate`/`db push` localmente). Corrigir exigiria rebaixar o Prisma pra 6.x, o que não faz sentido dado que fixamos 7.x deliberadamente. Exposição real: só se alguém interceptar minha própria conexão local durante um `db push` — janela estreita, aceito por ora.
- **Flutter (`web/`):** `flutter pub outdated` — todas as dependências diretas em dia; só 3 transitivas com patch/minor disponível (sem CVE conhecido).
- **Confirmado:** nenhuma query SQL crua (`$queryRawUnsafe`/`$executeRawUnsafe`) em nenhuma rota — tudo via Prisma Client parametrizado, sem superfície de SQL injection própria.
- **Confirmado:** `.gitignore` do `server/` já cobre `.env` (mas o `server/` nem tem `.git` inicializado ainda, então não há risco de commit acidental agora).
- **Timing side-channel corrigido nos dois logins (empresa e admin):** antes, quando o email não existia, a resposta era mais rápida (pulava o `bcrypt.compare`); quando existia mas a senha estava errada, era mais lenta — dava pra descobrir quais emails estão cadastrados só medindo o tempo de resposta. Corrigido rodando `bcrypt.compare` sempre, contra um hash "morto" pré-computado quando o usuário não existe, igualando o tempo. Testado: diferença caiu de uma gap perceptível pra ~12ms (ruído de rede), com os dois tipos de login (empresa e admin) continuando funcionando normalmente.
- **TLS na conexão com o MySQL (achado + corrigido nesta rodada):** o `DATABASE_URL` não especificava SSL, e a conexão (pelo menos a minha, local, até o banco remoto pela internet) rodava sem criptografia — risco de dados (inclusive CPF/CNPJ) trafegando em texto claro nesse trecho. Testei manualmente e confirmei que **a Hostmídia suporta TLS** (negociou `DHE-RSA-AES128-GCM-SHA256`). Ativado em `server/src/prisma.js`: adapter agora passa `ssl: { rejectUnauthorized: false }` por padrão (desligável via `DB_SSL=false` se algum dia a conexão local produção→`localhost` não suportar). `rejectUnauthorized: false` porque o certificado da Hostmídia não é de uma CA pública (comum em hospedagem compartilhada) — mesmo assim criptografa o tráfego, só não valida a cadeia. Testado localmente: login, rota protegida e `/health` continuam funcionando normalmente com SSL ativo. **Pendente:** ao fazer o deploy (produção conecta via `localhost`, não pela internet — risco bem menor, mas vale confirmar que a negociação SSL funciona igual nesse caminho antes de considerar fechado).
- **Rate limiting: brecha de spoofing de IP — corrigida só pela metade, falta a parte de infraestrutura.** O limitador dependia de `req.ip`, que depende do `trust proxy` contar certo quantos proxies existem entre o cliente e o Node (Cloudflare + Apache/Passenger) — contagem errada permitiria forjar `X-Forwarded-For` pra burlar o limite. Mudei os 3 limitadores (`src/middleware/rateLimiters.js`) pra usar `CF-Connecting-IP` como fonte primária, com fallback pra `req.ip` (via `ipKeyGenerator`, trata IPv6 corretamente) — testado, baldes corretamente separados por IP.
  - **Porém — achado no ciclo seguinte:** `CF-Connecting-IP` só é confiável se **for impossível acessar o servidor de origem sem passar pelo Cloudflare**. Testei batendo direto no IP do servidor (`107.161.183.117`, que já usamos a sessão inteira pra FTP/MySQL — não é segredo) com um `CF-Connecting-IP` forjado, e a origem **aceitou normalmente** (`{"status":"ok"}`). Ou seja, hoje um atacante que descubra o IP de origem (não é difícil — histórico de DNS, certificate transparency logs, etc.) pode pular o Cloudflare inteiro e forjar esse header à vontade, voltando a burlar o rate limit.
  - **Correção real precisa ser em infraestrutura (Bloco C, pendente — não fiz, é mudança em produção):** restringir o Apache/cPanel pra só aceitar conexões nas portas 80/443 vindas dos IPs publicados do Cloudflare (via `.htaccess` com `Allow`/`Deny`, ou firewall do cPanel, ou o recurso "Authenticated Origin Pulls" do próprio Cloudflare, que é a forma mais robusta — usa certificado mTLS, não só faixa de IP). Até isso ser feito, considerar o rate limiting como uma camada de defesa "best-effort", não uma garantia contra um atacante que já sabe o IP de origem.
- **Status code de erro corrigido:** JSON malformado no corpo da requisição (`express.json()` falha ao parsear) retornava **500 "Erro interno do servidor"** — semanticamente errado (é erro do cliente, não do servidor) e polui métricas de erro de servidor com erros de input. Handler global de erro (`index.js`) agora respeita `err.status`/`err.statusCode` quando o próprio erro já vem marcado como 4xx (é o caso do `body-parser`), retornando 400 "Requisição inválida" nesses casos. Testado: JSON malformado → 400, login normal → 200 (sem regressão).
- **Erro meu cometido e corrigido nesta rodada — apaguei o registro errado na "limpeza de testes" de um ciclo anterior.** Ao limpar dados de teste, deletei a licença que eu tinha **renovado** (vencimento no futuro, `ATIVA`) achando que era duplicata, e mantive sem querer a licença original — que tinha sido criada de propósito com vencimento no passado só pra testar o bloqueio automático (`status_efetivo: BLOQUEADA`). Resultado: a empresa "Loja Teste" ficou bloqueada (`GET /empresas/me` retornando 403) até eu perceber no teste de fumaça completo deste ciclo. Corrigido renovando a licença remanescente (`PATCH /admin/licencas/:id`, vencimento empurrado +30 dias, status `ATIVA`) — confirmado que `/empresas/me` volta a 200. **Lição:** ao limpar dados de teste em ciclos futuros, checar o `status_efetivo` de cada licença antes de decidir qual é "a de verdade" e qual é ruído — não basear só em qual foi criada primeiro/por último.
- **Validação de formato de email adicionada:** o cadastro de empresa só checava se o campo `email` não estava vazio, aceitando qualquer string (ex: "não-é-email"). Adicionada checagem simples de formato (`nome@dominio.algo`, não precisa ser uma regex RFC completa) antes de gravar. Testado: formato inválido → 400, formato válido → 201 sem regressão. Registro de teste removido do banco.
- **Validação de entrada reforçada em `authEmpresa.js` (registro):** `metaFidelidade` agora exige inteiro entre 1 e 1000 (antes aceitava qualquer valor, inclusive negativo — a coluna é `UnsignedInt`, então virava erro 500 genérico do MySQL em vez de um 400 claro); `nome`/`email`/`categoria`/`descricaoRecompensa` agora checam o tamanho máximo batendo com as colunas `VARCHAR` do banco, pelo mesmo motivo. Testado: valores inválidos retornam 400 com mensagem clara, registro válido continua funcionando (201). Registro de teste criado durante o teste foi removido do banco de produção.
- **Validação de entrada reforçada em `admin.js`:** `valorMensal` (plano) precisa ser número positivo; `dataInicio`/`dataVencimento`/`dataAssinatura` são checadas com `Number.isNaN(data.getTime())` antes de gravar (evita `Invalid Date` silencioso no banco); `diasTolerancia` precisa ser inteiro ≥ 0; e — a mais importante — `POST /empresas/:id/contratos` agora confere que a `licencaId` informada **realmente pertence** à empresa do path antes de vincular (antes dava pra, por engano ou má-fé, criar um contrato de uma empresa apontando pra licença de outra). Todas testadas: casos inválidos retornam 400, e o fluxo normal (criar licença/contrato válidos) continua funcionando.

**Pendente para quando o usuário acordar (ver também blocos B/C/D na conversa):**
- Deploy do Bloco A pra produção (precisa de restart manual no cPanel).
- **Bloco B (ação do usuário):** trocar a senha do MySQL (`acumulaai_app`) e das 3 contas FTP (mesma senha reutilizada nas 3) — coladas em texto puro no chat várias vezes ao longo da sessão. Invalidar a chave SSH + senha coladas em sessão anterior.
- **Bloco C (infraestrutura, preciso te guiar):** restringir "MySQL remoto" no cPanel (hoje liberado pra `%`, qualquer IP da internet) a hosts específicos; ativar "Force HTTPS Redirect" nos 3 domínios/subdomínios; avaliar Bot Fight Mode / rate limit no Cloudflare; **(novo, prioridade alta) bloquear acesso direto à origem** (só aceitar tráfego do Cloudflare — "Authenticated Origin Pulls" ou allowlist de IP no Apache), senão o rate limiting inteiro (e o `CF-Connecting-IP`) é contornável por quem descobrir o IP `107.161.183.117`.
- **Bloco D (decisão, discutir antes de construir):** expiração de JWT mais curta + refresh token (hoje 7 dias sem revogação); CAPTCHA ou aprovação manual no cadastro público de empresa.

### Observação — tráfego de produção madrugada 2026-09-18 (investigada, provavelmente benigna)

Usei o próprio endpoint de monitoramento (`GET /admin/monitoramento/resumo`, só leitura, já estava em produção antes de eu passar a trabalhar só localmente — não precisou de deploy) pra checar se algo estranho aconteceu no servidor de verdade enquanto ninguém olhava.

**Primeira checagem** (24h): 103 requisições, 72×2xx, 31×4xx, 0×5xx. **Segunda checagem, ~30 min depois:** subiu pra 125 (103→125), e apareceu uma rota nova no top 5: `GET /` com 21 chamadas — uma rota que **não existe** na nossa API (não tem handler pra raiz `/`) e que eu nunca testei.

**Investiguei a fundo** (consulta direta na tabela `requisicoes_api`, últimas 2h, agrupado por rota/método/status): **toda chamada exceto `GET /` bate exatamente com meus próprios testes** desta madrugada (logins de admin/empresa, `/empresas/me`, CRUD de licença, registro de empresa, etc. — inclusive o 403 do bug da licença que corrigi mais cedo aparece aí). Só sobra o `GET /`, que retorna o 404 padrão do Express (`Cannot GET /`, sem vazar nada sensível).

**Avaliação:** um scanner malicioso típico tentaria várias rotas conhecidas de vulnerabilidade (`/wp-login.php`, `/.env`, `/phpmyadmin`, `/admin.php` etc.) — aqui apareceu só **uma rota repetida em intervalos regulares**, o que combina bem mais com um **health-check/monitor de uptime automatizado** (Cloudflare ou algum serviço de monitoramento) batendo periodicamente na raiz do domínio pra checar se está no ar, do que com uma tentativa de invasão. Não é 100% certeza, mas a hipótese mais provável é que seja benigno. Não tomei nenhuma ação (só leitura/investigação). **Vale confirmar quando acordar** — se você tiver algum uptime monitor configurado (Cloudflare Health Checks, UptimeRobot, etc.), isso explicaria totalmente.

**Acompanhamento (mais 2 checagens ao longo da madrugada):** o crescimento do `GET /` seguiu **lento e constante** (21 → 23 em ~30 min, sem picos), sem nenhuma rota nova suspeita aparecendo, 0 erro de servidor o tempo todo. Rebaixo essa observação pra baixa preocupação — o padrão é consistente com monitoramento automatizado, não com uma tentativa de invasão em andamento. Segue valendo dar uma olhada quando acordar, só que sem urgência.

## 12. Conectando o painel da Empresa (`web/`) a dados reais — Fase 1: Login + Configurações

Decisão do usuário (2026-09-19): começar a tirar o `web/` do modo 100% mockado, por fases. **Fase 1 escolhida:** Login real + tela Configurações lendo/gravando de verdade na API — as duas áreas que já tinham (ou só precisavam de um endpoint a mais) suporte pronto no backend. Fases seguintes (Aprovação/marcação, Campanhas, Dashboard/Relatório) ficam pra depois — exigem construir bastante rota nova (Cliente/Vínculo/Marcação, CRUD de Campanha) ou decisão de produto (o que é "Vendas"/"Faturamento" no nosso modelo, que hoje não existe).

**Backend novo:**
- `PATCH /empresas/me` (`server/src/routes/empresa.js`) — atualiza `nome`, `categoria`, `metaFidelidade`, `descricaoRecompensa`, `corPrincipal`/`corDestaque` (valida formato `#RRGGBB`), `nomePrograma`, `mensagemBoasVindas`, `mensagemResgate`, `textoBotaoResgate`. Fora do escopo por decisão de negócio ou falta de infra: `email`/`cnpj`/senha (fluxos próprios), `tipoFidelidade` (fixo após cadastro, ver MECANICA_FIDELIDADE.md), imagens de marca (sem endpoint de upload ainda). Mesmas validações de tamanho/faixa já usadas no registro. Testado local e em produção: valores válidos persistem, valores inválidos retornam 400, sem regressão no `GET /me`.

**Frontend (`web/`):**
- `lib/services/empresa_api.dart` (novo) — cliente HTTP (login, me, atualizarMe), mesmo padrão do `admin_api.dart`.
- `lib/state/empresa_session.dart` (novo) — `EmpresaSession`/`EmpresaSessionScope`, guarda o token JWT da Empresa logada (mesmo padrão do `AdminSession`).
- `lib/state/empresa_config.dart` — novo método `carregarDe(Map)` (popula todos os campos a partir do JSON de `/empresas/me`, convertendo hex→`Color`) e `aplicarSelecaoLocal(...)` (pra mecânica/regras de pontuação, que ainda não persistem — mantém a seleção da loja na tela sem sujar `carregarDe`).
- `lib/screens/login_screen.dart` — `_login()` agora é assíncrono, chama `POST /auth/empresa/login` de verdade, mostra erro real da API (ex: "Email ou senha inválidos"), estado de carregamento no botão, e popula `EmpresaConfig` com os dados reais antes de navegar.
- `lib/screens/web_configuracoes_screen.dart` — `_salvar()` agora chama `PATCH /empresas/me` antes de atualizar o estado local; mostra erro (SnackBar vermelho) se a API rejeitar, estado de carregamento no botão "Salvar alterações".
- `lib/widgets/web_sidebar.dart` (`_UserCard`) — trocado de "Admin Master"/"admin@acumula.ai" hardcoded pra nome/email reais da empresa logada (via `EmpresaConfigScope`/`EmpresaSessionScope`), e o ícone "⋮" (antes decorativo) virou um `PopupMenuButton` funcional com "Sair" (logout real: limpa a sessão e volta pro login).

**Testado (local + produção), ponta a ponta:**
- Login com credenciais erradas → erro real da API exibido na tela.
- Login com credenciais corretas (`teste@lojateste.com`) → dashboard carrega com nome/email reais na sidebar.
- Configurações: campo "Nome da loja" já vem preenchido com o dado real; editado e salvo com `Salvar alterações` → confirmado via API que persistiu no banco de produção.
- **Persistência real confirmada:** fechei a aba, abri uma nova, logou de novo → nome editado continua lá (não é só estado de sessão).
- Logout: limpa a sessão e volta pra tela de login.
- `flutter analyze`: limpo (só os avisos de estilo pré-existentes, não relacionados).

**Ainda mockado nessas mesmas telas (fica pra depois, fora do escopo desta fase):** mecânica de fidelidade (marcações/pontos) e regras de pontuação na tela Configurações (não têm endpoint ainda — a seleção fica só na sessão do navegador); upload das 3 imagens de marca (caixas de upload existem na tela, mas sem nenhuma funcionalidade, mockada ou real); tudo em Dashboard, Aprovação, Campanhas, Promoções e Relatório de Clientes.

**Publicado em produção (2026-09-19):** build do `web/` (Login + Configurações reais) enviado pro `public_html` via FTP, 39/39 arquivos. Cache do Cloudflare já estava configurado corretamente pelo `.htaccess` da rodada anterior (4h + `must-revalidate`), sem repetir o problema de cache preso.

## 13. Limpeza de estrutura: `android/`/`ios/` soltos em `web/`

Achado do usuário (2026-09-19): `web/` (Flutter Web, painel da empresa) tinha pastas `android/` e `ios/` soltas dentro dele — sobra do projeto único encontrado antes da divisão em `web/`/`mobile/` (ver seção 10, "Atualização 2026-09-15"), nunca removida. Isso é um risco real: como `web/` "sabia" compilar pra Android/iOS, rodar `flutter build apk` ali por engano geraria um app Android com o código do **painel da empresa**, não o do cliente final (que é o `mobile/`).

**Confirmado antes de remover:** `web/android/build.gradle` e `web/ios/Runner.xcodeproj` ainda tinham o identificador padrão do `flutter create` (`com.example.acumula_ai`/`com.example.acumulaAi`) — nunca foram customizados nem usados pra build real. Removidas as duas pastas. Confirmado que `flutter analyze` e `flutter build web` continuam funcionando normalmente em `web/` depois da remoção. `web/` agora só tem a pasta `web/` (mais correto/seguro estruturalmente).

`mobile/` já estava correto — só `android/` e `ios/`, sem `web/`.

**Ambiente de build (`flutter doctor`, nesta máquina Windows):** Android com toolchain completo (SDK, emulador disponível) — dá pra gerar build Android real aqui. iOS não é possível nesta máquina (precisa macOS). Usuário testou com **celular físico via USB** — `flutter devices` detectou (M2012K11AG, Android 13/API 33), `flutter run` compilou e instalou o app de verdade no aparelho.

**Bug de renderização encontrado e corrigido — "ListTile background color or ink splashes may be invisible":** apareceu no log do primeiro `flutter run` no device real. Causa: as únicas 3 ocorrências de `ListTile`/`SwitchListTile` no `mobile/` (`perfil_screen.dart` — menu de opções; `configuracoes_screen.dart` — `_SwitchTile` e `_NavTile`) ficavam dentro de um `Container` com `BoxDecoration` (cor + sombra), sem nenhum `Material` por perto — o efeito de toque (`InkWell` interno do `ListTile`) pinta na camada do `Material` ancestral mais próximo, que nesse caso era o do `Scaffold`, renderizando o splash **atrás** do container colorido (por isso "invisível"). Corrigido envolvendo cada `ListTile`/`SwitchListTile` num `Material(color: Colors.transparent, child: ...)`. Testado no celular físico de verdade pelo usuário: **confirmado que o toque agora aparece certinho** nas telas Perfil e Configurações. `flutter analyze`: limpo (0 issues).

## 14. Cliente final real no `mobile/`: Cadastro, Login e Vincular loja + incidente de produção

**Contexto:** depois de testar todas as telas mockadas do `mobile/` (Início, Buscar, Promoções, Perfil, Configurações — achado nessa passada: a aba "Buscar" era só um placeholder "Em breve", sem nenhuma tela por trás), o usuário pediu pra construir a tela de Buscar/Vincular loja de verdade. Escolhido fazer o **fluxo real completo** (não só UI mockada): backend novo do Cliente final + conexão real do `mobile/`.

### Backend novo (`server/`)

- **`utils/cpf.js`** — validação/formatação de CPF (mesmo padrão do `utils/cnpj.js` já existente: `limpar`/`isValido`/`formatar`, dígitos verificadores mod 11).
- **`middleware/authCliente.js`** — mesmo padrão do `authEmpresa.js` (JWT `Bearer`, `algorithms: ['HS256']` explícito), mas sem checagem de licença (conceito que só existe pra Empresa).
- **`routes/authCliente.js`** — `POST /auth/cliente/cadastro` (nome, cpf, senha ≥8 chars, telefone obrigatórios; email opcional) e `POST /auth/cliente/login` (cpf + senha) — mesmo cuidado de timing side-channel do `authEmpresa.js` (hash morto pré-computado quando o CPF não existe). CPF guardado **sem formatação** no banco (`VARCHAR(11)`, só dígitos), diferente do CNPJ da Empresa (guardado formatado).
- **`routes/cliente.js`** — `GET /clientes/me`, `GET /clientes/me/vinculos` (lista cartões do cliente, com dados públicos da empresa), `POST /clientes/me/vinculos` (recebe `codigoLoja`, normaliza maiúsculo/sem símbolos antes de comparar, 404 se código não existe, 409 se já vinculado, cria o `Vinculo` com `saldo_atual: 0`). Um `empresaPublica()` interno garante que o cliente final nunca recebe email/cnpj/dados de gestão da empresa, só o necessário pro cartão (nome, cores, mecânica, textos).
- Rotas registradas em `index.js`: `/auth/cliente` e `/clientes`. Reaproveitados os limitadores `limiteLogin`/`limiteRegistro` já existentes.
- Testado localmente (contra o banco remoto) end-to-end antes de tocar em produção: cadastro, login, CPF/senha errados, `/me`, vincular com código formatado errado (`zz28-b4h8` → normaliza e acha), vínculo duplicado (409), código inexistente (404), listagem.

### `mobile/`: novas telas e serviços

- **`services/cliente_api.dart`** + **`state/cliente_session.dart`** — mesmo padrão de `EmpresaApi`/`EmpresaSession` do `web/` (`ChangeNotifier` + `Scope`/`InheritedWidget` via `findAncestorStateOfType`). `main.dart` envolvido em `ClienteSessionScope`.
- **`screens/login_screen.dart`** — trocado de mockado (E-mail fake, navega direto) pra login real por **CPF + senha** (decisão já registrada na seção 8: mesmo CPF usado pela Empresa pra marcar compras). Loading/erro reais.
- **`screens/cadastro_screen.dart`** (nova) — Nome completo, CPF, Telefone, Senha, Confirmar senha — layout seguindo o mockup original (`design/mobile/acumulaai-mobile-mockup.html`, tela `Cadastro.dc.html`, nunca implementada em código até agora). Cadastro já loga automaticamente (a API devolve token no `201`).
- **`screens/vincular_loja_screen.dart`** (nova, substitui o placeholder "Em breve" da aba Buscar em `mobile_root_screen.dart`) — segue o mockup `VincularLoja.dc.html`: visor de câmera **ilustrativo** (não lê QR de verdade — decisão de escopo: câmera real ficaria pra depois, junto de um pacote tipo `mobile_scanner`) + campo "Código da loja" que é o caminho funcional real, chamando `POST /clientes/me/vinculos`.
- **`android/app/src/main/AndroidManifest.xml`** — **bug encontrado e corrigido:** faltava `<uses-permission android:name="android.permission.INTERNET"/>`. Como todas as telas do `mobile/` até agora eram 100% mockadas (sem nenhuma chamada de rede), isso nunca tinha sido notado — toda tentativa de cadastro/login/vincular falhava com "Não foi possível conectar à API" mesmo com a API no ar e o celular com internet normal (confirmado via `ping` direto do device). Corrigido, rebuild + reinstall no celular físico resolveu.
- `flutter pub add http` (mesma versão `^1.2.0` já usada no `web/`).
- Testado end-to-end **no celular físico**, contra a API de produção: cadastro real → login automático → aba Buscar → "Vinculado a Loja Teste com sucesso!" (confirmado via `GET /clientes/me/vinculos` batendo com o vínculo criado). Dado de teste limpo do banco depois (`Cliente Prod QA`/CPF de teste).

### Incidente de produção durante o deploy (2026-09-19, ~13h–13h30) — API ficou fora do ar

Ao subir os 5 arquivos novos/alterados do backend (`cpf.js`, `authCliente.js` ×2, `cliente.js`, `index.js`) via FTP e pedir pro usuário reiniciar o Passenger, **a API caiu inteira** ("Web application could not be started") — afetando não só a feature nova, mas o `web/` e o admin já em produção.

**Causas encontradas, em cascata (cada uma mascarando a próxima):**
1. Primeira hipótese (**errada**): `package.json` de produção não tinha `helmet`/`express-rate-limit` (visíveis faltando via FTP). Corrigido subindo `package.json`/`package-lock.json` novos + pedindo `npm install` pelo cPanel.
2. **Descoberta que mudou o diagnóstico:** `node_modules` em produção é um **symlink** pra `/home/acumulaai/nodevenv/server/20/lib/node_modules` (fora da raiz `/home/acumulaai/server` onde a conta FTP fica presa) — por isso os `550`/"não encontrado" via FTP eram **falsos negativos** (a conta FTP não segue o link, não que o pacote não existisse). Rodar `npm install` direto no terminal do cPanel (o usuário tem acesso — `source .../nodevenv/server/20/bin/activate`) confirmou: `up to date, audited 235 packages` — os pacotes **já estavam instalados**.
3. **Causa real:** rodando `node src/index.js` direto no terminal (muito mais confiável que ler logs do Passenger, que por padrão nem estavam configurados — o campo "Arquivo de log Passenger" no cPanel estava vazio), o erro real apareceu na hora: `Cannot find module '../middleware/rateLimiters'`, exigido por `authCliente.js`. Ou seja: **um lote de arquivos de uma sessão anterior (a de segurança/`helmet`+rate limiting) nunca tinha sido totalmente enviado pra produção** — o processo Node antigo continuava rodando em memória com o código velho (Passenger não reinicia sozinho quando um arquivo muda, só no restart manual), mascarando o problema até esse restart forçar o carregamento do disco. É a mesma classe de bug já documentada na seção 10 ("Pegadinha de deploy descoberta nesta rodada") — se repetiu porque aquele lote de segurança rodou só localmente por decisão explícita do usuário na hora ("nunca faça commit sem eu autorizar" / "não deploye em produção sem estar acompanhando").
4. **Correção:** reenviados **todos** os 18 arquivos de `server/src/` (exceto `generated/`) via FTP de uma vez, em vez de tentar adivinhar quais faltavam. `node src/index.js` no terminal confirmou rodando sem erro; app reiniciado pelo cPanel; `GET /health` voltou a `200 {"status":"ok"}`.

**Lição consolidada (reforça e generaliza a da seção 10):** depois de qualquer sessão que mexeu em `server/src/` só localmente (por decisão de não deployar na hora), o **próximo** deploy real precisa reenviar a árvore `src/` inteira (não só os arquivos daquela sessão específica) antes de pedir um restart — e **sempre confirmar `GET /health` logo depois de qualquer restart do Passenger**, mesmo quando o restart não foi pedido por causa de uma mudança de código (ex: só ajuste de configuração no cPanel). Ter o terminal do cPanel disponível (`Setup Node.js App` → app → aba/link de terminal, ou opção separada) é muito mais rápido pra diagnosticar erro de boot do que caçar logs do Passenger — usar isso primeiro da próxima vez.

**Sem perda de dados:** o incidente foi só de disponibilidade (app não subia), não de integridade — nenhum dado de produção foi corrompido ou perdido. Duração: ~30 minutos, dentro desta mesma sessão, resolvido antes de qualquer teste real no celular.

## 15. Fase 2 — eliminação de dados mockados em `web/` e `mobile/` (Campanhas, Aprovação, Dashboard, Relatório, mobile completo)

Depois da seção 14, o usuário pediu uma varredura completa do código (`server/`, `web/`, `mobile/`) atrás de qualquer coisa ainda mockada ou sem endpoint, e que tudo fosse conectado de verdade. Feita uma auditoria (agente `Explore`) que confirmou: `server/` já estava 100% real; `web/` tinha 7 telas inteiras mockadas (Dashboard, Campanhas, Cadastro de Campanha, Promoções, Postar Promoção, Relatório de Clientes, Aprovação); `mobile/` tinha Início/Perfil/Promoções/Detalhe da Promoção/Configurações mockados, mais um arquivo morto (`lojas_screen.dart`, nunca referenciado).

**Decisões de modelo de dados tomadas antes de codar (perguntadas ao usuário, evitando inventar schema sem confirmar):**
- ~~"Promoções" = outra vitrine da `Campanha`~~ **(revisto em 2026-10-15, ver seção 19):** Promoção agora é uma entidade própria (`Promocao`, só um aviso/post, sem cartão); quem gera cartão fidelidade é a Campanha.
- **Dashboard não teria mais "Vendas Totais"/"Faturamento" fake** (não existe campo de valor monetário em nenhuma marcação/compra) — trocado por métricas 100% reais: clientes vinculados, campanhas ativas, marcações no mês, resgates no mês, e uma "Atividades Recentes" real (junção de `Marcacao`+`Resgate` mais recentes).
- **Preferências do Cliente (push/e-mail/biométrico) ganharam campo real no banco e endpoint**, mesmo sem infraestrutura de envio de notificação ainda — decisão explícita do usuário, ciente da limitação.

### Backend novo (`server/`)

- **Schema:** novo model `SolicitacaoMarcacao` (`vinculo_id`, `cupom_fiscal?`, `status` PENDENTE/APROVADA/REJEITADA, `created_at`, `resolved_at?`) — faltava justamente pra fila de pendências da tela "Aprovação" (ver MECANICA_FIDELIDADE.md seção 9), que até então só existia mockada. Novos campos em `Cliente`: `notificacoes_push`, `notificacoes_email`, `login_biometrico` (todos `Boolean`). Aplicado via `prisma db push` (aditivo, sem `--force-reset`, sem risco de perda de dado) + `prisma generate` local, com o Client regenerado reenviado a produção junto (lição da seção 14 aplicada: qualquer novo `prisma generate` precisa subir `src/generated/prisma` inteiro, não só as rotas).
- **`utils/fidelidade.js`** (novo) — `creditarVinculo(vinculo, empresa)`: lógica única e compartilhada de creditar marcação/pontos e liberar resgate automático ao atingir a meta (zera saldo em MARCAÇÕES, desconta só a meta e mantém residual em PONTOS — exatamente como MECANICA_FIDELIDADE.md seção 3 especifica). Usada tanto por aprovar solicitação quanto por marcação manual, evitando duplicar a regra em dois lugares.
- **`routes/campanhas.js`** (novo) — CRUD de campanhas: `GET/POST /empresas/me/campanhas`, `PATCH /empresas/me/campanhas/:id` (ativar/encerrar).
- **`routes/solicitacoes.js`** (novo) — fila de Aprovação: `GET /empresas/me/solicitacoes` (filtra por status/CPF/cupom fiscal), `PATCH /:id` (aprovar credita de verdade via `creditarVinculo`; rejeitar só muda status), `POST /marcar-manual` (busca cliente por CPF, credita direto, sem passar pela fila).
- **`routes/relatorio.js`** (novo) — `GET /empresas/me/clientes` (lista vinculados + saldo/marcações/resgates agregados), `GET /empresas/me/dashboard` (KPIs reais + atividades recentes).
- **`routes/cliente.js`** (extendido) — `GET /me/resumo` (saldo total + histórico agregado, pra tela Perfil do mobile), `POST /me/solicitacoes` (cliente pede validação de compra, com cupom fiscal opcional — a metade que faltava do fluxo de Aprovação, pelo lado do consumidor), `PATCH /me/preferencias`.
- **Testado exaustivamente**, local e depois em produção (empresas/clientes de teste criados e removidos em cada rodada): CRUD de campanhas, aprovar/rejeitar solicitação, marcação manual, mecânica MARCAÇÕES e PONTOS (incluindo o desconto parcial com saldo residual), liberação automática de recompensa ao bater a meta, dashboard, relatório, resumo, preferências.

### `web/`: as 7 telas reescritas

`empresa_api.dart` ganhou os métodos novos (`listarCampanhas`, `criarCampanha`, `atualizarStatusCampanha`, `listarSolicitacoes`, `resolverSolicitacao`, `marcarManual`, `listarClientes`, `dashboard`). Cada tela foi **simplificada pra só mostrar o que tem dado real por trás** — nenhuma delas manteve os campos decorativos que não tinham backing (contagem de visualizações/cliques de post, tiers de cliente Ouro/Prata/Bronze, "Meta Trimestral", gráfico de vendas semanais, avatares empilhados de "clientes engajados", paginação falsa):

- **Dashboard:** 4 KPIs reais + tabela de atividades recentes real. Removidos o gráfico de linha e o donut de meta trimestral (não davam pra sustentar com dado real sem inventar métrica).
- **Campanhas:** listagem real, criação real, toggle Ativa/Encerrada real. Removidas colunas de "clientes participando"/"resgates por campanha" (exigiria campanha específica sendo escolhida na Aprovação, fora de escopo).
- **Cadastro de Campanha:** só os campos que a `Campanha` realmente tem (nome, descrição, meta, validade) — removidos Recompensa/Loja Vinculada/Periodicidade/Visibilidade/upload de imagem (sem coluna correspondente).
- **Promoções / Postar Promoção:** (revisto em 2026-10-15, seção 19) agora usam a entidade própria `Promocao` — título, descrição, validade opcional; sem meta.
- **Relatório de Clientes:** lista real de vinculados com saldo/marcações/resgates/data de vínculo. Removidos cidade/tier/gasto total/ações sem destino (não existe endereço nem valor monetário no cadastro do cliente).
- **Aprovação:** fila real (antes só existia mockada desde a criação original em 2026-09-15), aprovar/rejeitar reais, marcação manual real, progresso "X de Y" lido do vínculo real.

Também corrigido en passant: `EmpresaConfig` tinha valores default hardcoded ("Loja Bela Cores"/"Beleza"/"1 esmalte grátis...") que apareciam por uma fração de segundo antes do login preencher os reais — trocados por string vazia. Rodapé (`WebFooter`) tinha "© 2024" fixo — agora usa `DateTime.now().year`.

### `mobile/`: Início, Perfil, Promoções, Detalhe, Configurações + tela nova de solicitar marcação

- **`lojas_screen.dart` removida** (arquivo morto, nunca referenciado — a aba "Buscar" usa `VincularLojaScreen`).
- **`cliente_api.dart`/`cliente_session.dart`** ganharam `resumo()`, `solicitarMarcacao()`, `atualizarPreferencias()`.
- **`mobile_home_screen.dart`:** saldo total e progresso da loja em destaque vêm de `GET /clientes/me/vinculos` de verdade (a meta/progresso já vinha nesse endpoint desde a seção 14 — não precisou de campo novo). Removidos "Nível Ouro" (sem sistema de tier real), "Nova Campanha" (ação de empresa, não fazia sentido no app do cliente) e o banner "Convide amigos, ganhe 500 pontos" (programa de indicação nunca existiu).
- **`perfil_screen.dart`:** nome/e-mail reais, stats reais (`GET /clientes/me/resumo`), logout real (antes era `onPressed: () {}`). Removido o menu inteiro (Histórico de Pontos/Cupons Ativos/Indicar Amigos/Notificações/Ajuda) — nenhum item tinha destino real.
- **`promocoes_screen.dart` + `detalhe_promo_screen.dart`:** viraram vitrine das lojas vinculadas de verdade (via `promo_catalog.dart` reescrito: `PromoDetailData.fromVinculo()` monta os dados a partir da API, nada mais hardcoded). O botão que antes era "Resgatar" (não fazia sentido — resgate é automático no backend) virou **"Solicitar marcação"**, abrindo um diálogo com cupom fiscal opcional e chamando `POST /clientes/me/solicitacoes` — **esta é a metade que faltava do fluxo de Aprovação pelo lado do app do cliente**, que antes só existia do lado da empresa.
- **`configuracoes_screen.dart`:** os 3 toggles (push/e-mail/biométrico) agora persistem de verdade via `PATCH /clientes/me/preferencias`. Removidos "Alterar senha"/"Privacidade e dados"/"Idioma" (sem fluxo real por trás).
- **`campaign_models.dart`:** `HomeCampaigns` (dado mockado) removida, mantidas só as classes `Campaign`/`FeaturedCampaign` (containers reutilizáveis, agora populados com dado real).

`flutter analyze` limpo em `web/` e `mobile/` durante todo o processo (só os avisos de estilo pré-existentes, não relacionados). Testado local (localhost + build web estático) e depois em produção com empresas/clientes de teste criados e removidos a cada rodada — cobrindo login, dashboard, criar/pausar campanha, promoção como card, aprovar solicitação, marcar manualmente por CPF, relatório de clientes. Publicado em produção: backend (44 arquivos, `server/src/` inteiro incluindo o Prisma Client regenerado) e o build do `web/` (39 arquivos em `public_html`).

**Pegadinha de cache encontrada nesta rodada (nova camada, distinta das já documentadas):** depois do purge do Cloudflare, uma aba de teste ainda mostrava o dashboard antigo. Investigado com `fetch(..., {cache:'no-store'})` direto no console do navegador: o arquivo servido pela origem/Cloudflare já estava 100% correto (bytes idênticos ao build novo) — o que estava desatualizado era o **cache HTTP do próprio navegador de teste**, que tinha visitado o domínio horas antes nesta mesma sessão e ainda estava dentro da janela de `max-age=14400` (4h) do `.htaccess`, então nem chegou a perguntar pro servidor se havia versão nova. **Terceira camada de cache confirmada na prática** (origem → Cloudflare → navegador do usuário) — abrir uma aba nova não basta pra escapar dela, porque o cache HTTP é por origem, não por aba. Não é um bug do deploy; é só uma limitação inerente ao trade-off de `max-age=14400` já aceito antes. Zero ação necessária — usuários com cache expirado ou visita nova já recebem a versão certa.

### Teste no celular físico + bug real encontrado e corrigido (`detalhe_promo_screen.dart`)

Depois do `web/` validado, o `mobile/` foi buildado e testado de ponta a ponta no celular físico contra a API de produção: cadastro → login → vincular loja (código real) → card da campanha em destaque com progresso real → badge "Quase lá!" calculado dinamicamente (progresso ≥70%) → tela de Detalhe → **Solicitar marcação** (o botão novo que substitui o antigo "Resgatar" mockado) → marcação manual pela empresa via API até bater a meta → **pull-to-refresh** (adicionado nesta rodada em Início/Perfil/Promoções, ver abaixo) mostrando o saldo zerado e a recompensa liberada sem precisar reiniciar o app → Perfil com stats batendo exatamente com o testado via API → Configurações com os 3 toggles persistindo de verdade (`login_biometrico: true` confirmado no banco depois do teste).

**Bug real encontrado nesse teste:** ao tocar em "Enviar" no diálogo de solicitar marcação, o app quebrava com `'_dependents.isEmpty': is not true` (tela vermelha). Causa raiz, achada pelo stack trace completo do `flutter run` (não pelo logcat, que não capturou): *"A TextEditingController was used after being disposed"* — **um bug que a própria sessão introduziu horas antes**, durante uma checagem autônoma de "sweeping the branch" que identificou o `TextEditingController` do diálogo como um vazamento de memória e "corrigiu" chamando `.dispose()` nele logo depois do `showDialog()` retornar. Só que o `TextField` dentro do `AlertDialog` ainda está sendo desmontado pela animação de saída do diálogo nesse momento — descartar o controller antes dela terminar quebra o frame em transição. **Corrigido de verdade** extraindo o conteúdo do diálogo pra um `StatefulWidget` próprio (`_CupomFiscalDialog`) que descarta o controller no seu **próprio** `dispose()`, callback que o Flutter só chama depois que o elemento é desmontado de forma segura — o padrão canônico pra esse caso, em vez de descarte manual fora do ciclo de vida do widget. Reinstalado e testado de novo no aparelho: solicitação enviada sem crash, confirmada via API. **Lição:** um "conserto" de vazamento de memória feito sem testar na UI de verdade pode trocar um problema pequeno (memória) por um muito maior (crash) — vazamentos de `TextEditingController` de vida curta e sem listeners são inofensivos o suficiente pra não valer o risco de descarte manual fora do `dispose()` do widget dono.

**Melhoria adicional encontrada durante o teste (não era mock, era uma lacuna de atualização):** como o `MobileRootScreen` usa `IndexedStack` (mantém as 5 abas vivas simultaneamente), os dados carregados no `initState()` de cada tela nunca atualizavam sozinhos ao trocar de aba — confirmado marcando compras via API e vendo o card da Início continuar com o progresso antigo até reiniciar o app. Adicionado **`RefreshIndicator`** (puxar para atualizar) em Início, Perfil e Promoções, reaproveitando o mesmo método `_carregar()` de cada tela — testado no aparelho, progresso atualiza corretamente sem precisar reiniciar.

## 16. Multi-loja / filiais — agrupamento comercial via `empresa_pai_id`

Decisão de 2026-09-19, resolvendo o item pendente da seção 8. Duas perguntas foram colocadas ao usuário, que escolheu a opção recomendada nas duas:

1. **Como agrupar filiais sob uma matriz para gestão comercial/cobrança da 2RL?** → Campo simples `empresa_pai_id` (auto-referência em `empresas`, nullable), sem entidade nova (`conta`/`grupo_empresarial` descartada). Login continua por filial, cada uma com seu próprio e-mail/senha.
2. **O saldo do cartão fidelidade é compartilhado entre filiais da mesma matriz?** → **Independente por filial** — decisão que não exigiu nenhuma mudança de schema (`vinculos` já é por `empresa_id`, sempre foi).

### Implementação

- **Schema** (`server/prisma/schema.prisma`): `Empresa.empresa_pai_id String? @db.VarChar(36)` + relação auto-referenciada `empresa_pai`/`filiais` (`@relation("FiliaisDaMatriz")`) + índice em `empresa_pai_id`. Aplicado via `prisma db push` (aditivo, sem perda de dado) + `prisma generate`. `docs/schema.sql` e `docs/MODELO_DADOS.md` atualizados com a nova coluna/FK/índice.
- **Backend** (`server/src/routes/admin.js`): `GET /admin/empresas/:id` agora inclui `empresa_pai` e `filiais` no retorno. Novo `PATCH /admin/empresas/:id` (`{ empresaPaiId: string | null }`) define/remove o vínculo — só acessível pelo admin interno (mesma allowlist/JWT dos outros endpoints de admin), nunca pela própria empresa. Validações: não pode ser matriz de si mesma, matriz precisa existir, e o ciclo mais simples (A matriz de B, B matriz de A) é rejeitado; cadeias mais profundas não são checadas (agrupamento é só de exibição/cobrança, não entra em nenhuma regra de negócio).
- **Frontend** (`web/lib/screens/admin/admin_empresa_detalhe_screen.dart` + `web/lib/services/admin_api.dart`): novo card "Matriz / Filiais" na tela de detalhe da empresa (admin interno) — mostra a matriz atual (se houver) e a lista de filiais, com botão "Definir matriz" abrindo um diálogo com dropdown de todas as empresas (exceto ela própria) para escolher a nova matriz ou remover o vínculo.

### Teste

Backend testado via `curl` direto contra o servidor local (apontado pro banco remoto) com uma conta admin e duas empresas descartáveis (link, listagem bidirecional `filiais`/`empresa_pai`, os dois casos de ciclo, desvínculo) — todos os casos passaram, dados de teste removidos depois. Frontend testado no browser pane apontando temporariamente o `AdminApi.baseUrl` pro servidor local (revertido para produção logo em seguida) — fluxo completo validado: abrir "Definir matriz", selecionar (excluindo a própria empresa da lista), salvar, ver o card atualizado, ver a filial aparecer na matriz, e tentativa de ciclo corretamente rejeitada (estado permanece inalterado). `flutter analyze` limpo (só avisos de estilo pré-existentes no arquivo).

**Ainda não deployado em produção** — schema já foi aplicado no banco remoto (via `db push` local), mas o `server/src/routes/admin.js` novo e o build do `web/` (admin) ainda precisam do deploy manual via FTP + restart do Passenger, pendente de confirmação do usuário.

**Em aberto (não resolvido nesta rodada, fora de escopo):** se a 2RL cobra por filial ou só da matriz — implicação de billing que só deve ser endereçada quando o gateway de pagamento for escolhido (seção 11).

## 17. Landing page comercial (SEO) + split de deploy por path em `acumulaai.com.br`

Decisão de 2026-09-30. Antes, `acumulaai.com.br` servia direto o build do Flutter Web (`web/`, painel da Empresa) — quem chegava no domínio sem já ser cliente caía direto na tela de login, sem nenhum contexto comercial, e por ser uma SPA Flutter a página não era indexável de forma útil pelo Google.

**Decisão:** split por path no mesmo domínio (não subdomínio — evita mudança de DNS e não toca no CORS allowlist do `server/`, que já libera `https://acumulaai.com.br` independente do path):
- `acumulaai.com.br/` → nova pasta `landing/` na raiz do monorepo (irmã de `web/`/`mobile/`/`server/`) — site estático puro (HTML/CSS, sem build, sem framework JS): `index.html` (página comercial), `privacidade.html`, `robots.txt`, `sitemap.xml`, `assets/favicon.svg`.
- `acumulaai.com.br/app/` → painel da Empresa (`web/`, `main.dart`), agora buildado com `flutter build web --base-href /app/` em vez de `/`.
- `admin.acumulaai.com.br` não muda — continua sem landing, só o painel admin.

**Conteúdo:** copy baseada no que já estava consolidado nesta spec (produto, perfis, fluxo, diferenciais — seções 2 a 7). SEO técnico: HTML5 semântico, meta description, Open Graph/Twitter Card, `<link rel="canonical">`, dado estruturado JSON-LD (`Organization` + `SoftwareApplication`), `robots.txt` bloqueando `/app/` da indexação (painel autenticado não tem valor de busca).

**CTA de contato:** link direto pro WhatsApp (`https://wa.me/5562984999122`) — decisão explícita de não criar formulário com endpoint novo em `server/` nesta rodada, pra não adicionar escopo em produção real.

**Política de privacidade:** `docs/privacidade.html` (rascunho com placeholders, existia desde a seção 14/pendência da Play Store) foi preenchido com os dados reais e movido para `landing/privacidade.html` — passa a ser o arquivo publicável de fato. Dados legais: razão social **HR THECH LTDA**, CNPJ **49.905.063/0001-86** (informado pelo usuário; endereço consultado via BrasilAPI/Receita Federal, registro público), e-mail de contato/DPO **privacidade@acumulaai.com.br**. `docs/privacidade.html` removido (conteúdo agora vive só em `landing/`, para não haver duas cópias divergentes).

**Sem logo-imagem por enquanto** — landing usa wordmark em texto ("ACUMULA**AI**") com a paleta já usada no app (`#5B0A8F` roxo / `#FFC107` amarelo, ver `web/lib/theme/app_colors.dart`) e um favicon SVG simples (monograma "A"), não a logo padrão do Flutter que ainda está em uso no ícone do app mobile (pendência separada, seção 8).

**Documentação atualizada:** `docs/dev/DEPLOYMENT.md` — nova seção `landing/` + instruções de build/deploy do `web/` ajustadas pro `--base-href /app/` e pro subcaminho `app/` no doc-root.

**(Atualização 2026-10-09: já publicado e no ar — ver seção 18.)** Passos usados para publicar: rodar o `flutter build web --target=lib/main.dart --base-href /app/`, subir `landing/` pra raiz do `public_html` (conta `web@acumulaai.com.br`) e o novo build do `web/` pra dentro de `public_html/app/`, depois purgar cache do Cloudflare e validar (ver `docs/dev/DEPLOYMENT.md`). Só fazer isso com confirmação explícita do usuário, seguindo a regra já registrada de não publicar/reiniciar produção sem ele por perto.


## 18. Preparação para publicar na Play Store (2026-10-08/09) — release, conformidade, recuperação de senha e login com Google

Sessão dedicada a deixar o app `mobile/` pronto para a Google Play e a fechar as lacunas que a revisão da loja costuma reprovar. Tudo abaixo foi **testado e publicado em produção**, salvo onde indicado. Documentação operacional complementar: [dev/PLAY_STORE.md](dev/PLAY_STORE.md) (checklist de publicação), [dev/LOGIN_GOOGLE.md](dev/LOGIN_GOOGLE.md), [dev/API.md](dev/API.md), [dev/DEPLOYMENT.md](dev/DEPLOYMENT.md).

### Build de release e identidade do app
- `applicationId`/`namespace` trocados de `com.example.acumulaai_mobile` (a Play Store recusa `com.example.*`) para **`br.com.acumulaai.cliente`**; nome do app "Acumula Aí"; `MainActivity.kt` movido para o novo pacote.
- **Assinatura de release própria:** keystore de upload `mobile/android/app/upload-keystore.jks` (PKCS12, RSA 2048, ~27 anos) + `mobile/android/key.properties`, ambos **fora do git** (`.gitignore` do Flutter). Build conferido com `apksigner` (fingerprint do APK = o do keystore, não o de debug). SHA-1 da chave de upload: `3C:44:98:A2:D3:49:BB:F6:55:A2:9A:76:0D:DB:12:79:B3:06:9D:D5`. **Backup do `.jks` e das senhas fora deste PC é responsabilidade do responsável** — perder a chave impede atualizar o app (mitigação: Play App Signing).
- Artefatos: `flutter build appbundle --release` (`.aab`, ~54 MB, formato exigido pela loja) e `flutter build apk --release`. Versão atual `1.0.0+1`. `minSdk 24`, `targetSdk 36`.
- **Ícone do app:** aplicado o símbolo da marca (triângulo amarelo sobre o roxo `#5B0A8F`, o mesmo da tela de login) como ícone adaptativo do Android (`mipmap-anydpi-v26`, com versão monocromática para o tema de ícones do Android 13+) e como ícones legados (`mipmap-*/ic_launcher.png`). É um **desenho provisório gerado a partir do símbolo existente** — se o responsável tiver um logo definitivo, substituir os arquivos de `mobile/android/app/src/main/res/mipmap-*` e rebuildar o `.aab`. Rascunhos para a ficha da loja em `docs/play-store/assets/` (ícone 512×512 e imagem de destaque 1024×500).

### Funcionalidades novas / correções no app (`mobile/`)
- **Exclusão de conta** (exigência da Google e da LGPD): `DELETE /clientes/me` (confirma a senha; apaga em transação cliente, vínculos, marcações, solicitações e resgates) + item "Excluir minha conta" em Configurações + página pública `landing/excluir-conta.html` (URL para informar no Play Console). Testado em produção com cliente descartável.
- **Política de privacidade acessível dentro do app** (link no Cadastro e em Configurações > Sobre, via `url_launcher`) e e-mail como campo opcional no Cadastro.
- **Recuperação de senha** ("Esqueceu a senha?" agora funciona): código de 6 dígitos por e-mail (validade 15 min, uso único, bloqueio após 5 erros, 1 envio/min por conta, 5 pedidos/h por IP, resposta igual exista ou não a conta). Colunas novas em `clientes`: `reset_codigo_hash`, `reset_expira_em`, `reset_tentativas`. Envio por `sendmail` da hospedagem (`server/src/utils/mailer.js`, sem credencial SMTP) — **validado com e-mail real**. "E-mail de recuperação" editável em Configurações (`PATCH /clientes/me`).
- **Tela "Atividades"** (sino do Início, antes um botão morto): `GET /clientes/me/atividades` — marcações, resgates e solicitações com status, de todas as lojas.
- **Login com Google** (ver abaixo). O botão da **Apple foi escondido** por decisão do responsável.
- **Textos que prometiam o que não existe foram corrigidos:** QR Code (a tela Buscar só vincula digitando o código; visor mostra "Leitura de QR Code em breve"), e as chaves de push/e-mail/biometria agora dizem "Preferência salva — será ativado em breve" (só gravam o valor, não há push nem biometria por trás).
- **Bug corrigido:** a tela de Detalhe do cartão aparecia com fundo preto (Scaffold transparente numa rota empilhada).
- **Falha de segurança evitada antes do deploy:** os campos novos de recuperação (`reset_codigo_hash`…) e `google_id` seriam devolvidos nas respostas de cliente (inclusive às lojas) — `sanitizarCliente` foi ajustado em `authCliente.js`, `cliente.js` e `solicitacoes.js`.

### Login com Google
- App: `google_sign_in` 7.x, `mobile/lib/config/google.dart` (Web Client ID). Servidor: `POST /auth/cliente/google` valida o ID token no `tokeninfo` do Google (`aud`, emissor, validade, e-mail verificado) e: entra se o `google_id` já existe; vincula e entra se há cliente com o mesmo e-mail; senão devolve `precisaCadastro` e o app abre **"Concluir cadastro"** (CPF e telefone, obrigatórios no sistema) → `POST /auth/cliente/google/completar`. Coluna nova `clientes.google_id` (única).
- Projeto no Google Cloud (Google Auth Platform): Web Client ID `954272668229-hrcersad8banluij7r90eis9t2jbp2u6.apps.googleusercontent.com` (app + servidor); cliente Android `954272668229-6se7knrj7djssfqiini3p09kg59hlfe8…` com o SHA-1 da chave de upload. E-mail de suporte do consentimento = o da conta Google dona do projeto (o campo não aceita outro domínio).
- **Validado em produção com o Google real:** conta existente (vínculo por e-mail) e primeiro acesso (CPF + telefone). Os dados do teste foram removidos.
- **Pendente:** após o 1º upload na Play Store, criar no Google Cloud outro cliente Android com o **SHA-1 do Play App Signing** (senão o login falha nos apps instalados pela loja).

### Painel da Empresa (`/app/`)
- **QR Code e código da loja** em Configurações (QR do `codigo_loja`; copiar código; baixar PNG 1024×1024 com o logo numa caixa branca central — correção de erro nível H). Antes só existia no mockup HTML, nunca no Flutter.
- **Upload das 3 imagens de marca** (ícone, logo do QR, logo de promoções) que antes eram caixas decorativas: `PUT/DELETE /empresas/me/imagens/:tipo` (binário PNG/JPEG até 2 MB, validado pelos bytes; arquivos em `server/uploads/<empresaId>/`, servidos em `/uploads/`). Ainda **não são exibidas no app mobile**.
- **Sessão persistente:** o login sobrevivia só em memória (F5 derrubava). Agora o token fica no `localStorage`, é validado ao abrir (`GET /empresas/me`) e 401 durante o uso leva ao login. O painel admin continua só em memória.
- **Cache busting obrigatório em todo deploy do Flutter Web:** o Cloudflare impõe `max-age=14400` nos `.js` (ignora o `.htaccess`) e o usuário via a versão antiga; o `index.html` (nunca cacheado) passa a apontar `flutter_bootstrap.js?v=<carimbo>` e `main.dart.js?v=<carimbo>`. Passo documentado em `dev/DEPLOYMENT.md`.
- `acumulaai.com.br` (landing em `/`, painel em `/app/`) e `admin.acumulaai.com.br` confirmados **no ar**; o "ainda não deployado" da seção 17 está desatualizado.

### Material da Play Store
- [dev/PLAY_STORE.md](dev/PLAY_STORE.md): ficha (nome, descrições, categoria), declarações (Segurança dos dados, classificação, anúncios), checklist de publicação por responsável e riscos.
- 6 capturas 1080×2160 (proporção 2:1, sem barra de status) em `docs/play-store/screenshots/`, tiradas no celular físico.
- **Cliente de revisão para o Google** criado em produção ("Revisor Google Play", CPF `390.533.447-05`, vinculado à Loja Teste com 3/10). A senha **não** é versionada — está só com o responsável. Não apagar enquanto o app estiver em análise.

### Dados de teste em produção (estado ao fim da sessão)
Empresa "Loja Teste" (`ZZ28B4H8`), admin `admin@2rl.com.br`, clientes "Cliente Teste" (CPF `529.982.247-25`, e-mail de teste do responsável), "Revisor Google Play" e "rozenraurio" (conta real — não tocar). Todos os dados descartáveis dos testes (clientes de QA, imagens, conta Google de teste) foram removidos.

### Lições
- "Corrigir" um item quebrado = **fazer funcionar ou construir o que falta**, não remover (o responsável corrigiu esse entendimento).
- Testes de rate limit (10 logins/15 min, 5 cadastros/h por IP) mascaram casos seguintes — reiniciar o servidor local zera os contadores.
- `taskkill` por nome de imagem mata todos os `node.exe` da máquina; encerrar sempre por porta/PID.
- Antes de qualquer deploy, conferir que `baseUrl` dos clientes aponta para produção e que o build não contém `localhost`.

### Decisões e andamento da publicação
- Tipo de conta no Play Console: o responsável informou "pessoal e recente", mas o console mostra **"Conta da organização" (Hr Thech)**, com outros apps já publicados; na página Produção do app o botão "Criar nova versão" está liberado, **sem exigência visível de teste fechado**. Conclusão provisória: o teste de 12 testadores/14 dias provavelmente não se aplica (confirmar ao enviar). Roteiro completo em [dev/PLAY_CONSOLE_PASSO_A_PASSO.md](dev/PLAY_CONSOLE_PASSO_A_PASSO.md).
- Permissões reais do APK: `INTERNET`, `USE_BIOMETRIC`, `USE_FINGERPRINT` (vindas da biblioteca do login com Google); sem `AD_ID`.

### Andamento no Play Console (2026-10-09, feito com acompanhamento do responsável)
- App criado no console: "Acumula Aí – Fidelidade", pacote `br.com.acumulaai.cliente`, conta de desenvolvedor "Hr Thech" (organização). Status do app: Rascunho.
- **Conteúdo do app concluído** (todas as declarações com ✔): política de privacidade, detalhes do login (cliente de revisão), anúncios, classificação de conteúdo, público-alvo (18+), segurança dos dados, apps do governo, recursos financeiros e saúde.
- **Configurações da loja:** categoria **Compras**, e-mail `privacidade@acumulaai.com.br`, site `https://acumulaai.com.br` (salvos como rascunho).
- **Página "Detalhes do app" padrão (pt-BR):** nome, breve descrição, descrição completa, ícone 512, imagem de destaque e 6 capturas, na ordem Início, Detalhe do cartão, Buscar, Promoções, Perfil, Configurações — **concluída e salva** (passo 2 "Avaliação": declaração de recursos de IA = **"Não rotular recursos"**, escolha do responsável, pois ícone e imagem de destaque foram desenhados por script e as capturas são do app real). As mudanças aguardam envio em "Visão geral da publicação".
- **Versão de Produção preparada (2026-10-09):** `.aab` enviado (versão `1 (1.0.0)`, Android 24+, SDK 36, 3 ABIs, 15,1 MB para novas instalações), notas da versão em pt-BR, país **Brasil** adicionado; revisão da versão = "Tudo pronto para o lançamento"; **enviada ao Google para análise pelo responsável em 2026-10-09** (10 mudanças; público-alvo corrigido para 18+ antes do envio).
- **Play App Signing ativo:** SHA-1 do certificado da chave de **assinatura do app** (a que vale nos aparelhos que instalam pela loja): `CA:13:AB:53:E0:64:1B:87:E6:24:C0:06:D8:FE:25:43:97:29:E3:59`. **Cadastrado em 2026-10-09** no Google Cloud (projeto `acumula-ai`) como o cliente OAuth Android "Cliente Android Play Store" (pacote `br.com.acumulaai.cliente`). **Resolvido na mesma data:** o app OAuth estava em "Testando" (só contas do projeto entravam). Branding completado (página inicial `https://acumulaai.com.br`, política `https://acumulaai.com.br/privacidade.html`, domínio autorizado `acumulaai.com.br`, contato do desenvolvedor `privacidade@acumulaai.com.br`) e o app foi **publicado: status "Em produção"** em Google Auth Platform → Público-alvo (usuário externo; escopos `openid`, `email`, `profile` não exigem verificação; limite de 100 usuários só vale para escopos sensíveis). O SHA-1 da chave de upload (`3C:44:98:…:9D:D5`) já está cadastrado.
- **SHA-1 do Play App Signing cadastrado no Google Cloud, mudanças enviadas em 2026-10-09 e app APROVADO e PUBLICADO (verificado no Painel em 2026-10-11: "A atualização do app foi publicada").** Próximo: testar o login com Google e os fluxos no app instalado pela loja; recomendação do Google (não bloqueante): conferir exibição de ponta a ponta (edge-to-edge) no Android 15+.

### Pendências para publicar (resumo; detalhe em dev/PLAY_STORE.md)
Conta de desenvolvedor Google Play (US$ 25 + verificação de identidade; pessoal vs. organização), logo definitivo (opcional — há rascunhos prontos), caixa `privacidade@acumulaai.com.br`, teste fechado (12 testadores por 14 dias se a conta for pessoal e nova), SHA-1 do Play App Signing no Google Cloud, exibir as imagens de marca no app e implementar push/biometria reais (hoje só preferências).

## 19. Campanhas × Promoções (2026-10-15)

Correção de um desvio da seção 14: Promoção estava só "reaproveitando" a Campanha, então o app mostrava um cartão por loja e a aba Promoções era a mesma lista de cartões. Agora são duas coisas distintas:

- **Campanha** (meta + validade) **gera um cartão fidelidade próprio** no app do cliente — um cartão por campanha ativa e dentro da validade, de cada loja vinculada, listado em "Campanhas" na tela Início. Cada compra aprovada (`creditarVinculo`) credita o cartão contínuo da loja **e** o de cada campanha vigente (`Marcacao`/`Resgate` com `campanha_id`); o saldo da campanha é calculado (`saldoCampanha`), e ao bater a meta o resgate da campanha é gerado e o cartão recomeça. As marcações de campanha são cópias da mesma compra e **não** entram nas contagens de relatório/dashboard/perfil/atividades (filtro `campanha_id: null`).
- **Promoção** (`Promocao`: título, descrição, validade opcional, status) é **só um aviso/post**: sem meta, sem cartão, sem marcação. Aparece na aba "Promoções" do app, listando as promoções ativas de todas as lojas vinculadas (busca + filtro por categoria).
- API nova: `GET/POST/PATCH/DELETE /empresas/me/promocoes`, `GET /clientes/me/campanhas`, `GET /clientes/me/promocoes` (ver docs/dev/API.md). Tabela nova `promocoes` (aditiva; exige `prisma db push` local + subir `src/generated/prisma`).
- Também nesta rodada: diálogos de cadastro/edição (web admin, web, app) não fecham mais ao clicar fora (`barrierDismissible: false`).

## 20. Revisão geral e correções (2026-10-15, à noite)

Revisão completa de `server/`, `mobile/`, `web/` (painel da Empresa) e admin. Corrigido **no código** (ver "Publicação" abaixo — nada disto está em produção ainda):

**Segurança / correção**
- **Exclusão de conta de quem entrou pelo Google:** a confirmação exigia uma senha que essas contas não têm. Agora o app confirma com uma nova autenticação do Google (`DELETE /clientes/me` aceita `idToken` da MESMA conta); `conta_google` vem em `/clientes/me`.
- **Vínculo do Google:** parou de vincular por e-mail (o e-mail do cadastro por CPF nunca é verificado → uma pessoa podia herdar a conta de outra). Quem já tem conta por CPF vincula o Google informando a senha dela (`/google/completar` com `senha`).
- **Aprovação/crédito transacional:** `creditarVinculo` roda em transação com `SELECT ... FOR UPDATE` no vínculo e relê o saldo; aprovar/rejeitar solicitação é condicional ("só se ainda PENDENTE") — acaba o crédito em duplicidade por duplo clique. Verificado `$transaction` + `FOR UPDATE` no adaptador MariaDB.
- **Datas no fuso de Brasília** (`utils/data.js`): o servidor roda em UTC, então "hoje" virava amanhã às 21h (campanha "Corte de Cabelo" gravou início 16/10 num cadastro de 15/10 21:31) e campanhas/licenças venciam 3 h antes da meia-noite. Agora: dia de calendário em Brasília, validade/vencimento valem até o fim do dia, início do mês do dashboard em BRT, validade no passado é recusada.
- **Token do cliente invalidável** (`Cliente.token_valido_desde`): `authCliente` confere se a conta existe e se o token é posterior à última redefinição de senha.
- **Anti-spam de solicitações:** um pedido pendente por loja e cupom fiscal não reutilizável.
- **Validação de tipos** (`utils/validar.js`) em cadastro/login de cliente e empresa, PATCH da empresa, planos, campanhas, promoções: texto que chega como número/objeto virou 400 (antes, 500).
- **Admin:** token de 8 h, `GET /admin/me`, sessão retomada ao recarregar (guardada só na aba, `sessionStorage`) e volta ao login quando o token vence.
- **Painel Web:** sessão só é descartada em 401/403 (antes qualquer erro, até 5xx/429, deslogava a loja).
- **Dependências:** `npm audit fix` → 0 vulnerabilidades (`proxy-addr` 2.0.8 era a crítica; o resto vinha do CLI do Prisma).
- **Operação:** CORS aceita `localhost` só se `NODE_ENV` ≠ `production`; log de requisições não grava `/health` e apaga registros com mais de 90 dias; `seed-admin.js` lê a senha de `ADMIN_SENHA`; build de release **falha** sem `key.properties` (antes caía na chave de debug); `GoogleSignIn.signOut()` no "Sair da conta".
- **Painel:** campanhas e promoções mostram o status real (`Ativa`/`Agendada`/`Vencida`/`Encerrada`, via `status_efetivo`); KPI "campanhas ativas" só conta as vigentes; "Reativar" some quando o prazo já passou.
- **Cabeçalhos de segurança** dos painéis e do site: `deploy/htaccess-web.txt` e `deploy/htaccess-admin.txt` (+ `admin-robots.txt`, `noindex`) — anti-clickjacking, `nosniff`, HSTS, referrer/permissions policy.
- **Testes automatizados** (`server/test`, `npm test`): datas, licença, validação e a lógica de cartões/campanhas (13 testes).
- Lints dos três projetos zerados (`flutter analyze`: nenhum aviso).

**Incidente do deploy (2026-10-15, ~23:30):** o lote subiu com o client do Prisma desatualizado (a coluna `token_valido_desde` entrou no schema e no banco, mas o `prisma generate` não foi refeito). Resultado: toda rota autenticada do cliente respondia 500 ("Unknown field token_valido_desde") — o login funcionava, mas ler o QR, listar lojas etc. falhavam. Achado reproduzindo a API local contra o banco; corrigido regenerando e reenviando `src/generated/prisma`. Proteção: `server/test/prisma-gerado.test.js`.

**Erro de CORS no login (reportado pelo QA, 2026-10-16):** a lista de origens da API só tinha `https://acumulaai.com.br` e `https://admin.acumulaai.com.br`, mas `https://www.acumulaai.com.br/app/` abre o mesmo painel (200, sem redirecionar) — o login por esse endereço falhava com erro de CORS, e origem recusada virava um 500 sem cabeçalhos. Corrigido: `www` liberado, recusa com 403 claro, e `CORS_ORIGENS_EXTRAS` para domínios de teste (ver `docs/dev/DEPLOYMENT.md`). Teste: `server/test/cors.test.js`.

**Decisões que NÃO foram tomadas no código (precisam do responsável)**
- **Cadastro livre de empresa sem prova de posse do CNPJ** (`/auth/empresa/registrar`): alguém pode registrar o CNPJ de outra empresa e bloqueá-la. Opções: exigir aprovação do admin antes de ativar, ou confirmar e-mail do domínio/CNPJ. Hoje o admin corrige pelo painel (`PATCH /admin/empresas/:id` troca CNPJ/e-mail/senha).
- **Minificação (R8) do app** não foi ligada: precisa de teste em aparelho para não quebrar os plugins (câmera, armazenamento seguro, Google).
- **Limite de tentativas depende de `CF-Connecting-IP`:** só é confiável se o servidor aceitar tráfego somente do Cloudflare (regra no Cloudflare/cPanel).
- **MySQL:** TLS sem validar certificado (hospedagem compartilhada) e porta 3306 acessível de fora — conferir a lista de IPs liberados.
- Campanhas de teste da Loja Teste ("Base", "BATON", "Corte de Cabelo") geram cartões reais para os clientes vinculados: encerrar antes de divulgar.

**Publicação deste lote — feita em 2026-10-15** (banco, servidor, painel da Empresa, admin e `.htaccess`; falta só o app 1.0.2 na Play; `NODE_ENV=production` ainda não foi definido no cPanel, então o CORS de `localhost` segue aberto). Ordem usada (obrigatória em lotes com schema novo): 1) `prisma db push` (coluna `clientes.token_valido_desde`) **antes** do código novo; 2) enviar `server/src/` inteiro + `package.json`/`package-lock.json`; 3) "Run NPM Install" no Node.js App do cPanel (para `proxy-addr` 2.0.8) e, se quiser, definir `NODE_ENV=production`; 4) reiniciar o Passenger e conferir `/health`; 5) publicar `/app/` e o admin (builds novos) e os `.htaccess` de `deploy/`; 6) app 1.0.2 (código 3) na Play.
