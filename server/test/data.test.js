const test = require('node:test');
const assert = require('node:assert/strict');
const { hojeBrasilia, paraData, fimDoDiaBrasilia } = require('../src/utils/data');
const { statusEfetivo } = require('../src/utils/licenca');
const { textoValido, primeiroErroTexto } = require('../src/utils/validar');

test('hojeBrasilia: às 22h de Brasília ainda é o mesmo dia (UTC já virou)', () => {
  // 15/10 22:07 BRT = 16/10 01:07 UTC
  const agora = new Date('2026-10-16T01:07:00Z');
  assert.equal(hojeBrasilia(agora).toISOString(), '2026-10-15T00:00:00.000Z');
});

test('hojeBrasilia: depois da meia-noite de Brasília vira o dia seguinte', () => {
  const agora = new Date('2026-10-16T03:00:01Z'); // 00:00:01 BRT de 16/10
  assert.equal(hojeBrasilia(agora).toISOString(), '2026-10-16T00:00:00.000Z');
});

test('paraData: aceita data simples e ISO do painel (sem fuso), ignora hora', () => {
  assert.equal(paraData('2026-10-20').toISOString(), '2026-10-20T00:00:00.000Z');
  assert.equal(paraData('2026-10-20T00:00:00.000').toISOString(), '2026-10-20T00:00:00.000Z');
  assert.equal(paraData('2026-10-20T23:59:59.999Z').toISOString(), '2026-10-20T00:00:00.000Z');
});

test('paraData: rejeita lixo e datas impossíveis', () => {
  for (const ruim of [undefined, null, 123, '', 'amanhã', '2026-13-01', '2026-02-30', {}]) {
    assert.equal(paraData(ruim), null, String(ruim));
  }
});

test('licença vale até o FIM do dia de vencimento em Brasília', () => {
  const licenca = { status: 'ATIVA', data_vencimento: new Date('2026-10-15T00:00:00Z'), dias_tolerancia: 5 };
  // 15/10 22:00 BRT: ainda no dia do vencimento -> ATIVA (antes dava INADIMPLENTE às 21h)
  assert.equal(statusEfetivo(licenca, new Date('2026-10-16T01:00:00Z')), 'ATIVA');
  // 16/10 00:00:01 BRT -> começa a tolerância
  assert.equal(statusEfetivo(licenca, new Date('2026-10-16T03:00:01Z')), 'INADIMPLENTE');
  // 5 dias depois do fim do vencimento acaba a tolerância
  assert.equal(statusEfetivo(licenca, fimDoDiaBrasilia(new Date('2026-10-20T00:00:00Z'))), 'INADIMPLENTE');
  assert.equal(statusEfetivo(licenca, new Date('2026-10-21T03:00:01Z')), 'BLOQUEADA');
});

test('licença BLOQUEADA/CANCELADA manual prevalece', () => {
  const l = { status: 'BLOQUEADA', data_vencimento: new Date('2099-01-01T00:00:00Z'), dias_tolerancia: 5 };
  assert.equal(statusEfetivo(l), 'BLOQUEADA');
});

test('textoValido / primeiroErroTexto', () => {
  assert.equal(textoValido('abc', { max: 5 }), true);
  assert.equal(textoValido('abcdef', { max: 5 }), false);
  assert.equal(textoValido(123, { max: 5 }), false);
  assert.equal(textoValido({}, {}), false);
  assert.equal(textoValido(undefined, {}), true);
  assert.equal(textoValido('  ', { obrigatorio: true }), false);
  assert.equal(textoValido(undefined, { obrigatorio: true }), false);
  assert.match(primeiroErroTexto({ nome: [42, { max: 10 }] }), /nome inválido/);
  assert.equal(primeiroErroTexto({ nome: ['ok', { max: 10 }] }), null);
});
