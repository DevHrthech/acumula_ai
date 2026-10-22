const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');

process.env.JWT_SECRET = 'segredo-de-teste';

// Banco falso: um cliente só, com foto_url mutável.
const cliente = { id: 'cliente-foto-teste', nome: 'Teste', cpf: '00000000000', senha_hash: 'x', foto_url: null, token_valido_desde: null };
const db = {
  cliente: {
    findUnique: async () => ({ ...cliente }),
    update: async ({ data }) => Object.assign(cliente, data),
  },
};
const prismaPath = require.resolve(path.resolve(__dirname, '../src/prisma'));
require.cache[prismaPath] = { id: prismaPath, filename: prismaPath, loaded: true, exports: db };

const express = require('express');
const jwt = require('jsonwebtoken');
const clienteRoutes = require('../src/routes/cliente');
const { UPLOADS_DIR } = require('../src/utils/imagem');

const app = express();
app.use(express.json());
app.use('/clientes', clienteRoutes);
app.use((err, req, res, next) => res.status(err.status || 500).json({ erro: err.message })); // eslint-disable-line no-unused-vars

const pastaCliente = path.join(UPLOADS_DIR, 'clientes', cliente.id);
let servidor;
let base;
const token = jwt.sign({ sub: cliente.id, tipo: 'cliente' }, process.env.JWT_SECRET, { algorithm: 'HS256', expiresIn: '5m' });
const auth = { Authorization: `Bearer ${token}` };

// JPEG mínimo válido só no cabeçalho (o servidor confere os bytes iniciais).
const jpeg = (extra = 0) => Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32 + extra, 1)]);
const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(32, 2)]);

test.before(async () => {
  await new Promise((resolve) => { servidor = app.listen(0, resolve); });
  base = `http://localhost:${servidor.address().port}`;
});

test.after(async () => {
  await new Promise((resolve) => servidor.close(resolve));
  await fs.rm(pastaCliente, { recursive: true, force: true });
});

const enviar = (corpo, tipo = 'image/jpeg') =>
  fetch(`${base}/clientes/me/foto`, { method: 'PUT', headers: { ...auth, 'Content-Type': tipo }, body: corpo });

test('sem token não envia foto', async () => {
  const r = await fetch(`${base}/clientes/me/foto`, { method: 'PUT', headers: { 'Content-Type': 'image/jpeg' }, body: jpeg() });
  assert.equal(r.status, 401);
});

test('envia JPEG: grava arquivo e devolve foto_url sem dados secretos', async () => {
  const r = await enviar(jpeg());
  assert.equal(r.status, 200);
  const corpo = await r.json();
  assert.match(corpo.foto_url, /\/uploads\/clientes\/cliente-foto-teste\/foto-\d+\.jpg$/);
  assert.equal(corpo.senha_hash, undefined);
  assert.equal(corpo.token_valido_desde, undefined);
  const arquivos = await fs.readdir(pastaCliente);
  assert.equal(arquivos.length, 1);
});

test('nova foto (PNG) substitui e apaga o arquivo anterior', async () => {
  await new Promise((r) => setTimeout(r, 5)); // nome novo (timestamp)
  const r = await enviar(png, 'image/png');
  assert.equal(r.status, 200);
  assert.match((await r.json()).foto_url, /\.png$/);
  const arquivos = await fs.readdir(pastaCliente);
  assert.equal(arquivos.length, 1);
  assert.match(arquivos[0], /\.png$/);
});

test('recusa arquivo que não é imagem mesmo com Content-Type de imagem', async () => {
  const r = await enviar(Buffer.from('<svg onload=alert(1)></svg>'));
  assert.equal(r.status, 400);
});

test('recusa corpo vazio e tipo não aceito', async () => {
  assert.equal((await enviar(Buffer.alloc(0))).status, 400);
  assert.equal((await enviar(jpeg(), 'text/plain')).status, 400);
});

test('recusa foto acima de 1 MB', async () => {
  const r = await enviar(jpeg(1024 * 1024 + 10));
  assert.ok(r.status === 413 || r.status === 400, `status ${r.status}`);
});

test('remover a foto zera foto_url e apaga o arquivo', async () => {
  const r = await fetch(`${base}/clientes/me/foto`, { method: 'DELETE', headers: auth });
  assert.equal(r.status, 200);
  assert.equal((await r.json()).foto_url, null);
  const arquivos = await fs.readdir(pastaCliente);
  assert.equal(arquivos.length, 0);
});
