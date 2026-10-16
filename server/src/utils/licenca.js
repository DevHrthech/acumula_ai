const { fimDoDiaBrasilia } = require('./data');

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

  // A licença vale até o FIM do dia de vencimento (horário de Brasília) e a
  // tolerância conta em dias a partir daí.
  const vencimento = fimDoDiaBrasilia(licenca.data_vencimento);
  const limiteTolerancia = new Date(vencimento.getTime() + licenca.dias_tolerancia * 24 * 60 * 60 * 1000);

  if (agora <= vencimento) return 'ATIVA';
  if (agora <= limiteTolerancia) return 'INADIMPLENTE';
  return 'BLOQUEADA';
}

module.exports = { statusEfetivo };
