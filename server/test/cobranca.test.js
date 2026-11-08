const test = require('node:test');
const assert = require('node:assert');

const { somarMeses, paraData } = require('../src/utils/data');
const { novoVencimentoLicenca, dadosDaCobranca } = require('../src/utils/cobranca');

const dia = (d) => d.toISOString().slice(0, 10);

test('somarMeses limita ao último dia do mês de destino', () => {
  assert.strictEqual(dia(somarMeses(paraData('2026-01-31'), 1)), '2026-02-28');
  assert.strictEqual(dia(somarMeses(paraData('2026-11-11'), 1)), '2026-12-11');
  assert.strictEqual(dia(somarMeses(paraData('2026-12-15'), 1)), '2027-01-15');
});

test('pagar a 1ª cobrança (vence no dia seguinte ao trial) cobre um mês', () => {
  // trial vence 10/11, cobrança vence 11/11 -> licença vale até 10/12
  const novo = novoVencimentoLicenca(paraData('2026-11-10'), paraData('2026-11-11'));
  assert.strictEqual(dia(novo), '2026-12-10');
});

test('pagamento adiantado nunca encurta a licença', () => {
  const novo = novoVencimentoLicenca(paraData('2027-03-01'), paraData('2026-11-11'));
  assert.strictEqual(dia(novo), '2027-03-01');
});

test('dadosDaCobranca espelha os campos da payment do Asaas', () => {
  const d = dadosDaCobranca({
    id: 'pay_1',
    subscription: 'sub_1',
    value: 99.9,
    billingType: 'BOLETO',
    status: 'RECEIVED',
    dueDate: '2026-11-11',
    paymentDate: '2026-11-09',
    invoiceUrl: 'https://sandbox.asaas.com/i/abc',
  });
  assert.strictEqual(d.asaas_subscription_id, 'sub_1');
  assert.strictEqual(d.status, 'RECEIVED');
  assert.strictEqual(dia(d.data_vencimento), '2026-11-11');
  assert.strictEqual(dia(d.data_pagamento), '2026-11-09');
  assert.strictEqual(d.invoice_url, 'https://sandbox.asaas.com/i/abc');
});
