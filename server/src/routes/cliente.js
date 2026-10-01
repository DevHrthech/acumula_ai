const express = require('express');

const prisma = require('../prisma');
const authCliente = require('../middleware/authCliente');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

function sanitizarCliente(cliente) {
  const { senha_hash, ...resto } = cliente;
  return resto;
}

// Campos públicos da empresa que o cliente final pode ver — nunca email,
// cnpj ou qualquer dado interno de gestão (planos/licenças/contratos).
function empresaPublica(empresa) {
  const {
    id, nome, categoria, tipo_fidelidade, meta_fidelidade, descricao_recompensa,
    icone_url, logo_qrcode_url, logo_promocao_url, cor_principal, cor_destaque,
    nome_programa, mensagem_boas_vindas, mensagem_resgate, texto_botao_resgate,
  } = empresa;
  return {
    id, nome, categoria, tipo_fidelidade, meta_fidelidade, descricao_recompensa,
    icone_url, logo_qrcode_url, logo_promocao_url, cor_principal, cor_destaque,
    nome_programa, mensagem_boas_vindas, mensagem_resgate, texto_botao_resgate,
  };
}

router.get('/me', authCliente, asyncHandler(async (req, res) => {
  const cliente = await prisma.cliente.findUnique({ where: { id: req.clienteId } });

  if (!cliente) {
    return res.status(404).json({ erro: 'Cliente não encontrado.' });
  }

  return res.json(sanitizarCliente(cliente));
}));

router.get('/me/vinculos', authCliente, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { cliente_id: req.clienteId },
    include: { empresa: true },
    orderBy: { data_vinculo: 'desc' },
  });

  return res.json(vinculos.map((v) => ({
    id: v.id,
    saldoAtual: v.saldo_atual,
    dataVinculo: v.data_vinculo,
    empresa: empresaPublica(v.empresa),
  })));
}));

router.post('/me/vinculos', authCliente, asyncHandler(async (req, res) => {
  const { codigoLoja } = req.body || {};

  if (!codigoLoja || typeof codigoLoja !== 'string') {
    return res.status(400).json({ erro: 'Informe o código da loja.' });
  }

  // Códigos são gerados sem espaços/traços (ver utils/codigoLoja.js), mas o
  // cliente pode digitar com traço/espaço/minúsculo por engano — normaliza
  // antes de comparar em vez de rejeitar o formato.
  const codigoNormalizado = codigoLoja.toUpperCase().replace(/[^A-Z0-9]/g, '');

  const empresa = await prisma.empresa.findUnique({ where: { codigo_loja: codigoNormalizado } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Loja não encontrada para esse código.' });
  }

  const existente = await prisma.vinculo.findUnique({
    where: { cliente_id_empresa_id: { cliente_id: req.clienteId, empresa_id: empresa.id } },
  });
  if (existente) {
    return res.status(409).json({ erro: 'Você já está vinculado a esta loja.' });
  }

  const vinculo = await prisma.vinculo.create({
    data: { cliente_id: req.clienteId, empresa_id: empresa.id },
  });

  return res.status(201).json({
    id: vinculo.id,
    saldoAtual: vinculo.saldo_atual,
    dataVinculo: vinculo.data_vinculo,
    empresa: empresaPublica(empresa),
  });
}));

// Estatísticas agregadas pra tela Perfil — histórico completo, não só o
// saldo atual (que zera/desconta ao resgatar).
router.get('/me/resumo', authCliente, asyncHandler(async (req, res) => {
  const [totalMarcacoes, totalResgates, vinculos] = await Promise.all([
    prisma.marcacao.count({ where: { vinculo: { cliente_id: req.clienteId } } }),
    prisma.resgate.count({ where: { vinculo: { cliente_id: req.clienteId } } }),
    prisma.vinculo.findMany({ where: { cliente_id: req.clienteId }, select: { saldo_atual: true } }),
  ]);

  const saldoTotal = vinculos.reduce((acc, v) => acc + v.saldo_atual, 0);

  return res.json({ saldoTotal, totalMarcacoes, totalResgates });
}));

// Pedido de validação de compra (com ou sem cupom fiscal) — cai na fila da
// tela "Aprovação" da loja (ver docs/MECANICA_FIDELIDADE.md seção 9).
router.post('/me/solicitacoes', authCliente, asyncHandler(async (req, res) => {
  const { empresaId, cupomFiscal } = req.body || {};

  if (!empresaId) {
    return res.status(400).json({ erro: 'Informe a loja (empresaId).' });
  }
  if (cupomFiscal && cupomFiscal.length > 50) {
    return res.status(400).json({ erro: 'cupomFiscal deve ter no máximo 50 caracteres.' });
  }

  const vinculo = await prisma.vinculo.findUnique({
    where: { cliente_id_empresa_id: { cliente_id: req.clienteId, empresa_id: empresaId } },
  });
  if (!vinculo) {
    return res.status(404).json({ erro: 'Você não está vinculado a esta loja.' });
  }

  const solicitacao = await prisma.solicitacaoMarcacao.create({
    data: { vinculo_id: vinculo.id, cupom_fiscal: cupomFiscal || null },
  });

  return res.status(201).json({
    id: solicitacao.id,
    status: solicitacao.status,
    createdAt: solicitacao.created_at,
  });
}));

router.patch('/me/preferencias', authCliente, asyncHandler(async (req, res) => {
  const { notificacoesPush, notificacoesEmail, loginBiometrico } = req.body || {};

  const dados = {};
  if (typeof notificacoesPush === 'boolean') dados.notificacoes_push = notificacoesPush;
  if (typeof notificacoesEmail === 'boolean') dados.notificacoes_email = notificacoesEmail;
  if (typeof loginBiometrico === 'boolean') dados.login_biometrico = loginBiometrico;

  if (Object.keys(dados).length === 0) {
    return res.status(400).json({ erro: 'Informe ao menos uma preferência pra atualizar.' });
  }

  const cliente = await prisma.cliente.update({ where: { id: req.clienteId }, data: dados });
  return res.json(sanitizarCliente(cliente));
}));

module.exports = router;
