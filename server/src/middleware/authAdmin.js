const jwt = require('jsonwebtoken');
const prisma = require('../prisma');
const asyncHandler = require('../utils/asyncHandler');

const authAdmin = asyncHandler(async (req, res, next) => {
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
    if (payload.tipo !== 'admin') {
      return res.status(401).json({ erro: 'Token inválido para este recurso.' });
    }
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido ou expirado.' });
  }

  // Com "Lembrar acesso" o token vale dias, então conferimos a cada chamada se
  // o admin ainda existe e se "Sair" foi acionado depois da emissão dele
  // (token_valido_desde) — assim o token guardado em outro aparelho é derrubado.
  const admin = await prisma.adminInterno.findUnique({
    where: { id: payload.sub },
    select: { token_valido_desde: true },
  });
  if (!admin) {
    return res.status(401).json({ erro: 'Administrador não encontrado.' });
  }
  if (admin.token_valido_desde && payload.iat < Math.floor(admin.token_valido_desde.getTime() / 1000)) {
    return res.status(401).json({ erro: 'Sessão encerrada. Entre novamente.' });
  }

  req.adminId = payload.sub;
  next();
});

module.exports = authAdmin;
