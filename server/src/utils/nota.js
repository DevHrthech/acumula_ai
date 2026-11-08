const { paraData } = require('./data');

// Nota fiscal de serviço (NFS-e) emitida pelo Asaas após cada pagamento
// confirmado. A emissão é uma "regra" na assinatura (invoiceSettings) — o
// Asaas gera a nota sozinho — e o resultado volta pelos eventos INVOICE_*.
// Docs: https://docs.asaas.com/docs/emitir-notas-fiscais-automaticamente-para-assinaturas

const NOTA_AUTORIZADA = 'AUTHORIZED';

// Número com ponto ou vírgula decimal ("3", "3,5"); vazio/inválido = padrão.
function numeroEnv(valor, padrao) {
  if (valor === undefined || valor === null || String(valor).trim() === '') return padrao;
  const n = Number(String(valor).replace(',', '.'));
  return Number.isFinite(n) ? n : padrao;
}

// A emissão só liga quando NFSE_ATIVA=true E o serviço fiscal está definido
// (código ou id municipal). Assim, sem configuração fiscal nenhuma nota é pedida.
function notaAtiva(env = process.env) {
  if (String(env.NFSE_ATIVA || '').toLowerCase() !== 'true') return false;
  return Boolean(env.NFSE_SERVICO_CODIGO || env.NFSE_SERVICO_ID);
}

// Corpo de POST/PUT /subscriptions/{id}/invoiceSettings, montado a partir do
// .env (a contabilidade define serviço e alíquotas). Os impostos federais
// ficam em 0 por padrão (Simples Nacional); `taxes` é o estado completo
// desejado — o Asaas trata campo omitido como null.
function montarRegraNota(env = process.env) {
  const regra = {
    effectiveDatePeriod: 'ON_PAYMENT_CONFIRMATION',
    observations: env.NFSE_OBSERVACOES || 'Mensalidade do sistema ACUMULAAI.',
    deductions: 0,
    updatePayment: false,
    taxes: {
      retainIss: String(env.NFSE_RETEM_ISS || '').toLowerCase() === 'true',
      iss: numeroEnv(env.NFSE_ISS, 0),
      pis: numeroEnv(env.NFSE_PIS, 0),
      cofins: numeroEnv(env.NFSE_COFINS, 0),
      csll: numeroEnv(env.NFSE_CSLL, 0),
      inss: numeroEnv(env.NFSE_INSS, 0),
      ir: numeroEnv(env.NFSE_IR, 0),
    },
  };
  // O Asaas pede um OU outro (id da lista da prefeitura, ou código do serviço).
  if (env.NFSE_SERVICO_ID) {
    regra.municipalServiceId = env.NFSE_SERVICO_ID;
  } else {
    regra.municipalServiceCode = env.NFSE_SERVICO_CODIGO;
  }
  if (env.NFSE_SERVICO_NOME) regra.municipalServiceName = env.NFSE_SERVICO_NOME;
  // Regime Normal pelo Portal Nacional (NT-007): só quando informados.
  if (env.NFSE_PIS_COFINS_STATUS) regra.taxes.pisCofinsTaxStatus = env.NFSE_PIS_COFINS_STATUS;
  if (env.NFSE_OPERACAO_PIS) regra.taxes.operationPis = numeroEnv(env.NFSE_OPERACAO_PIS, 0);
  if (env.NFSE_OPERACAO_COFINS) regra.taxes.operationCofins = numeroEnv(env.NFSE_OPERACAO_COFINS, 0);
  return regra;
}

// Só guardamos/expomos links https (vêm do Asaas e são abertos no navegador).
function urlSegura(url) {
  if (typeof url !== 'string') return null;
  try {
    const u = new URL(url);
    return u.protocol === 'https:' && url.length <= 500 ? url : null;
  } catch {
    return null;
  }
}

const texto = (v, max) => (v === undefined || v === null || v === '' ? null : String(v).slice(0, max));

// Campos do `invoice` do webhook que espelhamos em notas_fiscais.
function dadosDaNota(invoice) {
  const valor = Number(invoice.value);
  return {
    asaas_payment_id: invoice.payment,
    status: String(invoice.status || '').slice(0, 40),
    numero: texto(invoice.number, 40),
    codigo_validacao: texto(invoice.validationCode, 100),
    valor: Number.isFinite(valor) ? valor : null,
    data_emissao: paraData(invoice.effectiveDate || ''),
    pdf_url: urlSegura(invoice.pdfUrl),
    xml_url: urlSegura(invoice.xmlUrl),
    // A doc não explica o conteúdo de statusDescription; é o campo mais
    // provável para o motivo do INVOICE_ERROR (confirmar com uma nota real).
    motivo_erro: texto(invoice.statusDescription, 500),
  };
}

// Eventos "pelo menos uma vez" podem chegar fora de ordem (ex: INVOICE_CREATED
// depois de INVOICE_AUTHORIZED). A atualização nunca apaga um dado já salvo
// (número, PDF, XML) com um vazio nem faz uma nota autorizada/cancelada voltar
// a "agendada". O motivo do erro é limpo quando a nota passa a autorizada.
const STATUS_INICIAIS = ['SCHEDULED', 'SYNCHRONIZED'];
const STATUS_FINAIS = ['AUTHORIZED', 'CANCELED'];

function atualizacaoDaNota(existente, dados) {
  const atualizacao = {};
  for (const [campo, valor] of Object.entries(dados)) {
    if (valor !== null && valor !== undefined) atualizacao[campo] = valor;
  }
  if (STATUS_FINAIS.includes(existente.status) && STATUS_INICIAIS.includes(dados.status)) {
    delete atualizacao.status;
  }
  if ((atualizacao.status || existente.status) === NOTA_AUTORIZADA) atualizacao.motivo_erro = null;
  return atualizacao;
}

function dataBR(d) {
  if (!d) return '';
  const [a, m, dia] = d.toISOString().slice(0, 10).split('-');
  return `${dia}/${m}/${a}`;
}

// E-mail (texto puro) com os links da nota para a empresa.
function montarEmailNota({ empresaNome, nota }) {
  const numero = nota.numero ? ` nº ${nota.numero}` : '';
  const linhas = [
    `Olá, ${empresaNome}!`,
    '',
    `A nota fiscal de serviço${numero} referente à sua mensalidade do ACUMULAAI foi emitida.`,
    '',
  ];
  if (nota.valor !== null && nota.valor !== undefined) {
    linhas.push(`Valor: R$ ${Number(nota.valor).toFixed(2).replace('.', ',')}`);
  }
  if (nota.data_emissao) linhas.push(`Data: ${dataBR(nota.data_emissao)}`);
  if (nota.codigo_validacao) linhas.push(`Código de verificação: ${nota.codigo_validacao}`);
  linhas.push('');
  if (nota.pdf_url) linhas.push(`Nota fiscal (PDF): ${nota.pdf_url}`);
  if (nota.xml_url) linhas.push(`Arquivo XML: ${nota.xml_url}`);
  linhas.push('', 'Você também encontra a nota (PDF e XML) no painel, em Assinatura: https://acumulaai.com.br/app/', '', 'Equipe ACUMULAAI');
  return {
    assunto: `Sua nota fiscal${numero} - ACUMULAAI`,
    texto: linhas.join('\n'),
  };
}

module.exports = { NOTA_AUTORIZADA, notaAtiva, montarRegraNota, urlSegura, dadosDaNota, atualizacaoDaNota, montarEmailNota };
