const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = require('../prisma');
const { limiteLogin } = require('../middleware/rateLimiters');

const router = express.Router();

// Ver mesmo comentário em authEmpresa.js: garante tempo de resposta
// constante independente do email existir ou não (evita timing side-channel
// pra descobrir emails de admin cadastrados).
const HASH_MORTO = '$2b$12$yM5whqp/vY47JQrnKGy.jO0JMp8m2LLrKw4q3n5Bk.V8fta5MriZy';

router.post('/login', limiteLogin, async (req, res) => {
  const { email, senha } = req.body || {};

  if (!email || !senha) {
    return res.status(400).json({ erro: 'Informe email e senha.' });
  }

  try {
    const admin = await prisma.adminInterno.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    const senhaOk = await bcrypt.compare(senha, admin?.senha_hash || HASH_MORTO);
    if (!admin || !senhaOk) {
      return res.status(401).json({ erro: 'Email ou senha inválidos.' });
    }

    const token = jwt.sign({ sub: admin.id, tipo: 'admin' }, process.env.JWT_SECRET, {
      expiresIn: '7d',
      algorithm: 'HS256',
    });

    return res.json({ admin: { id: admin.id, nome: admin.nome, email: admin.email }, token });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao fazer login.' });
  }
});

module.exports = router;
