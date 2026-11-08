const express = require('express');

const prisma = require('../prisma');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

// Lista pública dos planos ativos — alimenta a escolha de plano no
// auto-cadastro da loja (antes do login, por isso sem autenticação).
router.get('/', asyncHandler(async (req, res) => {
  const planos = await prisma.plano.findMany({
    where: { ativo: true },
    orderBy: { valor_mensal: 'asc' },
    select: { id: true, nome: true, valor_mensal: true, descricao: true },
  });
  res.json(planos);
}));

module.exports = router;
