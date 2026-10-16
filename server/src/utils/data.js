// Datas de calendário (colunas DATE) no fuso de Brasília. O servidor roda em
// UTC: usar `new Date()` direto fazia o "dia de hoje" virar o dia seguinte a
// partir das 21h (e campanhas/licenças vencerem 3h antes da meia-noite).
// Convenção: um dia de calendário é representado pela meia-noite UTC dessa
// data (é como o Prisma lê/grava colunas DATE).

const FUSO = 'America/Sao_Paulo';
const DIA_MS = 24 * 60 * 60 * 1000;

const formatadorData = new Intl.DateTimeFormat('en-CA', {
  timeZone: FUSO,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

// Hoje em Brasília, como meia-noite UTC da data de calendário.
function hojeBrasilia(agora = new Date()) {
  return new Date(`${formatadorData.format(agora)}T00:00:00Z`);
}

// Lê só a parte AAAA-MM-DD de um texto (aceita "2026-10-20" ou um ISO
// completo, como o que o painel envia) e ignora hora/fuso. Devolve null se
// não for uma data válida.
function paraData(valor) {
  if (typeof valor !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(valor.trim());
  if (!m) return null;
  const texto = `${m[1]}-${m[2]}-${m[3]}`;
  const data = new Date(`${texto}T00:00:00Z`);
  if (Number.isNaN(data.getTime()) || data.toISOString().slice(0, 10) !== texto) return null;
  return data;
}

// Instante em que o dia de calendário `data` termina em Brasília (UTC-3, sem
// horário de verão desde 2019): 23:59:59.999 BRT.
function fimDoDiaBrasilia(data) {
  return new Date(new Date(data).getTime() + DIA_MS + 3 * 60 * 60 * 1000 - 1);
}

module.exports = { hojeBrasilia, paraData, fimDoDiaBrasilia, DIA_MS };
