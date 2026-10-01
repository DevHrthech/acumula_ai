const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = require('../prisma');
const cpfUtil = require('../utils/cpf');
const { limiteLogin, limiteRegistro } = require('../middleware/rateLimiters');

const router = express.Router();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function sanitizarCliente(cliente) {
  const { senha_hash, ...resto } = cliente;
  return resto;
}

// Hash "morto" pra rodar bcrypt.compare mesmo quando o CPF não existe — ver
// o mesmo raciocínio em authEmpresa.js (evita timing side-channel).
const HASH_MORTO = '$2b$12$yM5whqp/vY47JQrnKGy.jO0JMp8m2LLrKw4q3n5Bk.V8fta5MriZy';

function gerarToken(cliente) {
  return jwt.sign({ sub: cliente.id, tipo: 'cliente' }, process.env.JWT_SECRET, {
    expiresIn: '30d',
    algorithm: 'HS256',
  });
}

router.post('/cadastro', limiteRegistro, async (req, res) => {
  const { nome, cpf, senha, telefone, email } = req.body || {};

  if (!nome || !cpf || !senha || !telefone) {
    return res.status(400).json({
      erro: 'Campos obrigatórios: nome, cpf, senha, telefone.',
    });
  }

  if (!cpfUtil.isValido(cpf)) {
    return res.status(400).json({ erro: 'CPF inválido.' });
  }

  if (senha.length < 8) {
    return res.status(400).json({ erro: 'A senha deve ter ao menos 8 caracteres.' });
  }

  if (email && !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ erro: 'Email inválido.' });
  }

  const limitesTexto = { nome: 150, telefone: 20, email: 150 };
  for (const [campo, limite] of Object.entries(limitesTexto)) {
    const valor = { nome, telefone, email }[campo];
    if (valor && valor.length > limite) {
      return res.status(400).json({ erro: `${campo} deve ter no máximo ${limite} caracteres.` });
    }
  }

  try {
    const senhaHash = await bcrypt.hash(senha, 12);

    const cliente = await prisma.cliente.create({
      data: {
        nome,
        cpf: cpfUtil.limpar(cpf),
        senha_hash: senhaHash,
        telefone,
        email: email ? email.toLowerCase().trim() : null,
      },
    });

    const token = gerarToken(cliente);
    return res.status(201).json({ cliente: sanitizarCliente(cliente), token });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ erro: 'Já existe uma conta cadastrada com esse CPF.' });
    }
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao cadastrar.' });
  }
});

router.post('/login', limiteLogin, async (req, res) => {
  const { cpf, senha } = req.body || {};

  if (!cpf || !senha) {
    return res.status(400).json({ erro: 'Informe CPF e senha.' });
  }

  try {
    const cliente = await prisma.cliente.findUnique({
      where: { cpf: cpfUtil.limpar(cpf) },
    });

    const senhaOk = await bcrypt.compare(senha, cliente?.senha_hash || HASH_MORTO);
    if (!cliente || !senhaOk) {
      return res.status(401).json({ erro: 'CPF ou senha inválidos.' });
    }

    const token = gerarToken(cliente);
    return res.json({ cliente: sanitizarCliente(cliente), token });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao fazer login.' });
  }
});

module.exports = router;
