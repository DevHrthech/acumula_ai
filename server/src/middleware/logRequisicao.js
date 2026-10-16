const prisma = require('../prisma');

// Registra cada chamada pra base do monitoramento (uso por empresa + saúde
// da API, ver src/routes/adminMonitoramento.js). Fica no 'finish' (depois
// da resposta já ter sido enviada) pra: (1) ter o status_code final e a
// duração real, e (2) já ter passado pelos middlewares de auth, que são
// quem preenche req.empresaId/req.adminId. Gravação é "fire and forget" —
// uma falha aqui nunca deve derrubar a resposta real ao cliente.
function logRequisicao(req, res, next) {
  const inicio = Date.now();

  // O /health é chamado por monitoramento e não diz nada sobre uso por empresa.
  if (req.path === '/health') return next();

  res.on('finish', () => {
    prisma.requisicaoApi
      .create({
        data: {
          metodo: req.method,
          rota: req.route
            ? req.baseUrl + (req.route.path !== '/' ? req.route.path : '')
            : req.originalUrl.split('?')[0],
          status_code: res.statusCode,
          duracao_ms: Date.now() - inicio,
          empresa_id: req.empresaId || null,
          admin_id: req.adminId || null,
          ip: req.ip,
        },
      })
      .catch((err) => console.error('Falha ao registrar log de requisição:', err.message));
  });

  next();
}

// Retenção: o log não cresce pra sempre. Apaga o que tem mais de 90 dias ao
// subir e uma vez por dia (timer "unref": não segura o processo vivo).
const RETENCAO_DIAS = 90;

function limparLogsAntigos() {
  const limite = new Date(Date.now() - RETENCAO_DIAS * 24 * 60 * 60 * 1000);
  return prisma.requisicaoApi
    .deleteMany({ where: { created_at: { lt: limite } } })
    .catch((err) => console.error('Falha ao limpar logs antigos:', err.message));
}

function agendarLimpezaDeLogs() {
  limparLogsAntigos();
  setInterval(limparLogsAntigos, 24 * 60 * 60 * 1000).unref();
}

module.exports = logRequisicao;
module.exports.agendarLimpezaDeLogs = agendarLimpezaDeLogs;
