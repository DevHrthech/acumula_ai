const prisma = require('../prisma');

// Credita uma marcação/pontuação no vínculo e libera resgate automático ao
// atingir a meta — mesma lógica usada tanto pra aprovar uma solicitação do
// cliente quanto pra marcação manual da empresa (ver
// docs/MECANICA_FIDELIDADE.md seções 3 e 9). Critério de qual regra de
// pontuação aplicar ainda é um detalhe em aberto (seção 4) — por ora usa
// sempre a primeira regra ativa cadastrada pela loja.
async function creditarVinculo(vinculo, empresa) {
  let pontosGerados = null;
  let regraPontuacaoId = null;

  if (empresa.tipo_fidelidade === 'PONTOS') {
    const regra = await prisma.regraPontuacao.findFirst({
      where: { empresa_id: empresa.id, ativo: true },
      orderBy: { created_at: 'asc' },
    });
    pontosGerados = regra ? regra.pontos : 1;
    regraPontuacaoId = regra ? regra.id : null;
  }

  const marcacao = await prisma.marcacao.create({
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
    resgate = await prisma.resgate.create({
      data: {
        vinculo_id: vinculo.id,
        saldo_no_momento: novoSaldo,
        saldo_descontado: saldoDescontado,
        saldo_restante: saldoRestante,
      },
    });
    novoSaldo = saldoRestante;
  }

  await prisma.vinculo.update({ where: { id: vinculo.id }, data: { saldo_atual: novoSaldo } });

  return { marcacao, resgate, saldoAtual: novoSaldo };
}

module.exports = { creditarVinculo };
