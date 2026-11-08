const test = require('node:test');
const assert = require('node:assert');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Prisma falso (nada de banco) e segredo de teste: o que se testa é a regra do
// token ("Lembrar acesso" dura mais; "Sair" derruba o token guardado).
process.env.JWT_SECRET = 'segredo-so-de-teste-0123456789abcdef0123456789';
const prismaPath = require.resolve('../src/prisma');
const admins = new Map();
require.cache[prismaPath] = {
  id: prismaPath,
  filename: prismaPath,
  loaded: true,
  exports: {
    adminInterno: {
      findUnique: async ({ where }) => [...admins.values()].find((a) => a.id === where.id || a.email === where.email) || null,
      update: async ({ where, data }) => Object.assign(admins.get(where.id), data),
    },
  },
};

const authAdmin = require('../src/middleware/authAdmin');
const router = require('../src/routes/authAdmin');

function rodarMiddleware(token) {
  return new Promise((resolve) => {
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = { status: (s) => ({ json: (j) => resolve({ status: s, corpo: j }) }) };
    authAdmin(req, res, () => resolve({ status: 200, adminId: req.adminId }));
  });
}

function chamarRota(caminho, req) {
  const camada = router.stack.find((l) => l.route && l.route.path === caminho);
  const handlers = camada.route.stack.map((s) => s.handle);
  return new Promise((resolve) => {
    const res = {
      status(s) { this.codigo = s; return this; },
      json(j) { resolve({ status: this.codigo || 200, corpo: j }); },
    };
    let i = 0;
    const next = () => { handlers[++i](req, res, next); };
    handlers[0](req, res, next);
  });
}

test('login com lembrar emite token de 14 dias; sem lembrar, de 8 horas; sem e-mail/senha no token', async () => {
  admins.set('a1', { id: 'a1', nome: 'Admin', email: 'a@x.com', senha_hash: await bcrypt.hash('senha-teste-1', 4), token_valido_desde: null });
  const emitir = async (extra) => {
    const r = await chamarRota('/login', { body: { email: 'a@x.com', senha: 'senha-teste-1', ...extra }, headers: {}, ip: '1.1.1.1' });
    assert.strictEqual(r.status, 200);
    return jwt.decode(r.corpo.token);
  };

  const curto = await emitir({});
  assert.strictEqual(curto.exp - curto.iat, 8 * 3600);
  const longo = await emitir({ lembrar: true });
  assert.strictEqual(longo.exp - longo.iat, 14 * 24 * 3600);
  // "lembrar" só vale como booleano verdadeiro.
  const texto = await emitir({ lembrar: 'true' });
  assert.strictEqual(texto.exp - texto.iat, 8 * 3600);

  for (const payload of [curto, longo]) {
    assert.deepStrictEqual(Object.keys(payload).sort(), ['exp', 'iat', 'sub', 'tipo']);
    assert.ok(!JSON.stringify(payload).includes('a@x.com'));
  }
});

test('middleware aceita token válido e recusa depois do Sair (token_valido_desde)', async () => {
  const agora = Math.floor(Date.now() / 1000);
  const token = jwt.sign({ sub: 'a1', tipo: 'admin', iat: agora - 60 }, process.env.JWT_SECRET, { expiresIn: '14d', algorithm: 'HS256' });
  assert.strictEqual((await rodarMiddleware(token)).status, 200);

  const r = await chamarRota('/logout', { adminId: 'a1', headers: { authorization: `Bearer ${token}` } });
  assert.deepStrictEqual(r.corpo, { ok: true });

  const recusado = await rodarMiddleware(token);
  assert.strictEqual(recusado.status, 401);

  // Login feito depois do Sair volta a funcionar.
  const novo = jwt.sign({ sub: 'a1', tipo: 'admin', iat: agora + 5 }, process.env.JWT_SECRET, { expiresIn: '8h', algorithm: 'HS256' });
  assert.strictEqual((await rodarMiddleware(novo)).status, 200);
});

test('middleware recusa admin inexistente, tipo errado e token adulterado', async () => {
  const sub = (p, segredo = process.env.JWT_SECRET) => jwt.sign(p, segredo, { expiresIn: '1h', algorithm: 'HS256' });
  assert.strictEqual((await rodarMiddleware(sub({ sub: 'sumiu', tipo: 'admin' }))).status, 401);
  assert.strictEqual((await rodarMiddleware(sub({ sub: 'a1', tipo: 'empresa' }))).status, 401);
  assert.strictEqual((await rodarMiddleware(sub({ sub: 'a1', tipo: 'admin' }, 'outro-segredo'))).status, 401);
});
