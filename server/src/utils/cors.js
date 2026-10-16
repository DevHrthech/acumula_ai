const cors = require('cors');

// Origens (sites) que podem chamar a API pelo navegador. A autenticação é por
// Bearer token (não usa cookies), então o CORS aqui só decide quais sites o
// navegador deixa ler as respostas. O app do celular não é afetado: ele não
// envia o cabeçalho `Origin`.
const ORIGENS_FIXAS = [
  'https://acumulaai.com.br',
  // O `www` abre o mesmo painel (/app/) e o site; sem ele o login do painel
  // acessado por www.acumulaai.com.br falhava com erro de CORS.
  'https://www.acumulaai.com.br',
  'https://admin.acumulaai.com.br',
];

// Desenvolvimento local. Fechado em produção (NODE_ENV=production).
const ORIGENS_DESENVOLVIMENTO = [/^http:\/\/localhost:\d+$/, /^http:\/\/127\.0\.0\.1:\d+$/];

// CORS_ORIGENS_EXTRAS="https://teste.exemplo.com,https://outro.exemplo.com":
// libera domínios de teste/homologação sem mexer no código. Só origens exatas
// (http/https + domínio + porta opcional); curinga e caminho são ignorados.
function origensExtras(valor) {
  return String(valor || '')
    .split(',')
    .map((s) => s.trim().replace(/\/+$/, ''))
    .filter((s) => /^https?:\/\/[A-Za-z0-9.-]+(:\d+)?$/.test(s));
}

function montarOrigensPermitidas(env = process.env) {
  return [
    ...ORIGENS_FIXAS,
    ...origensExtras(env.CORS_ORIGENS_EXTRAS),
    ...(env.NODE_ENV === 'production' ? [] : ORIGENS_DESENVOLVIMENTO),
  ];
}

// Sem `Origin` (app do celular, curl, servidor→servidor) não há o que checar.
function origemPermitida(origin, lista) {
  return !origin || lista.some((o) => (o instanceof RegExp ? o.test(origin) : o === origin));
}

// Dois middlewares: o `cors` (cabeçalhos para as origens liberadas) e um
// bloqueio que responde 403 claro para as demais. Antes, a origem recusada
// virava uma exceção -> 500 "Erro interno do servidor" sem nenhum cabeçalho,
// o que confundia quem testava e contava como falha do servidor no monitoramento.
function criarCors(lista = montarOrigensPermitidas()) {
  return [
    cors({ origin: (origin, callback) => callback(null, origemPermitida(origin, lista)) }),
    (req, res, next) => {
      if (origemPermitida(req.headers.origin, lista)) return next();
      return res.status(403).json({ erro: 'Origem não permitida pela API.', origem: req.headers.origin });
    },
  ];
}

module.exports = { ORIGENS_FIXAS, origensExtras, montarOrigensPermitidas, origemPermitida, criarCors };
