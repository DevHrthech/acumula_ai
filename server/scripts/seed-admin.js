// Cria (ou atualiza a senha de) um admin interno da 2RL. Não existe rota
// HTTP pública para isso — só este script, rodado manualmente:
//   node scripts/seed-admin.js "Nome" email@2rl.com.br "senhaForte123"
require('dotenv').config();
const bcrypt = require('bcryptjs');
const prisma = require('../src/prisma');

async function main() {
  const [nome, email, senha] = process.argv.slice(2);

  if (!nome || !email || !senha) {
    console.error('Uso: node scripts/seed-admin.js "Nome" email@2rl.com.br "senhaForte123"');
    process.exit(1);
  }

  if (senha.length < 8) {
    console.error('A senha deve ter ao menos 8 caracteres.');
    process.exit(1);
  }

  const senha_hash = await bcrypt.hash(senha, 12);

  const admin = await prisma.adminInterno.upsert({
    where: { email: email.toLowerCase().trim() },
    update: { senha_hash, nome },
    create: { nome, email: email.toLowerCase().trim(), senha_hash },
  });

  console.log('Admin pronto:', { id: admin.id, nome: admin.nome, email: admin.email });
  await prisma.$disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
