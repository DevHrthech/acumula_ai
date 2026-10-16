const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// Protege contra um erro real (2026-10-15): o schema ganhou uma coluna e o
// `prisma db push` foi feito, mas o client NÃO foi regenerado — o código novo
// passou a pedir um campo que o client enviado ao servidor não conhecia e toda
// rota autenticada do cliente caiu em 500. Aqui: todo campo escalar do
// schema.prisma precisa existir no client gerado (src/generated/prisma).

const schema = fs.readFileSync(path.join(__dirname, '../prisma/schema.prisma'), 'utf8').replace(/\r\n/g, '\n');
const { Prisma } = require('../src/generated/prisma');

const nomesModelos = [...schema.matchAll(/^model (\w+) \{/gm)].map((m) => m[1]);

function camposEscalares(corpo) {
  const campos = [];
  for (const linha of corpo.split('\n')) {
    const m = /^\s+(\w+)\s+(\w+)(\[\])?(\?)?/.exec(linha);
    if (!m || linha.trim().startsWith('//') || linha.trim().startsWith('@@')) continue;
    const [, nome, tipo, lista] = m;
    if (lista || nomesModelos.includes(tipo)) continue; // relação
    campos.push(nome);
  }
  return campos;
}

for (const modelo of nomesModelos) {
  test(`client gerado conhece todos os campos de ${modelo}`, () => {
    const corpo = new RegExp(`^model ${modelo} \\{([\\s\\S]*?)^\\}`, 'm').exec(schema)[1];
    const enumGerado = Prisma[`${modelo}ScalarFieldEnum`];
    assert.ok(enumGerado, `${modelo} não existe no client gerado — rode "npx prisma generate"`);
    for (const campo of camposEscalares(corpo)) {
      assert.ok(
        campo in enumGerado,
        `${modelo}.${campo} está no schema.prisma mas não no client gerado — rode "npx prisma generate" e reenvie src/generated/prisma`,
      );
    }
  });
}
