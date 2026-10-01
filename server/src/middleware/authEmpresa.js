const jwt = require('jsonwebtoken');
const prisma = require('../prisma');
const { statusEfetivo } = require('../utils/licenca');
const asyncHandler = require('../utils/asyncHandler');

const authEmpresa = asyncHandler(async (req, res, next) => {
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
    if (payload.tipo !== 'empresa') {
      return res.status(401).json({ erro: 'Token inválido para este recurso.' });
    }
  } catch (err) {
    return res.status(401).json({ erro: 'Token inválido ou expirado.' });
  }

  // Empresa sem nenhuma licença ainda (ex: recém-cadastrada, sem plano
  // atribuído pelo admin) segue liberada — o bloqueio só vale a partir do
  // momento em que existe uma licença e ela está BLOQUEADA/CANCELADA.
  const licencaMaisRecente = await prisma.licenca.findFirst({
    where: { empresa_id: payload.sub },
    orderBy: { created_at: 'desc' },
  });

  if (licencaMaisRecente && ['BLOQUEADA', 'CANCELADA'].includes(statusEfetivo(licencaMaisRecente))) {
    return res.status(403).json({
      erro: 'Acesso bloqueado por pendência de licença/pagamento. Entre em contato com a 2RL.',
    });
  }

  req.empresaId = payload.sub;
  next();
});

module.exports = authEmpresa;
