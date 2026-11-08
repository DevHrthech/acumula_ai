// Cliente mínimo da API do Asaas (gateway de pagamento da 2RL). Docs:
// https://docs.asaas.com — a chave vai no header `access_token` e o ambiente
// (sandbox x produção) é definido só por ASAAS_BASE_URL/ASAAS_API_KEY.

const TIMEOUT_MS = 10000;

class AsaasErro extends Error {
  constructor(mensagem, { status, detalhes } = {}) {
    super(mensagem);
    this.name = 'AsaasErro';
    this.status = status;
    this.detalhes = detalhes;
  }
}

function configurado() {
  return Boolean(process.env.ASAAS_API_KEY && process.env.ASAAS_BASE_URL);
}

async function chamar(metodo, caminho, corpo) {
  if (!configurado()) {
    throw new AsaasErro('Asaas não configurado (ASAAS_API_KEY/ASAAS_BASE_URL).');
  }

  let res;
  try {
    res = await fetch(`${process.env.ASAAS_BASE_URL.replace(/\/$/, '')}${caminho}`, {
      method: metodo,
      headers: {
        'Content-Type': 'application/json',
        // Obrigatório para contas raiz criadas depois de 13/06/2024.
        'User-Agent': 'acumulaai-server',
        access_token: process.env.ASAAS_API_KEY,
      },
      body: corpo ? JSON.stringify(corpo) : undefined,
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  } catch (err) {
    throw new AsaasErro(`Falha de rede ao falar com o Asaas: ${err.message}`);
  }

  const texto = await res.text();
  let json = null;
  try {
    json = texto ? JSON.parse(texto) : null;
  } catch {
    // resposta não-JSON: cai no tratamento de erro abaixo
  }

  if (!res.ok) {
    const descricao = json?.errors?.map((e) => e.description).join('; ');
    throw new AsaasErro(descricao || `Asaas respondeu ${res.status}.`, {
      status: res.status,
      detalhes: json,
    });
  }
  return json;
}

// Garante que a empresa exista como cliente no Asaas e devolve o id (`cus_...`).
// Idempotente: procura antes pelo `externalReference` (id da empresa), então
// repetir a chamada (ex: replicação que falhou no cadastro) não duplica cliente.
async function garantirCliente(empresa) {
  const existentes = await chamar(
    'GET',
    `/customers?externalReference=${encodeURIComponent(empresa.id)}&limit=1`,
  );
  if (existentes?.data?.length) return existentes.data[0].id;

  const criado = await chamar('POST', '/customers', {
    name: empresa.nome,
    cpfCnpj: empresa.cnpj.replace(/\D/g, ''),
    email: empresa.email,
    externalReference: empresa.id,
  });
  return criado.id;
}

// Cria a assinatura mensal da licença. A 1ª cobrança é gerada na hora pelo
// Asaas (status PENDING) com vencimento em `proximoVencimento` (AAAA-MM-DD) —
// por isso usamos o dia seguinte ao fim do trial. `referencia` (id da licença)
// volta em todo evento de cobrança.
//
// Obs. (confirmado no sandbox): billingType PIX em assinatura vira BOLETO no
// Asaas — a fatura sai com QR Code Pix. CREDIT_CARD sem dados de cartão é
// aceito; o cartão é informado pela empresa na fatura.
async function criarAssinatura({ clienteId, billingType, valor, proximoVencimento, descricao, referencia }) {
  return chamar('POST', '/subscriptions', {
    customer: clienteId,
    billingType,
    value: valor,
    nextDueDate: proximoVencimento,
    cycle: 'MONTHLY',
    description: descricao,
    externalReference: referencia,
  });
}

// Cancela a assinatura (para de gerar cobranças). 404 = já não existe no
// Asaas, o que para nós é o mesmo resultado.
async function cancelarAssinatura(assinaturaId) {
  try {
    await chamar('DELETE', `/subscriptions/${encodeURIComponent(assinaturaId)}`);
  } catch (err) {
    if (err.status !== 404) throw err;
  }
}

async function listarCobrancasDaAssinatura(assinaturaId) {
  return chamar('GET', `/subscriptions/${encodeURIComponent(assinaturaId)}/payments?limit=20`);
}

// Regra de emissão automática de NFS-e da assinatura (invoiceSettings): POST
// cria e PUT atualiza (a doc do PUT pressupõe regra existente; notas já
// emitidas não mudam). A doc não diz qual erro o POST dá quando a regra já
// existe, então tentamos o PUT depois de qualquer 400 do POST. Se os dois
// falharem, o erro traz as duas mensagens (o 400 pode ser validação, ex.:
// serviço inválido, e não "regra já existe").
async function configurarNotaDaAssinatura(assinaturaId, regra) {
  const caminho = `/subscriptions/${encodeURIComponent(assinaturaId)}/invoiceSettings`;
  try {
    return await chamar('POST', caminho, regra);
  } catch (errCriar) {
    if (errCriar.status !== 400) throw errCriar;
    try {
      return await chamar('PUT', caminho, regra);
    } catch (errAtualizar) {
      throw new AsaasErro(`Criar regra: ${errCriar.message} | Atualizar regra: ${errAtualizar.message}`, {
        status: errAtualizar.status,
        detalhes: errAtualizar.detalhes,
      });
    }
  }
}

module.exports = {
  AsaasErro,
  configurado,
  garantirCliente,
  criarAssinatura,
  cancelarAssinatura,
  listarCobrancasDaAssinatura,
  configurarNotaDaAssinatura,
};
