const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = require('../prisma');
const { gerarCodigoLojaUnico } = require('../utils/codigoLoja');
const cnpjUtil = require('../utils/cnpj');
const { limiteLogin, limiteRegistro } = require('../middleware/rateLimiters');
const { primeiroErroTexto } = require('../utils/validar');

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
  } = req.body || {};

  if (!nome || !cnpj || !email || !senha || !descricaoRecompensa) {
    return res.status(400).json({
      erro: 'Campos obrigatórios: nome, cnpj, email, senha, descricaoRecompensa.',
    });
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
      },
    });

    const token = gerarToken(empresa);
    return res.status(201).json({ empresa: sanitizarEmpresa(empresa), token });
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
