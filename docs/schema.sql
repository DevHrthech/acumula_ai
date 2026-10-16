-- ACUMULAAI — Schema (MySQL)
-- Espelha server/prisma/schema.prisma — mesmos nomes de tabela/coluna.
-- Conferido campo a campo contra o banco de produção em 2026-09-19
-- (DESCRIBE + SHOW INDEX + information_schema.KEY_COLUMN_USAGE), sem
-- nenhuma divergência. `empresas.empresa_pai_id` (agrupamento matriz/filiais,
-- gestão comercial 2RL) adicionado em 2026-09-19 — ver SPEC.md seção 16.
--
-- Chaves primárias/estrangeiras em UUID (CHAR(36)), geradas pela aplicação
-- (Prisma `@default(uuid())`) — decisão do usuário, 2026-09-18: evita expor
-- contagem/sequência via ID, e IDs previsíveis em URLs/tokens. MySQL não tem
-- tipo UUID nativo, por isso VARCHAR(36).
--
-- Ver docs/MODELO_DADOS.md (visão conceitual) e docs/MECANICA_FIDELIDADE.md
-- (mecânica configurável por loja: marcações ou pontos).

CREATE TABLE empresas (
  id                    VARCHAR(36) PRIMARY KEY,
  nome                  VARCHAR(150) NOT NULL,
  cnpj                  VARCHAR(18) NOT NULL UNIQUE,
  email                 VARCHAR(150) NOT NULL UNIQUE,
  senha_hash            VARCHAR(255) NOT NULL,
  codigo_loja           VARCHAR(20) NOT NULL UNIQUE,
  categoria             VARCHAR(100) NULL,
  empresa_pai_id        VARCHAR(36) NULL,
  tipo_fidelidade       ENUM('MARCACOES', 'PONTOS') NOT NULL DEFAULT 'MARCACOES',
  meta_fidelidade       INT UNSIGNED NOT NULL DEFAULT 10,
  descricao_recompensa  VARCHAR(255) NOT NULL,
  icone_url             VARCHAR(255) NULL,
  logo_qrcode_url       VARCHAR(255) NULL,
  logo_promocao_url     VARCHAR(255) NULL,
  cor_principal         VARCHAR(7) NOT NULL DEFAULT '#5B0A8F',
  cor_destaque          VARCHAR(7) NOT NULL DEFAULT '#FFC107',
  nome_programa         VARCHAR(100) NOT NULL DEFAULT 'Cartão Fidelidade',
  mensagem_boas_vindas  VARCHAR(255) NULL,
  mensagem_resgate      VARCHAR(255) NULL,
  texto_botao_resgate   VARCHAR(60) NOT NULL DEFAULT 'Resgatar recompensa',
  created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_empresas_empresa_pai FOREIGN KEY (empresa_pai_id) REFERENCES empresas(id),
  INDEX idx_empresas_empresa_pai_id (empresa_pai_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Preferências de notificação/segurança do cliente (2026-09-19) — sem
-- infraestrutura de envio de push/e-mail por trás ainda, mas os campos já
-- persistem de verdade (ver server/src/routes/cliente.js PATCH /me/preferencias).
CREATE TABLE clientes (
  id                  VARCHAR(36) PRIMARY KEY,
  nome                VARCHAR(150) NOT NULL,
  cpf                 VARCHAR(11) NOT NULL UNIQUE,
  senha_hash          VARCHAR(255) NOT NULL,
  telefone            VARCHAR(20) NOT NULL,
  email               VARCHAR(150) NULL,
  notificacoes_push   BOOLEAN NOT NULL DEFAULT TRUE,
  notificacoes_email  BOOLEAN NOT NULL DEFAULT FALSE,
  login_biometrico    BOOLEAN NOT NULL DEFAULT FALSE,
  google_id           VARCHAR(64) NULL UNIQUE,
  reset_codigo_hash   VARCHAR(255) NULL,
  reset_expira_em     TIMESTAMP NULL,
  reset_tentativas    INT NOT NULL DEFAULT 0,
  token_valido_desde  TIMESTAMP NULL, -- tokens emitidos antes disso são recusados (senha redefinida)
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- O "cartão fidelidade" — relação entre um cliente e uma empresa. saldo_atual
-- é interpretado conforme empresas.tipo_fidelidade: contador de marcações
-- (zera ao resgatar) ou saldo de pontos (resgate desconta só a meta).
CREATE TABLE vinculos (
  id                 VARCHAR(36) PRIMARY KEY,
  cliente_id         VARCHAR(36) NOT NULL,
  empresa_id         VARCHAR(36) NOT NULL,
  saldo_atual        INT UNSIGNED NOT NULL DEFAULT 0,
  data_vinculo       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vinculos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  CONSTRAINT fk_vinculos_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id),
  UNIQUE KEY uq_cliente_empresa (cliente_id, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Promoção com validade própria, criada pela empresa. Sempre herda o
-- tipo_fidelidade da empresa (sem coluna de tipo própria). Aprovação é
-- automática — só ATIVA/EXPIRADA, sem estado de moderação. Cada campanha
-- ativa vira um cartão fidelidade próprio no app. "Promoções" é outra
-- entidade (tabela promocoes, abaixo) — ver docs/SPEC.md seção 19.
CREATE TABLE campanhas (
  id             VARCHAR(36) PRIMARY KEY,
  empresa_id     VARCHAR(36) NOT NULL,
  nome           VARCHAR(150) NOT NULL,
  descricao      VARCHAR(255) NULL,
  meta           INT UNSIGNED NOT NULL,
  data_inicio    DATE NULL, -- opcional; nulo/omitido = data do cadastro
  data_validade  DATE NOT NULL,
  status         ENUM('ATIVA', 'EXPIRADA') NOT NULL DEFAULT 'ATIVA',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_campanhas_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Promoção = só um aviso/post da empresa (aba "Promoções" do app). Sem meta,
-- sem cartão fidelidade, sem marcações — quem faz isso é a campanha.
CREATE TABLE promocoes (
  id             VARCHAR(36) PRIMARY KEY,
  empresa_id     VARCHAR(36) NOT NULL,
  titulo         VARCHAR(150) NOT NULL,
  descricao      VARCHAR(500) NULL,
  data_inicio    DATE NULL, -- opcional; nulo/omitido = data do cadastro
  data_validade  DATE NULL,  -- opcional; nulo = sem data limite
  status         ENUM('ATIVA', 'EXPIRADA') NOT NULL DEFAULT 'ATIVA',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_promocoes_empresa (empresa_id),
  CONSTRAINT fk_promocoes_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Só relevante para empresas com tipo_fidelidade = PONTOS: define quantos
-- pontos uma marcação concede. Critério de aplicação ainda em aberto (ver
-- docs/MECANICA_FIDELIDADE.md seção 4) — por ora `criterio` é texto livre,
-- e a aprovação de uma marcação sempre usa a primeira regra ativa cadastrada
-- (ver server/src/utils/fidelidade.js).
CREATE TABLE regras_pontuacao (
  id           VARCHAR(36) PRIMARY KEY,
  empresa_id   VARCHAR(36) NOT NULL,
  descricao    VARCHAR(150) NOT NULL,
  pontos       INT UNSIGNED NOT NULL,
  criterio     VARCHAR(255) NULL,
  ativo        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_regras_pontuacao_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Histórico de cada compra marcada (fonte da verdade da contagem/pontuação).
-- campanha_id/regra_pontuacao_id ficam nulos quando a marcação é do programa
-- contínuo padrão da loja (não de uma campanha específica) ou quando o tipo
-- da loja é MARCACOES.
CREATE TABLE marcacoes (
  id                  VARCHAR(36) PRIMARY KEY,
  vinculo_id          VARCHAR(36) NOT NULL,
  campanha_id         VARCHAR(36) NULL,
  regra_pontuacao_id  VARCHAR(36) NULL,
  pontos_gerados      INT UNSIGNED NULL,
  data_hora           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_marcacoes_vinculo FOREIGN KEY (vinculo_id) REFERENCES vinculos(id),
  CONSTRAINT fk_marcacoes_campanha FOREIGN KEY (campanha_id) REFERENCES campanhas(id),
  CONSTRAINT fk_marcacoes_regra_pontuacao FOREIGN KEY (regra_pontuacao_id) REFERENCES regras_pontuacao(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pedido do cliente pra empresa validar uma compra (com ou sem cupom
-- fiscal) — fila de pendências da tela "Aprovação" (ver
-- docs/MECANICA_FIDELIDADE.md seção 9 e docs/SPEC.md seção 15). Aprovar
-- gera a `marcacao` real e credita o vínculo; rejeitar só muda o status,
-- sem efeito no saldo. A empresa também pode marcar uma compra manualmente
-- por CPF, sem passar por aqui (ver server/src/routes/solicitacoes.js).
CREATE TABLE solicitacoes_marcacao (
  id            VARCHAR(36) PRIMARY KEY,
  vinculo_id    VARCHAR(36) NOT NULL,
  cupom_fiscal  VARCHAR(50) NULL,
  status        ENUM('PENDENTE', 'APROVADA', 'REJEITADA') NOT NULL DEFAULT 'PENDENTE',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at   TIMESTAMP NULL,
  CONSTRAINT fk_solicitacoes_marcacao_vinculo FOREIGN KEY (vinculo_id) REFERENCES vinculos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Histórico de recompensas liberadas. saldo_descontado = saldo_no_momento
-- inteiro no tipo MARCACOES (zera tudo), ou só a meta no tipo PONTOS
-- (saldo_restante fica > 0 se o cliente tinha mais que a meta).
CREATE TABLE resgates (
  id                 VARCHAR(36) PRIMARY KEY,
  vinculo_id         VARCHAR(36) NOT NULL,
  campanha_id        VARCHAR(36) NULL,
  data_hora          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  saldo_no_momento   INT UNSIGNED NOT NULL,
  saldo_descontado   INT UNSIGNED NOT NULL,
  saldo_restante     INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT fk_resgates_vinculo FOREIGN KEY (vinculo_id) REFERENCES vinculos(id),
  CONSTRAINT fk_resgates_campanha FOREIGN KEY (campanha_id) REFERENCES campanhas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_marcacoes_vinculo ON marcacoes(vinculo_id);
CREATE INDEX idx_marcacoes_campanha ON marcacoes(campanha_id);
CREATE INDEX idx_solicitacoes_marcacao_vinculo ON solicitacoes_marcacao(vinculo_id);
CREATE INDEX idx_resgates_vinculo ON resgates(vinculo_id);
CREATE INDEX idx_campanhas_empresa ON campanhas(empresa_id);
CREATE INDEX idx_regras_pontuacao_empresa ON regras_pontuacao(empresa_id);

-- ============================================================
-- Gestão comercial 2RL — licenciamento, contratos e cobrança
-- (decisão do usuário, 2026-09-17; ver docs/SPEC.md seção 11)
-- ============================================================

-- Usuário interno da 2RL (equipe comercial/suporte). Sem autocadastro —
-- criado só via server/scripts/seed-admin.js.
CREATE TABLE admins_2rl (
  id          VARCHAR(36) PRIMARY KEY,
  nome        VARCHAR(150) NOT NULL,
  email       VARCHAR(150) NOT NULL UNIQUE,
  senha_hash  VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE planos (
  id            VARCHAR(36) PRIMARY KEY,
  nome          VARCHAR(100) NOT NULL,
  valor_mensal  DECIMAL(10,2) NOT NULL,
  descricao     VARCHAR(255) NULL,
  ativo         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- status efetivo (usado para liberar/bloquear login da empresa) é
-- calculado por data (data_vencimento + dias_tolerancia), não só pelo
-- campo `status` gravado — ver server/src/utils/licenca.js.
CREATE TABLE licencas (
  id                     VARCHAR(36) PRIMARY KEY,
  empresa_id             VARCHAR(36) NOT NULL,
  plano_id               VARCHAR(36) NOT NULL,
  status                 ENUM('ATIVA','INADIMPLENTE','BLOQUEADA','CANCELADA') NOT NULL DEFAULT 'ATIVA',
  data_inicio            DATE NOT NULL,
  data_vencimento        DATE NOT NULL,
  dias_tolerancia        INT UNSIGNED NOT NULL DEFAULT 5,
  gateway_provedor       VARCHAR(50) NULL,
  gateway_assinatura_id  VARCHAR(150) NULL,
  created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_licencas_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id),
  CONSTRAINT fk_licencas_plano FOREIGN KEY (plano_id) REFERENCES planos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- documento_url/assinatura_* ficam nulos até a 2RL escolher um provedor
-- de assinatura eletrônica (Clicksign/D4Sign) — por ora atualizado manual.
CREATE TABLE contratos (
  id                   VARCHAR(36) PRIMARY KEY,
  empresa_id           VARCHAR(36) NOT NULL,
  licenca_id           VARCHAR(36) NULL,
  status               ENUM('RASCUNHO','AGUARDANDO_ASSINATURA','ASSINADO','CANCELADO') NOT NULL DEFAULT 'RASCUNHO',
  documento_url        VARCHAR(255) NULL,
  assinatura_provedor  VARCHAR(50) NULL,
  assinatura_id        VARCHAR(150) NULL,
  data_criacao         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_assinatura      TIMESTAMP NULL,
  CONSTRAINT fk_contratos_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id),
  CONSTRAINT fk_contratos_licenca FOREIGN KEY (licenca_id) REFERENCES licencas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_licencas_empresa ON licencas(empresa_id);
CREATE INDEX idx_contratos_empresa ON contratos(empresa_id);

-- ============================================================
-- Telemetria/auditoria — monitoramento do admin interno
-- ============================================================

-- Log de cada chamada à API — base da tela de monitoramento do admin
-- interno (uso por empresa + saúde geral). Sem FK de propósito: é um
-- registro de auditoria, não deve travar nem cascatear com a exclusão
-- de uma empresa/admin.
CREATE TABLE requisicoes_api (
  id           VARCHAR(36) PRIMARY KEY,
  metodo       VARCHAR(10) NOT NULL,
  rota         VARCHAR(255) NOT NULL,
  status_code  SMALLINT UNSIGNED NOT NULL,
  duracao_ms   INT UNSIGNED NOT NULL,
  empresa_id   VARCHAR(36) NULL,
  admin_id     VARCHAR(36) NULL,
  ip           VARCHAR(45) NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_requisicoes_api_created_at ON requisicoes_api(created_at);
CREATE INDEX idx_requisicoes_api_empresa ON requisicoes_api(empresa_id);
