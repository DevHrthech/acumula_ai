function limpar(cpf) {
  return String(cpf || '').replace(/\D/g, '');
}

function calcularDigito(base, pesoInicial) {
  const soma = base
    .split('')
    .reduce((acc, digito, i) => acc + Number(digito) * (pesoInicial - i), 0);
  const resto = (soma * 10) % 11;
  return resto === 10 ? 0 : resto;
}

function isValido(cpf) {
  const digitos = limpar(cpf);
  if (digitos.length !== 11 || /^(\d)\1{10}$/.test(digitos)) return false;

  const dv1 = calcularDigito(digitos.slice(0, 9), 10);
  const dv2 = calcularDigito(digitos.slice(0, 9) + dv1, 11);

  return digitos === digitos.slice(0, 9) + String(dv1) + String(dv2);
}

function formatar(cpf) {
  const d = limpar(cpf);
  return `${d.slice(0, 3)}.${d.slice(3, 6)}.${d.slice(6, 9)}-${d.slice(9, 11)}`;
}

module.exports = { limpar, isValido, formatar };
