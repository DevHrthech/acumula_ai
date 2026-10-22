const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');
const { creditarVinculo } = require('../utils/fidelidade');

const router = express.Router();

function sanitizarCliente(cliente) {
  // O painel da loja não precisa (nem deve ver) a foto de perfil do cliente nem
  // campos internos de sessão: a foto é só do app do cliente.
  const {
    senha_hash, reset_codigo_hash, reset_expira_em, reset_tentativas, token_valido_desde, foto_url, google_id, ...resto
  } = cliente;
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

  // A troca de status é condicional ("só se ainda PENDENTE"): num duplo clique
  // ou em duas abas, só uma das chamadas resolve a solicitação — a outra cai
  // no 409 e não credita de novo.
  const jaResolvida = () => res.status(409).json({ erro: 'Esta solicitação já foi resolvida.' });

  if (acao === 'rejeitar') {
    const { count } = await prisma.solicitacaoMarcacao.updateMany({
      where: { id: req.params.id, status: 'PENDENTE' },
      data: { status: 'REJEITADA', resolved_at: new Date() },
    });
    if (count === 0) return jaResolvida();
    return res.json({ id: req.params.id, status: 'REJEITADA' });
  }

  // Marcar como aprovada e creditar andam juntos na mesma transação: se o
  // crédito falhar, a solicitação volta a ficar PENDENTE.
  const resultado = await prisma.$transaction(async (tx) => {
    const { count } = await tx.solicitacaoMarcacao.updateMany({
      where: { id: req.params.id, status: 'PENDENTE' },
      data: { status: 'APROVADA', resolved_at: new Date() },
    });
    if (count === 0) return null;
    return creditarVinculo(solicitacao.vinculo, solicitacao.vinculo.empresa, tx);
  }, { timeout: 15000 });

  if (!resultado) return jaResolvida();

  return res.json({
    id: req.params.id,
    status: 'APROVADA',
    saldoAtual: resultado.saldoAtual,
    recompensaLiberada: Boolean(resultado.resgate),
    campanhasConcluidas: resultado.campanhasConcluidas,
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
