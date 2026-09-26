const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'reservas',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'reservas',
  // RDS PostgreSQL >= 15 exige SSL; localmente (Compose) fica desligado.
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

const SCHEMA = `
  CREATE TABLE IF NOT EXISTS reservas (
    id      SERIAL PRIMARY KEY,
    cliente TEXT NOT NULL,
    data    TIMESTAMPTZ NOT NULL,
    status  TEXT NOT NULL DEFAULT 'pendente'
            CHECK (status IN ('pendente', 'confirmada', 'cancelada'))
  )`;

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// O banco (principalmente o RDS) pode demorar a aceitar conexões: tenta de novo com backoff.
async function iniciarBanco({ tentativas = 30, esperaInicialMs = 1000 } = {}) {
  let espera = esperaInicialMs;
  for (let i = 1; i <= tentativas; i++) {
    try {
      await pool.query(SCHEMA);
      console.log('Banco de dados pronto.');
      return;
    } catch (erro) {
      console.log(`Banco indisponível (tentativa ${i}/${tentativas}): ${erro.message}`);
      if (i === tentativas) throw erro;
      await esperar(espera);
      espera = Math.min(espera * 2, 10000);
    }
  }
}

module.exports = { pool, iniciarBanco };
