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

**Fora de escopo deste endpoint** (por decisão de produto ou falta de infra): `email`/`cnpj`/senha, `tipoFidelidade` (fixo após cadastro), imagens de marca (sem upload ainda).

- **200** empresa atualizada
- **400** valor fora do formato/intervalo esperado

---

## Campanhas (autenticada — `authEmpresa`)

### `GET /empresas/me/campanhas`
- **200** array de campanhas da empresa, mais recentes primeiro

### `POST /empresas/me/campanhas`
`nome` (≤150, obrigatório) · `meta` (int 1–100000, obrigatório) · `dataValidade` (data, obrigatório) · `descricao` (≤255, opcional)
- **201** campanha criada

### `PATCH /empresas/me/campanhas/:id`
`status` (obrigatório): `ATIVA` \| `EXPIRADA`
- **200** campanha atualizada
- **404** campanha não encontrada ou não pertence à empresa autenticada

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

---

## Cliente final (autenticado — `authCliente`)

### `GET /clientes/me`
- **200** dados completos do cliente (sem `senha_hash`)

### `GET /clientes/me/vinculos`
- **200** array `{ id, saldoAtual, dataVinculo, empresa }` — `empresa` é uma versão pública (nunca inclui email/CNPJ/dados de gestão, só o necessário para renderizar o cartão: nome, cores, mecânica, textos, ícones)

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

---

## Autenticação — Admin interno 2RL

### `POST /auth/admin/login`
Sem autenticação (conta criada só via `server/scripts/seed-admin.js`, sem autocadastro). Body: `email`, `senha`.
- **200** `{ admin: {id, nome, email}, token }` (expira em 7 dias)
- **401** `Email ou senha inválidos.`

---

## Admin — Empresas, Planos, Licenças, Contratos (autenticada — `authAdmin`)

### `GET /admin/empresas`
- **200** array de todas as empresas + `licenca_status` (status efetivo da licença mais recente, ou `null`)

### `GET /admin/empresas/:id`
- **200** empresa + `licencas[]` (com `status_efetivo` e `plano`) + `contratos[]` + `empresa_pai` + `filiais[]`
- **404** empresa não encontrada

### `PATCH /admin/empresas/:id`
Define/remove o vínculo de matriz/filial. Body: `empresaPaiId` (obrigatório — string ou `null` explícito para desvincular).
- **200** empresa atualizada
- **400** empresa não pode ser matriz de si mesma / ciclo simples detectado (A matriz de B, B matriz de A)
- **404** empresa ou empresa-matriz não encontrada

### `GET /admin/planos`
- **200** array de planos

### `POST /admin/planos`
`nome` (obrigatório) · `valorMensal` (número positivo, obrigatório) · `descricao` (opcional)
- **201** plano criado

### `POST /admin/empresas/:id/licencas`
`planoId`, `dataInicio`, `dataVencimento` (obrigatórios) · `diasTolerancia` (opcional, default 5)
- **201** licença criada + `status_efetivo`
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
