const { statusEfetivo } = require('./licenca');
const { DIA_MS } = require('./data');

// Status de cobrança do Asaas em que o dinheiro entrou.
const STATUS_PAGOS = ['RECEIVED', 'CONFIRMED', 'RECEIVED_IN_CASH'];
// Em aberto: ainda pode ser paga. (DELETED/REFUNDED etc. ficam de fora.)
const STATUS_ABERTOS = ['PENDING', 'OVERDUE'];

const PERIODOS = { mes: 0, '3m': 2, '6m': 5, '12m': 11, ano: null };

const dia = (d) => d.toISOString().slice(0, 10);
const mesDe = (d) => d.toISOString().slice(0, 7);
const arredondar = (n) => Math.round(n * 100) / 100;

// Situação financeira da empresa, a partir da licença mais recente:
// SEM_LICENCA, EM_TESTE (trial de 15 dias), PAGA (assinatura Asaas com 1º
// pagamento feito), ATIVA_MANUAL (licença lançada à mão, sem cobrança no
// Asaas), ATRASADA (vencida, dentro da tolerância), BLOQUEADA, CANCELADA.
function situacaoFinanceira(licenca, agora = new Date()) {
  if (!licenca) return 'SEM_LICENCA';
  const status = statusEfetivo(licenca, agora);
  if (status === 'CANCELADA') return 'CANCELADA';
  if (status === 'BLOQUEADA') return 'BLOQUEADA';
  if (status === 'INADIMPLENTE') return 'ATRASADA';
  if (licenca.em_trial) return 'EM_TESTE';
  return licenca.gateway_assinatura_id ? 'PAGA' : 'ATIVA_MANUAL';
}

// Cobrança em atraso: marcada OVERDUE pelo Asaas, ou ainda PENDING mas já
// vencida (caso o webhook de atraso não tenha chegado).
function cobrancaAtrasada(cobranca, hoje) {
  if (cobranca.status === 'OVERDUE') return true;
  return cobranca.status === 'PENDING' && cobranca.data_vencimento < hoje;
}

// Intervalo [de, ate] do período pedido (dias de calendário em Brasília).
// 'mes' = mês atual; '3m'/'6m'/'12m' = esse nº de meses terminando no atual;
// 'ano' = desde 1º de janeiro.
function intervaloPeriodo(periodo, hoje) {
  const ano = hoje.getUTCFullYear();
  const mes = hoje.getUTCMonth();
  const voltar = PERIODOS[periodo];
  const de = periodo === 'ano'
    ? new Date(Date.UTC(ano, 0, 1))
    : new Date(Date.UTC(ano, mes - voltar, 1));
  return { de, ate: hoje };
}

// ['2026-08', '2026-09', ...] do mês de `de` ao mês de `ate`.
function mesesEntre(de, ate) {
  const meses = [];
  let a = de.getUTCFullYear();
  let m = de.getUTCMonth();
  while (a < ate.getUTCFullYear() || (a === ate.getUTCFullYear() && m <= ate.getUTCMonth())) {
    meses.push(`${a}-${String(m + 1).padStart(2, '0')}`);
    m += 1;
    if (m > 11) { m = 0; a += 1; }
  }
  return meses;
}

// Consolida o dashboard financeiro. Funções puras sobre dados já lidos do
// banco: `empresas` (com `licencas` ordenadas, a mais recente primeiro, e
// `plano`), `cobrancas` e o `hoje` (meia-noite UTC do dia em Brasília).
function montarDashboard({ empresas, cobrancas, hoje, periodo }) {
  const { de, ate } = intervaloPeriodo(periodo, hoje);
  const meses = mesesEntre(de, ate);
  const nomePorEmpresa = new Map(empresas.map((e) => [e.id, e.nome]));
  // Meio-dia de Brasília do dia `hoje`: o status das licenças é calculado
  // para esse dia (e não pelo relógio), então o resultado é reproduzível.
  const agora = new Date(hoje.getTime() + 15 * 60 * 60 * 1000);

  const pago = (c) => STATUS_PAGOS.includes(c.status);
  const dataRecebimento = (c) => c.data_pagamento || c.data_vencimento;
  const noPeriodo = (d) => d >= de && d <= ate;

  // ---- faturamento -------------------------------------------------------
  const recebidas = cobrancas.filter(pago);
  const recebidasNoPeriodo = recebidas.filter((c) => noPeriodo(dataRecebimento(c)));
  const somar = (lista) => arredondar(lista.reduce((s, c) => s + Number(c.valor), 0));

  const mesAtual = mesDe(hoje);
  const mesAnterior = mesDe(new Date(Date.UTC(hoje.getUTCFullYear(), hoje.getUTCMonth() - 1, 1)));
  const recebidoNoMes = (chave) => somar(recebidas.filter((c) => mesDe(dataRecebimento(c)) === chave));
  const faturamentoMesAtual = recebidoNoMes(mesAtual);
  const faturamentoMesAnterior = recebidoNoMes(mesAnterior);

  // ---- em aberto / atraso ------------------------------------------------
  const abertas = cobrancas.filter((c) => STATUS_ABERTOS.includes(c.status));
  const atrasadas = abertas.filter((c) => cobrancaAtrasada(c, hoje));
  const aVencer = abertas.filter((c) => !cobrancaAtrasada(c, hoje));

  // ---- empresas / licenças ----------------------------------------------
  const situacoes = { PAGA: 0, ATIVA_MANUAL: 0, EM_TESTE: 0, ATRASADA: 0, BLOQUEADA: 0, CANCELADA: 0, SEM_LICENCA: 0 };
  const porPlano = new Map();
  const trialsTerminando = [];
  let mrr = 0;
  let assinantesPagantes = 0;
  let previsaoTrials = 0;
  let trialsTotal = 0;
  let convertidos = 0;
  let trialsIniciadosNoPeriodo = 0;

  for (const empresa of empresas) {
    const licenca = empresa.licencas[0] || null;
    const situacao = situacaoFinanceira(licenca, agora);
    situacoes[situacao] += 1;
    const valorPlano = licenca ? Number(licenca.plano.valor_mensal) : 0;

    if (situacao === 'PAGA') {
      mrr += valorPlano;
      assinantesPagantes += 1;
      const item = porPlano.get(licenca.plano.nome) || { plano: licenca.plano.nome, assinantes: 0, receita_mensal: 0 };
      item.assinantes += 1;
      item.receita_mensal = arredondar(item.receita_mensal + valorPlano);
      porPlano.set(licenca.plano.nome, item);
    }
    if (situacao === 'EM_TESTE') {
      previsaoTrials += valorPlano;
      const restam = Math.round((licenca.data_vencimento.getTime() - hoje.getTime()) / DIA_MS);
      if (restam <= 7) {
        trialsTerminando.push({
          empresa_id: empresa.id,
          empresa: empresa.nome,
          plano: licenca.plano.nome,
          data_vencimento: dia(licenca.data_vencimento),
          dias_restantes: Math.max(restam, 0),
        });
      }
    }
    if (empresa.trial_usado_em) {
      trialsTotal += 1;
      if (licenca && !licenca.em_trial && licenca.gateway_assinatura_id) convertidos += 1;
      if (noPeriodo(new Date(`${dia(empresa.trial_usado_em)}T00:00:00Z`))) trialsIniciadosNoPeriodo += 1;
    }
  }
  trialsTerminando.sort((a, b) => a.dias_restantes - b.dias_restantes);
  const trialsEncerrados = trialsTotal - situacoes.EM_TESTE;

  // ---- séries ------------------------------------------------------------
  const serieMensal = meses.map((mes) => ({
    mes,
    recebido: somar(recebidas.filter((c) => mesDe(dataRecebimento(c)) === mes)),
    em_aberto: somar(abertas.filter((c) => mesDe(c.data_vencimento) === mes)),
  }));

  const porForma = new Map();
  for (const c of recebidasNoPeriodo) {
    const chave = c.forma_pagamento || 'OUTRA';
    const item = porForma.get(chave) || { forma: chave, total: 0, quantidade: 0 };
    item.total = arredondar(item.total + Number(c.valor));
    item.quantidade += 1;
    porForma.set(chave, item);
  }

  // ---- listas ------------------------------------------------------------
  const linhaCobranca = (c) => ({
    empresa_id: c.empresa_id,
    empresa: nomePorEmpresa.get(c.empresa_id) || '—',
    valor: Number(c.valor),
    forma_pagamento: c.forma_pagamento,
    data_vencimento: dia(c.data_vencimento),
    dias_atraso: Math.max(Math.round((hoje.getTime() - c.data_vencimento.getTime()) / DIA_MS), 0),
    invoice_url: c.invoice_url,
  });
  const em30dias = new Date(hoje.getTime() + 30 * DIA_MS);

  return {
    periodo: { chave: periodo, de: dia(de), ate: dia(ate) },
    kpis: {
      faturamento_periodo: somar(recebidasNoPeriodo),
      pagamentos_periodo: recebidasNoPeriodo.length,
      ticket_medio: recebidasNoPeriodo.length ? arredondar(somar(recebidasNoPeriodo) / recebidasNoPeriodo.length) : 0,
      faturamento_mes_atual: faturamentoMesAtual,
      faturamento_mes_anterior: faturamentoMesAnterior,
      variacao_mes_pct: faturamentoMesAnterior > 0
        ? arredondar(((faturamentoMesAtual - faturamentoMesAnterior) / faturamentoMesAnterior) * 100)
        : null,
      mrr: arredondar(mrr),
      assinantes_pagantes: assinantesPagantes,
      previsao_trials: arredondar(previsaoTrials),
      a_receber: somar(aVencer),
      faturas_a_receber: aVencer.length,
      em_atraso: somar(atrasadas),
      faturas_em_atraso: atrasadas.length,
    },
    empresas: { total: empresas.length, ...situacoes },
    conversao_trial: {
      trials_total: trialsTotal,
      em_andamento: situacoes.EM_TESTE,
      iniciados_no_periodo: trialsIniciadosNoPeriodo,
      convertidos,
      taxa_pct: trialsEncerrados > 0 ? arredondar((convertidos / trialsEncerrados) * 100) : null,
    },
    serie_mensal: serieMensal,
    por_plano: [...porPlano.values()].sort((a, b) => b.receita_mensal - a.receita_mensal),
    por_forma: [...porForma.values()].sort((a, b) => b.total - a.total),
    faturas_em_atraso: atrasadas
      .sort((a, b) => a.data_vencimento - b.data_vencimento)
      .slice(0, 10)
      .map(linhaCobranca),
    proximos_vencimentos: aVencer
      .filter((c) => c.data_vencimento <= em30dias)
      .sort((a, b) => a.data_vencimento - b.data_vencimento)
      .slice(0, 10)
      .map(linhaCobranca),
    trials_terminando: trialsTerminando.slice(0, 10),
  };
}

module.exports = {
  STATUS_PAGOS,
  STATUS_ABERTOS,
  PERIODOS,
  situacaoFinanceira,
  cobrancaAtrasada,
  intervaloPeriodo,
  mesesEntre,
  montarDashboard,
};
