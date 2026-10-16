const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { montarOrigensPermitidas, origensExtras, origemPermitida, criarCors } = require('../src/utils/cors');

test('www, domínio principal e admin estão liberados em produção', () => {
  const lista = montarOrigensPermitidas({ NODE_ENV: 'production' });
  for (const o of ['https://acumulaai.com.br', 'https://www.acumulaai.com.br', 'https://admin.acumulaai.com.br']) {
    assert.equal(origemPermitida(o, lista), true, o);
  }
});

test('em produção localhost e 127.0.0.1 ficam fechados; fora dela abrem', () => {
  const prod = montarOrigensPermitidas({ NODE_ENV: 'production' });
  assert.equal(origemPermitida('http://localhost:5555', prod), false);
  assert.equal(origemPermitida('http://127.0.0.1:5555', prod), false);
  const dev = montarOrigensPermitidas({});
  assert.equal(origemPermitida('http://localhost:5555', dev), true);
  assert.equal(origemPermitida('http://127.0.0.1:5555', dev), true);
});

test('recusa variações enganosas do domínio', () => {
  const lista = montarOrigensPermitidas({ NODE_ENV: 'production' });
  for (const o of [
    'http://acumulaai.com.br', // sem https
    'https://acumulaai.com.br.evil.com',
    'https://evilacumulaai.com.br',
    'https://acumulaai.com.br:8443',
    'https://app.acumulaai.com.br',
    'https://outro-site.com',
  ]) {
    assert.equal(origemPermitida(o, lista), false, o);
  }
});

test('sem Origin (app do celular, curl) passa', () => {
  assert.equal(origemPermitida(undefined, montarOrigensPermitidas({ NODE_ENV: 'production' })), true);
});

test('CORS_ORIGENS_EXTRAS: só origens exatas válidas', () => {
  assert.deepEqual(origensExtras('https://teste.exemplo.com, https://b.exemplo.com:8443/ ,*, https://*.x.com,ftp://x.com,https://c.com/caminho,'), [
    'https://teste.exemplo.com',
    'https://b.exemplo.com:8443',
  ]);
  const lista = montarOrigensPermitidas({ NODE_ENV: 'production', CORS_ORIGENS_EXTRAS: 'https://qa.exemplo.com' });
  assert.equal(origemPermitida('https://qa.exemplo.com', lista), true);
});

test('integração: origem liberada recebe cabeçalhos; recusada recebe 403 claro (não 500)', async () => {
  const app = express();
  app.use(criarCors(montarOrigensPermitidas({ NODE_ENV: 'production' })));
  app.post('/auth/empresa/login', (req, res) => res.json({ ok: true }));
  const servidor = await new Promise((resolve) => { const s = app.listen(0, () => resolve(s)); });
  const base = `http://localhost:${servidor.address().port}`;
  try {
    const pre = (origin) => fetch(`${base}/auth/empresa/login`, {
      method: 'OPTIONS',
      headers: { Origin: origin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type,authorization' },
    });

    const ok = await pre('https://www.acumulaai.com.br');
    assert.equal(ok.status, 204);
    assert.equal(ok.headers.get('access-control-allow-origin'), 'https://www.acumulaai.com.br');

    const ruim = await pre('https://outro-site.com');
    assert.equal(ruim.status, 403);
    assert.equal(ruim.headers.get('access-control-allow-origin'), null);
    assert.match((await ruim.json()).erro, /Origem não permitida/);

    const real = await fetch(`${base}/auth/empresa/login`, { method: 'POST', headers: { Origin: 'https://outro-site.com' } });
    assert.equal(real.status, 403); // a requisição real também nem chega na rota

    const semOrigin = await fetch(`${base}/auth/empresa/login`, { method: 'POST' });
    assert.equal(semOrigin.status, 200);
  } finally {
    await new Promise((resolve) => servidor.close(resolve));
  }
});
