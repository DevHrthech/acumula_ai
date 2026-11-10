const { hojeBrasilia, DIA_MS } = require('./data');

// Trial gratuito concedido uma única vez no auto-cadastro da loja.
const DIAS_TRIAL = 15;

// Versão do texto que a empresa aceita no cadastro (cobrança via gateway
// Asaas) — gravada em empresas.aceite_termos_versao. Mudou o texto na tela,
// mude aqui também.
const VERSAO_TERMOS = '2026-11'; // 2026-11: o termo passa a citar CPF/CNPJ (nome, CPF/CNPJ e e-mail)

const FORMAS_PAGAMENTO = ['PIX', 'CARTAO_RECORRENTE'];

// Período da licença de trial: começa hoje (Brasília) e vale até o fim do
// dia `hoje + DIAS_TRIAL`.
function periodoTrial(agora = new Date()) {
  const inicio = hojeBrasilia(agora);
  return { inicio, vencimento: new Date(inicio.getTime() + DIAS_TRIAL * DIA_MS) };
}

module.exports = { DIAS_TRIAL, VERSAO_TERMOS, FORMAS_PAGAMENTO, periodoTrial };
