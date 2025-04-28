const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = 3000;

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'foodrecipes',
    password: 'admin',
    port: 5432,
  });
  

app.use(cors());
app.use(bodyParser.json());

app.get('/api/recipes', async (req, res) => {
    const result = await pool.query('SELECT * FROM recipe');
    res.json(result.rows);
  });
  
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
