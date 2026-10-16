const express = require('express');
const bcrypt = require('bcryptjs');

const prisma = require('../prisma');
const authCliente = require('../middleware/authCliente');
const { limiteLogin } = require('../middleware/rateLimiters');
const asyncHandler = require('../utils/asyncHandler');
const { campanhasVigentes, saldoCampanha } = require('../utils/fidelidade');
const { hojeBrasilia } = require('../utils/data');
const { verificarIdToken } = require('../utils/google');
const { primeiroErroTexto } = require('../utils/validar');

const router = express.Router();

function sanitizarCliente(cliente) {
  const { senha_hash, reset_codigo_hash, reset_expira_em, reset_tentativas, token_valido_desde, google_id, ...resto } = cliente;
  // `conta_google`: o app oferece "confirmar com o Google" ao excluir a conta.
  return { ...resto, conta_google: Boolean(google_id) };
}

// Campos públicos da empresa que o cliente final pode ver — nunca email,
// cnpj ou qualquer dado interno de gestão (planos/licenças/contratos).
function empresaPublica(empresa) {
  const {
    id, nome, categoria, tipo_fidelidade, meta_fidelidade, descricao_recompensa,
    icone_url, logo_qrcode_url, logo_promocao_url, cor_principal, cor_destaque,
    nome_programa, mensagem_boas_vindas, mensagem_resgate, texto_botao_resgate,
  } = empresa;
  return {
    id, nome, categoria, tipo_fidelidade, meta_fidelidade, descricao_recompensa,
    icone_url, logo_qrcode_url, logo_promocao_url, cor_principal, cor_destaque,
    nome_programa, mensagem_boas_vindas, mensagem_resgate, texto_botao_resgate,
  };
}

router.get('/me', authCliente, asyncHandler(async (req, res) => {
  const cliente = await prisma.cliente.findUnique({ where: { id: req.clienteId } });

  if (!cliente) {
    return res.status(404).json({ erro: 'Cliente não encontrado.' });
  }

  return res.json(sanitizarCliente(cliente));
}));

// E-mail de recuperação de senha. null/'' remove o e-mail cadastrado.
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.patch('/me', authCliente, asyncHandler(async (req, res) => {
  const { email } = req.body || {};

  if (email === undefined) {
    return res.status(400).json({ erro: 'Informe o e-mail (ou vazio para remover).' });
  }

  const novoEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

  if (novoEmail && (novoEmail.length > 150 || !EMAIL_REGEX.test(novoEmail))) {
    return res.status(400).json({ erro: 'E-mail inválido.' });
  }

  const cliente = await prisma.cliente.update({
    where: { id: req.clienteId },
    data: { email: novoEmail || null },
  });

  return res.json(sanitizarCliente(cliente));
}));

router.get('/me/vinculos', authCliente, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { cliente_id: req.clienteId },
    include: { empresa: true },
    orderBy: { data_vinculo: 'desc' },
  });

  return res.json(vinculos.map((v) => ({
    id: v.id,
    saldoAtual: v.saldo_atual,
    dataVinculo: v.data_vinculo,
    empresa: empresaPublica(v.empresa),
  })));
}));

router.post('/me/vinculos', authCliente, asyncHandler(async (req, res) => {
  const { codigoLoja } = req.body || {};

  if (!codigoLoja || typeof codigoLoja !== 'string') {
    return res.status(400).json({ erro: 'Informe o código da loja.' });
  }

  // Códigos são gerados sem espaços/traços (ver utils/codigoLoja.js), mas o
  // cliente pode digitar com traço/espaço/minúsculo por engano — normaliza
  // antes de comparar em vez de rejeitar o formato.
  const codigoNormalizado = codigoLoja.toUpperCase().replace(/[^A-Z0-9]/g, '');

  const empresa = await prisma.empresa.findUnique({ where: { codigo_loja: codigoNormalizado } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Loja não encontrada para esse código.' });
  }

  const existente = await prisma.vinculo.findUnique({
    where: { cliente_id_empresa_id: { cliente_id: req.clienteId, empresa_id: empresa.id } },
  });
  if (existente) {
    return res.status(409).json({ erro: 'Você já está vinculado a esta loja.' });
  }

  const vinculo = await prisma.vinculo.create({
    data: { cliente_id: req.clienteId, empresa_id: empresa.id },
  });

  return res.status(201).json({
    id: vinculo.id,
    saldoAtual: vinculo.saldo_atual,
    dataVinculo: vinculo.data_vinculo,
    empresa: empresaPublica(empresa),
  });
}));

// Cartões de campanha: cada campanha ativa (e dentro da validade) das lojas em
// que o cliente está vinculado vira um cartão próprio, com progresso à parte
// do cartão contínuo da loja.
router.get('/me/campanhas', authCliente, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { cliente_id: req.clienteId },
    include: { empresa: true },
  });

  const cartoes = [];
  for (const v of vinculos) {
    const campanhas = await campanhasVigentes(v.empresa_id);
    const saldos = await Promise.all(campanhas.map((c) => saldoCampanha(v.id, c.id, v.empresa.tipo_fidelidade)));
    campanhas.forEach((c, i) => {
      cartoes.push({
        id: c.id,
        nome: c.nome,
        descricao: c.descricao,
        meta: c.meta,
        dataInicio: c.data_inicio,
        dataValidade: c.data_validade,
        saldoAtual: saldos[i],
        empresa: empresaPublica(v.empresa),
      });
    });
  }

  cartoes.sort((a, b) => new Date(a.dataValidade) - new Date(b.dataValidade));
  return res.json(cartoes);
}));

// Promoções = avisos/posts das lojas vinculadas (sem cartão, sem marcação).
router.get('/me/promocoes', authCliente, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { cliente_id: req.clienteId },
    select: { empresa_id: true },
  });
  const empresaIds = vinculos.map((v) => v.empresa_id);
  if (empresaIds.length === 0) {
    return res.json([]);
  }

  const hoje = hojeBrasilia();
  const promocoes = await prisma.promocao.findMany({
    where: {
      empresa_id: { in: empresaIds },
      status: 'ATIVA',
      // Dentro do período: já iniciada (sem início = desde o cadastro) e
      // não vencida (sem fim = sem data limite).
      AND: [
        { OR: [{ data_inicio: null }, { data_inicio: { lte: hoje } }] },
        { OR: [{ data_validade: null }, { data_validade: { gte: hoje } }] },
      ],
    },
    include: { empresa: true },
    orderBy: { created_at: 'desc' },
  });

  return res.json(promocoes.map((p) => ({
    id: p.id,
    titulo: p.titulo,
    descricao: p.descricao,
    dataInicio: p.data_inicio,
    dataValidade: p.data_validade,
    createdAt: p.created_at,
    empresa: empresaPublica(p.empresa),
  })));
}));

// Estatísticas agregadas pra tela Perfil — histórico completo, não só o
// saldo atual (que zera/desconta ao resgatar). Marcações de campanha são
// cópias da mesma compra já contada no cartão da loja, então ficam de fora.
router.get('/me/resumo', authCliente, asyncHandler(async (req, res) => {
  const [totalMarcacoes, totalResgates, vinculos] = await Promise.all([
    prisma.marcacao.count({ where: { vinculo: { cliente_id: req.clienteId }, campanha_id: null } }),
    prisma.resgate.count({ where: { vinculo: { cliente_id: req.clienteId } } }),
    prisma.vinculo.findMany({ where: { cliente_id: req.clienteId }, select: { saldo_atual: true } }),
  ]);

  const saldoTotal = vinculos.reduce((acc, v) => acc + v.saldo_atual, 0);

  return res.json({ saldoTotal, totalMarcacoes, totalResgates });
}));

// Pedido de validação de compra (com ou sem cupom fiscal) — cai na fila da
// tela "Aprovação" da loja (ver docs/MECANICA_FIDELIDADE.md seção 9).
router.post('/me/solicitacoes', authCliente, asyncHandler(async (req, res) => {
  const { empresaId, cupomFiscal } = req.body || {};

  if (!empresaId || typeof empresaId !== 'string') {
    return res.status(400).json({ erro: 'Informe a loja (empresaId).' });
  }
  const erroTexto = primeiroErroTexto({ cupomFiscal: [cupomFiscal, { max: 50 }] });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
  }
  const cupom = cupomFiscal ? cupomFiscal.trim() : '';

  const vinculo = await prisma.vinculo.findUnique({
    where: { cliente_id_empresa_id: { cliente_id: req.clienteId, empresa_id: empresaId } },
  });
  if (!vinculo) {
    return res.status(404).json({ erro: 'Você não está vinculado a esta loja.' });
  }

  // Anti-spam: um pedido em aberto por loja, e o mesmo cupom fiscal não pode
  // ser usado em dois pedidos (pendente ou já aprovado) na mesma loja.
  const pendente = await prisma.solicitacaoMarcacao.findFirst({
    where: { vinculo_id: vinculo.id, status: 'PENDENTE' },
  });
  if (pendente) {
    return res.status(409).json({ erro: 'Você já tem uma solicitação aguardando validação nesta loja.' });
  }
  if (cupom) {
    const repetido = await prisma.solicitacaoMarcacao.findFirst({
      where: {
        cupom_fiscal: cupom,
        status: { in: ['PENDENTE', 'APROVADA'] },
        vinculo: { empresa_id: empresaId },
      },
    });
    if (repetido) {
      return res.status(409).json({ erro: 'Este cupom fiscal já foi informado.' });
    }
  }

  const solicitacao = await prisma.solicitacaoMarcacao.create({
    data: { vinculo_id: vinculo.id, cupom_fiscal: cupom || null },
  });

  return res.status(201).json({
    id: solicitacao.id,
    status: solicitacao.status,
    createdAt: solicitacao.created_at,
  });
}));

router.patch('/me/preferencias', authCliente, asyncHandler(async (req, res) => {
  const { notificacoesPush, notificacoesEmail, loginBiometrico } = req.body || {};

  const dados = {};
  if (typeof notificacoesPush === 'boolean') dados.notificacoes_push = notificacoesPush;
  if (typeof notificacoesEmail === 'boolean') dados.notificacoes_email = notificacoesEmail;
  if (typeof loginBiometrico === 'boolean') dados.login_biometrico = loginBiometrico;

  if (Object.keys(dados).length === 0) {
    return res.status(400).json({ erro: 'Informe ao menos uma preferência pra atualizar.' });
  }

  const cliente = await prisma.cliente.update({ where: { id: req.clienteId }, data: dados });
  return res.json(sanitizarCliente(cliente));
}));

// Histórico recente do cliente: marcações, resgates e solicitações (com o
// status que a loja deu) de todas as lojas vinculadas — alimenta a tela de
// atividades aberta pelo sino no app.
router.get('/me/atividades', authCliente, asyncHandler(async (req, res) => {
  const vinculos = await prisma.vinculo.findMany({
    where: { cliente_id: req.clienteId },
    select: { id: true, empresa: { select: { nome: true } } },
  });
  const lojaPorVinculo = new Map(vinculos.map((v) => [v.id, v.empresa.nome]));
  const ids = [...lojaPorVinculo.keys()];

  if (ids.length === 0) {
    return res.json([]);
  }

  const [marcacoes, resgates, solicitacoes] = await Promise.all([
    prisma.marcacao.findMany({ where: { vinculo_id: { in: ids }, campanha_id: null }, orderBy: { data_hora: 'desc' }, take: 30 }),
    prisma.resgate.findMany({ where: { vinculo_id: { in: ids } }, orderBy: { data_hora: 'desc' }, take: 30 }),
    prisma.solicitacaoMarcacao.findMany({ where: { vinculo_id: { in: ids } }, orderBy: { created_at: 'desc' }, take: 30 }),
  ]);

  const itens = [
    ...marcacoes.map((m) => ({
      tipo: 'MARCACAO',
      loja: lojaPorVinculo.get(m.vinculo_id),
      data: m.data_hora,
      pontos: m.pontos_gerados,
    })),
    ...resgates.map((r) => ({
      tipo: 'RESGATE',
      loja: lojaPorVinculo.get(r.vinculo_id),
      data: r.data_hora,
    })),
    ...solicitacoes.map((s) => ({
      tipo: 'SOLICITACAO',
      loja: lojaPorVinculo.get(s.vinculo_id),
      data: s.created_at,
      status: s.status,
    })),
  ];

  itens.sort((a, b) => b.data - a.data);
  return res.json(itens.slice(0, 30));
}));

// Exclusão definitiva da conta (exigida pela política da Google Play e pela
// LGPD): apaga o cliente e tudo que depende dele. Exige a senha como
// confirmação, já que a ação é irreversível.
router.delete('/me', authCliente, limiteLogin, asyncHandler(async (req, res) => {
  const { senha, idToken } = req.body || {};

  if ((!senha || typeof senha !== 'string') && (!idToken || typeof idToken !== 'string')) {
    return res.status(400).json({ erro: 'Confirme com a sua senha (ou com o Google) para excluir a conta.' });
  }

  const cliente = await prisma.cliente.findUnique({ where: { id: req.clienteId } });
  if (!cliente) {
    return res.status(404).json({ erro: 'Cliente não encontrado.' });
  }

  if (idToken) {
    // Conta criada pelo Google não tem senha que o cliente conheça: a
    // confirmação é uma nova autenticação do Google, da MESMA conta vinculada.
    if (!cliente.google_id) {
      return res.status(400).json({ erro: 'Esta conta não está vinculada ao Google. Confirme com a senha.' });
    }
    let perfil;
    try {
      perfil = await verificarIdToken(idToken);
    } catch (err) {
      return res.status(401).json({ erro: 'Não foi possível validar a confirmação do Google.' });
    }
    if (perfil.googleId !== cliente.google_id) {
      return res.status(401).json({ erro: 'Esta não é a conta do Google vinculada ao seu cadastro.' });
    }
  } else {
    const senhaConfere = await bcrypt.compare(senha, cliente.senha_hash);
    if (!senhaConfere) {
      return res.status(401).json({ erro: 'Senha incorreta.' });
    }
  }

  await prisma.$transaction(async (tx) => {
    const vinculos = await tx.vinculo.findMany({ where: { cliente_id: cliente.id }, select: { id: true } });
    const vinculoIds = vinculos.map((v) => v.id);

    await tx.solicitacaoMarcacao.deleteMany({ where: { vinculo_id: { in: vinculoIds } } });
    await tx.marcacao.deleteMany({ where: { vinculo_id: { in: vinculoIds } } });
    await tx.resgate.deleteMany({ where: { vinculo_id: { in: vinculoIds } } });
    await tx.vinculo.deleteMany({ where: { cliente_id: cliente.id } });
    await tx.cliente.delete({ where: { id: cliente.id } });
  });

  return res.json({ ok: true });
}));

module.exports = router;
