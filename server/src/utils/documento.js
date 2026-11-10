const cpf = require('./cpf');
const cnpj = require('./cnpj');

// Documento da empresa: CPF (pessoa física) ou CNPJ (pessoa jurídica), guardado
// na mesma coluna `empresas.cnpj_cpf`. O tipo é deduzido pelo número de dígitos
// (11 = CPF, 14 = CNPJ) e o dígito verificador é conferido pelo tipo certo.

function limpar(valor) {
  return String(valor ?? '').replace(/\D/g, '');
}

// Devolve { tipo: 'CPF' | 'CNPJ', digitos, formatado } ou null se o documento
// não é um CPF/CNPJ válido (tamanho, sequência repetida ou dígito verificador).
function analisar(valor) {
  if (typeof valor !== 'string' && typeof valor !== 'number') return null;
  const digitos = limpar(valor);
  if (digitos.length === 11 && cpf.isValido(digitos)) {
    return { tipo: 'CPF', digitos, formatado: cpf.formatar(digitos) };
  }
  if (digitos.length === 14 && cnpj.isValido(digitos)) {
    return { tipo: 'CNPJ', digitos, formatado: cnpj.formatar(digitos) };
  }
  return null;
}

// Nome amigável do campo único violado, a partir do nome da coluna ou do índice
// (`cnpj_cpf`, `empresas_cnpj_cpf_key`, o antigo `empresas_cnpj_key`...).
function rotuloCampoUnico(campo) {
  const nome = String(campo ?? '');
  if (/cnpj/i.test(nome)) return 'CPF/CNPJ';
  if (/email/i.test(nome)) return 'e-mail';
  if (/codigo_loja/i.test(nome)) return 'código de loja';
  return 'campo único';
}

// Campo da duplicidade (erro P2002 do Prisma). Com o adaptador MariaDB o alvo
// não vem em `meta.target`, e sim no nome do índice (`meta.driverAdapterError`).
// Nunca devolve a mensagem crua do banco (ela traz o valor duplicado).
function campoDuplicado(err) {
  const meta = err?.meta || {};
  const candidato = meta.target?.[0] ?? meta.driverAdapterError?.cause?.constraint?.index;
  return rotuloCampoUnico(candidato);
}

module.exports = { limpar, analisar, rotuloCampoUnico, campoDuplicado };
