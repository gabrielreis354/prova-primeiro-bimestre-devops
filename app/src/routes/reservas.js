const express = require('express');
const { pool } = require('../db');

const router = express.Router();

const STATUS_VALIDOS = ['pendente', 'confirmada', 'cancelada'];
const ID_MAXIMO = 2147483647; // limite do SERIAL (integer)

const COLUNAS = 'id, cliente, data, status';

// Valida o corpo da requisição; devolve { erro } ou { valores }.
function validar(corpo, { statusObrigatorio }) {
  const { cliente, data, status } = corpo || {};

  if (typeof cliente !== 'string' || cliente.trim() === '') {
    return { erro: 'O campo "cliente" é obrigatório.' };
  }
  if (typeof data !== 'string' || data.trim() === '' || isNaN(new Date(data))) {
    return { erro: 'O campo "data" é obrigatório e deve ser uma data válida (ex.: 2026-10-01T14:00:00Z).' };
  }
  if (status === undefined && statusObrigatorio) {
    return { erro: `O campo "status" é obrigatório (${STATUS_VALIDOS.join(', ')}).` };
  }
  if (status !== undefined && !STATUS_VALIDOS.includes(status)) {
    return { erro: `O campo "status" deve ser um de: ${STATUS_VALIDOS.join(', ')}.` };
  }

  return {
    valores: {
      cliente: cliente.trim(),
      data: new Date(data).toISOString(),
      status: status || 'pendente',
    },
  };
}

// Valida :id antes de chegar no banco (evita erro 500 de sintaxe/overflow do PostgreSQL).
router.param('id', (req, res, next, id) => {
  const numero = Number(id);
  if (!/^\d+$/.test(id) || numero < 1 || numero > ID_MAXIMO) {
    return res.status(400).json({ erro: 'O "id" deve ser um inteiro positivo.' });
  }
  req.reservaId = numero;
  next();
});

const naoEncontrada = (res, id) => res.status(404).json({ erro: `Reserva ${id} não encontrada.` });

// Envolve handlers async para que erros caiam no middleware de erro.
const assincrono = (fn) => (req, res, next) => fn(req, res, next).catch(next);

router.post('/', assincrono(async (req, res) => {
  const { erro, valores } = validar(req.body, { statusObrigatorio: false });
  if (erro) return res.status(400).json({ erro });

  const { rows } = await pool.query(
    `INSERT INTO reservas (cliente, data, status) VALUES ($1, $2, $3) RETURNING ${COLUNAS}`,
    [valores.cliente, valores.data, valores.status]
  );
  res.status(201).json(rows[0]);
}));

router.get('/', assincrono(async (req, res) => {
  const { rows } = await pool.query(`SELECT ${COLUNAS} FROM reservas ORDER BY id`);
  res.json(rows);
}));

router.get('/:id', assincrono(async (req, res) => {
  const { rows } = await pool.query(`SELECT ${COLUNAS} FROM reservas WHERE id = $1`, [req.reservaId]);
  if (rows.length === 0) return naoEncontrada(res, req.reservaId);
  res.json(rows[0]);
}));

router.put('/:id', assincrono(async (req, res) => {
  const { erro, valores } = validar(req.body, { statusObrigatorio: true });
  if (erro) return res.status(400).json({ erro });

  const { rows } = await pool.query(
    `UPDATE reservas SET cliente = $1, data = $2, status = $3 WHERE id = $4 RETURNING ${COLUNAS}`,
    [valores.cliente, valores.data, valores.status, req.reservaId]
  );
  if (rows.length === 0) return naoEncontrada(res, req.reservaId);
  res.json(rows[0]);
}));

router.delete('/:id', assincrono(async (req, res) => {
  const { rows } = await pool.query(`DELETE FROM reservas WHERE id = $1 RETURNING ${COLUNAS}`, [req.reservaId]);
  if (rows.length === 0) return naoEncontrada(res, req.reservaId);
  res.json({ mensagem: 'Reserva removida.', reserva: rows[0] });
}));

module.exports = router;
