const prisma = require('../prisma');
const { hojeBrasilia } = require('./data');

// Credita uma marcação/pontuação no vínculo e libera resgate automático ao
// atingir a meta — mesma lógica usada tanto pra aprovar uma solicitação do
// cliente quanto pra marcação manual da empresa (ver
// docs/MECANICA_FIDELIDADE.md seções 3 e 9). Critério de qual regra de
// pontuação aplicar ainda é um detalhe em aberto (seção 4) — por ora usa
// sempre a primeira regra ativa cadastrada pela loja.
//
// Tudo roda numa transação, com o vínculo travado (SELECT ... FOR UPDATE) e o
// saldo relido já com a trava: duas aprovações simultâneas do mesmo cliente
// não creditam em duplicidade nem perdem um crédito. Quem já está numa
// transação (ex.: aprovar solicitação) passa o `db` dela.
async function creditarVinculo(vinculo, empresa, db) {
  if (db) return executarCredito(db, vinculo, empresa);
  return prisma.$transaction((tx) => executarCredito(tx, vinculo, empresa), { timeout: 15000 });
}

async function executarCredito(db, vinculoRef, empresa) {
  await db.$queryRaw`SELECT id FROM vinculos WHERE id = ${vinculoRef.id} FOR UPDATE`;
  const vinculo = await db.vinculo.findUnique({ where: { id: vinculoRef.id } });

  let pontosGerados = null;
  let regraPontuacaoId = null;

  if (empresa.tipo_fidelidade === 'PONTOS') {
    const regra = await db.regraPontuacao.findFirst({
      where: { empresa_id: empresa.id, ativo: true },
      orderBy: { created_at: 'asc' },
    });
    pontosGerados = regra ? regra.pontos : 1;
    regraPontuacaoId = regra ? regra.id : null;
  }

  const marcacao = await db.marcacao.create({
    data: {
      vinculo_id: vinculo.id,
      regra_pontuacao_id: regraPontuacaoId,
      pontos_gerados: pontosGerados,
    },
  });

  const incremento = empresa.tipo_fidelidade === 'PONTOS' ? pontosGerados : 1;
  let novoSaldo = vinculo.saldo_atual + incremento;
  let resgate = null;

  if (novoSaldo >= empresa.meta_fidelidade) {
    // MARCACOES zera tudo; PONTOS desconta só a meta e mantém o residual
    // (ver docs/MECANICA_FIDELIDADE.md seção 3).
    const saldoDescontado = empresa.tipo_fidelidade === 'MARCACOES' ? novoSaldo : empresa.meta_fidelidade;
    const saldoRestante = novoSaldo - saldoDescontado;
    resgate = await db.resgate.create({
      data: {
        vinculo_id: vinculo.id,
        saldo_no_momento: novoSaldo,
        saldo_descontado: saldoDescontado,
        saldo_restante: saldoRestante,
      },
    });
    novoSaldo = saldoRestante;
  }

  await db.vinculo.update({ where: { id: vinculo.id }, data: { saldo_atual: novoSaldo } });

  // Cada campanha ativa da loja é um cartão à parte: a mesma compra credita
  // também o cartão de cada uma delas.
  const campanhasConcluidas = await creditarCampanhas(db, vinculo, empresa, pontosGerados, regraPontuacaoId);

  return { marcacao, resgate, saldoAtual: novoSaldo, campanhasConcluidas };
}

// Campanhas que ainda aceitam marcação: ATIVA, já iniciadas (sem data de
// início = desde o cadastro) e dentro da validade (vale até o fim do dia, no
// calendário de Brasília).
async function campanhasVigentes(empresaId, db = prisma) {
  const hoje = hojeBrasilia();
  return db.campanha.findMany({
    where: {
      empresa_id: empresaId,
      status: 'ATIVA',
      data_validade: { gte: hoje },
      OR: [{ data_inicio: null }, { data_inicio: { lte: hoje } }],
    },
    orderBy: { created_at: 'asc' },
  });
}

// Saldo do cliente em UMA campanha: marcações/pontos recebidos nela menos o
// que já foi descontado em resgates dela.
async function saldoCampanha(vinculoId, campanhaId, tipo, db = prisma) {
  const [marcacoes, resgates] = await Promise.all([
    db.marcacao.aggregate({
      where: { vinculo_id: vinculoId, campanha_id: campanhaId },
      _count: { _all: true },
      _sum: { pontos_gerados: true },
    }),
    db.resgate.aggregate({
      where: { vinculo_id: vinculoId, campanha_id: campanhaId },
      _sum: { saldo_descontado: true },
    }),
  ]);
  const recebido = tipo === 'PONTOS' ? (marcacoes._sum.pontos_gerados || 0) : marcacoes._count._all;
  return Math.max(0, recebido - (resgates._sum.saldo_descontado || 0));
}

async function creditarCampanhas(db, vinculo, empresa, pontosGerados, regraPontuacaoId) {
  const concluidas = [];
  const campanhas = await campanhasVigentes(empresa.id, db);

  for (const campanha of campanhas) {
    await db.marcacao.create({
      data: {
        vinculo_id: vinculo.id,
        campanha_id: campanha.id,
        regra_pontuacao_id: regraPontuacaoId,
        pontos_gerados: pontosGerados,
      },
    });

    const saldo = await saldoCampanha(vinculo.id, campanha.id, empresa.tipo_fidelidade, db);
    if (saldo >= campanha.meta) {
      const descontado = empresa.tipo_fidelidade === 'MARCACOES' ? saldo : campanha.meta;
      await db.resgate.create({
        data: {
          vinculo_id: vinculo.id,
          campanha_id: campanha.id,
          saldo_no_momento: saldo,
          saldo_descontado: descontado,
          saldo_restante: saldo - descontado,
        },
      });
      concluidas.push(campanha.nome);
    }
  }

  return concluidas;
}

module.exports = { creditarVinculo, campanhasVigentes, saldoCampanha };
