const ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sem 0/O/1/I para evitar confusão

function gerarCodigo(tamanho = 8) {
  let codigo = '';
  for (let i = 0; i < tamanho; i++) {
    codigo += ALFABETO[Math.floor(Math.random() * ALFABETO.length)];
  }
  return codigo;
}

async function gerarCodigoLojaUnico(prisma) {
  for (let tentativa = 0; tentativa < 10; tentativa++) {
    const codigo = gerarCodigo();
    const existente = await prisma.empresa.findUnique({ where: { codigo_loja: codigo } });
    if (!existente) return codigo;
  }
  throw new Error('Não foi possível gerar um código de loja único.');
}

module.exports = { gerarCodigoLojaUnico };
