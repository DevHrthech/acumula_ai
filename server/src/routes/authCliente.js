const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const prisma = require('../prisma');
const cpfUtil = require('../utils/cpf');
const { enviarEmail } = require('../utils/mailer');
const { verificarIdToken } = require('../utils/google');
const { limiteLogin, limiteRegistro, limiteRecuperacao } = require('../middleware/rateLimiters');
const { primeiroErroTexto } = require('../utils/validar');

const router = express.Router();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function sanitizarCliente(cliente) {
  const { senha_hash, reset_codigo_hash, reset_expira_em, reset_tentativas, token_valido_desde, google_id, ...resto } = cliente;
  // `conta_google`: o app usa pra oferecer "confirmar com o Google" ao excluir a conta.
  return { ...resto, conta_google: Boolean(google_id) };
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

  const erroTexto = primeiroErroTexto({
    nome: [nome, { max: 150, obrigatorio: true }],
    telefone: [telefone, { max: 20, obrigatorio: true }],
    email: [email, { max: 150 }],
    senha: [senha, { max: 200, obrigatorio: true }],
  });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
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

  if (!cpf || !senha || typeof senha !== 'string' || senha.length > 200) {
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

// ---- Recuperação de senha -------------------------------------------------
// Código de 6 dígitos enviado ao e-mail cadastrado (o e-mail é opcional no
// cadastro — quem não informou precisa falar com o suporte). A resposta é a
// mesma exista ou não a conta, pra não revelar quais CPFs estão cadastrados.
const VALIDADE_CODIGO_MIN = 15;
const MAX_TENTATIVAS_CODIGO = 5;
const INTERVALO_MIN_ENTRE_ENVIOS_S = 60;
const MENSAGEM_PADRAO = 'Se houver uma conta com esse CPF e um e-mail cadastrado, enviamos um código de 6 dígitos para esse e-mail.';

router.post('/esqueci-senha', limiteRecuperacao, async (req, res) => {
  const { cpf } = req.body || {};

  if (!cpf || !cpfUtil.isValido(cpf)) {
    return res.status(400).json({ erro: 'Informe um CPF válido.' });
  }

  try {
    const cliente = await prisma.cliente.findUnique({ where: { cpf: cpfUtil.limpar(cpf) } });

    if (cliente && cliente.email) {
      const emitidoEm = cliente.reset_expira_em
        ? cliente.reset_expira_em.getTime() - VALIDADE_CODIGO_MIN * 60 * 1000
        : 0;
      const recente = Date.now() - emitidoEm < INTERVALO_MIN_ENTRE_ENVIOS_S * 1000;

      if (!recente) {
        const codigo = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
        await prisma.cliente.update({
          where: { id: cliente.id },
          data: {
            reset_codigo_hash: await bcrypt.hash(codigo, 10),
            reset_expira_em: new Date(Date.now() + VALIDADE_CODIGO_MIN * 60 * 1000),
            reset_tentativas: 0,
          },
        });

        try {
          await enviarEmail({
            para: cliente.email,
            assunto: 'Seu código para redefinir a senha — Acumula Aí',
            texto: [
              `Olá, ${cliente.nome.split(' ')[0]}!`,
              '',
              `Seu código para redefinir a senha do Acumula Aí é: ${codigo}`,
              '',
              `Ele vale por ${VALIDADE_CODIGO_MIN} minutos. Se você não pediu isso, pode ignorar este e-mail — sua senha continua a mesma.`,
            ].join('\n'),
          });
        } catch (err) {
          console.error('Falha ao enviar e-mail de recuperação:', err.message);
        }
      }
    }

    return res.json({ ok: true, mensagem: MENSAGEM_PADRAO });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao processar o pedido.' });
  }
});

router.post('/redefinir-senha', limiteLogin, async (req, res) => {
  const { cpf, codigo, novaSenha } = req.body || {};

  if (!cpf || !codigo || !novaSenha) {
    return res.status(400).json({ erro: 'Informe CPF, código e a nova senha.' });
  }

  if (typeof novaSenha !== 'string' || novaSenha.length < 8) {
    return res.status(400).json({ erro: 'A senha deve ter ao menos 8 caracteres.' });
  }

  const erroGenerico = { erro: 'Código inválido ou expirado. Peça um novo código.' };

  try {
    const cliente = await prisma.cliente.findUnique({ where: { cpf: cpfUtil.limpar(cpf) } });

    const valido = cliente
      && cliente.reset_codigo_hash
      && cliente.reset_expira_em
      && cliente.reset_expira_em.getTime() > Date.now()
      && cliente.reset_tentativas < MAX_TENTATIVAS_CODIGO;

    const codigoOk = await bcrypt.compare(String(codigo).trim(), valido ? cliente.reset_codigo_hash : HASH_MORTO);

    if (!valido || !codigoOk) {
      if (valido) {
        await prisma.cliente.update({ where: { id: cliente.id }, data: { reset_tentativas: { increment: 1 } } });
      }
      return res.status(400).json(erroGenerico);
    }

    await prisma.cliente.update({
      where: { id: cliente.id },
      data: {
        senha_hash: await bcrypt.hash(novaSenha, 12),
        reset_codigo_hash: null,
        reset_expira_em: null,
        reset_tentativas: 0,
        // derruba as sessões abertas em outros aparelhos
        token_valido_desde: new Date(),
      },
    });

    return res.json({ ok: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao redefinir a senha.' });
  }
});

// ---- Login com Google ---------------------------------------------------------
// O app manda o ID token do Google. Conta já vinculada (google_id) ou com o
// mesmo e-mail verificado pelo Google entra direto; quem é novo precisa
// completar CPF e telefone (obrigatórios no sistema) com o tokenCadastro.
function gerarTokenCadastroGoogle({ googleId, email, nome }) {
  return jwt.sign({ sub: googleId, email, nome, tipo: 'google-cadastro' }, process.env.JWT_SECRET, {
    expiresIn: '15m',
    algorithm: 'HS256',
  });
}

router.post('/google', limiteLogin, async (req, res) => {
  const { idToken } = req.body || {};

  let perfil;
  try {
    perfil = await verificarIdToken(idToken);
  } catch (err) {
    if (err.naoConfigurado) {
      return res.status(503).json({ erro: 'Login com Google indisponível no momento.' });
    }
    return res.status(401).json({ erro: 'Não foi possível validar o login com o Google.' });
  }

  try {
    // Só entra direto quem já tem esta conta Google vinculada. NÃO vinculamos
    // por e-mail: o e-mail de um cadastro por CPF nunca foi confirmado, então
    // qualquer pessoa poderia ter cadastrado o e-mail de outra e herdar o
    // acesso quando ela entrasse com o Google. Quem já tem conta por CPF
    // vincula o Google confirmando a senha (ver /google/completar).
    const cliente = await prisma.cliente.findUnique({ where: { google_id: perfil.googleId } });

    if (cliente) {
      return res.json({ cliente: sanitizarCliente(cliente), token: gerarToken(cliente) });
    }

    return res.json({
      precisaCadastro: true,
      nome: perfil.nome,
      email: perfil.email,
      tokenCadastro: gerarTokenCadastroGoogle(perfil),
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao entrar com o Google.' });
  }
});

router.post('/google/completar', limiteRegistro, async (req, res) => {
  const { tokenCadastro, cpf, telefone, senha } = req.body || {};

  if (!tokenCadastro || !cpf || !telefone) {
    return res.status(400).json({ erro: 'Informe CPF e telefone.' });
  }
  if (senha !== undefined && (typeof senha !== 'string' || senha.length > 200)) {
    return res.status(400).json({ erro: 'Senha inválida.' });
  }

  let dados;
  try {
    dados = jwt.verify(tokenCadastro, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (dados.tipo !== 'google-cadastro') throw new Error('tipo');
  } catch (err) {
    return res.status(401).json({ erro: 'Sessão do Google expirada. Toque em "Google" para entrar de novo.' });
  }

  if (!cpfUtil.isValido(cpf)) {
    return res.status(400).json({ erro: 'CPF inválido.' });
  }

  if (typeof telefone !== 'string' || telefone.trim().length < 8 || telefone.length > 20) {
    return res.status(400).json({ erro: 'Telefone inválido.' });
  }

  try {
    const cliente = await prisma.cliente.create({
      data: {
        nome: String(dados.nome).slice(0, 150),
        cpf: cpfUtil.limpar(cpf),
        // Conta criada pelo Google não tem senha própria: o hash vem de um
        // valor aleatório que ninguém conhece (a senha pode ser definida
        // depois pelo fluxo "Esqueceu a senha?", usando o e-mail).
        senha_hash: await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 12),
        telefone: telefone.trim(),
        email: dados.email,
        google_id: dados.sub,
      },
    });

    return res.status(201).json({ cliente: sanitizarCliente(cliente), token: gerarToken(cliente) });
  } catch (err) {
    if (err.code === 'P2002') {
      // CPF já cadastrado. Se a pessoa informou a senha dessa conta, vincula o
      // Google a ela (prova de posse); senão pede a senha.
      const existente = await prisma.cliente.findUnique({ where: { cpf: cpfUtil.limpar(cpf) } });
      if (existente && !existente.google_id && senha) {
        const senhaOk = await bcrypt.compare(senha, existente.senha_hash);
        if (!senhaOk) {
          return res.status(401).json({ erro: 'Senha incorreta para essa conta.', codigo: 'CPF_EXISTENTE' });
        }
        const vinculada = await prisma.cliente.update({
          where: { id: existente.id },
          data: { google_id: dados.sub, ...(existente.email ? {} : { email: dados.email }) },
        });
        return res.json({ cliente: sanitizarCliente(vinculada), token: gerarToken(vinculada) });
      }
      return res.status(409).json({
        erro: 'Esse CPF já tem uma conta. Informe a senha dela para vincular o Google.',
        codigo: 'CPF_EXISTENTE',
      });
    }
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao concluir o cadastro.' });
  }
});

module.exports = router;
