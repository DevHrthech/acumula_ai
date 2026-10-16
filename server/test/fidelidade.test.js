const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

// Banco falso em memória, injetado no lugar de src/prisma.
const marcacoes = [];
const resgates = [];
let vinculo;
let campanhas;
const chamadas = { forUpdate: 0, transacoes: 0 };

const db = {
  $queryRaw: async () => { chamadas.forUpdate += 1; return []; },
  vinculo: {
    findUnique: async () => ({ ...vinculo }),
    update: async ({ data }) => { Object.assign(vinculo, data); return vinculo; },
  },
  regraPontuacao: { findFirst: async () => null },
  marcacao: {
    create: async ({ data }) => { marcacoes.push(data); return data; },
    aggregate: async ({ where }) => {
      const m = marcacoes.filter((x) => x.vinculo_id === where.vinculo_id && x.campanha_id === where.campanha_id);
      return { _count: { _all: m.length }, _sum: { pontos_gerados: m.reduce((a, x) => a + (x.pontos_gerados || 0), 0) } };
    },
  },
  resgate: {
    create: async ({ data }) => { resgates.push(data); return data; },
    aggregate: async ({ where }) => ({
      _sum: {
        saldo_descontado: resgates
          .filter((x) => x.vinculo_id === where.vinculo_id && x.campanha_id === where.campanha_id)
          .reduce((a, x) => a + x.saldo_descontado, 0),
      },
    }),
  },
  campanha: { findMany: async () => campanhas },
  $transaction: async (fn) => { chamadas.transacoes += 1; return fn(db); },
};

const prismaPath = require.resolve(path.resolve(__dirname, '../src/prisma'));
require.cache[prismaPath] = { id: prismaPath, filename: prismaPath, loaded: true, exports: db };
const { creditarVinculo, saldoCampanha } = require('../src/utils/fidelidade');

function reiniciar(campanhasDaLoja = []) {
  marcacoes.length = 0;
  resgates.length = 0;
  vinculo = { id: 'v1', saldo_atual: 0 };
  campanhas = campanhasDaLoja;
  chamadas.forUpdate = 0;
  chamadas.transacoes = 0;
}

const loja = { id: 'e1', tipo_fidelidade: 'MARCACOES', meta_fidelidade: 3 };

test('credita dentro de uma transação, com o vínculo travado', async () => {
  reiniciar();
  await creditarVinculo({ id: 'v1', saldo_atual: 0 }, loja);
  assert.equal(chamadas.transacoes, 1);
  assert.equal(chamadas.forUpdate, 1);
  assert.equal(vinculo.saldo_atual, 1);
});

test('usa o saldo RELIDO sob a trava, não o objeto antigo recebido', async () => {
  reiniciar();
  vinculo.saldo_atual = 1; // outra aprovação já creditou
  // quem chamou ainda tem a foto antiga (saldo 0)
  await creditarVinculo({ id: 'v1', saldo_atual: 0 }, loja);
  assert.equal(vinculo.saldo_atual, 2);
});

test('ao bater a meta gera resgate e zera (MARCACOES)', async () => {
  reiniciar();
  let r;
  for (let i = 0; i < 3; i++) r = await creditarVinculo({ id: 'v1' }, loja);
  assert.ok(r.resgate);
  assert.equal(vinculo.saldo_atual, 0);
  assert.equal(resgates.length, 1);
});

test('PONTOS: desconta só a meta e mantém o residual', async () => {
  reiniciar();
  db.regraPontuacao.findFirst = async () => ({ id: 'r1', pontos: 5 });
  const pontos = { id: 'e1', tipo_fidelidade: 'PONTOS', meta_fidelidade: 8 };
  await creditarVinculo({ id: 'v1' }, pontos);
  const r = await creditarVinculo({ id: 'v1' }, pontos); // 10 pontos, meta 8
  assert.ok(r.resgate);
  assert.equal(vinculo.saldo_atual, 2);
  db.regraPontuacao.findFirst = async () => null;
});

test('cada campanha vigente é um cartão à parte: credita e fecha na meta dela', async () => {
  reiniciar([{ id: 'c1', nome: 'Verão', meta: 2 }]);
  const lojaGrande = { ...loja, meta_fidelidade: 100 };
  const r1 = await creditarVinculo({ id: 'v1' }, lojaGrande);
  assert.deepEqual(r1.campanhasConcluidas, []);
  assert.equal(await saldoCampanha('v1', 'c1', 'MARCACOES', db), 1);
  const r2 = await creditarVinculo({ id: 'v1' }, lojaGrande);
  assert.deepEqual(r2.campanhasConcluidas, ['Verão']);
  assert.equal(await saldoCampanha('v1', 'c1', 'MARCACOES', db), 0); // recomeça
  assert.equal(marcacoes.filter((m) => !m.campanha_id).length, 2); // cartão da loja
});

test('com db de uma transação existente, não abre outra', async () => {
  reiniciar();
  await creditarVinculo({ id: 'v1' }, loja, db);
  assert.equal(chamadas.transacoes, 0);
});
