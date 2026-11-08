const test = require('node:test');
const assert = require('node:assert');

const { periodoTrial, DIAS_TRIAL } = require('../src/utils/trial');

test('trial começa no dia de Brasília e vence 15 dias depois', () => {
  // 02:00 UTC de 16/10 ainda é 15/10 (23h) em Brasília.
  const { inicio, vencimento } = periodoTrial(new Date('2026-10-16T02:00:00Z'));
  assert.strictEqual(DIAS_TRIAL, 15);
  assert.strictEqual(inicio.toISOString().slice(0, 10), '2026-10-15');
  assert.strictEqual(vencimento.toISOString().slice(0, 10), '2026-10-30');
});
