const test = require('node:test');
const assert = require('node:assert');

const {
  notaAtiva,
  montarRegraNota,
  urlSegura,
  dadosDaNota,
  atualizacaoDaNota,
  montarEmailNota,
} = require('../src/utils/nota');

const dia = (d) => d.toISOString().slice(0, 10);

test('notaAtiva exige NFSE_ATIVA=true e um serviço fiscal', () => {
  assert.strictEqual(notaAtiva({}), false);
  assert.strictEqual(notaAtiva({ NFSE_ATIVA: 'true' }), false);
  assert.strictEqual(notaAtiva({ NFSE_SERVICO_CODIGO: '1.01' }), false);
  assert.strictEqual(notaAtiva({ NFSE_ATIVA: 'false', NFSE_SERVICO_CODIGO: '1.01' }), false);
  assert.strictEqual(notaAtiva({ NFSE_ATIVA: 'TRUE', NFSE_SERVICO_CODIGO: '1.01' }), true);
  assert.strictEqual(notaAtiva({ NFSE_ATIVA: 'true', NFSE_SERVICO_ID: '123' }), true);
});

test('montarRegraNota emite na confirmação do pagamento e zera impostos não informados', () => {
  const r = montarRegraNota({ NFSE_SERVICO_CODIGO: '1.01', NFSE_ISS: '3,5' });
  assert.strictEqual(r.effectiveDatePeriod, 'ON_PAYMENT_CONFIRMATION');
  assert.strictEqual(r.municipalServiceCode, '1.01');
  assert.strictEqual(r.municipalServiceId, undefined);
  assert.deepStrictEqual(r.taxes, { retainIss: false, iss: 3.5, pis: 0, cofins: 0, csll: 0, inss: 0, ir: 0 });
  assert.strictEqual(r.updatePayment, false);
});

test('montarRegraNota usa o id do serviço OU o código, nunca os dois', () => {
  const r = montarRegraNota({ NFSE_SERVICO_ID: '4321', NFSE_SERVICO_CODIGO: '1.01' });
  assert.strictEqual(r.municipalServiceId, '4321');
  assert.strictEqual(r.municipalServiceCode, undefined);
});

test('montarRegraNota repassa os campos de PIS/COFINS do regime normal e ignora número inválido', () => {
  const r = montarRegraNota({
    NFSE_SERVICO_CODIGO: '1.01',
    NFSE_ISS: 'abc',
    NFSE_RETEM_ISS: 'true',
    NFSE_PIS_COFINS_STATUS: 'STANDARD_TAXABLE_OPERATION',
    NFSE_OPERACAO_PIS: '0.65',
    NFSE_OPERACAO_COFINS: '3',
  });
  assert.strictEqual(r.taxes.iss, 0);
  assert.strictEqual(r.taxes.retainIss, true);
  assert.strictEqual(r.taxes.pisCofinsTaxStatus, 'STANDARD_TAXABLE_OPERATION');
  assert.strictEqual(r.taxes.operationPis, 0.65);
  assert.strictEqual(r.taxes.operationCofins, 3);
});

test('urlSegura só aceita https curto', () => {
  assert.strictEqual(urlSegura('https://www.asaas.com/i/nota.pdf'), 'https://www.asaas.com/i/nota.pdf');
  assert.strictEqual(urlSegura('http://www.asaas.com/nota.pdf'), null);
  assert.strictEqual(urlSegura('javascript:alert(1)'), null);
  assert.strictEqual(urlSegura(null), null);
  assert.strictEqual(urlSegura(`https://x.com/${'a'.repeat(500)}`), null);
});

test('dadosDaNota espelha o invoice autorizado do Asaas', () => {
  const d = dadosDaNota({
    id: 'inv_1',
    status: 'AUTHORIZED',
    payment: 'pay_1',
    number: '123',
    validationCode: 'ABC-9',
    value: 99.9,
    effectiveDate: '2026-11-11',
    pdfUrl: 'https://asaas.com/n/1.pdf',
    xmlUrl: 'https://asaas.com/n/1.xml',
  });
  assert.strictEqual(d.asaas_payment_id, 'pay_1');
  assert.strictEqual(d.status, 'AUTHORIZED');
  assert.strictEqual(d.numero, '123');
  assert.strictEqual(d.valor, 99.9);
  assert.strictEqual(dia(d.data_emissao), '2026-11-11');
  assert.strictEqual(d.pdf_url, 'https://asaas.com/n/1.pdf');
  assert.strictEqual(d.xml_url, 'https://asaas.com/n/1.xml');
  assert.strictEqual(d.motivo_erro, null);
});

test('dadosDaNota guarda o motivo do erro e descarta link não-https', () => {
  const d = dadosDaNota({ id: 'inv_2', status: 'ERROR', payment: 'pay_2', statusDescription: 'Inscrição municipal inválida', pdfUrl: 'http://x.com/a.pdf' });
  assert.strictEqual(d.motivo_erro, 'Inscrição municipal inválida');
  assert.strictEqual(d.pdf_url, null);
  assert.strictEqual(d.valor, null);
});

test('atualizacaoDaNota não apaga dados salvos nem volta uma nota autorizada para agendada', () => {
  const existente = { status: 'AUTHORIZED', numero: '123', pdf_url: 'https://a/1.pdf' };
  const dadosAtrasados = dadosDaNota({ id: 'inv_1', status: 'SCHEDULED', payment: 'pay_1', value: 99.9 });
  const u = atualizacaoDaNota(existente, dadosAtrasados);
  assert.strictEqual(u.status, undefined);
  assert.strictEqual(u.numero, undefined);
  assert.strictEqual(u.pdf_url, undefined);
  assert.strictEqual(u.valor, 99.9);
  assert.strictEqual(u.motivo_erro, null); // autorizada: limpa erro antigo
});

test('atualizacaoDaNota aplica a autorização sobre uma nota agendada', () => {
  const existente = { status: 'SCHEDULED', numero: null, pdf_url: null };
  const u = atualizacaoDaNota(existente, dadosDaNota({ id: 'i', status: 'AUTHORIZED', payment: 'p', number: '7', pdfUrl: 'https://a/7.pdf' }));
  assert.strictEqual(u.status, 'AUTHORIZED');
  assert.strictEqual(u.numero, '7');
  assert.strictEqual(u.pdf_url, 'https://a/7.pdf');
});

test('montarEmailNota traz número, valor e os links de PDF e XML', () => {
  const { assunto, texto } = montarEmailNota({
    empresaNome: 'Loja Teste',
    nota: {
      numero: '123',
      valor: 99.9,
      data_emissao: new Date('2026-11-11T00:00:00Z'),
      codigo_validacao: 'ABC-9',
      pdf_url: 'https://asaas.com/n/1.pdf',
      xml_url: 'https://asaas.com/n/1.xml',
    },
  });
  assert.match(assunto, /nº 123/);
  assert.match(texto, /Loja Teste/);
  assert.match(texto, /R\$ 99,90/);
  assert.match(texto, /11\/11\/2026/);
  assert.match(texto, /https:\/\/asaas\.com\/n\/1\.pdf/);
  assert.match(texto, /https:\/\/asaas\.com\/n\/1\.xml/);
});
