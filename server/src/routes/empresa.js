const express = require('express');
const fs = require('fs/promises');
const path = require('path');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');
const { primeiroErroTexto } = require('../utils/validar');

const router = express.Router();

const HEX_COR_REGEX = /^#[0-9A-Fa-f]{6}$/;

function sanitizarEmpresa(empresa) {
  const { senha_hash, ...resto } = empresa;
  return resto;
}

router.get('/me', authEmpresa, asyncHandler(async (req, res) => {
  const empresa = await prisma.empresa.findUnique({ where: { id: req.empresaId } });

  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  return res.json(sanitizarEmpresa(empresa));
}));

// Campos editáveis aqui: identidade da loja (nome/categoria), mecânica
// "quantitativa" (meta/recompensa — não o tipo em si, que é fixo após o
// cadastro, ver docs/MECANICA_FIDELIDADE.md), cores da marca e textos
// voltados ao cliente final. Fora do escopo por ora: email/cnpj/senha
// (fluxos próprios, com verificação), tipo_fidelidade (fixo), imagens
// (sem endpoint de upload ainda).
router.patch('/me', authEmpresa, asyncHandler(async (req, res) => {
  const {
    nome,
    categoria,
    metaFidelidade,
    descricaoRecompensa,
    corPrincipal,
    corDestaque,
    nomePrograma,
    mensagemBoasVindas,
    mensagemResgate,
    textoBotaoResgate,
  } = req.body || {};

  if (metaFidelidade !== undefined && (!Number.isInteger(metaFidelidade) || metaFidelidade < 1 || metaFidelidade > 1000)) {
    return res.status(400).json({ erro: 'metaFidelidade deve ser um inteiro entre 1 e 1000.' });
  }

  if (corPrincipal !== undefined && !(typeof corPrincipal === 'string' && HEX_COR_REGEX.test(corPrincipal))) {
    return res.status(400).json({ erro: 'corPrincipal deve estar no formato #RRGGBB.' });
  }

  if (corDestaque !== undefined && !(typeof corDestaque === 'string' && HEX_COR_REGEX.test(corDestaque))) {
    return res.status(400).json({ erro: 'corDestaque deve estar no formato #RRGGBB.' });
  }

  // Tipo e tamanho de cada texto (um número/objeto no lugar de uma string
  // virava erro 500 no `.trim()`).
  const erroTexto = primeiroErroTexto({
    nome: [nome, { max: 150, obrigatorio: nome !== undefined }],
    categoria: [categoria, { max: 100 }],
    descricaoRecompensa: [descricaoRecompensa, { max: 255 }],
    nomePrograma: [nomePrograma, { max: 100 }],
    mensagemBoasVindas: [mensagemBoasVindas, { max: 255 }],
    mensagemResgate: [mensagemResgate, { max: 255 }],
    textoBotaoResgate: [textoBotaoResgate, { max: 60 }],
  });
  if (erroTexto) {
    return res.status(400).json({ erro: erroTexto });
  }

  const empresa = await prisma.empresa.update({
    where: { id: req.empresaId },
    data: {
      ...(nome !== undefined && { nome: nome.trim() }),
      ...(categoria !== undefined && { categoria: categoria || null }),
      ...(metaFidelidade !== undefined && { meta_fidelidade: metaFidelidade }),
      ...(descricaoRecompensa !== undefined && { descricao_recompensa: descricaoRecompensa }),
      ...(corPrincipal !== undefined && { cor_principal: corPrincipal }),
      ...(corDestaque !== undefined && { cor_destaque: corDestaque }),
      ...(nomePrograma !== undefined && { nome_programa: nomePrograma }),
      ...(mensagemBoasVindas !== undefined && { mensagem_boas_vindas: mensagemBoasVindas }),
      ...(mensagemResgate !== undefined && { mensagem_resgate: mensagemResgate }),
      ...(textoBotaoResgate !== undefined && { texto_botao_resgate: textoBotaoResgate }),
    },
  });

  return res.json(sanitizarEmpresa(empresa));
}));

// ---- Imagens de marca ----------------------------------------------------
// Binário no disco (server/uploads/<empresaId>/), só a URL vai pro MySQL — ver
// docs/SPEC.md seção 7. Aceita só PNG/JPEG (conferido pelos bytes iniciais, não
// pelo Content-Type enviado) — nada de SVG, que poderia carregar script.
const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads');
const TAMANHO_MAX_IMAGEM = 2 * 1024 * 1024;
const CAMPOS_IMAGEM = {
  icone: 'icone_url',
  'logo-qrcode': 'logo_qrcode_url',
  'logo-promocao': 'logo_promocao_url',
};

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

async function removerArquivoAnterior(empresaId, urlAntiga) {
  if (!urlAntiga) return;
  const nome = path.basename(urlAntiga);
  await fs.rm(path.join(UPLOADS_DIR, empresaId, nome), { force: true });
}

router.put(
  '/me/imagens/:tipo',
  authEmpresa,
  express.raw({ type: ['image/png', 'image/jpeg'], limit: TAMANHO_MAX_IMAGEM }),
  asyncHandler(async (req, res) => {
    const campo = CAMPOS_IMAGEM[req.params.tipo];
    if (!campo) {
      return res.status(400).json({ erro: 'Tipo de imagem inválido.' });
    }

    const corpo = req.body;
    if (!Buffer.isBuffer(corpo) || corpo.length === 0) {
      return res.status(400).json({ erro: 'Envie uma imagem PNG ou JPG no corpo da requisição.' });
    }

    const formato = detectarFormatoImagem(corpo);
    if (!formato) {
      return res.status(400).json({ erro: 'Formato inválido. Envie uma imagem PNG ou JPG.' });
    }

    const empresa = await prisma.empresa.findUnique({ where: { id: req.empresaId } });
    if (!empresa) {
      return res.status(404).json({ erro: 'Empresa não encontrada.' });
    }

    const pasta = path.join(UPLOADS_DIR, req.empresaId);
    await fs.mkdir(pasta, { recursive: true });
    const nomeArquivo = `${req.params.tipo}-${Date.now()}.${formato}`;
    await fs.writeFile(path.join(pasta, nomeArquivo), corpo);

    const atualizada = await prisma.empresa.update({
      where: { id: req.empresaId },
      data: { [campo]: `${urlPublicaBase(req)}/uploads/${req.empresaId}/${nomeArquivo}` },
    });
    await removerArquivoAnterior(req.empresaId, empresa[campo]);

    return res.json(sanitizarEmpresa(atualizada));
  }),
);

router.delete('/me/imagens/:tipo', authEmpresa, asyncHandler(async (req, res) => {
  const campo = CAMPOS_IMAGEM[req.params.tipo];
  if (!campo) {
    return res.status(400).json({ erro: 'Tipo de imagem inválido.' });
  }

  const empresa = await prisma.empresa.findUnique({ where: { id: req.empresaId } });
  if (!empresa) {
    return res.status(404).json({ erro: 'Empresa não encontrada.' });
  }

  const atualizada = await prisma.empresa.update({ where: { id: req.empresaId }, data: { [campo]: null } });
  await removerArquivoAnterior(req.empresaId, empresa[campo]);

  return res.json(sanitizarEmpresa(atualizada));
}));

module.exports = router;
