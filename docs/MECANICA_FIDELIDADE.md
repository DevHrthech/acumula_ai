# Mecânica de Fidelidade — Pontos ou Marcações (por loja)

> Decisão tomada em 2026-09-15, na reconciliação entre o SPEC original (cartão fidelidade fixo por marcações) e o código encontrado em `web/`/`mobile/` (sistema de pontos + campanhas). Ver [SPEC.md](SPEC.md) seção 10 para o histórico completo dessa reconciliação. **Item 1 da revisão "parte a parte" — ✅ CONCLUÍDO, aprovado pelo usuário em 2026-09-15.**

## 1. Decisão

Cada empresa escolhe, uma vez, no cadastro da loja, qual mecânica usar:

- **Marcações**: contador fixo por compra (ex: "a cada 10 compras, 1 grátis"). Zera ao resgatar.
- **Pontos**: cliente acumula um saldo numérico, resgata ao atingir uma meta.

Essa escolha é **fixa após o cadastro** — a loja não pode trocar de mecânica depois de já ter clientes com progresso acumulado (evita ter que converter ou perder progresso de clientes). Se precisar mudar, é um caso de suporte, fora do fluxo normal do produto.

## 2. Campanhas seguem a mesma lógica, sempre herdando o tipo da loja

Campanhas (promoções à parte que a empresa cria, com validade) **sempre usam o mesmo tipo que a loja escolheu** — não é possível uma loja "marcações" criar uma campanha em "pontos", ou vice-versa. Cada campanha declara sua própria **meta** e **validade** (data de expiração), mas o tipo é sempre herdado da empresa.

## 3. Como cada mecânica funciona

### Marcações
- Loja define `qtd_marcacoes_meta` (ex: 10).
- Cada compra marcada = +1 no vínculo cliente↔loja.
- Ao atingir a meta: recompensa liberada, contador **zera**.

### Pontos
- Loja define uma meta de pontos para resgate.
- Cada marcação de compra concede pontos — **não é um valor fixo global nem proporcional ao valor gasto**: vem de um **cadastro de regras de pontuação** que a loja mantém (ver seção 4).
- Ao atingir a meta: recompensa liberada, e o resgate **desconta só o valor da meta** do saldo (ex: meta 500, saldo 620 → após resgatar fica com 120). Saldo residual permanece, acumulando pra próxima recompensa. *(Diferente das marcações, que zeram tudo — no modelo de pontos o saldo é contínuo.)*

## 4. Cadastro de regras de pontuação (detalhe ainda em aberto)

Em vez de um valor único fixo, a loja (no modelo de pontos) mantém um **cadastro de regras** — cada regra define quantos pontos uma marcação concede. Múltiplas regras podem coexistir.

**Em aberto:** qual critério cada regra usa para decidir quando se aplica (por categoria de produto, por campanha específica, por período/dia da semana, ou outro). Isso será decidido quando desenharmos a tela desse cadastro — não bloqueia o restante do item 1.

## 5. Campanha expirada sem o cliente atingir a meta

O progresso daquela campanha **é perdido** ao expirar — pontos/marcações acumulados só valem dentro do período de validade da campanha, não migram pro saldo contínuo da loja.

## 6. Aprovação de campanhas: automática

A campanha fica visível pros clientes assim que a empresa publica — **sem moderação manual**. Não existe (e não vai existir, por ora) um perfil "admin da plataforma"; os perfis continuam só Empresa e Cliente final (SPEC seção 3).

**Implicação:** a tela `web_aprovacao_screen.dart` original (moderação de campanhas) foi removida. Uma nova tela "Aprovação", com propósito diferente (validar compras/marcações via CPF ou cupom fiscal), foi criada depois — ver seção 9. ✅ Concluída e aprovada em 2026-09-15.

## 7. Impacto no modelo de dados (conceitual — implementação fica para depois da fila "parte a parte")

- `empresas`: novo campo `tipo_fidelidade` (`marcacoes` | `pontos`), fixo após criação. Meta genérica (`qtd_marcacoes_meta` vira algo como `meta_fidelidade`, interpretado conforme o tipo).
- `vinculos`: campo genérico de saldo (`saldo_atual`) no lugar de `marcacoes_atuais` — interpretado como contador (zera ao resgatar) ou pontos (desconta só a meta ao resgatar) conforme `empresas.tipo_fidelidade`.
- **Nova entidade `campanhas`**: `empresa_id`, `nome`, `descricao`, `meta`, `data_validade`, `status` (ativa/expirada — sem estado de aprovação, já que é automática). Tipo não precisa de campo próprio — sempre = `empresas.tipo_fidelidade`.
- **Nova entidade `regras_pontuacao`** (nome provisório, só relevante pra lojas tipo `pontos`): `empresa_id`, pontos concedidos, critério de aplicação (a definir — seção 4).
- `resgates`: precisa registrar, no modelo de pontos, quanto foi descontado (a meta) vs. o saldo residual restante; e se o resgate foi do programa padrão ou de uma campanha específica.

## 8. Status

**Decisões fechadas.** Todas as decisões de mecânica (marcações vs. pontos, campanhas, aprovação, resgate, expiração, troca de mecânica) definidas. Único detalhe adiado de propósito: o critério exato das regras de pontuação (seção 4), a resolver quando desenharmos aquela tela especificamente.

**Implementação: ✅ CONCLUÍDA** (server/mobile ficaram de fora por decisão do usuário — foco só em `web/` por ora):
- [x] `schema.prisma` (em `server/`) atualizado com `TipoFidelidade`, `Campanha`, `RegraPontuacao`, saldo genérico em `Vinculo` — feito, mas **não migrado/testado contra banco real** (server está fora de escopo desta rodada; fica documentado, sem `prisma migrate`).
- [x] `web_cadastro_campanha_screen.dart` ganhou os campos **Meta** e **Validade** (que não existiam antes), com o rótulo dinâmico ("Meta de Marcações"/"Meta de Pontos") lido da configuração da loja.
- [x] `web_configuracoes_screen.dart` criado: dados da loja (nome, categoria), identidade visual (3 uploads — ícone, logo do QR Code, logo de promoções), escolha de mecânica (marcações/pontos), meta, descrição da recompensa e — quando "pontos" está selecionado — cadastro de regras de pontuação (adicionar/remover linhas).
- [x] Estado compartilhado `EmpresaConfig`/`EmpresaConfigScope` criado (`lib/state/empresa_config.dart`), mesmo padrão do `ThemeProvider`/`ThemeScope` já usado no projeto, pra outras telas lerem a mecânica escolhida.
- [x] `web_aprovacao_screen.dart` removida do código, do `AdminSection` enum e da navegação (`web_sidebar.dart`, `web_root_screen.dart`); item "Configurações" adicionado na sidebar.
- [x] `flutter analyze` limpo em `web/` (0 issues).
- [x] Testado rodando o app de verdade no navegador (`flutter run -d web-server`): login → dashboard → Configurações → troquei Marcações→Pontos → seção de regras apareceu → adicionei uma regra → salvei (confirmação exibida) → fui em Campanhas → Nova Campanha → confirmei que "Meta de Pontos" e "Validade" aparecem corretos e a pré-visualização reflete "Pontos".
- [x] **Usuário revisou e deu o OK** (2026-09-15).

**Achado durante o teste, corrigido em 2026-09-15:** a lista de campanhas em `web_campanhas_screen.dart` usava dado de exemplo fixo que misturava "Cartela de Selos" (marcações) e "Pontos" na mesma loja ao mesmo tempo. Corrigido: o mock virou uma função `_campanhasMock(TipoFidelidade tipo)`, lida reativamente de `EmpresaConfigScope.of(context)` — a lista inteira agora segue sempre a mecânica atual da loja, testado trocando Marcações↔Pontos e confirmando que todas as 5 campanhas de exemplo mudam juntas.

## 9. Tela "Aprovação" (2026-09-15) — ✅ CONCLUÍDO (aprovado pelo usuário) — conceito diferente da antiga tela removida

Depois do item 1 fechado, foi criada uma tela **"Aprovação"** — não confundir com a antiga `web_aprovacao_screen.dart` removida na seção 6 (aquela era moderação de campanhas de marketing). Esta é sobre **validar compras/marcações reais** dos clientes. Substitui o que seria a tela "Marcar compra" do MVP original (que nunca chegou a ser implementada em código real).

**Fluxo decidido:**
- O cliente solicita pelo app, informando o número do cupom fiscal da compra **ou** apenas solicitando sem informar.
- Toda solicitação cai numa fila de pendências na tela Aprovação (mockada por ora — sem app mobile real ainda).
- A loja busca/filtra a fila por **CPF do cliente** ou **número do cupom fiscal**, e Aprova ou Rejeita cada uma.
- A loja também pode marcar uma compra por conta própria (sem solicitação prévia do cliente), buscando diretamente pelo CPF — botão "Marcar compra manualmente".
- Aprovar = credita 1 marcação (ou pontos, conforme `EmpresaConfig.tipoFidelidade`) no cartão do cliente.

**Implementado e testado em `web/`:**
- `web_aprovacao_screen.dart` (novo arquivo): fila de solicitações, busca/filtro por CPF ou cupom fiscal, chips de status (Todas/Pendentes/Aprovadas/Rejeitadas), aprovar/rejeitar, marcação manual por CPF.
- Nova seção "FIDELIDADE" na sidebar, com "Aprovação" logo abaixo de "Dashboard".
- `flutter analyze` limpo.
- Testado rodando o app real no navegador: aprovar pendência, marcar manualmente por CPF, e a busca por CPF/cupom fiscal filtrando a lista (bug de busca não reativa encontrado e corrigido durante o teste — o campo não tinha listener pra disparar rebuild).
- [x] **Usuário revisou e deu o OK** (2026-09-15).

**Nota técnica:** durante o teste desta rodada, `flutter run -d web-server` (modo debug) mostrou-se pouco confiável neste ambiente (WebSocket de debug falhando, tela não interativa). Passamos a testar com `flutter build web` + um servidor estático simples (`serve-web-build.js`, `run-web.bat` na raiz) — mais lento pra iterar (precisa rebuildar a cada mudança) mas muito mais estável pra verificação.
