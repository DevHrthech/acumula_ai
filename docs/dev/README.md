# Documentação técnica — ACUMULAAI

Este diretório reúne a documentação técnica formal do projeto, escrita para quem vai desenvolver, dar manutenção ou fazer onboarding no código. Ela é complementar à documentação de produto/decisões já existente na raiz de `docs/` — **nenhuma substitui a outra**:

| Documento | Conteúdo | Quando consultar |
|---|---|---|
| [`../SPEC.md`](../SPEC.md) | Log cronológico de decisões de produto, sessões de trabalho e histórico do projeto | Entender **por que** uma decisão foi tomada, ou o que já foi tentado |
| [`../MODELO_DADOS.md`](../MODELO_DADOS.md) + [`../schema.sql`](../schema.sql) | Modelo de dados conceitual e DDL exato | Entender entidades e relacionamentos do banco |
| [`../MECANICA_FIDELIDADE.md`](../MECANICA_FIDELIDADE.md) | Regras de negócio da mecânica de fidelidade (pontos vs. marcações) | Implementar/alterar lógica de crédito e resgate |
| **`ARCHITECTURE.md`** (este diretório) | Visão geral do sistema, stack, fluxo entre as 3 frentes, autenticação | Entender como as peças se encaixam antes de mexer em qualquer uma |
| **`API.md`** (este diretório) | Referência completa de todos os endpoints do `server/` | Integrar um cliente novo ou depurar uma chamada |
| **`SETUP.md`** (este diretório) | Como rodar o projeto localmente (server/web/mobile) | Onboarding de um novo desenvolvedor |
| **`DEPLOYMENT.md`** (este diretório) | Como publicar cada frente em produção, passo a passo | Fazer um deploy |
| **`PLAY_STORE.md`** (este diretório) | Ficha da loja, declarações, checklist de publicação por responsável e riscos | Publicar/atualizar o app na Google Play |
| **`PLAY_CONSOLE_PASSO_A_PASSO.md`** (este diretório) | Roteiro tela a tela do Play Console (conta pessoal nova): verificação, declarações, teste fechado, produção | Operar o Play Console |
| **`LOGIN_GOOGLE.md`** (este diretório) | Como funciona o login com Google e como configurar o Google Cloud | Mexer no login social ou trocar credenciais |

## Visão geral em uma frase

**ACUMULAAI** é um sistema de fidelização digital B2B2C: a **2RL** vende o produto para **empresas-clientes** (lojas), que por sua vez fidelizam seus **consumidores finais** através de um cartão fidelidade digital (marcações ou pontos).

## As três frentes de código

- **`server/`** — API REST (Node.js + Express + Prisma + MySQL), em produção real.
- **`web/`** — Flutter Web, dois apps: painel da Empresa-cliente (`main.dart`) e painel administrativo interno da 2RL (`main_admin.dart`).
- **`mobile/`** — Flutter Android (app do consumidor final). iOS nunca foi testado (sem máquina Mac disponível).

Comece por [`ARCHITECTURE.md`](ARCHITECTURE.md) se é sua primeira vez no projeto.
