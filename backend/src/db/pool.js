const { Pool } = require('pg');
const { databaseUrl } = require('../config/env');

const pool = new Pool({ connectionString: databaseUrl });

pool.on('error', (err) => {
  console.error('Error inesperado en el pool de PostgreSQL:', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
