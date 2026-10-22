const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');
const { hojeBrasilia, paraData } = require('../utils/data');
const { primeiroErroTexto } = require('../utils/validar');

const router = express.Router();

// Promoção = aviso/post da loja para os clientes vinculados. Não tem meta e
// não gera cartão fidelidade (isso é a Campanha — ver routes/campanhas.js).

// Mesma ideia da campanha: o status gravado só muda por ação manual;
// `status_efetivo` acrescenta VENCIDA (fim da validade passou) e AGENDADA
// (início ainda no futuro).
function comStatusEfetivo(promocao, hoje = hojeBrasilia()) {
  const vencida = promocao.data_validade ? promocao.data_validade < hoje : false;
  const agendada = promocao.data_inicio ? promocao.data_inicio > hoje : false;
  let statusEfetivo = promocao.status;
  if (promocao.status === 'ATIVA') {
    if (vencida) statusEfetivo = 'VENCIDA';
    else if (agendada) statusEfetivo = 'AGENDADA';
  }
  return { ...promocao, status_efetivo: statusEfetivo, vencida };
}

router.get('/', authEmpresa, asyncHandler(async (req, res) => {
  const promocoes = await prisma.promocao.findMany({
    where: { empresa_id: req.empresaId },
    orderBy: { created_at: 'desc' },
  });
  const hoje = hojeBrasilia();
  return res.json(promocoes.map((p) => comStatusEfetivo(p, hoje)));
}));

router.post('/', authEmpresa, asyncHandler(async (req, res) => {
  const { titulo, descricao, dataValidade, dataInicio } = req.body || {};

  const erroTexto = primeiroErroTexto({
    titulo: [titulo, { max: 150, obrigatorio: true }],
    descricao: [descricao, { max: 500 }],
  });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
  }

  const hoje = hojeBrasilia();

  let validade = null;
  if (dataValidade) {
    validade = paraData(dataValidade);
    if (!validade) {
      return res.status(400).json({ erro: 'dataValidade inválida.' });
    }
    if (validade < hoje) {
      return res.status(400).json({ erro: 'A validade não pode ser uma data que já passou.' });
    }
  }

  // Início opcional: sem data informada, fixa a data do cadastro (hoje, em
  // Brasília).
  let inicio = hoje;
  if (dataInicio) {
    inicio = paraData(dataInicio);
    if (!inicio) {
      return res.status(400).json({ erro: 'dataInicio inválida.' });
    }
  }
  if (validade && inicio > validade) {
    return res.status(400).json({ erro: 'dataInicio não pode ser depois da validade.' });
  }

  const promocao = await prisma.promocao.create({
    data: {
      empresa_id: req.empresaId,
      titulo: titulo.trim(),
      descricao: descricao ? descricao.trim() : null,
      data_inicio: inicio,
      data_validade: validade,
    },
  });
  return res.status(201).json(comStatusEfetivo(promocao, hoje));
}));

router.patch('/:id', authEmpresa, asyncHandler(async (req, res) => {
  const promocao = await prisma.promocao.findUnique({ where: { id: req.params.id } });
  if (!promocao || promocao.empresa_id !== req.empresaId) {
    return res.status(404).json({ erro: 'Promoção não encontrada.' });
  }

  const { status } = req.body || {};
  if (!status || !['ATIVA', 'EXPIRADA'].includes(status)) {
    return res.status(400).json({ erro: 'status deve ser ATIVA ou EXPIRADA.' });
  }

  const atualizada = await prisma.promocao.update({ where: { id: req.params.id }, data: { status } });
  return res.json(comStatusEfetivo(atualizada));
}));

router.delete('/:id', authEmpresa, asyncHandler(async (req, res) => {
  const promocao = await prisma.promocao.findUnique({ where: { id: req.params.id } });
  if (!promocao || promocao.empresa_id !== req.empresaId) {
    return res.status(404).json({ erro: 'Promoção não encontrada.' });
  }

  await prisma.promocao.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
}));

module.exports = router;
