# Referência de API — ACUMULAAI

Base URL produção: `https://api.acumulaai.com.br` · Local: `http://localhost:3000`

Todas as respostas são JSON. Erros seguem o formato `{ "erro": "mensagem" }`. Autenticação via header `Authorization: Bearer <token>` (JWT HS256) — três tipos de token independentes e não-intercambiáveis, ver [ARCHITECTURE.md](ARCHITECTURE.md#4-modelo-de-autenticação).

Erros comuns aos três middlewares de autenticação:

| Status | Situação |
|---|---|
| 401 `Token de autenticação ausente.` | Sem header `Authorization` ou sem prefixo `Bearer` |
| 401 `Token inválido para este recurso.` | Token de um tipo usado em rota de outro tipo (ex: token de cliente numa rota de empresa) |
| 401 `Token inválido ou expirado.` | Assinatura inválida ou token expirado |
| 403 (só `authEmpresa`) `Acesso bloqueado por pendência de licença/pagamento...` | Licença da empresa com status efetivo `BLOQUEADA`/`CANCELADA` |

Rotas de login/cadastro têm rate limit dedicado (`limiteLogin`/`limiteRegistro`); todas as rotas têm um rate limit geral (`limiteGeral`). O webhook do Asaas (`/webhooks/asaas`) fica **antes** do limite geral e tem o seu próprio (`limiteWebhook`, 600/min por IP).

> **Cobrança (Asaas):** as rotas de cobrança estão nas seções [Planos (público)](#planos-público), [Empresa → Assinatura](#assinatura-e-forma-de-pagamento-autenticada--authempresa), [Webhook do Asaas](#webhook-do-asaas), [Admin → Licenças/Cobranças](#admin--empresas-planos-licenças-contratos-autenticada--authadmin) e [Admin → Financeiro](#admin--financeiro-autenticada--authadmin). Visão geral e regras em [SPEC.md](../SPEC.md) seção 21.

---

## Autenticação — Empresa

### `POST /auth/empresa/registrar`
Sem autenticação.

| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `nome` | string | sim | ≤150 caracteres |
| `cnpjCpf` | string | sim | **CPF** (pessoa física, 11 dígitos) **ou CNPJ** (14 dígitos), com ou sem máscara, com dígito verificador válido do tipo correspondente; sai formatado em `cnpj_cpf`. O campo antigo `cnpj` continua aceito (compatibilidade com painel antigo) |
| `email` | string | sim | ≤150, formato de e-mail |
| `senha` | string | sim | ≥8 caracteres |
| `descricaoRecompensa` | string | sim | ≤255 |
| `categoria` | string | não | ≤100 |
| `tipoFidelidade` | enum | não | `MARCACOES` \| `PONTOS` (default `MARCACOES`) |
| `metaFidelidade` | int | não | 1–1000 (default 10) |
| `planoId` | string | sim | id de um plano **ativo** (ver `GET /planos`) |
| `formaPagamento` | enum | sim | `PIX` \| `CARTAO_RECORRENTE` (boleto não é oferecido) |
| `aceiteTermos` | boolean | sim | tem de ser exatamente `true` (aceite de que os pagamentos são processados via gateway Asaas; grava `aceite_termos_em` e a versão do termo) |

Além da empresa, o cadastro cria a **licença de trial** (15 dias a partir de hoje no fuso de Brasília, `em_trial: true`, `gateway_provedor: 'ASAAS'`, uma única vez por empresa — o CPF/CNPJ é único), replica a empresa como cliente no Asaas e cria a **assinatura mensal** (a 1ª fatura vence no dia seguinte ao fim do trial). Falha do Asaas **não desfaz** o cadastro.

- **201** `{ empresa, token, licenca, asaas_sincronizado, assinatura_criada }` — token expira em 7 dias; `licenca` traz `data_vencimento` (fim do trial), `forma_pagamento`, `em_trial`, `gateway_assinatura_id` e `dias_trial: 15`; `asaas_sincronizado`/`assinatura_criada` são `false` se o Asaas falhou (o admin refaz em `POST /admin/licencas/:id/assinatura`)
- **400** campo obrigatório ausente / `CPF ou CNPJ inválido.` / email inválido / senha curta / valores fora do intervalo / `Escolha um plano.` / `formaPagamento deve ser PIX ou CARTAO_RECORRENTE.` / `É preciso aceitar que os pagamentos serão processados via gateway Asaas.` / `Plano indisponível. Escolha outro.`
- **409** `Já existe uma empresa cadastrada com esse <campo>.` (e-mail, CPF/CNPJ ou código de loja duplicado)
- **429** limite de cadastros (5 por hora por IP)

### `POST /auth/empresa/login`
Sem autenticação. Body: `email`, `senha`.
- **200** `{ empresa, token }`
- **401** `Email ou senha inválidos.`

---

## Planos (público)

### `GET /planos`
Sem autenticação. Lista os planos **ativos**, do mais barato ao mais caro — alimenta a escolha de plano no auto-cadastro.
- **200** `[{ id, nome, valor_mensal, descricao }]` (`valor_mensal` vem como texto decimal, ex: `"99.9"`)

---

## Empresa (autenticada — `authEmpresa`)

### `GET /empresas/me`
- **200** dados completos da empresa (sem `senha_hash`)

### `PATCH /empresas/me`
Atualização parcial — todos os campos opcionais:

`nome` (≤150, não vazio) · `categoria` (≤100, aceita `null`) · `metaFidelidade` (1–1000) · `descricaoRecompensa` (≤255) · `corPrincipal`/`corDestaque` (`#RRGGBB`) · `nomePrograma` (≤100) · `mensagemBoasVindas`/`mensagemResgate` (≤255) · `textoBotaoResgate` (≤60)

**Fora de escopo deste endpoint** (por decisão de produto ou falta de infra): `email`/`cnpjCpf`/senha, `tipoFidelidade` (fixo após cadastro), imagens de marca (ver `PUT /empresas/me/imagens/:tipo` abaixo).

- **200** empresa atualizada
- **400** valor fora do formato/intervalo esperado

### `PUT /empresas/me/imagens/:tipo`
Envia uma imagem de marca. `:tipo` = `icone` \| `logo-qrcode` \| `logo-promocao`. O corpo é o **binário da imagem** (não JSON), com `Content-Type: image/png` ou `image/jpeg`, até 2 MB. O formato é conferido pelos bytes iniciais (SVG e outros são recusados). O arquivo fica em `server/uploads/<empresaId>/` e é servido em `/uploads/...`; a imagem anterior do mesmo tipo é apagada.
- **200** empresa atualizada, com `icone_url` / `logo_qrcode_url` / `logo_promocao_url`
- **400** tipo inválido, corpo vazio ou formato inválido
- **413** imagem maior que 2 MB

### `DELETE /empresas/me/imagens/:tipo`
Remove a imagem (campo volta a `null` e o arquivo é apagado).
- **200** empresa atualizada

---

## Assinatura e forma de pagamento (autenticada — `authEmpresa`)

### `GET /empresas/me/assinatura`
Situação da licença mais recente da empresa e as últimas 12 faturas (as cobranças mensais geradas no Asaas, mais recentes por vencimento primeiro).
- **200** `{ licenca, cobrancas, nota_fiscal_ativa }` — `nota_fiscal_ativa` é `false` enquanto a emissão automática de NFS-e não está ligada no servidor (`NFSE_ATIVA`)
  - `licenca`: `{ plano: { nome, valor_mensal }, forma_pagamento, em_trial, data_inicio, data_vencimento, status_efetivo, assinatura_ativa }` — `status_efetivo` é `ATIVA` \| `INADIMPLENTE` \| `BLOQUEADA` \| `CANCELADA` (calculado por data); `assinatura_ativa` é `false` quando a licença não tem assinatura no Asaas (ex: licença antiga, lançada à mão)
  - `cobrancas`: `[{ id, valor, forma_pagamento, status, data_vencimento, data_pagamento, invoice_url, nota_fiscal }]` — `status` é o do Asaas (`PENDING`, `OVERDUE`, `RECEIVED`, `CONFIRMED`, `RECEIVED_IN_CASH`, `REFUNDED`, `DELETED`…); `invoice_url` é o link da fatura (abrir em nova aba); `nota_fiscal` é `null` até a nota ser autorizada e depois `{ numero, data_emissao, pdf_url, xml_url }` (links https do Asaas, abrir em nova aba; notas canceladas/com erro não aparecem)
- **200** `{ licenca: null, cobrancas: [] }` se a conta não tem licença

### `PUT /empresas/me/assinatura/forma-pagamento`
A própria empresa escolhe/troca a forma de pagamento da sua licença atual. Body: `formaPagamento` (`PIX` \| `CARTAO_RECORRENTE`).
- Sem assinatura no Asaas: só grava a forma (a cobrança automática continua sendo ativada pelo admin).
- Com assinatura: cancela a antiga no Asaas (as faturas em aberto são removidas) e cria uma nova na forma escolhida, com a 1ª fatura no dia seguinte ao fim do período já pago.
- **200** `{ forma_pagamento, aviso? }` — `aviso` vem quando a forma foi gravada mas a nova assinatura no Asaas não pôde ser criada
- **400** forma inválida / licença cancelada (`Licença cancelada: reative antes de trocar a forma de pagamento.`)
- **404** `Sua conta ainda não tem uma licença.`
- **502** `Não foi possível cancelar a assinatura atual no Asaas: …` (nada é alterado)

---

## Webhook do Asaas

### `POST /webhooks/asaas`
Chamado **pelo Asaas** (não pelos painéis). Sem JWT: autentica pelo header `asaas-access-token`, que tem de ser igual a `ASAAS_WEBHOOK_TOKEN` (comparação em tempo constante). Body (formato do Asaas): `{ id, event, payment? }`.

- Cada `id` de evento é gravado em `asaas_eventos`; um evento repetido (entrega "pelo menos uma vez") responde 200 sem reprocessar. Se o processamento falha, o `id` é liberado e a resposta é 500, para o Asaas reenviar.
- Eventos `PAYMENT_*` de cobranças que pertencem a uma assinatura **nossa** (`payment.subscription` = `licencas.gateway_assinatura_id`) atualizam `cobrancas`. Cobranças avulsas ou de outras assinaturas são ignoradas (200).
- `PAYMENT_CONFIRMED` / `PAYMENT_RECEIVED` **renovam a licença uma única vez por cobrança**: novo vencimento = um mês a partir do vencimento da fatura, menos 1 dia (nunca encurta); `em_trial` vira `false`; status `INADIMPLENTE` volta a `ATIVA` (`BLOQUEADA`/`CANCELADA` marcados pelo admin não são desfeitos). `PAYMENT_OVERDUE` não renova.
- **200** `{ recebido: true }` (ou `{ recebido: true, duplicado: true }`)
- **400** `Evento inválido.` · **401** `Token inválido.` · **500** erro ao processar · **503** `Webhook não configurado.` (servidor sem `ASAAS_WEBHOOK_TOKEN`)

- Eventos `INVOICE_*` (nota fiscal de serviço, body `{ id, event, invoice }`) de cobranças nossas (`invoice.payment` existe em `cobrancas`) criam/atualizam `notas_fiscais`; notas de cobranças desconhecidas são ignoradas (200). Eventos fora de ordem não apagam número/PDF/XML já salvos nem fazem uma nota autorizada voltar a agendada. Na **primeira** vez que a nota chega `AUTHORIZED` com PDF/XML, a empresa recebe um e-mail com os links (uma única vez por nota, `notas_fiscais.email_enviado_em`); falha no e-mail é logada e não derruba o webhook. `INVOICE_ERROR` grava `motivo_erro` e registra no log do servidor.

Eventos assinados no webhook (cadastrado por `server/scripts/asaas-webhook.js`): `PAYMENT_CREATED`, `PAYMENT_UPDATED`, `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED`, `PAYMENT_OVERDUE`, `PAYMENT_DELETED`, `PAYMENT_RESTORED`, `PAYMENT_REFUNDED`, `PAYMENT_CREDIT_CARD_CAPTURE_REFUSED`, `PAYMENT_CHARGEBACK_REQUESTED`, `INVOICE_CREATED`, `INVOICE_UPDATED`, `INVOICE_SYNCHRONIZED`, `INVOICE_AUTHORIZED`, `INVOICE_PROCESSING_CANCELLATION`, `INVOICE_CANCELED`, `INVOICE_CANCELLATION_DENIED`, `INVOICE_ERROR`. **Depois de subir esta versão, rodar o script de novo** para o webhook existente passar a receber os eventos de nota.

---

## Campanhas (autenticada — `authEmpresa`)

### `GET /empresas/me/campanhas`
- **200** array de campanhas da empresa, mais recentes primeiro. Cada item traz `status_efetivo` (`ATIVA` | `AGENDADA` início no futuro | `VENCIDA` passou da validade | `EXPIRADA` encerrada à mão) e `vencida` (boolean). O `status` gravado só muda por ação manual.

> **Datas:** campos DATE (`dataInicio`, `dataValidade`, vencimento de licença) são lidos só pela parte AAAA-MM-DD e valem no calendário de Brasília (`utils/data.js`); uma validade vale até o fim desse dia. Validade no passado → **400**.

### `POST /empresas/me/campanhas`
`nome` (≤150, obrigatório) · `meta` (int 1–100000, obrigatório) · `dataValidade` (data, obrigatório) · `dataInicio` (data, opcional — sem ela, fixa a data do cadastro; não pode ser depois da validade; campanha só gera cartão/recebe marcação a partir do início) · `descricao` (≤255, opcional)
- **201** campanha criada

### `PATCH /empresas/me/campanhas/:id`
`status` (obrigatório): `ATIVA` \| `EXPIRADA`
- **200** campanha atualizada
- **404** campanha não encontrada ou não pertence à empresa autenticada

---

## Promoções (autenticada — `authEmpresa`)

Promoção = aviso/post para os clientes vinculados. Sem meta e sem cartão fidelidade (isso é a Campanha).

### `GET /empresas/me/promocoes`
- **200** array de promoções da empresa, mais recentes primeiro (com `status_efetivo` e `vencida`, como nas campanhas)

### `POST /empresas/me/promocoes`
`titulo` (≤150, obrigatório) · `descricao` (≤500, opcional) · `dataInicio` (data, opcional — sem ela, fixa a data do cadastro) · `dataValidade` (data, opcional — sem ela, sem data limite; não pode ser antes do início). A promoção só aparece no app dentro do período.
- **201** promoção criada

### `PATCH /empresas/me/promocoes/:id`
`status` (obrigatório): `ATIVA` | `EXPIRADA` — **200** atualizada · **404** não encontrada

### `DELETE /empresas/me/promocoes/:id`
- **200** `{ ok: true }` · **404** não encontrada

---

## Solicitações de marcação (autenticada — `authEmpresa`)

### `GET /empresas/me/solicitacoes`
Query params opcionais: `status` (`PENDENTE`\|`APROVADA`\|`REJEITADA`), `cpf`, `cupomFiscal` (busca parcial)
- **200** array com dados do cliente, saldo atual e meta da empresa

### `PATCH /empresas/me/solicitacoes/:id`
`acao` (obrigatório): `aprovar` \| `rejeitar`
- **200** (rejeitar) `{ id, status: 'REJEITADA' }`
- **200** (aprovar) `{ id, status: 'APROVADA', saldoAtual, recompensaLiberada }` — credita o vínculo via `creditarVinculo()`
- **409** `Esta solicitação já foi resolvida.`

### `POST /empresas/me/solicitacoes/marcar-manual`
Marcação manual pela empresa, sem passar pelo fluxo de solicitação do cliente. Body: `cpf` (obrigatório).
- **201** `{ cliente: {nome, cpf}, saldoAtual, recompensaLiberada }`
- **404** cliente não encontrado, ou `Este cliente não está vinculado à sua loja.`

---

## Relatório (autenticada — `authEmpresa`)

### `GET /empresas/me/clientes`
- **200** array de clientes vinculados: `clienteId, nome, cpf, email, telefone, saldoAtual, totalMarcacoes, totalResgates, dataVinculo`

### `GET /empresas/me/dashboard`
- **200** `{ clientesAtivos, campanhasAtivas, marcacoesMes, resgatesMes, atividadesRecentes[] }` — `*Mes` conta a partir do dia 1 do mês corrente; `atividadesRecentes` mescla marcações e resgates (top 10, mais recentes primeiro)

---

## Autenticação — Cliente final

### `POST /auth/cliente/cadastro`
Sem autenticação. `nome` (≤150) · `cpf` (dígito verificador válido) · `senha` (≥8) · `telefone` (≤20) · `email` (opcional, ≤150) — todos exceto `email` obrigatórios.
- **201** `{ cliente, token }` (expira em 30 dias)
- **409** `Já existe uma conta cadastrada com esse CPF.`

### `POST /auth/cliente/login`
Body: `cpf`, `senha`.
- **200** `{ cliente, token }`
- **401** `CPF ou senha inválidos.`

### `POST /auth/cliente/esqueci-senha`
Sem autenticação. Body: `cpf` (válido). Se existir conta com esse CPF **e** e-mail cadastrado, gera um código de 6 dígitos (validade 15 min), guarda só o hash e envia ao e-mail (via `sendmail` local — ver `server/src/utils/mailer.js`). A resposta é sempre a mesma, exista ou não a conta. No máximo 1 envio por minuto por conta; 5 pedidos/hora por IP.
- **200** `{ ok: true, mensagem }`
- **400** `Informe um CPF válido.`
- **429** limite de pedidos

### `POST /auth/cliente/redefinir-senha`
Sem autenticação. Body: `cpf`, `codigo`, `novaSenha` (≥8). O código é de uso único; após 5 códigos errados ele é bloqueado e é preciso pedir outro.
- **200** `{ ok: true }`
- **400** `Código inválido ou expirado. Peça um novo código.` / senha curta

### `POST /auth/cliente/google`
Sem autenticação. Body: `idToken` (ID token do Google obtido no app). O servidor valida o token (ver [LOGIN_GOOGLE.md](LOGIN_GOOGLE.md)).
- **200** `{ cliente, token }` — conta já vinculada a este Google. **Não** vincula por e-mail (o e-mail do cadastro por CPF nunca foi confirmado)
- **200** `{ precisaCadastro: true, nome, email, tokenCadastro }` — primeiro acesso; falta CPF e telefone (`tokenCadastro` vale 15 min)
- **401** `Não foi possível validar o login com o Google.`
- **503** `Login com Google indisponível no momento.` (servidor sem `GOOGLE_CLIENT_ID`)

### `POST /auth/cliente/google/completar`
Sem autenticação. Body: `tokenCadastro`, `cpf`, `telefone`, `senha` (opcional). Cria a conta (nome e e-mail vêm do Google). Se o CPF **já tem conta** sem Google, informar a `senha` dela vincula o Google a essa conta.
- **201** `{ cliente, token }` (conta nova) · **200** `{ cliente, token }` (Google vinculado a conta existente)
- **400** CPF/telefone inválidos · **401** `tokenCadastro` expirado ou inválido, ou senha incorreta (`codigo: CPF_EXISTENTE`)
- **409** CPF já tem conta e nenhuma senha foi enviada (`codigo: CPF_EXISTENTE` — o app então pede a senha)

---

## Cliente final (autenticado — `authCliente`)

### `GET /clientes/me`
- **200** dados completos do cliente (sem `senha_hash`)

### `PATCH /clientes/me`
Atualiza o e-mail de recuperação. Body: `email` (string; vazio remove).
- **200** cliente atualizado
- **400** `E-mail inválido.`

### `GET /clientes/me/atividades`
Histórico recente (até 30 itens, mais novos primeiro) de marcações, resgates e solicitações de todas as lojas do cliente: `[{ tipo: MARCACAO|RESGATE|SOLICITACAO, loja, data, pontos?, status? }]`.

### `GET /clientes/me/vinculos`
- **200** array `{ id, saldoAtual, dataVinculo, empresa }` — `empresa` é uma versão pública (nunca inclui email/CPF/CNPJ/dados de gestão, só o necessário para renderizar o cartão: nome, cores, mecânica, textos, ícones)

### `GET /clientes/me/campanhas`
Cartões de campanha: um por campanha `ATIVA` e dentro da validade das lojas vinculadas. **200** `[{ id, nome, descricao, meta, dataValidade, saldoAtual, empresa }]` (progresso calculado só com as marcações daquela campanha).

### `GET /clientes/me/promocoes`
Promoções ativas (e dentro da validade, se houver) das lojas vinculadas, mais recentes primeiro. **200** `[{ id, titulo, descricao, dataInicio, dataValidade, createdAt, empresa }]`.

### `POST /clientes/me/vinculos`
Vincula o cliente a uma loja via código. Body: `codigoLoja` (normalizado para maiúsculas, sem símbolos, antes da busca).
- **201** vínculo criado (mesmo formato do GET)
- **404** `Loja não encontrada para esse código.`
- **409** `Você já está vinculado a esta loja.`

### `GET /clientes/me/resumo`
- **200** `{ saldoTotal, totalMarcacoes, totalResgates }` — agregado de todos os vínculos do cliente

### `POST /clientes/me/solicitacoes`
Cliente solicita que uma compra seja validada pela empresa. Body: `empresaId` (obrigatório), `cupomFiscal` (opcional, ≤50).
- **201** `{ id, status, createdAt }`
- **404** `Você não está vinculado a esta loja.`

### `PATCH /clientes/me/preferencias`
Atualização parcial, ao menos um campo obrigatório: `notificacoesPush`, `notificacoesEmail`, `loginBiometrico` (todos boolean).
- **200** cliente atualizado
- **400** `Informe ao menos uma preferência pra atualizar.`

### `DELETE /clientes/me`
Exclusão definitiva da conta (exigida pela Google Play/LGPD). Body: `senha` **ou** `idToken` (ID token recém-obtido do Google, para contas vinculadas ao Google — elas não têm senha que o cliente conheça; o token precisa ser da MESMA conta Google). Apaga em transação o cliente, seus vínculos, marcações, solicitações e resgates. Usa o rate limit de login.
- **200** `{ ok: true }`
- **400** sem senha nem `idToken`, ou `idToken` numa conta sem Google
- **401** `Senha incorreta.` / Google inválido ou de outra conta

> **Sessão do cliente:** o token de 30 dias é conferido a cada chamada (`middleware/authCliente.js`): conta excluída ou senha redefinida depois da emissão → **401** (`token_valido_desde`). `sanitizarCliente` expõe `conta_google`.

### `POST /clientes/me/solicitacoes` — regras anti-spam
Um pedido `PENDENTE` por loja (**409** `Você já tem uma solicitação aguardando validação nesta loja.`) e o mesmo `cupomFiscal` não pode ser usado em dois pedidos pendentes/aprovados da mesma loja (**409** `Este cupom fiscal já foi informado.`).

---

## Autenticação — Admin interno 2RL

### `POST /auth/admin/login`
Sem autenticação (conta criada só via `server/scripts/seed-admin.js`, sem autocadastro). Body: `email`, `senha`, `lembrar` (opcional; só `true` booleano conta — "Lembrar acesso neste dispositivo").
- **200** `{ admin: {id, nome, email}, token }` — o token (`{sub, tipo:'admin'}`, sem e-mail) expira em **8 h**, ou **14 dias** com `lembrar: true`
- **401** `Email ou senha inválidos.`

### `POST /auth/admin/logout`
Autenticada (`authAdmin`). Grava `admins_2rl.token_valido_desde = now()`: todos os tokens emitidos antes (inclusive o "lembrado" em outro aparelho) passam a dar 401. O painel chama ao clicar em "Sair do Painel" (melhor esforço). **200** `{ ok: true }`.

---

## Admin — Empresas, Planos, Licenças, Contratos (autenticada — `authAdmin`)

### `GET /admin/me`
- **200** `{ id, nome, email }` do admin logado (o painel usa pra retomar a sessão). O token do admin vale **8 h** (14 dias com "Lembrar acesso"); `authAdmin` confere a cada chamada se o admin existe e se o token é posterior a `token_valido_desde`.

### `GET /admin/empresas`
- **200** array de todas as empresas, cada uma com:
  - `licenca_status`: status efetivo da licença mais recente (`ATIVA`/`INADIMPLENTE`/`BLOQUEADA`/`CANCELADA`) ou `null`
  - `situacao_financeira`: `SEM_LICENCA` \| `EM_TESTE` \| `PAGA` \| `ATIVA_MANUAL` (licença lançada à mão, sem assinatura no Asaas) \| `ATRASADA` \| `BLOQUEADA` \| `CANCELADA`
  - `plano_nome`, `forma_pagamento` (`PIX`/`CARTAO_RECORRENTE`/`null`), `licenca_vencimento`
  - `fatura_aberta`: `{ valor, data_vencimento, atrasada }` da fatura em aberto mais antiga, ou `null`

### `POST /admin/empresas`
Cadastro de empresa pela equipe 2RL (a empresa também pode se cadastrar sozinha em `/auth/empresa/registrar`). Mesmas validações do cadastro público. Body: `nome`, `cnpjCpf` (CPF ou CNPJ; o antigo `cnpj` ainda é aceito), `email`, `senha` (≥ 8), `descricaoRecompensa` (obrigatórios) · `categoria`, `tipoFidelidade` (`MARCACOES`|`PONTOS`), `metaFidelidade` (1–1000), `empresaPaiId` (opcionais).
- **201** empresa criada (sem `senha_hash`; `codigo_loja` gerado)
- **400** campo obrigatório ausente / CPF ou CNPJ, e-mail, senha, tipo ou meta inválidos
- **404** `empresaPaiId` não encontrada
- **409** CPF/CNPJ ou e-mail já cadastrado

### `GET /admin/empresas/:id`
- **200** empresa + `licencas[]` (com `status_efetivo`, `plano`, `forma_pagamento`, `em_trial` e `gateway_assinatura_id`) + `situacao_financeira` + `cobrancas[]` (até 24, por vencimento decrescente: campos de `cobrancas` com `valor` numérico e `atrasada` boolean — em aberto e já vencida) + `contratos[]` + `empresa_pai` + `filiais[]`
- **404** empresa não encontrada

### `PATCH /admin/empresas/:id`
Edita o cadastro da empresa e/ou o vínculo de matriz/filial. Body (todos opcionais, mas ao menos um): `empresaPaiId` (string ou `null` para desvincular) · `nome` · `cnpjCpf` (CPF ou CNPJ; `cnpj` legado aceito) · `email` · `categoria` (ou `null`) · `descricaoRecompensa` · `metaFidelidade` (1–1000) · `novaSenha` (≥ 8; redefine a senha de acesso). A mecânica (`tipo_fidelidade`) é fixa após o cadastro e não é editável.
- **200** empresa atualizada (sem `senha_hash`)
- **400** nenhum campo informado / CPF ou CNPJ, e-mail, senha ou meta inválidos / empresa não pode ser matriz de si mesma / ciclo simples detectado (A matriz de B, B matriz de A)
- **404** empresa ou empresa-matriz não encontrada
- **409** CPF/CNPJ ou e-mail já em uso por outra empresa

### `GET /admin/planos`
- **200** array de planos

### `POST /admin/planos`
`nome` (obrigatório) · `valorMensal` (número positivo, obrigatório) · `descricao` (opcional)
- **201** plano criado

### `PATCH /admin/planos/:id`
Edita e/ou ativa/desativa um plano. Body (todos opcionais): `nome`, `valorMensal`, `descricao`, `ativo` (boolean). Plano desativado não pode ser usado em **novas** licenças (as existentes continuam valendo).
- **200** plano atualizado
- **400** valor inválido · **404** plano não encontrado

### `POST /admin/empresas/:id/licencas`
`planoId`, `dataInicio`, `dataVencimento` (obrigatórios) · `diasTolerancia` (opcional, default 5) · `formaPagamento` (`PIX` \| `CARTAO_RECORRENTE`, opcional, **padrão `PIX`**) · `criarAssinatura` (boolean, opcional, padrão `false`: com `true` cria já a assinatura no Asaas, com a 1ª fatura no dia seguinte ao vencimento da licença)
- **201** licença criada + `status_efetivo` (+ `aviso` se a licença foi criada mas a assinatura no Asaas falhou)
- **400** plano desativado / `formaPagamento` inválida / datas inválidas
- **404** empresa ou plano não encontrado

### `PATCH /admin/licencas/:id`
Todos opcionais: `status` (`ATIVA`\|`INADIMPLENTE`\|`BLOQUEADA`\|`CANCELADA`), `dataVencimento`, `diasTolerancia`
- **Cancelar** (`status: CANCELADA`) também **cancela a assinatura no Asaas** (as faturas em aberto somem; localmente ficam `DELETED` e `gateway_assinatura_id` é liberado). Se o Asaas recusar, nada é alterado.
- **Reativar** (`status: ATIVA` sobre uma licença cancelada que tem `forma_pagamento`) cria uma assinatura nova no Asaas; se falhar, a licença é reativada e a resposta traz `aviso`.
- **200** licença atualizada + `status_efetivo` (+ `aviso`)
- **400** status/data/tolerância inválidos · **404** licença não encontrada · **502** `Não foi possível cancelar a assinatura no Asaas: …`

### `PUT /admin/licencas/:id/forma-pagamento`
Troca a forma de pagamento da licença. Body: `formaPagamento` (`PIX` \| `CARTAO_RECORRENTE`). Mesma regra do `PUT /empresas/me/assinatura/forma-pagamento`: sem assinatura só grava; com assinatura, cancela a antiga e cria a nova.
- **200** licença atualizada + `status_efetivo` (+ `aviso`)
- **400** forma inválida / licença cancelada · **404** licença não encontrada · **502** falha ao cancelar a assinatura atual no Asaas

### `POST /admin/licencas/:id/assinatura`
Cria (ou refaz, se a criação no cadastro falhou, ou para licenças antigas sem cobrança automática) a assinatura da licença no Asaas: garante o cliente no Asaas, cria a assinatura mensal no valor do plano e já traz a 1ª fatura. **Idempotente:** se a licença já tem assinatura, não cria outra. A 1ª fatura vence no dia seguinte ao vencimento da licença (ou hoje, se o vencimento já passou).
- **200** `{ licencaId, assinaturaId }`
- **400** a licença não tem forma de pagamento · **404** licença não encontrada · **502** `Não foi possível criar a assinatura no Asaas: …`

### `POST /admin/empresas/:id/contratos`
`licencaId` (opcional — se informado, deve pertencer à mesma empresa)
- **201** contrato criado

### `PATCH /admin/contratos/:id`
Todos opcionais: `status` (`RASCUNHO`\|`AGUARDANDO_ASSINATURA`\|`ASSINADO`\|`CANCELADO`), `documentoUrl`, `assinaturaProvedor`, `assinaturaId`, `dataAssinatura`
- **200** contrato atualizado

---

## Admin — Financeiro (autenticada — `authAdmin`)

### `GET /admin/financeiro?periodo=mes|3m|6m|12m|ano`
Dashboard financeiro, calculado na hora a partir de `cobrancas` e `licencas`. `periodo` (padrão `6m`): `mes` = mês atual · `3m`/`6m`/`12m` = esse número de meses terminando no atual · `ano` = desde 1º de janeiro. Datas no calendário de Brasília. "Recebido" usa a data de pagamento; "em aberto" usa o vencimento.
- **200** `{ periodo, kpis, empresas, conversao_trial, serie_mensal, por_plano, por_forma, faturas_em_atraso, proximos_vencimentos, trials_terminando }`
  - `periodo`: `{ chave, de, ate }`
  - `kpis`: `faturamento_periodo`, `pagamentos_periodo`, `ticket_medio`, `faturamento_mes_atual`, `faturamento_mes_anterior`, `variacao_mes_pct` (`null` sem base), `mrr`, `assinantes_pagantes`, `previsao_trials` (receita mensal se todos os testes convertessem), `a_receber` + `faturas_a_receber` (em aberto e ainda não vencidas), `em_atraso` + `faturas_em_atraso` (`OVERDUE`, ou `PENDING` já vencida)
  - `empresas`: contagem por `situacao_financeira` (`PAGA`, `ATIVA_MANUAL`, `EM_TESTE`, `ATRASADA`, `BLOQUEADA`, `CANCELADA`, `SEM_LICENCA`) + `total`
  - `conversao_trial`: `trials_total`, `em_andamento`, `iniciados_no_periodo`, `convertidos`, `taxa_pct` (`null` sem testes encerrados)
  - `serie_mensal`: `[{ mes: 'AAAA-MM', recebido, em_aberto }]` — um item por mês do período
  - `por_plano`: `[{ plano, assinantes, receita_mensal }]` (empresas pagantes) · `por_forma`: `[{ forma, total, quantidade }]` (recebido no período, por forma do Asaas: `PIX`, `CREDIT_CARD`, `BOLETO`…)
  - `faturas_em_atraso` / `proximos_vencimentos` (30 dias) — até 10 itens `{ empresa_id, empresa, valor, forma_pagamento, data_vencimento, dias_atraso, invoice_url }` · `trials_terminando` (7 dias) — até 10 itens `{ empresa_id, empresa, plano, data_vencimento, dias_restantes }`
- **400** `periodo deve ser mes, 3m, 6m, 12m ou ano.`

---

## Admin — Monitoramento (autenticada — `authAdmin`)

### `GET /admin/monitoramento/resumo`
- **200** `{ total24h, total7d, porClasseStatus: {2xx,3xx,4xx,5xx}, latenciaMediaMs, topRotas: [{rota, metodo, total}] }` (top 5), agregado on-the-fly da tabela `requisicoes_api`

### `GET /admin/monitoramento/uso-por-empresa`
- **200** array `{ empresaId, nome, totalChamadas }`, últimos 7 dias, ordenado desc

---

## Diagnóstico

### `GET /health`
Sem autenticação. `{ "status": "ok" }` — **sempre verificar depois de qualquer restart do Passenger** (ver [DEPLOYMENT.md](DEPLOYMENT.md)).
