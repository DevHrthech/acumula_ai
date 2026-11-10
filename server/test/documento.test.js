const test = require('node:test');
const assert = require('node:assert');

const { analisar, limpar, rotuloCampoUnico, campoDuplicado } = require('../src/utils/documento');

test('CPF válido é reconhecido, com ou sem máscara, e formatado', () => {
  for (const entrada of ['529.982.247-25', '52998224725', ' 529 982 247 25 ']) {
    const d = analisar(entrada);
    assert.strictEqual(d.tipo, 'CPF');
    assert.strictEqual(d.digitos, '52998224725');
    assert.strictEqual(d.formatado, '529.982.247-25');
  }
});

test('CNPJ válido é reconhecido, com ou sem máscara, e formatado', () => {
  for (const entrada of ['11.222.333/0001-81', '11222333000181']) {
    const d = analisar(entrada);
    assert.strictEqual(d.tipo, 'CNPJ');
    assert.strictEqual(d.digitos, '11222333000181');
    assert.strictEqual(d.formatado, '11.222.333/0001-81');
  }
});

test('CPF com dígito verificador errado ou sequência repetida é recusado', () => {
  assert.strictEqual(analisar('529.982.247-26'), null);
  assert.strictEqual(analisar('111.111.111-11'), null);
  assert.strictEqual(analisar('000.000.000-00'), null);
});

test('CNPJ com dígito verificador errado ou sequência repetida é recusado', () => {
  assert.strictEqual(analisar('11.222.333/0001-82'), null);
  assert.strictEqual(analisar('11.111.111/1111-11'), null);
});

test('tamanhos que não são de CPF nem de CNPJ são recusados', () => {
  assert.strictEqual(analisar('5299822472'), null); // 10 dígitos
  assert.strictEqual(analisar('529982247250'), null); // 12 dígitos
  assert.strictEqual(analisar('1122233300018'), null); // 13 dígitos
  assert.strictEqual(analisar(''), null);
  assert.strictEqual(analisar('abc'), null);
});

test('entradas que não são texto são recusadas', () => {
  assert.strictEqual(analisar(undefined), null);
  assert.strictEqual(analisar(null), null);
  assert.strictEqual(analisar({}), null);
  assert.strictEqual(analisar(['52998224725']), null);
});

test('um CPF não é confundido com um CNPJ de mesmo prefixo', () => {
  // 11 dígitos de CPF válido nunca vira CNPJ, e vice-versa
  assert.strictEqual(analisar('52998224725').tipo, 'CPF');
  assert.strictEqual(analisar('11222333000181').tipo, 'CNPJ');
});

test('limpar tira tudo que não é dígito', () => {
  assert.strictEqual(limpar('529.982.247-25'), '52998224725');
  assert.strictEqual(limpar(null), '');
});

test('rotuloCampoUnico dá nome amigável à coluna ou ao índice violado', () => {
  assert.strictEqual(rotuloCampoUnico('cnpj_cpf'), 'CPF/CNPJ');
  assert.strictEqual(rotuloCampoUnico('cnpj'), 'CPF/CNPJ');
  assert.strictEqual(rotuloCampoUnico('empresas_cnpj_key'), 'CPF/CNPJ');
  assert.strictEqual(rotuloCampoUnico('empresas_cnpj_cpf_key'), 'CPF/CNPJ');
  assert.strictEqual(rotuloCampoUnico('empresas_email_key'), 'e-mail');
  assert.strictEqual(rotuloCampoUnico('empresas_codigo_loja_key'), 'código de loja');
  assert.strictEqual(rotuloCampoUnico('qualquer_outra'), 'campo único');
  assert.strictEqual(rotuloCampoUnico(undefined), 'campo único');
});

test('campoDuplicado lê o índice do erro do adaptador MariaDB (e o target clássico)', () => {
  const mariadb = {
    code: 'P2002',
    meta: {
      driverAdapterError: {
        cause: {
          originalMessage: "Duplicate entry '111.444.777-35' for key 'empresas_cnpj_cpf_key'",
          constraint: { index: 'empresas_cnpj_cpf_key' },
        },
      },
    },
  };
  assert.strictEqual(campoDuplicado(mariadb), 'CPF/CNPJ');
  assert.strictEqual(campoDuplicado({ meta: { target: ['email'] } }), 'e-mail');
  assert.strictEqual(campoDuplicado({}), 'campo único');
  assert.strictEqual(campoDuplicado(undefined), 'campo único');
  // nunca vaza a mensagem crua (que traz o valor duplicado)
  assert.ok(!campoDuplicado({ meta: { driverAdapterError: { cause: { originalMessage: 'Duplicate entry 123' } } } }).includes('123'));
});
