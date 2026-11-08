const prisma = require('../prisma');
const asaas = require('./asaas');
const { DIA_MS } = require('./data');
const { dadosDaCobranca } = require('./cobranca');
const { FORMAS_PAGAMENTO } = require('./trial');
const { STATUS_ABERTOS } = require('./financeiro');
const { notaAtiva, montarRegraNota } = require('./nota');

const BILLING_TYPE = { PIX: 'PIX', CARTAO_RECORRENTE: 'CREDIT_CARD' };

const dia = (data) => data.toISOString().slice(0, 10);

// Garante cliente + assinatura no Asaas para a licença e grava os ids.
// Idempotente: se a licença já tem assinatura, não cria outra. A 1ª cobrança
// vence no dia seguinte ao fim do trial (ou no vencimento atual, se o trial
// já acabou), e a licença é renovada quando o webhook confirma o pagamento.
async function garantirAssinatura(licencaId) {
  const licenca = await prisma.licenca.findUnique({
    where: { id: licencaId },
    include: { empresa: true, plano: true },
  });
  if (!licenca) throw new Error('Licença não encontrada.');
  if (licenca.gateway_assinatura_id) return licenca;
  if (!licenca.forma_pagamento) throw new Error('Licença sem forma de pagamento definida.');

  let empresa = licenca.empresa;
  if (!empresa.asaas_customer_id) {
    const clienteId = await asaas.garantirCliente(empresa);
    empresa = await prisma.empresa.update({ where: { id: empresa.id }, data: { asaas_customer_id: clienteId } });
  }

  const hoje = new Date();
  const base = licenca.data_vencimento.getTime() + DIA_MS;
  const proximoVencimento = dia(new Date(Math.max(base, hoje.getTime())));

  const assinatura = await asaas.criarAssinatura({
    clienteId: empresa.asaas_customer_id,
    billingType: BILLING_TYPE[licenca.forma_pagamento],
    valor: Number(licenca.plano.valor_mensal),
    proximoVencimento,
    descricao: `Mensalidade ACUMULAAI - ${licenca.plano.nome}`,
    referencia: licenca.id,
  });

  const atualizada = await prisma.licenca.update({
    where: { id: licenca.id },
    data: { gateway_provedor: 'ASAAS', gateway_assinatura_id: assinatura.id },
    include: { empresa: true, plano: true },
  });

  // Emissão automática de NFS-e a cada pagamento confirmado. Falha aqui não
  // desfaz a assinatura: dá pra reaplicar depois com server/scripts/nfse-regra.js.
  try {
    await garantirRegraNota(assinatura.id);
  } catch (err) {
    console.error('Falha ao configurar a emissão de nota fiscal da assinatura:', err.message);
  }

  // Traz já a 1ª cobrança (o Asaas a cria junto com a assinatura), para o
  // link da fatura existir mesmo antes de o webhook chegar. Falha aqui não
  // desfaz nada: o webhook PAYMENT_CREATED preenche depois.
  try {
    await sincronizarCobrancas(atualizada);
  } catch (err) {
    console.error('Falha ao buscar cobranças da assinatura:', err.message);
  }
  return atualizada;
}

// Liga a emissão automática de nota fiscal na assinatura do Asaas (a nota sai
// quando o pagamento é confirmado). Sem NFSE_ATIVA=true + serviço fiscal no
// .env não faz nada. Devolve true se a regra foi aplicada.
async function garantirRegraNota(assinaturaId) {
  if (!notaAtiva()) return false;
  await asaas.configurarNotaDaAssinatura(assinaturaId, montarRegraNota());
  return true;
}

// Espelha em `cobrancas` as cobranças que o Asaas já gerou para a assinatura.
async function sincronizarCobrancas(licenca) {
  const lista = await asaas.listarCobrancasDaAssinatura(licenca.gateway_assinatura_id);
  for (const payment of lista.data || []) {
    const dados = dadosDaCobranca(payment);
    if (!dados.data_vencimento) continue;
    await prisma.cobranca.upsert({
      where: { asaas_payment_id: payment.id },
      create: { ...dados, asaas_payment_id: payment.id, licenca_id: licenca.id, empresa_id: licenca.empresa_id },
      update: dados,
    });
  }
}

// Troca a forma de pagamento (PIX <-> CARTAO_RECORRENTE) da licença.
// - Sem assinatura no Asaas (ex: licença lançada à mão): só grava a forma; a
//   cobrança automática continua sendo ativada à parte (garantirAssinatura).
// - Com assinatura: cancela a antiga no Asaas (as faturas em aberto somem
//   junto), grava a forma e cria a nova — a 1ª cobrança vence no dia seguinte
//   ao fim do período já pago. Se a criação falhar, a forma já está gravada e
//   o retorno traz `aviso` (o admin refaz em "Criar assinatura no Asaas").
async function alterarFormaPagamento(licencaId, forma) {
  if (!FORMAS_PAGAMENTO.includes(forma)) {
    throw Object.assign(new Error('formaPagamento deve ser PIX ou CARTAO_RECORRENTE.'), { status: 400 });
  }
  const licenca = await prisma.licenca.findUnique({ where: { id: licencaId } });
  if (!licenca) throw Object.assign(new Error('Licença não encontrada.'), { status: 404 });
  if (licenca.status === 'CANCELADA') {
    throw Object.assign(new Error('Licença cancelada: reative antes de trocar a forma de pagamento.'), { status: 400 });
  }
  if (licenca.forma_pagamento === forma) return { licenca };

  if (!licenca.gateway_assinatura_id) {
    const atualizada = await prisma.licenca.update({ where: { id: licencaId }, data: { forma_pagamento: forma } });
    return { licenca: atualizada };
  }

  try {
    await asaas.cancelarAssinatura(licenca.gateway_assinatura_id);
  } catch (err) {
    throw Object.assign(new Error(`Não foi possível cancelar a assinatura atual no Asaas: ${err.message}`), { status: 502 });
  }
  await prisma.$transaction([
    prisma.cobranca.updateMany({ where: { licenca_id: licencaId, status: { in: STATUS_ABERTOS } }, data: { status: 'DELETED' } }),
    prisma.licenca.update({ where: { id: licencaId }, data: { forma_pagamento: forma, gateway_assinatura_id: null } }),
  ]);

  try {
    return { licenca: await garantirAssinatura(licencaId) };
  } catch (err) {
    console.error('Falha ao recriar assinatura no Asaas:', err.message);
    const atual = await prisma.licenca.findUnique({ where: { id: licencaId } });
    return { licenca: atual, aviso: `Forma de pagamento alterada, mas a nova assinatura no Asaas não foi criada: ${err.message}` };
  }
}

module.exports = { garantirAssinatura, garantirRegraNota, alterarFormaPagamento, sincronizarCobrancas, BILLING_TYPE };
