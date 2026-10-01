const jwt = require('jsonwebtoken');

function authAdmin(req, res, next) {
  const header = req.headers.authorization || '';
  const [tipo, token] = header.split(' ');

  if (tipo !== 'Bearer' || !token) {
    return res.status(401).json({ erro: 'Token de autenticação ausente.' });
  }

  try {
    // algorithms explícito: nunca confiar no "alg" que vem no próprio token
    // (defesa contra ataques de confusão de algoritmo, ex: alg=none).
    const payload = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (payload.tipo !== 'admin') {
      return res.status(401).json({ erro: 'Token inválido para este recurso.' });
    }
    req.adminId = payload.sub;
    next();
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido ou expirado.' });
  }
}

module.exports = authAdmin;
