const express = require('express');

const prisma = require('../prisma');
const authAdmin = require('../middleware/authAdmin');
const asyncHandler = require('../utils/asyncHandler');
const { hojeBrasilia } = require('../utils/data');
const { PERIODOS, montarDashboard } = require('../utils/financeiro');

const router = express.Router();
router.use(authAdmin);

// Dashboard financeiro da 2RL: faturamento, receita recorrente, a receber,
// atrasos, empresas por situação e conversão do trial.
//   GET /admin/financeiro?periodo=mes|3m|6m|12m|ano   (padrão: 6m)
// Calculado na hora a partir de `cobrancas` e `licencas` (volume ainda
// pequeno — mesmo critério do monitoramento, sem tabelas de agregação).
router.get('/', asyncHandler(async (req, res) => {
  const periodo = req.query.periodo === undefined ? '6m' : req.query.periodo;
  if (typeof periodo !== 'string' || !(periodo in PERIODOS)) {
    return res.status(400).json({ erro: 'periodo deve ser mes, 3m, 6m, 12m ou ano.' });
  }

  const [empresas, cobrancas] = await Promise.all([
    prisma.empresa.findMany({
      select: {
        id: true,
        nome: true,
        trial_usado_em: true,
        licencas: { orderBy: { created_at: 'desc' }, take: 1, include: { plano: true } },
      },
    }),
    prisma.cobranca.findMany({
      select: {
        empresa_id: true,
        valor: true,
        forma_pagamento: true,
        status: true,
        data_vencimento: true,
        data_pagamento: true,
        invoice_url: true,
      },
    }),
  ]);

  res.json(montarDashboard({ empresas, cobrancas, hoje: hojeBrasilia(), periodo }));
}));

module.exports = router;
