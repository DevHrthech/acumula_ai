const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', authEmpresa, asyncHandler(async (req, res) => {
  const campanhas = await prisma.campanha.findMany({
    where: { empresa_id: req.empresaId },
    orderBy: { created_at: 'desc' },
  });
  return res.json(campanhas);
}));

router.post('/', authEmpresa, asyncHandler(async (req, res) => {
  const { nome, descricao, meta, dataValidade } = req.body || {};

  if (!nome || !meta || !dataValidade) {
    return res.status(400).json({ erro: 'Campos obrigatórios: nome, meta, dataValidade.' });
  }
  if (!Number.isInteger(meta) || meta < 1 || meta > 100000) {
    return res.status(400).json({ erro: 'meta deve ser um inteiro entre 1 e 100000.' });
  }
  if (nome.length > 150) {
    return res.status(400).json({ erro: 'nome deve ter no máximo 150 caracteres.' });
  }
  if (descricao && descricao.length > 255) {
    return res.status(400).json({ erro: 'descricao deve ter no máximo 255 caracteres.' });
  }
  const validade = new Date(dataValidade);
  if (Number.isNaN(validade.getTime())) {
    return res.status(400).json({ erro: 'dataValidade inválida.' });
  }

  const campanha = await prisma.campanha.create({
    data: {
      empresa_id: req.empresaId,
      nome,
      descricao: descricao || null,
      meta,
      data_validade: validade,
    },
  });
  return res.status(201).json(campanha);
}));

router.patch('/:id', authEmpresa, asyncHandler(async (req, res) => {
  const campanha = await prisma.campanha.findUnique({ where: { id: req.params.id } });
  if (!campanha || campanha.empresa_id !== req.empresaId) {
    return res.status(404).json({ erro: 'Campanha não encontrada.' });
  }

  const { status } = req.body || {};
  if (!status || !['ATIVA', 'EXPIRADA'].includes(status)) {
    return res.status(400).json({ erro: 'status deve ser ATIVA ou EXPIRADA.' });
  }

  const atualizada = await prisma.campanha.update({ where: { id: req.params.id }, data: { status } });
  return res.json(atualizada);
}));

module.exports = router;
