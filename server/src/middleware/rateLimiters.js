const { rateLimit, ipKeyGenerator } = require('express-rate-limit');

// A API sempre roda atrás do Cloudflare (nunca exposta direto). O header
// `CF-Connecting-IP` é escrito pelo próprio Cloudflare e sobrescreve
// qualquer valor que o cliente tente enviar — é mais confiável que
// `req.ip`/`X-Forwarded-For`, que dependem do `trust proxy` contar
// certo quantos proxies existem no caminho (Cloudflare + Apache/Passenger);
// contar errado abriria brecha pra forjar o IP e burlar o limite.
// `ipKeyGenerator` normaliza IPv6 corretamente (exigido pelo express-rate-limit
// quando se customiza o keyGenerator, senão dá pra burlar com variações do
// mesmo IPv6).
function chavePorIp(req) {
  return req.headers['cf-connecting-ip'] || ipKeyGenerator(req.ip);
}

// Login (empresa e admin): alvo principal de força bruta de credenciais.
const limiteLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: chavePorIp,
  message: { erro: 'Muitas tentativas de login. Tente novamente em alguns minutos.' },
});

// Cadastro de empresa: rota pública sem CAPTCHA — limite mais generoso no
// tempo, mas baixo em volume, pra dificultar cadastro em massa automatizado.
const limiteRegistro = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: chavePorIp,
  message: { erro: 'Muitas tentativas de cadastro. Tente novamente mais tarde.' },
});

// Limite geral pra API inteira, como rede de segurança básica contra abuso/DoS.
const limiteGeral = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: chavePorIp,
});

module.exports = { limiteLogin, limiteRegistro, limiteGeral };
