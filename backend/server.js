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
    password: 'vanessa123',
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

app.get('/api/recipes/:id/ingredients', async (req, res) => {
  const recipeId = req.params.id;

  try {
    const result = await pool.query(`
      SELECT 
        i.ingredient_id,
        ri.recipe_id,
        i.ingredient_name,
        i.quantity
      FROM ingredients i
      JOIN recipe ri ON ri.recipe_id = i.recipe_id
      WHERE ri.recipe_id = $1
    `, [recipeId]);

    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).send('Server Error');
  }
});





app.listen(3000, '0.0.0.0', () =>  console.log(`Server running on http://localhost:${port}`));
