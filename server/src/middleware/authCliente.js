const jwt = require('jsonwebtoken');
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

  req.clienteId = payload.sub;
  next();
});

module.exports = authCliente;
