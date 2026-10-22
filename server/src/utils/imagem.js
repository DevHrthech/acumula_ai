const fs = require('fs/promises');
const path = require('path');

// Imagens enviadas por empresas (marca) e por clientes (foto de perfil): o
// binário fica no disco (server/uploads/...), só a URL vai pro MySQL — ver
// docs/SPEC.md seção 7. Aceita só PNG/JPEG, conferido pelos bytes iniciais e
// não pelo Content-Type enviado (nada de SVG, que poderia carregar script).

const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads');

function detectarFormatoImagem(buf) {
  if (buf.length > 8 && buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'png';
  if (buf.length > 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'jpg';
  return null;
}

function urlPublicaBase(req) {
  const host = req.get('host');
  const proto = /^localhost(:\d+)?$/.test(host) ? 'http' : 'https';
  return `${proto}://${host}`;
}

// Apaga o arquivo apontado por uma URL antiga, dentro da pasta `subpasta`
// (ex.: o id da empresa ou "clientes/<id>"). Só usa o nome do arquivo — nunca
// um caminho vindo da URL.
async function removerArquivoAnterior(subpasta, urlAntiga) {
  if (!urlAntiga) return;
  const nome = path.basename(urlAntiga);
  await fs.rm(path.join(UPLOADS_DIR, subpasta, nome), { force: true });
}

module.exports = { UPLOADS_DIR, detectarFormatoImagem, urlPublicaBase, removerArquivoAnterior };
