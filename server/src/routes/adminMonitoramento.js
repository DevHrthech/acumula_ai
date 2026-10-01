const express = require('express');

const prisma = require('../prisma');
const authAdmin = require('../middleware/authAdmin');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();
router.use(authAdmin);

function classeStatus(codigo) {
  if (codigo >= 500) return '5xx';
  if (codigo >= 400) return '4xx';
  if (codigo >= 300) return '3xx';
  return '2xx';
}

// Visão geral de saúde da API: volume, taxa de erro, latência média e
// endpoints mais chamados nas últimas 24h/7d. Tudo calculado on-the-fly a
// partir de requisicoes_api — sem tabelas de agregação separadas (volume
// ainda baixo o suficiente pra isso ser rápido).
router.get('/resumo', asyncHandler(async (req, res) => {
  const desde24h = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const desde7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const [total24h, total7d, porStatus, mediaLatencia, topRotas] = await Promise.all([
    prisma.requisicaoApi.count({ where: { created_at: { gte: desde24h } } }),
    prisma.requisicaoApi.count({ where: { created_at: { gte: desde7d } } }),
    prisma.requisicaoApi.groupBy({
      by: ['status_code'],
      where: { created_at: { gte: desde24h } },
      _count: true,
    }),
    prisma.requisicaoApi.aggregate({
      where: { created_at: { gte: desde24h } },
      _avg: { duracao_ms: true },
    }),
    prisma.requisicaoApi.groupBy({
      by: ['rota', 'metodo'],
      where: { created_at: { gte: desde24h } },
      _count: true,
      orderBy: { _count: { rota: 'desc' } },
      take: 5,
    }),
  ]);

  const porClasseStatus = { '2xx': 0, '3xx': 0, '4xx': 0, '5xx': 0 };
  for (const grupo of porStatus) {
    porClasseStatus[classeStatus(grupo.status_code)] += grupo._count;
  }

  res.json({
    total24h,
    total7d,
    porClasseStatus,
    latenciaMediaMs: Math.round(mediaLatencia._avg.duracao_ms || 0),
    topRotas: topRotas.map((r) => ({ rota: r.rota, metodo: r.metodo, total: r._count })),
  });
}));

// Uso por empresa nos últimos 7 dias — quantas chamadas cada empresa fez.
router.get('/uso-por-empresa', asyncHandler(async (req, res) => {
  const desde7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const grupos = await prisma.requisicaoApi.groupBy({
    by: ['empresa_id'],
    where: { created_at: { gte: desde7d }, empresa_id: { not: null } },
    _count: true,
  });

  const empresas = await prisma.empresa.findMany({
    where: { id: { in: grupos.map((g) => g.empresa_id) } },
    select: { id: true, nome: true },
  });

  const resultado = grupos
    .map((g) => ({
      empresaId: g.empresa_id,
      nome: empresas.find((e) => e.id === g.empresa_id)?.nome || '(empresa removida)',
      totalChamadas: g._count,
    }))
    .sort((a, b) => b.totalChamadas - a.totalChamadas);

  res.json(resultado);
}));

module.exports = router;
