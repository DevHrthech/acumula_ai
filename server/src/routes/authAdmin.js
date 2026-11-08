const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = require('../prisma');
const asyncHandler = require('../utils/asyncHandler');
const authAdmin = require('../middleware/authAdmin');
const { limiteLogin } = require('../middleware/rateLimiters');

const router = express.Router();

const DURACAO_PADRAO = '8h';
const DURACAO_LEMBRAR = '14d';

// Ver mesmo comentário em authEmpresa.js: garante tempo de resposta
// constante independente do email existir ou não (evita timing side-channel
// pra descobrir emails de admin cadastrados).
const HASH_MORTO = '$2b$12$yM5whqp/vY47JQrnKGy.jO0JMp8m2LLrKw4q3n5Bk.V8fta5MriZy';

router.post('/login', limiteLogin, async (req, res) => {
  const { email, senha, lembrar } = req.body || {};

  if (!email || !senha || typeof email !== 'string' || typeof senha !== 'string' || senha.length > 200) {
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

    // Painel interno com acesso a todas as empresas: sessão curta (o painel
    // guarda o token só na aba aberta). Só com "Lembrar acesso neste
    // dispositivo" (opt-in) o token dura mais e o painel o guarda no navegador.
    // A senha e o e-mail nunca são guardados: o token leva só o id do admin e
    // "Sair" o invalida no servidor (token_valido_desde).
    const token = jwt.sign({ sub: admin.id, tipo: 'admin' }, process.env.JWT_SECRET, {
      expiresIn: lembrar === true ? DURACAO_LEMBRAR : DURACAO_PADRAO,
      algorithm: 'HS256',
    });

    return res.json({ admin: { id: admin.id, nome: admin.nome, email: admin.email }, token });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao fazer login.' });
  }
});

// "Sair do Painel": invalida os tokens emitidos até agora (inclusive o de
// "Lembrar acesso" guardado em outro aparelho).
router.post('/logout', authAdmin, asyncHandler(async (req, res) => {
  await prisma.adminInterno.update({
    where: { id: req.adminId },
    data: { token_valido_desde: new Date() },
  });
  res.json({ ok: true });
}));

module.exports = router;
