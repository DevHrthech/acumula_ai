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

Rotas de login/cadastro têm rate limit dedicado (`limiteLogin`/`limiteRegistro`); todas as rotas têm um rate limit geral (`limiteGeral`).

---

## Autenticação — Empresa

### `POST /auth/empresa/registrar`
Sem autenticação.

| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `nome` | string | sim | ≤150 caracteres |
| `cnpj` | string | sim | dígito verificador válido |
| `email` | string | sim | ≤150, formato de e-mail |
| `senha` | string | sim | ≥8 caracteres |
| `descricaoRecompensa` | string | sim | ≤255 |
| `categoria` | string | não | ≤100 |
| `tipoFidelidade` | enum | não | `MARCACOES` \| `PONTOS` (default `MARCACOES`) |
| `metaFidelidade` | int | não | 1–1000 (default 10) |

- **201** `{ empresa, token }` (token expira em 7 dias)
- **400** campo obrigatório ausente / CNPJ inválido / email inválido / senha curta / valores fora do intervalo
- **409** `Já existe uma empresa cadastrada com esse <campo>.` (e-mail, CNPJ ou código de loja duplicado)

### `POST /auth/empresa/login`
Sem autenticação. Body: `email`, `senha`.
- **200** `{ empresa, token }`
- **401** `Email ou senha inválidos.`

---

## Empresa (autenticada — `authEmpresa`)

### `GET /empresas/me`
- **200** dados completos da empresa (sem `senha_hash`)

### `PATCH /empresas/me`
Atualização parcial — todos os campos opcionais:

`nome` (≤150, não vazio) · `categoria` (≤100, aceita `null`) · `metaFidelidade` (1–1000) · `descricaoRecompensa` (≤255) · `corPrincipal`/`corDestaque` (`#RRGGBB`) · `nomePrograma` (≤100) · `mensagemBoasVindas`/`mensagemResgate` (≤255) · `textoBotaoResgate` (≤60)

**Fora de escopo deste endpoint** (por decisão de produto ou falta de infra): `email`/`cnpj`/senha, `tipoFidelidade` (fixo após cadastro), imagens de marca (ver `PUT /empresas/me/imagens/:tipo` abaixo).

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
- **200** array `{ id, saldoAtual, dataVinculo, empresa }` — `empresa` é uma versão pública (nunca inclui email/CNPJ/dados de gestão, só o necessário para renderizar o cartão: nome, cores, mecânica, textos, ícones)

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
Sem autenticação (conta criada só via `server/scripts/seed-admin.js`, sem autocadastro). Body: `email`, `senha`.
- **200** `{ admin: {id, nome, email}, token }` (expira em 7 dias)
- **401** `Email ou senha inválidos.`

---

## Admin — Empresas, Planos, Licenças, Contratos (autenticada — `authAdmin`)

### `GET /admin/me`
- **200** `{ id, nome, email }` do admin logado (o painel usa pra retomar a sessão). O token do admin vale **8 h**.

### `GET /admin/empresas`
- **200** array de todas as empresas + `licenca_status` (status efetivo da licença mais recente, ou `null`)

### `POST /admin/empresas`
Cadastro de empresa pela equipe 2RL (a empresa também pode se cadastrar sozinha em `/auth/empresa/registrar`). Mesmas validações do cadastro público. Body: `nome`, `cnpj`, `email`, `senha` (≥ 8), `descricaoRecompensa` (obrigatórios) · `categoria`, `tipoFidelidade` (`MARCACOES`|`PONTOS`), `metaFidelidade` (1–1000), `empresaPaiId` (opcionais).
- **201** empresa criada (sem `senha_hash`; `codigo_loja` gerado)
- **400** campo obrigatório ausente / CNPJ, e-mail, senha, tipo ou meta inválidos
- **404** `empresaPaiId` não encontrada
- **409** CNPJ ou e-mail já cadastrado

### `GET /admin/empresas/:id`
- **200** empresa + `licencas[]` (com `status_efetivo` e `plano`) + `contratos[]` + `empresa_pai` + `filiais[]`
- **404** empresa não encontrada

### `PATCH /admin/empresas/:id`
Edita o cadastro da empresa e/ou o vínculo de matriz/filial. Body (todos opcionais, mas ao menos um): `empresaPaiId` (string ou `null` para desvincular) · `nome` · `cnpj` · `email` · `categoria` (ou `null`) · `descricaoRecompensa` · `metaFidelidade` (1–1000) · `novaSenha` (≥ 8; redefine a senha de acesso). A mecânica (`tipo_fidelidade`) é fixa após o cadastro e não é editável.
- **200** empresa atualizada (sem `senha_hash`)
- **400** nenhum campo informado / CNPJ, e-mail, senha ou meta inválidos / empresa não pode ser matriz de si mesma / ciclo simples detectado (A matriz de B, B matriz de A)
- **404** empresa ou empresa-matriz não encontrada
- **409** CNPJ ou e-mail já em uso por outra empresa

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
`planoId`, `dataInicio`, `dataVencimento` (obrigatórios) · `diasTolerancia` (opcional, default 5)
- **201** licença criada + `status_efetivo`
- **400** plano desativado
- **404** empresa ou plano não encontrado

### `PATCH /admin/licencas/:id`
Todos opcionais: `status` (`ATIVA`\|`INADIMPLENTE`\|`BLOQUEADA`\|`CANCELADA`), `dataVencimento`, `diasTolerancia`
- **200** licença atualizada + `status_efetivo`

### `POST /admin/empresas/:id/contratos`
`licencaId` (opcional — se informado, deve pertencer à mesma empresa)
- **201** contrato criado

### `PATCH /admin/contratos/:id`
Todos opcionais: `status` (`RASCUNHO`\|`AGUARDANDO_ASSINATURA`\|`ASSINADO`\|`CANCELADO`), `documentoUrl`, `assinaturaProvedor`, `assinaturaId`, `dataAssinatura`
- **200** contrato atualizado

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
