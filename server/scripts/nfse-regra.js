// Aplica (ou atualiza) a regra de emissão automática de NFS-e em assinaturas
// do Asaas que já existem. Assinaturas novas já saem com a regra; este script
// serve para as criadas antes de NFSE_ATIVA e para refazer depois de mudar as
// alíquotas/serviço no .env (notas já emitidas não mudam).
//
// Uso:  node scripts/nfse-regra.js            -> só lista o que faria
//       node scripts/nfse-regra.js --aplicar  -> aplica de verdade
// Usa o .env (ASAAS_*, NFSE_*) — o ambiente é o da chave do Asaas, e o banco
// do .env local é o de PRODUÇÃO: só lê licenças com assinatura.

require('dotenv').config({ quiet: true });

const prisma = require('../src/prisma');
const asaas = require('../src/utils/asaas');
const { notaAtiva, montarRegraNota } = require('../src/utils/nota');

(async () => {
  const aplicar = process.argv.includes('--aplicar');
  if (!notaAtiva()) {
    console.error('Defina NFSE_ATIVA=true e NFSE_SERVICO_CODIGO (ou NFSE_SERVICO_ID) no .env.');
    process.exit(1);
  }
  console.log('Regra:', JSON.stringify(montarRegraNota(), null, 2));

  const licencas = await prisma.licenca.findMany({
    where: { gateway_assinatura_id: { not: null }, status: { not: 'CANCELADA' } },
    include: { empresa: { select: { nome: true } } },
  });
  console.log(`${licencas.length} assinatura(s) ativa(s).`);

  let falhas = 0;
  for (const l of licencas) {
    const rotulo = `${l.empresa.nome} (${l.gateway_assinatura_id})`;
    if (!aplicar) {
      console.log('[simulação]', rotulo);
      continue;
    }
    try {
      await asaas.configurarNotaDaAssinatura(l.gateway_assinatura_id, montarRegraNota());
      console.log('ok       ', rotulo);
    } catch (err) {
      falhas += 1;
      console.error('FALHOU   ', rotulo, '-', err.message);
    }
  }
  if (!aplicar) console.log('Nada foi alterado. Rode com --aplicar para aplicar.');
  await prisma.$disconnect();
  process.exit(falhas ? 1 : 0);
})().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
