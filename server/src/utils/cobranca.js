const { paraData, somarMeses, DIA_MS } = require('./data');

// Eventos em que o dinheiro entrou (ou está garantido): renovam a licença.
// O Asaas manda CONFIRMED e depois RECEIVED para o mesmo pagamento — a
// renovação é aplicada uma vez só (Cobranca.licenca_estendida_em).
const EVENTOS_PAGAMENTO = ['PAYMENT_CONFIRMED', 'PAYMENT_RECEIVED'];

// Vencimento da licença depois de pagar a cobrança que vence em `vencimentoCobranca`:
// cobre um mês a partir dele (cobrança 11/11 paga -> licença vale até 10/12).
// Nunca encurta uma licença que já vai mais longe (ex: pagamento adiantado).
function novoVencimentoLicenca(vencimentoAtual, vencimentoCobranca) {
  const fimDoPeriodo = new Date(somarMeses(vencimentoCobranca, 1).getTime() - DIA_MS);
  return fimDoPeriodo > vencimentoAtual ? fimDoPeriodo : vencimentoAtual;
}

// Campos da `payment` do Asaas que espelhamos na tabela cobrancas.
function dadosDaCobranca(payment) {
  return {
    asaas_subscription_id: payment.subscription || null,
    valor: payment.value,
    forma_pagamento: payment.billingType || null,
    status: payment.status,
    data_vencimento: paraData(payment.dueDate),
    data_pagamento: paraData(payment.paymentDate || payment.confirmedDate || ''),
    invoice_url: payment.invoiceUrl ? String(payment.invoiceUrl).slice(0, 500) : null,
  };
}

module.exports = { EVENTOS_PAGAMENTO, novoVencimentoLicenca, dadosDaCobranca };
