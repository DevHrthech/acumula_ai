const express = require('express');

const prisma = require('../prisma');
const authAdmin = require('../middleware/authAdmin');
const { statusEfetivo } = require('../utils/licenca');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();
router.use(authAdmin);

function sanitizarEmpresa(empresa) {
  const { senha_hash, ...resto } = empresa;
  return resto;
}

// ---- Empresas -------------------------------------------------------

router.get('/empresas', asyncHandler(async (req, res) => {
  const empresas = await prisma.empresa.findMany({
    orderBy: { created_at: 'desc' },
    include: { licencas: { orderBy: { created_at: 'desc' }, take: 1 } },
  });

  const resultado = empresas.map((empresa) => {
    const [licencaAtual] = empresa.licencas;
    return {
      ...sanitizarEmpresa(empresa),
      licencas: undefined,
      licenca_status: licencaAtual ? statusEfetivo(licencaAtual) : null,
    };
  });

  res.json(resultado);
}));

router.get('/empresas/:id', asyncHandler(async (req, res) => {
  const id = req.params.id;

  const empresa = await prisma.empresa.findUnique({
    where: { id },
    include: {
      licencas: { orderBy: { created_at: 'desc' }, include: { plano: true } },
      contratos: { orderBy: { data_criacao: 'desc' } },
      empresa_pai: true,
      filiais: { orderBy: { nome: 'asc' } },
    },
  });

  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  const licencas = empresa.licencas.map((l) => ({ ...l, status_efetivo: statusEfetivo(l) }));

  res.json({
    ...sanitizarEmpresa(empresa),
    licencas,
    contratos: empresa.contratos,
    empresa_pai: empresa.empresa_pai ? sanitizarEmpresa(empresa.empresa_pai) : null,
    filiais: empresa.filiais.map(sanitizarEmpresa),
  });
}));

// Agrupamento de filiais sob uma matriz — só gestão comercial/cobrança pela
// 2RL (ver docs/SPEC.md seção 8). Não afeta login, configuração nem cartão
// fidelidade da filial, que continuam 100% independentes.
router.patch('/empresas/:id', asyncHandler(async (req, res) => {
  const id = req.params.id;
  const { empresaPaiId } = req.body || {};

  if (empresaPaiId === undefined) {
    return res.status(400).json({ erro: 'Informe empresaPaiId (ou null para desvincular).' });
  }

  const empresa = await prisma.empresa.findUnique({ where: { id } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  if (empresaPaiId !== null) {
    if (empresaPaiId === id) {
      return res.status(400).json({ erro: 'Uma empresa não pode ser matriz de si mesma.' });
    }

    const matriz = await prisma.empresa.findUnique({ where: { id: empresaPaiId } });
    if (!matriz) {
      return res.status(404).json({ erro: 'Empresa-matriz não encontrada.' });
    }

    // Evita o ciclo mais simples (A matriz de B, B matriz de A). Cadeias
    // mais profundas não são checadas por ora — o agrupamento é só de
    // exibição/cobrança, não afeta nenhuma regra de negócio.
    if (matriz.empresa_pai_id === id) {
      return res.status(400).json({ erro: 'Isso criaria um ciclo: a empresa-matriz escolhida já é filial desta empresa.' });
    }
  }

  const atualizada = await prisma.empresa.update({
    where: { id },
    data: { empresa_pai_id: empresaPaiId },
  });

  res.json(sanitizarEmpresa(atualizada));
}));

// ---- Planos -----------------------------------------------------------

router.get('/planos', asyncHandler(async (req, res) => {
  const planos = await prisma.plano.findMany({ orderBy: { created_at: 'asc' } });
  res.json(planos);
}));

router.post('/planos', asyncHandler(async (req, res) => {
  const { nome, valorMensal, descricao } = req.body || {};

  if (!nome || valorMensal === undefined) {
    return res.status(400).json({ erro: 'Campos obrigatórios: nome, valorMensal.' });
  }

  if (typeof valorMensal !== 'number' || !Number.isFinite(valorMensal) || valorMensal <= 0) {
    return res.status(400).json({ erro: 'valorMensal deve ser um número positivo.' });
  }

  const plano = await prisma.plano.create({
    data: { nome, valor_mensal: valorMensal, descricao: descricao || null },
  });

  res.status(201).json(plano);
}));

// ---- Licenças -----------------------------------------------------------

router.post('/empresas/:id/licencas', asyncHandler(async (req, res) => {
  const empresaId = req.params.id;
  const { planoId, dataInicio, dataVencimento, diasTolerancia } = req.body || {};

  if (!planoId || !dataInicio || !dataVencimento) {
    return res.status(400).json({ erro: 'Campos obrigatórios: planoId, dataInicio, dataVencimento.' });
  }

  const inicio = new Date(dataInicio);
  const vencimento = new Date(dataVencimento);
  if (Number.isNaN(inicio.getTime()) || Number.isNaN(vencimento.getTime())) {
    return res.status(400).json({ erro: 'dataInicio/dataVencimento inválidas.' });
  }

  if (diasTolerancia !== undefined && (!Number.isInteger(diasTolerancia) || diasTolerancia < 0)) {
    return res.status(400).json({ erro: 'diasTolerancia deve ser um inteiro >= 0.' });
  }

  const empresa = await prisma.empresa.findUnique({ where: { id: empresaId } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  const plano = await prisma.plano.findUnique({ where: { id: planoId } });
  if (!plano) {
    return res.status(404).json({ erro: 'Plano não encontrado.' });
  }

  const licenca = await prisma.licenca.create({
    data: {
      empresa_id: empresaId,
      plano_id: planoId,
      data_inicio: inicio,
      data_vencimento: vencimento,
      dias_tolerancia: diasTolerancia ?? 5,
    },
  });

  res.status(201).json({ ...licenca, status_efetivo: statusEfetivo(licenca) });
}));

router.patch('/licencas/:id', asyncHandler(async (req, res) => {
  const id = req.params.id;
  const { status, dataVencimento, diasTolerancia } = req.body || {};

  const licencaAtual = await prisma.licenca.findUnique({ where: { id } });
  if (!licencaAtual) {
    return res.status(404).json({ erro: 'Licença não encontrada.' });
  }

  if (status && !['ATIVA', 'INADIMPLENTE', 'BLOQUEADA', 'CANCELADA'].includes(status)) {
    return res.status(400).json({ erro: 'Status inválido.' });
  }

  let novoVencimento;
  if (dataVencimento) {
    novoVencimento = new Date(dataVencimento);
    if (Number.isNaN(novoVencimento.getTime())) {
      return res.status(400).json({ erro: 'dataVencimento inválida.' });
    }
  }

  if (diasTolerancia !== undefined && (!Number.isInteger(diasTolerancia) || diasTolerancia < 0)) {
    return res.status(400).json({ erro: 'diasTolerancia deve ser um inteiro >= 0.' });
  }

  const licenca = await prisma.licenca.update({
    where: { id },
    data: {
      ...(status && { status }),
      ...(novoVencimento && { data_vencimento: novoVencimento }),
      ...(diasTolerancia !== undefined && { dias_tolerancia: diasTolerancia }),
    },
  });

  res.json({ ...licenca, status_efetivo: statusEfetivo(licenca) });
}));

// ---- Contratos ----------------------------------------------------------

router.post('/empresas/:id/contratos', asyncHandler(async (req, res) => {
  const empresaId = req.params.id;
  const { licencaId } = req.body || {};

  const empresa = await prisma.empresa.findUnique({ where: { id: empresaId } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  if (licencaId) {
    const licenca = await prisma.licenca.findUnique({ where: { id: licencaId } });
    if (!licenca || licenca.empresa_id !== empresaId) {
      return res.status(400).json({ erro: 'licencaId não pertence a essa empresa.' });
    }
  }

  const contrato = await prisma.contrato.create({
    data: { empresa_id: empresaId, licenca_id: licencaId || null },
  });

  res.status(201).json(contrato);
}));

router.patch('/contratos/:id', asyncHandler(async (req, res) => {
  const id = req.params.id;
  const { status, documentoUrl, assinaturaProvedor, assinaturaId, dataAssinatura } = req.body || {};

  const contratoAtual = await prisma.contrato.findUnique({ where: { id } });
  if (!contratoAtual) {
    return res.status(404).json({ erro: 'Contrato não encontrado.' });
  }

  if (status && !['RASCUNHO', 'AGUARDANDO_ASSINATURA', 'ASSINADO', 'CANCELADO'].includes(status)) {
    return res.status(400).json({ erro: 'Status inválido.' });
  }

  let novaDataAssinatura;
  if (dataAssinatura) {
    novaDataAssinatura = new Date(dataAssinatura);
    if (Number.isNaN(novaDataAssinatura.getTime())) {
      return res.status(400).json({ erro: 'dataAssinatura inválida.' });
    }
  }

  const contrato = await prisma.contrato.update({
    where: { id },
    data: {
      ...(status && { status }),
      ...(documentoUrl !== undefined && { documento_url: documentoUrl }),
      ...(assinaturaProvedor !== undefined && { assinatura_provedor: assinaturaProvedor }),
      ...(assinaturaId !== undefined && { assinatura_id: assinaturaId }),
      ...(novaDataAssinatura && { data_assinatura: novaDataAssinatura }),
    },
  });

  res.json(contrato);
}));

module.exports = router;
