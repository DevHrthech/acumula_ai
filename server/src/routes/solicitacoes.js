const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');
const { creditarVinculo } = require('../utils/fidelidade');

const router = express.Router();

function sanitizarCliente(cliente) {
  const { senha_hash, ...resto } = cliente;
  return resto;
}

// Fila de pendências da tela "Aprovação" — busca/filtro por CPF ou cupom
// fiscal (ver docs/MECANICA_FIDELIDADE.md seção 9).
router.get('/', authEmpresa, asyncHandler(async (req, res) => {
  const { status, cpf, cupomFiscal } = req.query;

  const where = { vinculo: { empresa_id: req.empresaId } };
  if (status && ['PENDENTE', 'APROVADA', 'REJEITADA'].includes(status)) {
    where.status = status;
  }
  if (cpf) {
    where.vinculo = { ...where.vinculo, cliente: { cpf: String(cpf).replace(/\D/g, '') } };
  }
  if (cupomFiscal) {
    where.cupom_fiscal = { contains: String(cupomFiscal) };
  }

  const solicitacoes = await prisma.solicitacaoMarcacao.findMany({
    where,
    include: { vinculo: { include: { cliente: true, empresa: true } } },
    orderBy: { created_at: 'desc' },
  });

  return res.json(solicitacoes.map((s) => ({
    id: s.id,
    cupomFiscal: s.cupom_fiscal,
    status: s.status,
    createdAt: s.created_at,
    resolvedAt: s.resolved_at,
    cliente: sanitizarCliente(s.vinculo.cliente),
    saldoAtual: s.vinculo.saldo_atual,
    metaFidelidade: s.vinculo.empresa.meta_fidelidade,
  })));
}));

router.patch('/:id', authEmpresa, asyncHandler(async (req, res) => {
  const { acao } = req.body || {};
  if (!['aprovar', 'rejeitar'].includes(acao)) {
    return res.status(400).json({ erro: 'acao deve ser "aprovar" ou "rejeitar".' });
  }

  const solicitacao = await prisma.solicitacaoMarcacao.findUnique({
    where: { id: req.params.id },
    include: { vinculo: { include: { empresa: true } } },
  });
  if (!solicitacao || solicitacao.vinculo.empresa_id !== req.empresaId) {
    return res.status(404).json({ erro: 'Solicitação não encontrada.' });
  }
  if (solicitacao.status !== 'PENDENTE') {
    return res.status(409).json({ erro: 'Esta solicitação já foi resolvida.' });
  }

  if (acao === 'rejeitar') {
    const atualizada = await prisma.solicitacaoMarcacao.update({
      where: { id: req.params.id },
      data: { status: 'REJEITADA', resolved_at: new Date() },
    });
    return res.json({ id: atualizada.id, status: atualizada.status });
  }

  const resultado = await creditarVinculo(solicitacao.vinculo, solicitacao.vinculo.empresa);
  const atualizada = await prisma.solicitacaoMarcacao.update({
    where: { id: req.params.id },
    data: { status: 'APROVADA', resolved_at: new Date() },
  });

  return res.json({
    id: atualizada.id,
    status: atualizada.status,
    saldoAtual: resultado.saldoAtual,
    recompensaLiberada: Boolean(resultado.resgate),
  });
}));

// Marcação manual pela loja, sem solicitação prévia do cliente — busca
// direta por CPF (ver docs/MECANICA_FIDELIDADE.md seção 9).
router.post('/marcar-manual', authEmpresa, asyncHandler(async (req, res) => {
  const { cpf } = req.body || {};
  if (!cpf) {
    return res.status(400).json({ erro: 'Informe o CPF do cliente.' });
  }
  const cpfLimpo = String(cpf).replace(/\D/g, '');

  const cliente = await prisma.cliente.findUnique({ where: { cpf: cpfLimpo } });
  if (!cliente) {
    return res.status(404).json({ erro: 'Cliente não encontrado.' });
  }

  const vinculo = await prisma.vinculo.findUnique({
    where: { cliente_id_empresa_id: { cliente_id: cliente.id, empresa_id: req.empresaId } },
  });
  if (!vinculo) {
    return res.status(404).json({ erro: 'Este cliente não está vinculado à sua loja.' });
  }

  const empresa = await prisma.empresa.findUnique({ where: { id: req.empresaId } });
  const resultado = await creditarVinculo(vinculo, empresa);

  return res.status(201).json({
    cliente: { nome: cliente.nome, cpf: cliente.cpf },
    saldoAtual: resultado.saldoAtual,
    recompensaLiberada: Boolean(resultado.resgate),
  });
}));

module.exports = router;
