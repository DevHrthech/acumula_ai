// Deriva o status "efetivo" da licença a partir das datas, sem depender de
// um job agendado. CANCELADA/BLOQUEADA gravados manualmente pelo admin
// sempre prevalecem; caso contrário o status nasce de data_vencimento +
// dias_tolerancia (decisão do usuário, 2026-09-17: período de tolerância,
// depois bloqueia tudo).
function statusEfetivo(licenca, agora = new Date()) {
  if (!licenca) return null;
  if (licenca.status === 'CANCELADA' || licenca.status === 'BLOQUEADA') {
    return licenca.status;
  }

  const vencimento = new Date(licenca.data_vencimento);
  const limiteTolerancia = new Date(vencimento);
  limiteTolerancia.setDate(limiteTolerancia.getDate() + licenca.dias_tolerancia);

  if (agora <= vencimento) return 'ATIVA';
  if (agora <= limiteTolerancia) return 'INADIMPLENTE';
  return 'BLOQUEADA';
}

module.exports = { statusEfetivo };
