const express = require('express');
const { iniciarBanco } = require('./db');
const reservas = require('./routes/reservas');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/reservas', reservas);

// JSON malformado no corpo → 400; qualquer outro erro inesperado → 500 sem vazar detalhes.
app.use((erro, req, res, next) => {
  if (erro.type === 'entity.parse.failed') {
    return res.status(400).json({ erro: 'Corpo da requisição não é um JSON válido.' });
  }
  console.error(erro);
  res.status(500).json({ erro: 'Erro interno do servidor.' });
});

iniciarBanco()
  .then(() => {
    app.listen(PORT, () => console.log(`API de Reservas rodando na porta ${PORT}`));
  })
  .catch((erro) => {
    console.error('Não foi possível iniciar o banco de dados:', erro.message);
    process.exit(1);
  });
