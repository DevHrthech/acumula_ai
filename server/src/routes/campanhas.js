const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');
const { hojeBrasilia, paraData } = require('../utils/data');
const { primeiroErroTexto } = require('../utils/validar');

const router = express.Router();

// O status gravado (ATIVA/EXPIRADA) só muda quando a empresa encerra a
// campanha à mão. `status_efetivo` acrescenta o vencimento por data, pra o
// painel não mostrar como "Ativa" uma campanha cujo prazo já passou.
function comStatusEfetivo(campanha, hoje = hojeBrasilia()) {
  const vencida = campanha.data_validade < hoje;
  const agendada = campanha.data_inicio ? campanha.data_inicio > hoje : false;
  let statusEfetivo = campanha.status;
  if (campanha.status === 'ATIVA') {
    if (vencida) statusEfetivo = 'VENCIDA';
    else if (agendada) statusEfetivo = 'AGENDADA';
  }
  return { ...campanha, status_efetivo: statusEfetivo, vencida };
}

router.get('/', authEmpresa, asyncHandler(async (req, res) => {
  const campanhas = await prisma.campanha.findMany({
    where: { empresa_id: req.empresaId },
    orderBy: { created_at: 'desc' },
  });
  const hoje = hojeBrasilia();
  return res.json(campanhas.map((c) => comStatusEfetivo(c, hoje)));
}));

router.post('/', authEmpresa, asyncHandler(async (req, res) => {
  const { nome, descricao, meta, dataValidade, dataInicio } = req.body || {};

  if (!nome || !meta || !dataValidade) {
    return res.status(400).json({ erro: 'Campos obrigatórios: nome, meta, dataValidade.' });
  }
  if (!Number.isInteger(meta) || meta < 1 || meta > 100000) {
    return res.status(400).json({ erro: 'meta deve ser um inteiro entre 1 e 100000.' });
  }
  const erroTexto = primeiroErroTexto({
    nome: [nome, { max: 150, obrigatorio: true }],
    descricao: [descricao, { max: 255 }],
  });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
  }

  const hoje = hojeBrasilia();
  const validade = paraData(dataValidade);
  if (!validade) {
    return res.status(400).json({ erro: 'dataValidade inválida.' });
  }
  if (validade < hoje) {
    return res.status(400).json({ erro: 'A validade não pode ser uma data que já passou.' });
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
  if (inicio > validade) {
    return res.status(400).json({ erro: 'dataInicio não pode ser depois da validade.' });
  }

  const campanha = await prisma.campanha.create({
    data: {
      empresa_id: req.empresaId,
      nome: nome.trim(),
      descricao: descricao ? descricao.trim() : null,
      meta,
      data_inicio: inicio,
      data_validade: validade,
    },
  });
  return res.status(201).json(comStatusEfetivo(campanha, hoje));
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
  return res.json(comStatusEfetivo(atualizada));
}));

module.exports = router;
module.exports.comStatusEfetivo = comStatusEfetivo;
