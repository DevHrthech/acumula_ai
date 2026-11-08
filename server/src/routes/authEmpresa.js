const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = require('../prisma');
const { gerarCodigoLojaUnico } = require('../utils/codigoLoja');
const cnpjUtil = require('../utils/cnpj');
const { limiteLogin, limiteRegistro } = require('../middleware/rateLimiters');
const { primeiroErroTexto } = require('../utils/validar');
const { FORMAS_PAGAMENTO, VERSAO_TERMOS, DIAS_TRIAL, periodoTrial } = require('../utils/trial');
const asaas = require('../utils/asaas');
const { garantirAssinatura } = require('../utils/assinatura');

const router = express.Router();

const TIPOS_FIDELIDADE = ['MARCACOES', 'PONTOS'];

// Checagem simples de formato — não precisa ser uma regex RFC completa, só
// pegar erros óbvios de digitação antes de gravar (a confirmação de posse
// real do email, se algum dia precisar, é um recurso separado).
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function sanitizarEmpresa(empresa) {
  const { senha_hash, ...resto } = empresa;
  return resto;
}

// Hash "morto" pra rodar bcrypt.compare mesmo quando o email não existe —
// sem isso, a resposta é mais rápida (sem hash real pra comparar) quando o
// email não está cadastrado, e mais lenta quando existe mas a senha está
// errada, dando um timing side-channel pra enumerar emails cadastrados.
const HASH_MORTO = '$2b$12$yM5whqp/vY47JQrnKGy.jO0JMp8m2LLrKw4q3n5Bk.V8fta5MriZy';

function gerarToken(empresa) {
  return jwt.sign({ sub: empresa.id, tipo: 'empresa' }, process.env.JWT_SECRET, {
    expiresIn: '7d',
    algorithm: 'HS256',
  });
}

router.post('/registrar', limiteRegistro, async (req, res) => {
  const {
    nome,
    cnpj,
    email,
    senha,
    descricaoRecompensa,
    categoria,
    tipoFidelidade,
    metaFidelidade,
    planoId,
    formaPagamento,
    aceiteTermos,
  } = req.body || {};

  if (!nome || !cnpj || !email || !senha || !descricaoRecompensa) {
    return res.status(400).json({
      erro: 'Campos obrigatórios: nome, cnpj, email, senha, descricaoRecompensa.',
    });
  }

  if (typeof planoId !== 'string' || !planoId) {
    return res.status(400).json({ erro: 'Escolha um plano.' });
  }
  if (!FORMAS_PAGAMENTO.includes(formaPagamento)) {
    return res.status(400).json({ erro: 'formaPagamento deve ser PIX ou CARTAO_RECORRENTE.' });
  }
  if (aceiteTermos !== true) {
    return res.status(400).json({ erro: 'É preciso aceitar que os pagamentos serão processados via gateway Asaas.' });
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

  try {
    const plano = await prisma.plano.findUnique({ where: { id: planoId } });
    if (!plano || !plano.ativo) {
      return res.status(400).json({ erro: 'Plano indisponível. Escolha outro.' });
    }

    const senhaHash = await bcrypt.hash(senha, 12);
    const codigoLoja = await gerarCodigoLojaUnico(prisma);
    const trial = periodoTrial();

    // Empresa + licença de trial nascem juntas (uma única escrita): o CNPJ é
    // único, então o trial só é concedido uma vez por empresa.
    let empresa = await prisma.empresa.create({
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
        trial_usado_em: new Date(),
        aceite_termos_em: new Date(),
        aceite_termos_versao: VERSAO_TERMOS,
        licencas: {
          create: {
            plano_id: plano.id,
            forma_pagamento: formaPagamento,
            em_trial: true,
            gateway_provedor: 'ASAAS',
            data_inicio: trial.inicio,
            data_vencimento: trial.vencimento,
          },
        },
      },
      include: { licencas: true },
    });

    // Replica a empresa como cliente no Asaas. Se falhar (Asaas fora do ar,
    // sem configuração), o cadastro NÃO é desfeito: asaas_customer_id fica
    // nulo e a replicação é refeita ao gerar a primeira cobrança.
    let asaasSincronizado = false;
    try {
      const asaasId = await asaas.garantirCliente(empresa);
      empresa = await prisma.empresa.update({
        where: { id: empresa.id },
        data: { asaas_customer_id: asaasId },
        include: { licencas: true },
      });
      asaasSincronizado = true;
    } catch (errAsaas) {
      console.error('Falha ao replicar empresa no Asaas:', errAsaas.message);
    }

    // Assinatura mensal no Asaas: a 1ª cobrança vence no dia seguinte ao fim
    // do trial. Mesma regra de falha: não desfaz o cadastro; o admin pode
    // refazer em POST /admin/licencas/:id/assinatura.
    let assinaturaCriada = false;
    if (asaasSincronizado) {
      try {
        await garantirAssinatura(empresa.licencas[0].id);
        assinaturaCriada = true;
      } catch (errAssinatura) {
        console.error('Falha ao criar assinatura no Asaas:', errAssinatura.message);
      }
    }

    const licencaFinal = await prisma.licenca.findUnique({ where: { id: empresa.licencas[0].id } });
    const { licencas, ...dadosEmpresa } = empresa;
    const token = gerarToken(empresa);
    return res.status(201).json({
      empresa: sanitizarEmpresa(dadosEmpresa),
      token,
      licenca: { ...licencaFinal, dias_trial: DIAS_TRIAL },
      asaas_sincronizado: asaasSincronizado,
      assinatura_criada: assinaturaCriada,
    });
  } catch (err) {
    if (err.code === 'P2002') {
      const campo = err.meta?.target?.[0] || 'campo único';
      return res.status(409).json({ erro: `Já existe uma empresa cadastrada com esse ${campo}.` });
    }
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao registrar empresa.' });
  }
});

router.post('/login', limiteLogin, async (req, res) => {
  const { email, senha } = req.body || {};

  if (!email || !senha || typeof email !== 'string' || typeof senha !== 'string' || senha.length > 200) {
    return res.status(400).json({ erro: 'Informe email e senha.' });
  }

  try {
    const empresa = await prisma.empresa.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    const senhaOk = await bcrypt.compare(senha, empresa?.senha_hash || HASH_MORTO);
    if (!empresa || !senhaOk) {
      return res.status(401).json({ erro: 'Email ou senha inválidos.' });
    }

    const token = gerarToken(empresa);
    return res.json({ empresa: sanitizarEmpresa(empresa), token });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao fazer login.' });
  }
});

module.exports = router;
