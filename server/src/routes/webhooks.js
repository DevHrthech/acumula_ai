const express = require('express');
const crypto = require('crypto');

const prisma = require('../prisma');
const { limiteWebhook } = require('../middleware/rateLimiters');
const { EVENTOS_PAGAMENTO, novoVencimentoLicenca, dadosDaCobranca } = require('../utils/cobranca');
const { NOTA_AUTORIZADA, dadosDaNota, atualizacaoDaNota, montarEmailNota } = require('../utils/nota');
const { enviarEmail } = require('../utils/mailer');

const router = express.Router();

// Compara o token do header `asaas-access-token` com ASAAS_WEBHOOK_TOKEN sem
// vazar o resultado pelo tempo de resposta.
function tokenValido(recebido) {
  const esperado = process.env.ASAAS_WEBHOOK_TOKEN;
  if (!esperado || typeof recebido !== 'string') return false;
  const a = Buffer.from(recebido);
  const b = Buffer.from(esperado);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// Espelha a cobrança do Asaas em `cobrancas` e, se o evento é de pagamento
// confirmado/recebido, renova a licença (uma única vez por cobrança).
async function processarPagamento(evento, payment) {
  if (!payment.subscription) return; // cobrança avulsa: não é de licença nossa

  const licenca = await prisma.licenca.findFirst({ where: { gateway_assinatura_id: payment.subscription } });
  if (!licenca) return; // assinatura que não é nossa

  const dados = dadosDaCobranca(payment);
  if (!dados.data_vencimento) throw new Error(`Cobrança ${payment.id} sem dueDate válido.`);

  await prisma.$transaction(async (tx) => {
    const cobranca = await tx.cobranca.upsert({
      where: { asaas_payment_id: payment.id },
      create: { ...dados, asaas_payment_id: payment.id, licenca_id: licenca.id, empresa_id: licenca.empresa_id },
      update: dados,
    });

    if (!EVENTOS_PAGAMENTO.includes(evento)) return;

    // "Reivindica" a renovação: só o primeiro evento de pagamento dessa
    // cobrança consegue (count 1); CONFIRMED + RECEIVED não renovam duas vezes.
    const reivindicada = await tx.cobranca.updateMany({
      where: { id: cobranca.id, licenca_estendida_em: null },
      data: { licenca_estendida_em: new Date() },
    });
    if (reivindicada.count !== 1) return;

    const atual = await tx.licenca.findUnique({ where: { id: licenca.id } });
    await tx.licenca.update({
      where: { id: licenca.id },
      data: {
        data_vencimento: novoVencimentoLicenca(atual.data_vencimento, dados.data_vencimento),
        em_trial: false,
        // BLOQUEADA/CANCELADA gravados à mão pelo admin continuam valendo.
        ...(atual.status === 'INADIMPLENTE' && { status: 'ATIVA' }),
      },
    });
  });
}

// Espelha a nota fiscal (INVOICE_*) em `notas_fiscais` e, na primeira vez que
// ela chega autorizada (com PDF/XML), avisa a empresa por e-mail.
async function processarNota(evento, invoice) {
  const dados = dadosDaNota(invoice);
  if (!dados.asaas_payment_id) return;

  // Só notas de cobranças nossas (a conta Asaas pode ter outras notas).
  const cobranca = await prisma.cobranca.findUnique({ where: { asaas_payment_id: dados.asaas_payment_id } });
  if (!cobranca) return;

  const existente = await prisma.notaFiscal.findUnique({ where: { asaas_invoice_id: invoice.id } });
  const nota = existente
    ? await prisma.notaFiscal.update({ where: { id: existente.id }, data: atualizacaoDaNota(existente, dados) })
    : await prisma.notaFiscal.create({
        data: { ...dados, asaas_invoice_id: invoice.id, empresa_id: cobranca.empresa_id, licenca_id: cobranca.licenca_id },
      });

  if (evento === 'INVOICE_ERROR') {
    console.error(`NFS-e ${invoice.id} (cobrança ${dados.asaas_payment_id}) com erro: ${dados.motivo_erro || 'sem descrição'}`);
  }
  if (nota.status !== NOTA_AUTORIZADA || (!nota.pdf_url && !nota.xml_url)) return;

  // "Reivindica" o envio: só o primeiro evento autorizado dessa nota consegue.
  const reivindicada = await prisma.notaFiscal.updateMany({
    where: { id: nota.id, email_enviado_em: null },
    data: { email_enviado_em: new Date() },
  });
  if (reivindicada.count !== 1) return;

  try {
    const empresa = await prisma.empresa.findUnique({ where: { id: nota.empresa_id } });
    if (!empresa) return;
    const { assunto, texto } = montarEmailNota({ empresaNome: empresa.nome, nota });
    await enviarEmail({ para: empresa.email, assunto, texto });
  } catch (err) {
    // O e-mail é cortesia (a nota segue no painel): não derruba o webhook, e
    // libera o envio para um próximo evento da mesma nota tentar de novo.
    console.error(`Falha ao enviar e-mail da nota ${invoice.id}:`, err.message);
    await prisma.notaFiscal.update({ where: { id: nota.id }, data: { email_enviado_em: null } }).catch(() => {});
  }
}

router.post('/asaas', limiteWebhook, async (req, res) => {
  if (!process.env.ASAAS_WEBHOOK_TOKEN) {
    console.error('Webhook Asaas recebido, mas ASAAS_WEBHOOK_TOKEN não está configurado.');
    return res.status(503).json({ erro: 'Webhook não configurado.' });
  }
  if (!tokenValido(req.headers['asaas-access-token'])) {
    return res.status(401).json({ erro: 'Token inválido.' });
  }

  const { id, event, payment, invoice } = req.body || {};
  if (typeof id !== 'string' || !id || id.length > 100 || typeof event !== 'string' || !event || event.length > 60) {
    return res.status(400).json({ erro: 'Evento inválido.' });
  }

  // Entrega "pelo menos uma vez": evento já visto é ignorado (responde 200
  // para o Asaas parar de reenviar).
  try {
    await prisma.asaasEvento.create({ data: { id, evento: event } });
  } catch (err) {
    if (err.code === 'P2002') return res.json({ recebido: true, duplicado: true });
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao registrar evento.' });
  }

  try {
    if (event.startsWith('PAYMENT_') && payment && typeof payment.id === 'string') {
      await processarPagamento(event, payment);
    } else if (event.startsWith('INVOICE_') && invoice && typeof invoice.id === 'string' && invoice.id) {
      await processarNota(event, invoice);
    }
    return res.json({ recebido: true });
  } catch (err) {
    // Libera o id para o Asaas poder reenviar (resposta fora de 2xx = retentativa).
    await prisma.asaasEvento.delete({ where: { id } }).catch(() => {});
    console.error(`Falha ao processar evento ${event} (${id}):`, err);
    return res.status(500).json({ erro: 'Erro ao processar evento.' });
  }
});

module.exports = router;
