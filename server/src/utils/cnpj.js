function limpar(cnpj) {
  return String(cnpj || '').replace(/\D/g, '');
}

function calcularDigito(base, pesos) {
  const soma = base
    .split('')
    .reduce((acc, digito, i) => acc + Number(digito) * pesos[i], 0);
  const resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

function isValido(cnpj) {
  const digitos = limpar(cnpj);
  if (digitos.length !== 14 || /^(\d)\1{13}$/.test(digitos)) return false;

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  const dv1 = calcularDigito(digitos.slice(0, 12), pesos1);
  const dv2 = calcularDigito(digitos.slice(0, 12) + dv1, pesos2);

  return digitos === digitos.slice(0, 12) + String(dv1) + String(dv2);
}

function formatar(cnpj) {
  const d = limpar(cnpj);
  return `${d.slice(0, 2)}.${d.slice(2, 5)}.${d.slice(5, 8)}/${d.slice(8, 12)}-${d.slice(12, 14)}`;
}

module.exports = { limpar, isValido, formatar };
