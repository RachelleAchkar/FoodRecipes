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
  const result = await pool.query(`
    SELECT 
      r.recipe_id,
      r.recipe_name,
      r.recipe_steps,
      r.image,
      r.preparation_time,
      r.total_calories,
      r.category_id,
      c.category_name,
      r.cuisine_id,
      cu.cuisine_name,
      r.type_id,
      t.type_name
    FROM recipe r
    JOIN category c ON r.category_id = c.category_id
    JOIN cuisine cu ON r.cuisine_id = cu.cuisine_id
    JOIN recipe_type t ON r.type_id = t.type_id
  `);

  res.json(result.rows);
});


app.listen(3000, '0.0.0.0', () =>  console.log(`Server running on http://localhost:${port}`));
