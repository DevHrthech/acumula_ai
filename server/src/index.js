require('dotenv').config();
const express = require('express');
const path = require('path');
const helmet = require('helmet');

const authEmpresaRoutes = require('./routes/authEmpresa');
const empresaRoutes = require('./routes/empresa');
const authAdminRoutes = require('./routes/authAdmin');
const adminRoutes = require('./routes/admin');
const adminMonitoramentoRoutes = require('./routes/adminMonitoramento');
const authClienteRoutes = require('./routes/authCliente');
const clienteRoutes = require('./routes/cliente');
const campanhasRoutes = require('./routes/campanhas');
const promocoesRoutes = require('./routes/promocoes');
const solicitacoesRoutes =require('./routes/solicitacoes');
const relatorioRoutes = require('./routes/relatorio');
const logRequisicao = require('./middleware/logRequisicao');
const { agendarLimpezaDeLogs } = logRequisicao;
const { limiteGeral } = require('./middleware/rateLimiters');
const { criarCors } = require('./utils/cors');

const app = express();

// API pura (JSON), sem HTML — mas os painéis Web/Admin em subdomínios
// diferentes precisam poder consumi-la via fetch(); sem esse ajuste, o
// Cross-Origin-Resource-Policy "same-origin" (padrão do helmet) bloquearia
// essas chamadas mesmo com CORS liberado (são camadas independentes).
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

app.set('trust proxy', 1); // atrás do Cloudflare — necessário pro rate limit identificar o IP real do cliente

// CORS: ver utils/cors.js (origens liberadas, CORS_ORIGENS_EXTRAS e o 403 claro
// para origem recusada).
app.use(criarCors());
// Imagens de marca enviadas pelas empresas (ver routes/empresa.js). Os nomes
// levam timestamp, então cache longo é seguro.
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads'), { maxAge: '7d', index: false }));
app.use(express.json({ limit: '100kb' })); // nenhuma rota hoje precisa de payload grande (sem upload de arquivo via JSON)
app.use(limiteGeral);
app.use(logRequisicao);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth/empresa', authEmpresaRoutes);
app.use('/empresas', empresaRoutes);
app.use('/auth/admin', authAdminRoutes);
app.use('/admin', adminRoutes);
app.use('/admin/monitoramento', adminMonitoramentoRoutes);
app.use('/auth/cliente', authClienteRoutes);
app.use('/clientes', clienteRoutes);
app.use('/empresas/me/campanhas', campanhasRoutes);
app.use('/empresas/me/promocoes', promocoesRoutes);
app.use('/empresas/me/solicitacoes',solicitacoesRoutes);
app.use('/empresas/me', relatorioRoutes);

// Rede de segurança: qualquer erro que uma rota encaminhe via next(err)
// (ver src/utils/asyncHandler.js) cai aqui em vez de derrubar o processo.
// Respeita o status code do próprio erro quando ele já vem marcado como erro
// de cliente (ex: JSON malformado do express.json() vem com status 400) —
// sem isso, um corpo mal formado virava "500 Erro interno" (semanticamente
// errado, e polui métricas de erro de servidor com erros de cliente).
app.use((err, req, res, next) => {
  const status = err.status || err.statusCode;
  const erroDoCliente = status >= 400 && status < 500;
  console.error(err);
  res.status(erroDoCliente ? status : 500).json({
    erro: erroDoCliente ? 'Requisição inválida.' : 'Erro interno do servidor.',
  });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`ACUMULAAI API rodando na porta ${port}`);
  agendarLimpezaDeLogs();
});
