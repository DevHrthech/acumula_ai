const { PrismaMariaDb } = require('@prisma/adapter-mariadb');
const { PrismaClient } = require('./generated/prisma');

// O pacote `mariadb` espera o esquema `mariadb://` em strings de conexão,
// mas o Prisma exige `mysql://` no DATABASE_URL — por isso montamos o
// objeto de configuração manualmente em vez de passar a string direto.
const url = new URL(process.env.DATABASE_URL);

// TLS na conexão com o MySQL — confirmado que a Hostmídia suporta (testado
// localmente, negociou DHE-RSA-AES128-GCM-SHA256). `rejectUnauthorized:
// false` porque o certificado do host não é de uma CA pública (comum em
// hospedagem compartilhada) — ainda assim criptografa o tráfego, só não
// valida a cadeia do certificado. Desligável via DB_SSL=false se algum dia
// a conexão local (produção→localhost) não suportar/precisar de TLS.
const usarSsl = process.env.DB_SSL !== 'false';

const adapter = new PrismaMariaDb({
  host: url.hostname,
  port: Number(url.port) || 3306,
  user: decodeURIComponent(url.username),
  password: decodeURIComponent(url.password),
  database: url.pathname.replace(/^\//, ''),
  ...(usarSsl && { ssl: { rejectUnauthorized: false } }),
});
const prisma = new PrismaClient({ adapter });

module.exports = prisma;
