const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/clientes', authEmpresa, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { empresa_id: req.empresaId },
    include: {
      cliente: true,
      _count: { select: { marcacoes: true, resgates: true } },
    },
    orderBy: { data_vinculo: 'desc' },
  });

  return res.json(vinculos.map((v) => ({
    clienteId: v.cliente.id,
    nome: v.cliente.nome,
    cpf: v.cliente.cpf,
    email: v.cliente.email,
    telefone: v.cliente.telefone,
    saldoAtual: v.saldo_atual,
    totalMarcacoes: v._count.marcacoes,
    totalResgates: v._count.resgates,
    dataVinculo: v.data_vinculo,
  })));
}));

router.get('/dashboard', authEmpresa, asyncHandler(async (req, res) => {
  const inicioMes = new Date();
  inicioMes.setDate(1);
  inicioMes.setHours(0, 0, 0, 0);

  const [clientesAtivos, campanhasAtivas, marcacoesMes, resgatesMes, marcacoesRecentes, resgatesRecentes] =
    await Promise.all([
      prisma.vinculo.count({ where: { empresa_id: req.empresaId } }),
      prisma.campanha.count({ where: { empresa_id: req.empresaId, status: 'ATIVA' } }),
      prisma.marcacao.count({
        where: { vinculo: { empresa_id: req.empresaId }, data_hora: { gte: inicioMes } },
      }),
      prisma.resgate.count({
        where: { vinculo: { empresa_id: req.empresaId }, data_hora: { gte: inicioMes } },
      }),
      prisma.marcacao.findMany({
        where: { vinculo: { empresa_id: req.empresaId } },
        include: { vinculo: { include: { cliente: true } } },
        orderBy: { data_hora: 'desc' },
        take: 10,
      }),
      prisma.resgate.findMany({
        where: { vinculo: { empresa_id: req.empresaId } },
        include: { vinculo: { include: { cliente: true } } },
        orderBy: { data_hora: 'desc' },
        take: 10,
      }),
    ]);

  // Junta os dois tipos de evento (marcação/resgate) numa única linha do
  // tempo, ordenada por data — a tabela "Atividades Recentes" do dashboard
  // não distingue a origem, só mostra o que aconteceu de mais recente.
  const atividades = [
    ...marcacoesRecentes.map((m) => ({
      tipo: 'MARCACAO',
      cliente: m.vinculo.cliente.nome,
      dataHora: m.data_hora,
      pontosGerados: m.pontos_gerados,
    })),
    ...resgatesRecentes.map((r) => ({
      tipo: 'RESGATE',
      cliente: r.vinculo.cliente.nome,
      dataHora: r.data_hora,
      saldoDescontado: r.saldo_descontado,
    })),
  ]
    .sort((a, b) => new Date(b.dataHora) - new Date(a.dataHora))
    .slice(0, 10);

  return res.json({ clientesAtivos, campanhasAtivas, marcacoesMes, resgatesMes, atividadesRecentes: atividades });
}));

module.exports = router;
