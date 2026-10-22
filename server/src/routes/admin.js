const express = require('express');

const prisma = require('../prisma');
const authAdmin = require('../middleware/authAdmin');
const { statusEfetivo } = require('../utils/licenca');
const asyncHandler = require('../utils/asyncHandler');
const bcrypt = require('bcryptjs');
const cnpjUtil = require('../utils/cnpj');
const { gerarCodigoLojaUnico } = require('../utils/codigoLoja');
const { primeiroErroTexto } = require('../utils/validar');
const { paraData } = require('../utils/data');

const router = express.Router();
router.use(authAdmin);

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const TIPOS_FIDELIDADE = ['MARCACOES', 'PONTOS'];

function sanitizarEmpresa(empresa) {
  const { senha_hash, ...resto } = empresa;
  return resto;
}

// ---- Empresas -------------------------------------------------------

// Dados do admin logado — o painel usa pra retomar a sessão ao recarregar a página.
router.get('/me', asyncHandler(async (req, res) => {
  const admin = await prisma.adminInterno.findUnique({
    where: { id: req.adminId },
    select: { id: true, nome: true, email: true },
  });
  if (!admin) {
    return res.status(401).json({ erro: 'Administrador não encontrado.' });
  }
  res.json(admin);
}));

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

// Cadastro de empresa feito pela equipe 2RL (a empresa também pode se
// cadastrar sozinha em /auth/empresa/registrar). Mesmas validações do
// cadastro público; a senha informada aqui é a inicial, entregue à empresa.
router.post('/empresas', asyncHandler(async (req, res) => {
  const {
    nome, cnpj, email, senha, descricaoRecompensa,
    categoria, tipoFidelidade, metaFidelidade, empresaPaiId,
  } = req.body || {};

  if (!nome || !cnpj || !email || !senha || !descricaoRecompensa) {
    return res.status(400).json({ erro: 'Campos obrigatórios: nome, cnpj, email, senha, descricaoRecompensa.' });
  }
  const erroTexto = primeiroErroTexto({
    nome: [nome, { max: 150, obrigatorio: true }],
    email: [email, { max: 150, obrigatorio: true }],
    senha: [senha, { max: 200, obrigatorio: true }],
    categoria: [categoria, { max: 100 }],
    descricaoRecompensa: [descricaoRecompensa, { max: 255, obrigatorio: true }],
  });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
  }
  if (!cnpjUtil.isValido(cnpj)) {
    return res.status(400).json({ erro: 'CNPJ inválido.' });
  }
  if (!EMAIL_REGEX.test(email)) {
    return res.status(400).json({ erro: 'Email inválido.' });
  }
  if (senha.length < 8) {
    return res.status(400).json({ erro: 'A senha deve ter ao menos 8 caracteres.' });
  }
  if (tipoFidelidade && !TIPOS_FIDELIDADE.includes(tipoFidelidade)) {
    return res.status(400).json({ erro: 'tipoFidelidade deve ser MARCACOES ou PONTOS.' });
  }
  if (metaFidelidade !== undefined && (!Number.isInteger(metaFidelidade) || metaFidelidade < 1 || metaFidelidade > 1000)) {
    return res.status(400).json({ erro: 'metaFidelidade deve ser um inteiro entre 1 e 1000.' });
  }
  if (empresaPaiId) {
    const matriz = await prisma.empresa.findUnique({ where: { id: empresaPaiId } });
    if (!matriz) {
      return res.status(404).json({ erro: 'Empresa-matriz não encontrada.' });
    }
  }

  try {
    const senhaHash = await bcrypt.hash(senha, 12);
    const codigoLoja = await gerarCodigoLojaUnico(prisma);
    const empresa = await prisma.empresa.create({
      data: {
        nome,
        cnpj: cnpjUtil.formatar(cnpj),
        email: email.toLowerCase().trim(),
        senha_hash: senhaHash,
        codigo_loja: codigoLoja,
        categoria: categoria || null,
        tipo_fidelidade: tipoFidelidade || 'MARCACOES',
        meta_fidelidade: metaFidelidade || 10,
        descricao_recompensa: descricaoRecompensa,
        empresa_pai_id: empresaPaiId || null,
      },
    });
    return res.status(201).json(sanitizarEmpresa(empresa));
  } catch (err) {
    if (err.code === 'P2002') {
      const campo = err.meta?.target?.[0] || 'campo único';
      return res.status(409).json({ erro: `Já existe uma empresa cadastrada com esse ${campo}.` });
    }
    throw err;
  }
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
//
// Também edita o cadastro da empresa (nome, CNPJ, e-mail, categoria,
// recompensa, meta) e redefine a senha de acesso. A mecânica de fidelidade
// (marcações/pontos) fica fixa após o cadastro, então não é editável aqui.
router.patch('/empresas/:id', asyncHandler(async (req, res) => {
  const id = req.params.id;
  const {
    empresaPaiId, nome, cnpj, email, categoria,
    descricaoRecompensa, metaFidelidade, novaSenha,
  } = req.body || {};

  const algumCampo = [empresaPaiId, nome, cnpj, email, categoria, descricaoRecompensa, metaFidelidade, novaSenha]
    .some((v) => v !== undefined);
  if (!algumCampo) {
    return res.status(400).json({ erro: 'Nenhum campo para atualizar.' });
  }

  const empresa = await prisma.empresa.findUnique({ where: { id } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  const dados = {};
  if (nome !== undefined) {
    if (typeof nome !== 'string' || !nome.trim() || nome.length > 150) {
      return res.status(400).json({ erro: 'nome inválido (até 150 caracteres).' });
    }
    dados.nome = nome.trim();
  }
  if (cnpj !== undefined) {
    if (!cnpjUtil.isValido(cnpj)) {
      return res.status(400).json({ erro: 'CNPJ inválido.' });
    }
    dados.cnpj = cnpjUtil.formatar(cnpj);
  }
  if (email !== undefined) {
    if (typeof email !== 'string' || !EMAIL_REGEX.test(email) || email.length > 150) {
      return res.status(400).json({ erro: 'Email inválido.' });
    }
    dados.email = email.toLowerCase().trim();
  }
  if (categoria !== undefined) {
    if (categoria !== null && String(categoria).length > 100) {
      return res.status(400).json({ erro: 'categoria deve ter no máximo 100 caracteres.' });
    }
    dados.categoria = categoria ? String(categoria).trim() : null;
  }
  if (descricaoRecompensa !== undefined) {
    if (typeof descricaoRecompensa !== 'string' || !descricaoRecompensa.trim() || descricaoRecompensa.length > 255) {
      return res.status(400).json({ erro: 'descricaoRecompensa inválida (até 255 caracteres).' });
    }
    dados.descricao_recompensa = descricaoRecompensa.trim();
  }
  if (metaFidelidade !== undefined) {
    if (!Number.isInteger(metaFidelidade) || metaFidelidade < 1 || metaFidelidade > 1000) {
      return res.status(400).json({ erro: 'metaFidelidade deve ser um inteiro entre 1 e 1000.' });
    }
    dados.meta_fidelidade = metaFidelidade;
  }
  if (novaSenha !== undefined) {
    if (typeof novaSenha !== 'string' || novaSenha.length < 8) {
      return res.status(400).json({ erro: 'A senha deve ter ao menos 8 caracteres.' });
    }
    dados.senha_hash = await bcrypt.hash(novaSenha, 12);
  }

  if (empresaPaiId !== undefined && empresaPaiId !== null) {
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

  if (empresaPaiId !== undefined) {
    dados.empresa_pai_id = empresaPaiId;
  }

  try {
    const atualizada = await prisma.empresa.update({ where: { id }, data: dados });
    res.json(sanitizarEmpresa(atualizada));
  } catch (err) {
    if (err.code === 'P2002') {
      const campo = err.meta?.target?.[0] || 'campo único';
      return res.status(409).json({ erro: `Já existe uma empresa cadastrada com esse ${campo}.` });
    }
    throw err;
  }
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
  const erroPlano = primeiroErroTexto({
    nome: [nome, { max: 100, obrigatorio: true }],
    descricao: [descricao, { max: 255 }],
  });
  if (erroPlano) {
    return res.status(400).json({ erro: erroPlano });
  }

  if (typeof valorMensal !== 'number' || !Number.isFinite(valorMensal) || valorMensal <= 0) {
    return res.status(400).json({ erro: 'valorMensal deve ser um número positivo.' });
  }

  const plano = await prisma.plano.create({
    data: { nome: nome.trim(), valor_mensal: valorMensal, descricao: descricao || null },
  });

  res.status(201).json(plano);
}));

// Editar plano / ativar-desativar. Plano desativado some das opções para novas
// licenças, mas continua valendo para as licenças que já usam ele.
router.patch('/planos/:id', asyncHandler(async (req, res) => {
  const { nome, valorMensal, descricao, ativo } = req.body || {};

  const atual = await prisma.plano.findUnique({ where: { id: req.params.id } });
  if (!atual) {
    return res.status(404).json({ erro: 'Plano não encontrado.' });
  }
  if (nome !== undefined && (typeof nome !== 'string' || !nome.trim() || nome.length > 100)) {
    return res.status(400).json({ erro: 'nome inválido (até 100 caracteres).' });
  }
  if (valorMensal !== undefined && (typeof valorMensal !== 'number' || !Number.isFinite(valorMensal) || valorMensal <= 0)) {
    return res.status(400).json({ erro: 'valorMensal deve ser um número positivo.' });
  }
  if (descricao !== undefined && descricao !== null && String(descricao).length > 255) {
    return res.status(400).json({ erro: 'descricao deve ter no máximo 255 caracteres.' });
  }
  if (ativo !== undefined && typeof ativo !== 'boolean') {
    return res.status(400).json({ erro: 'ativo deve ser true ou false.' });
  }

  const plano = await prisma.plano.update({
    where: { id: req.params.id },
    data: {
      ...(nome !== undefined && { nome: nome.trim() }),
      ...(valorMensal !== undefined && { valor_mensal: valorMensal }),
      ...(descricao !== undefined && { descricao: descricao || null }),
      ...(ativo !== undefined && { ativo }),
    },
  });
  res.json(plano);
}));

// ---- Licenças -----------------------------------------------------------

router.post('/empresas/:id/licencas', asyncHandler(async (req, res) => {
  const empresaId = req.params.id;
  const { planoId, dataInicio, dataVencimento, diasTolerancia } = req.body || {};

  if (!planoId || !dataInicio || !dataVencimento) {
    return res.status(400).json({ erro: 'Campos obrigatórios: planoId, dataInicio, dataVencimento.' });
  }

  const inicio = paraData(dataInicio);
  const vencimento = paraData(dataVencimento);
  if (!inicio || !vencimento) {
    return res.status(400).json({ erro: 'dataInicio/dataVencimento inválidas.' });
  }
  if (inicio > vencimento) {
    return res.status(400).json({ erro: 'dataInicio não pode ser depois do vencimento.' });
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
  if (!plano.ativo) {
    return res.status(400).json({ erro: 'Esse plano está desativado e não pode ser usado em novas licenças.' });
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
    novoVencimento = paraData(dataVencimento);
    if (!novoVencimento) {
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
