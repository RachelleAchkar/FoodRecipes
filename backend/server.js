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

/** GET ALL RECIPES */
app.get('/api/recipes', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        r.recipe_id,
        r.recipe_name,
        r.recipe_steps,
        r.image,
        r.preparation_time,
        r.total_calories,
        r.servings,
        r.category_id,
        c.category_name,
        r.cuisine_id,
        cu.cuisine_name,
        r.recipe_type_id,
        rt.recipe_type_name
      FROM recipe r
      JOIN category c ON r.category_id = c.category_id
      JOIN cuisine cu ON r.cuisine_id = cu.cuisine_id
      JOIN recipe_type rt ON r.recipe_type_id = rt.recipe_type_id
    `);

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

/** GET INGREDIENTS FOR A RECIPE */
app.get('/api/recipes/:id/ingredients', async (req, res) => {
  const recipeId = req.params.id;

  try {
    const result = await pool.query(`
      SELECT 
        ri.recipe_ingredient_id,
        ri.recipe_id,
        i.ingredient_id,
        i.ingredient_name,
        ri.quantity,
        ri.calories_per_quantity,
        it.ingredient_type_id,
        it.ingredient_type_name,
        cm.cooking_method_id,
        cm.cooking_method_name
      FROM recipe_ingredients ri
      JOIN ingredients i ON ri.ingredient_id = i.ingredient_id
      JOIN ingredient_type it ON ri.ingredient_type_id = it.ingredient_type_id
      JOIN cooking_method cm ON ri.cooking_method_id = cm.cooking_method_id
      WHERE ri.recipe_id = $1
    `, [recipeId]);

    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).send('Server Error');
  }
});

app.listen(port, '0.0.0.0', () => console.log(`Server running on http://localhost:${port}`));
