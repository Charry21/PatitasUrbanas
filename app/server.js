const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = 3000;

// Configuración de conexión a PostgreSQL
const pool = new Pool({
  user: process.env.POSTGRES_USER || 'admin',
  host: process.env.DB_HOST || 'postgres_db',
  database: process.env.POSTGRES_DB || 'patitas_urbanas',
  password: process.env.POSTGRES_PASSWORD || 'adminpassword',
  port: 5432,
});

app.get('/', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    res.json({
      status: 'success',
      message: 'Patitas Urbanas API está corriendo',
      db_connection: 'Exitosa',
      time: result.rows[0].now
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fallo al conectar con la base de datos' });
  }
});

app.listen(port, () => {
  console.log(`Servidor base ejecutándose en http://localhost:${port}`);
});