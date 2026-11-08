// Cadastra (ou atualiza) o webhook do Asaas apontando para a API.
// Uso:  node scripts/asaas-webhook.js <url-publica-do-webhook> [email-de-alerta]
//   ex: node scripts/asaas-webhook.js https://api.acumulaai.com.br/webhooks/asaas ti@exemplo.com
// Usa ASAAS_API_KEY / ASAAS_BASE_URL / ASAAS_WEBHOOK_TOKEN do .env — o
// ambiente (sandbox x produção) é o da chave. Rodar SÓ depois de a rota
// estar no ar: o Asaas pausa a fila após 15 falhas seguidas.

require('dotenv').config({ quiet: true });

const NOME = 'ACUMULAAI - cobranças';
const EVENTOS = [
  'PAYMENT_CREATED',
  'PAYMENT_UPDATED',
  'PAYMENT_CONFIRMED',
  'PAYMENT_RECEIVED',
  'PAYMENT_OVERDUE',
  'PAYMENT_DELETED',
  'PAYMENT_RESTORED',
  'PAYMENT_REFUNDED',
  'PAYMENT_CREDIT_CARD_CAPTURE_REFUSED',
  'PAYMENT_CHARGEBACK_REQUESTED',
  // Notas fiscais (NFS-e) emitidas após o pagamento.
  'INVOICE_CREATED',
  'INVOICE_UPDATED',
  'INVOICE_SYNCHRONIZED',
  'INVOICE_AUTHORIZED',
  'INVOICE_PROCESSING_CANCELLATION',
  'INVOICE_CANCELED',
  'INVOICE_CANCELLATION_DENIED',
  'INVOICE_ERROR',
];

async function chamar(metodo, caminho, corpo) {
  const res = await fetch(`${process.env.ASAAS_BASE_URL}${caminho}`, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'acumulaai-server',
      access_token: process.env.ASAAS_API_KEY,
    },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  const json = await res.json().catch(() => null);
  if (!res.ok) throw new Error(`${metodo} ${caminho} -> ${res.status} ${JSON.stringify(json)}`);
  return json;
}

(async () => {
  const [url, email] = process.argv.slice(2);
  if (!url || !/^https:\/\//.test(url)) {
    console.error('Informe a URL pública https do webhook.');
    process.exit(1);
  }
  if (!process.env.ASAAS_API_KEY || !process.env.ASAAS_BASE_URL || !process.env.ASAAS_WEBHOOK_TOKEN) {
    console.error('Faltam ASAAS_API_KEY, ASAAS_BASE_URL ou ASAAS_WEBHOOK_TOKEN no .env.');
    process.exit(1);
  }

  const corpo = {
    name: NOME,
    url,
    ...(email && { email }),
    enabled: true,
    interrupted: false,
    authToken: process.env.ASAAS_WEBHOOK_TOKEN,
    sendType: 'SEQUENTIALLY',
    events: EVENTOS,
  };

  const existentes = await chamar('GET', '/webhooks');
  const atual = (existentes.data || []).find((w) => w.name === NOME);
  const resultado = atual
    ? await chamar('PUT', `/webhooks/${atual.id}`, corpo)
    : await chamar('POST', '/webhooks', corpo);

  console.log(atual ? 'Webhook atualizado:' : 'Webhook criado:', resultado.id, '->', resultado.url);
})().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
