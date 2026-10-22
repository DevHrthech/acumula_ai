// Cria (ou atualiza a senha de) um admin interno da 2RL. Não existe rota
// HTTP pública para isso — só este script, rodado manualmente:
//   ADMIN_SENHA='senhaForte123' node scripts/seed-admin.js "Nome" email@2rl.com.br
// (também aceita a senha como 3º argumento, mas isso fica no histórico do shell)
require('dotenv').config();
const bcrypt = require('bcryptjs');
const prisma = require('../src/prisma');

async function main() {
  const [nome, email, senhaArg] = process.argv.slice(2);
  const senha = process.env.ADMIN_SENHA || senhaArg;

  if (!nome || !email || !senha) {
    console.error('Uso: ADMIN_SENHA=... node scripts/seed-admin.js "Nome" email@2rl.com.br');
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
