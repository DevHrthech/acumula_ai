const { spawn } = require('child_process');

// Envio via `sendmail` local da hospedagem (cPanel/Exim) — não precisa de
// credencial SMTP nem de dependência extra. MAIL_MODE=console imprime o
// e-mail no log em vez de enviar (só pra desenvolvimento local).
const SENDMAIL = process.env.SENDMAIL_PATH || '/usr/sbin/sendmail';
const REMETENTE_NOME = 'Acumula Aí';
const REMETENTE_EMAIL = process.env.MAIL_FROM_ADDRESS || 'nao-responda@acumulaai.com.br';

function codificarCabecalho(texto) {
  return `=?UTF-8?B?${Buffer.from(texto, 'utf8').toString('base64')}?=`;
}

function montarMensagem({ para, assunto, texto }) {
  const corpo = Buffer.from(texto, 'utf8').toString('base64').replace(/(.{76})/g, '$1\r\n');
  return [
    `From: ${codificarCabecalho(REMETENTE_NOME)} <${REMETENTE_EMAIL}>`,
    `To: ${para}`,
    `Subject: ${codificarCabecalho(assunto)}`,
    `Date: ${new Date().toUTCString()}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: base64',
    '',
    corpo,
    '',
  ].join('\r\n');
}

function enviarEmail({ para, assunto, texto }) {
  if (/[\r\n]/.test(para)) {
    return Promise.reject(new Error('Destinatário inválido.'));
  }

  if (process.env.MAIL_MODE === 'console') {
    console.log(`[mailer:console] para=${para} assunto=${assunto}\n${texto}`);
    return Promise.resolve();
  }

  return new Promise((resolve, reject) => {
    const proc = spawn(SENDMAIL, ['-t', '-i', '-f', REMETENTE_EMAIL]);
    proc.on('error', reject);
    proc.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`sendmail saiu com código ${code}`))));
    proc.stdin.end(montarMensagem({ para, assunto, texto }));
  });
}

module.exports = { enviarEmail };
