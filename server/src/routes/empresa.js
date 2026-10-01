const express = require('express');

const prisma = require('../prisma');
const authEmpresa = require('../middleware/authEmpresa');
const asyncHandler = require('../utils/asyncHandler');

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

  if (corPrincipal !== undefined && !HEX_COR_REGEX.test(corPrincipal)) {
    return res.status(400).json({ erro: 'corPrincipal deve estar no formato #RRGGBB.' });
  }

  if (corDestaque !== undefined && !HEX_COR_REGEX.test(corDestaque)) {
    return res.status(400).json({ erro: 'corDestaque deve estar no formato #RRGGBB.' });
  }

  const limitesTexto = {
    nome: 150,
    categoria: 100,
    descricaoRecompensa: 255,
    nomePrograma: 100,
    mensagemBoasVindas: 255,
    mensagemResgate: 255,
    textoBotaoResgate: 60,
  };
  const valores = { nome, categoria, descricaoRecompensa, nomePrograma, mensagemBoasVindas, mensagemResgate, textoBotaoResgate };
  for (const [campo, limite] of Object.entries(limitesTexto)) {
    const valor = valores[campo];
    if (valor !== undefined && valor !== null && valor.length > limite) {
      return res.status(400).json({ erro: `${campo} deve ter no máximo ${limite} caracteres.` });
    }
  }

  if (nome !== undefined && !nome.trim()) {
    return res.status(400).json({ erro: 'nome não pode ser vazio.' });
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

module.exports = router;
