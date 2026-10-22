// Validação de tipos nas bordas da API: um campo de texto que chega como
// número/objeto/array gerava erro 500 (ex.: `.trim()` num número). Aqui vira
// um 400 claro.

// true se `valor` é string (não vazia depois do trim, se `obrigatorio`) e cabe
// em `max` caracteres. `undefined`/`null` só passam quando não é obrigatório.
function textoValido(valor, { max, obrigatorio = false } = {}) {
  if (valor === undefined || valor === null || valor === '') return !obrigatorio;
  if (typeof valor !== 'string') return false;
  if (obrigatorio && !valor.trim()) return false;
  return max === undefined || valor.length <= max;
}

// Procura o primeiro campo inválido num objeto { nome: [valor, opcoes] } e
// devolve a mensagem de erro, ou null se estiver tudo certo.
function primeiroErroTexto(campos) {
  for (const [nome, [valor, opcoes]] of Object.entries(campos)) {
    if (!textoValido(valor, opcoes)) {
      const limite = opcoes && opcoes.max ? ` (até ${opcoes.max} caracteres)` : '';
      return `${nome} inválido${limite}.`;
    }
  }
  return null;
}

module.exports = { textoValido, primeiroErroTexto };
