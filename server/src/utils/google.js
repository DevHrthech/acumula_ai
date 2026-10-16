// Validação do ID token do "Entrar com Google". O app obtém o token com o
// Web Client ID (o mesmo do GOOGLE_CLIENT_ID do servidor, que vira o `aud`)
// e o servidor o confere no endpoint oficial tokeninfo do Google — sem
// dependência extra: o Google valida assinatura e expiração, nós conferimos
// público-alvo, emissor e e-mail verificado.
const ISSUERS_VALIDOS = ['accounts.google.com', 'https://accounts.google.com'];

function clientIdConfigurado() {
  // Web Client ID é público (não é segredo); a variável de ambiente, se existir, tem prioridade.
  return process.env.GOOGLE_CLIENT_ID || '954272668229-hrcersad8banluij7r90eis9t2jbp2u6.apps.googleusercontent.com';
}

function tokenInfoUrl() {
  return process.env.GOOGLE_TOKENINFO_URL || 'https://oauth2.googleapis.com/tokeninfo';
}

async function verificarIdToken(idToken) {
  const clientId = clientIdConfigurado();
  if (!clientId) {
    const err = new Error('Login com Google não configurado.');
    err.naoConfigurado = true;
    throw err;
  }

  if (typeof idToken !== 'string' || idToken.length < 20 || idToken.length > 4096) {
    throw new Error('Token inválido.');
  }

  const resposta = await fetch(`${tokenInfoUrl()}?id_token=${encodeURIComponent(idToken)}`, {
    signal: AbortSignal.timeout(8000),
  });
  if (!resposta.ok) {
    throw new Error('Google recusou o token.');
  }

  const dados = await resposta.json();

  if (dados.aud !== clientId) throw new Error('Token emitido para outro aplicativo.');
  if (!ISSUERS_VALIDOS.includes(dados.iss)) throw new Error('Emissor inválido.');
  if (Number(dados.exp) * 1000 < Date.now()) throw new Error('Token expirado.');
  if (String(dados.email_verified) !== 'true' || !dados.email) throw new Error('E-mail do Google não verificado.');

  return {
    googleId: String(dados.sub),
    email: String(dados.email).toLowerCase(),
    nome: dados.name ? String(dados.name) : String(dados.email).split('@')[0],
  };
}

module.exports = { verificarIdToken };
