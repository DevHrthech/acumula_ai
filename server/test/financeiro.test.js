const test = require('node:test');
const assert = require('node:assert');

const { paraData } = require('../src/utils/data');
const {
  situacaoFinanceira,
  cobrancaAtrasada,
  intervaloPeriodo,
  mesesEntre,
  montarDashboard,
} = require('../src/utils/financeiro');

const d = (texto) => paraData(texto);
const dia = (x) => x.toISOString().slice(0, 10);
const HOJE = d('2026-11-20');
const agora = new Date('2026-11-20T15:00:00Z');

const licenca = (extra) => ({
  status: 'ATIVA',
  data_vencimento: d('2026-12-10'),
  dias_tolerancia: 5,
  em_trial: false,
  gateway_assinatura_id: 'sub_1',
  ...extra,
});

test('situacaoFinanceira cobre todos os casos', () => {
  assert.strictEqual(situacaoFinanceira(null, agora), 'SEM_LICENCA');
  assert.strictEqual(situacaoFinanceira(licenca({ em_trial: true }), agora), 'EM_TESTE');
  assert.strictEqual(situacaoFinanceira(licenca({}), agora), 'PAGA');
  assert.strictEqual(situacaoFinanceira(licenca({ gateway_assinatura_id: null }), agora), 'ATIVA_MANUAL');
  // venceu há 2 dias, tolerância de 5 -> atrasada
  assert.strictEqual(situacaoFinanceira(licenca({ data_vencimento: d('2026-11-18') }), agora), 'ATRASADA');
  // venceu há 10 dias -> bloqueada
  assert.strictEqual(situacaoFinanceira(licenca({ data_vencimento: d('2026-11-10') }), agora), 'BLOQUEADA');
  assert.strictEqual(situacaoFinanceira(licenca({ status: 'CANCELADA' }), agora), 'CANCELADA');
});

test('cobrancaAtrasada: OVERDUE, ou PENDING já vencida', () => {
  assert.strictEqual(cobrancaAtrasada({ status: 'OVERDUE', data_vencimento: d('2026-12-01') }, HOJE), true);
  assert.strictEqual(cobrancaAtrasada({ status: 'PENDING', data_vencimento: d('2026-11-19') }, HOJE), true);
  assert.strictEqual(cobrancaAtrasada({ status: 'PENDING', data_vencimento: d('2026-11-20') }, HOJE), false);
  assert.strictEqual(cobrancaAtrasada({ status: 'RECEIVED', data_vencimento: d('2026-01-01') }, HOJE), false);
});

test('intervaloPeriodo e mesesEntre', () => {
  const mes = intervaloPeriodo('mes', HOJE);
  assert.strictEqual(dia(mes.de), '2026-11-01');
  const tres = intervaloPeriodo('3m', HOJE);
  assert.strictEqual(dia(tres.de), '2026-09-01');
  assert.deepStrictEqual(mesesEntre(tres.de, tres.ate), ['2026-09', '2026-10', '2026-11']);
  const ano = intervaloPeriodo('ano', HOJE);
  assert.strictEqual(dia(ano.de), '2026-01-01');
  assert.strictEqual(mesesEntre(ano.de, ano.ate).length, 11);
  // virada de ano
  const doze = intervaloPeriodo('12m', d('2027-02-10'));
  assert.strictEqual(dia(doze.de), '2026-03-01');
  assert.strictEqual(mesesEntre(doze.de, doze.ate).length, 12);
});

test('montarDashboard consolida faturamento, atraso, MRR e situações', () => {
  const plano = { nome: 'Plano Básico', valor_mensal: '99.9' };
  const empresas = [
    { id: 'e1', nome: 'Paga Ltda', trial_usado_em: d('2026-10-01'), licencas: [{ ...licenca({}), plano }] },
    { id: 'e2', nome: 'Teste Ltda', trial_usado_em: d('2026-11-15'), licencas: [{ ...licenca({ em_trial: true, data_vencimento: d('2026-11-25') }), plano }] },
    { id: 'e3', nome: 'Atrasada Ltda', trial_usado_em: d('2026-09-01'), licencas: [{ ...licenca({ data_vencimento: d('2026-11-18') }), plano }] },
    { id: 'e4', nome: 'Sem Licença', trial_usado_em: null, licencas: [] },
  ];
  const cob = (extra) => ({ forma_pagamento: 'PIX', invoice_url: null, data_pagamento: null, ...extra });
  const cobrancas = [
    cob({ empresa_id: 'e1', valor: '99.9', status: 'RECEIVED', data_vencimento: d('2026-11-11'), data_pagamento: d('2026-11-10') }),
    cob({ empresa_id: 'e1', valor: '99.9', status: 'RECEIVED', data_vencimento: d('2026-10-11'), data_pagamento: d('2026-10-12') }),
    cob({ empresa_id: 'e3', valor: '99.9', status: 'OVERDUE', data_vencimento: d('2026-11-18') }),
    cob({ empresa_id: 'e2', valor: '99.9', status: 'PENDING', data_vencimento: d('2026-11-26') }),
    cob({ empresa_id: 'e1', valor: '99.9', status: 'DELETED', data_vencimento: d('2026-09-11') }),
  ];

  const r = montarDashboard({ empresas, cobrancas, hoje: HOJE, periodo: '3m' });

  assert.strictEqual(r.kpis.faturamento_periodo, 199.8);
  assert.strictEqual(r.kpis.pagamentos_periodo, 2);
  assert.strictEqual(r.kpis.faturamento_mes_atual, 99.9);
  assert.strictEqual(r.kpis.faturamento_mes_anterior, 99.9);
  assert.strictEqual(r.kpis.variacao_mes_pct, 0);
  assert.strictEqual(r.kpis.mrr, 99.9);
  assert.strictEqual(r.kpis.assinantes_pagantes, 1);
  assert.strictEqual(r.kpis.previsao_trials, 99.9);
  assert.strictEqual(r.kpis.a_receber, 99.9);
  assert.strictEqual(r.kpis.em_atraso, 99.9);
  assert.strictEqual(r.kpis.faturas_em_atraso, 1);

  assert.deepStrictEqual(
    { paga: r.empresas.PAGA, teste: r.empresas.EM_TESTE, atrasada: r.empresas.ATRASADA, sem: r.empresas.SEM_LICENCA, total: r.empresas.total },
    { paga: 1, teste: 1, atrasada: 1, sem: 1, total: 4 },
  );
  assert.deepStrictEqual(r.serie_mensal.map((m) => m.mes), ['2026-09', '2026-10', '2026-11']);
  assert.strictEqual(r.serie_mensal[1].recebido, 99.9);
  assert.strictEqual(r.faturas_em_atraso[0].empresa, 'Atrasada Ltda');
  assert.strictEqual(r.faturas_em_atraso[0].dias_atraso, 2);
  assert.strictEqual(r.proximos_vencimentos[0].empresa, 'Teste Ltda');
  assert.strictEqual(r.trials_terminando[0].dias_restantes, 5);
  assert.strictEqual(r.por_plano[0].assinantes, 1);
  assert.strictEqual(r.por_forma[0].forma, 'PIX');
  // e1 e e3 já passaram pelo trial (1 convertido; e3 tem assinatura e !trial também)
  assert.strictEqual(r.conversao_trial.trials_total, 3);
});
