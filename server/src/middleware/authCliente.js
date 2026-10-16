const jwt = require('jsonwebtoken');
const prisma = require('../prisma');
const asyncHandler = require('../utils/asyncHandler');

const authCliente = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [tipo, token] = header.split(' ');

  if (tipo !== 'Bearer' || !token) {
    return res.status(401).json({ erro: 'Token de autenticação ausente.' });
  }

  let payload;
  try {
    // algorithms explícito: nunca confiar no "alg" que vem no próprio token
    // (defesa contra ataques de confusão de algoritmo, ex: alg=none).
    payload = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (payload.tipo !== 'cliente') {
      return res.status(401).json({ erro: 'Token inválido para este recurso.' });
    }
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido ou expirado.' });
  }

  // O token vale 30 dias, então conferimos a cada chamada se a conta ainda
  // existe (foi excluída?) e se a senha foi redefinida depois da emissão dele
  // (token_valido_desde) — assim sair/trocar a senha realmente derruba os
  // aparelhos antigos.
  const cliente = await prisma.cliente.findUnique({
    where: { id: payload.sub },
    select: { token_valido_desde: true },
  });
  if (!cliente) {
    return res.status(401).json({ erro: 'Conta não encontrada. Entre novamente.' });
  }
  if (cliente.token_valido_desde && payload.iat < Math.floor(cliente.token_valido_desde.getTime() / 1000)) {
    return res.status(401).json({ erro: 'Sessão encerrada. Entre novamente.' });
  }

  req.clienteId = payload.sub;
  next();
});

module.exports = authCliente;
