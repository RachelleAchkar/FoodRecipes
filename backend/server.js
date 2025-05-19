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

/** GET ALL RECIPES */
app.get('/api/recipes', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        r.recipe_id,
        r.recipe_name,
        r.recipe_steps,
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

app.post('/api/recipes/filter', async (req, res) => {
  const {
    categoryId,
    recipeTypeId,
    cuisineId,
    maxCalories,
    ingredientIds,           // 🆕 List of selected ingredient IDs
    matchAllIngredients = false // 🆕 Optional flag for strict vs loose filtering
  } = req.body;

  console.log('Received filters:', req.body);

  let query = `
    SELECT 
      r.recipe_id,
      r.recipe_name,
      r.recipe_steps,
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
    WHERE 1=1
  `;

  const values = [];
  let count = 1;

  if (categoryId) {
    query += ` AND r.category_id = $${count++}`;
    values.push(categoryId);
  }

  if (recipeTypeId) {
    query += ` AND r.recipe_type_id = $${count++}`;
    values.push(recipeTypeId);
  }

  if (cuisineId) {
    query += ` AND r.cuisine_id = $${count++}`;
    values.push(cuisineId);
  }

  if (maxCalories) {
    query += ` AND r.total_calories <= $${count++}`;
    values.push(maxCalories);
  }

  // 🆕 Ingredient filtering logic
  if (ingredientIds && ingredientIds.length > 0) {
    if (matchAllIngredients) {
      // Must match ALL selected ingredients
      query += `
        AND r.recipe_id IN (
          SELECT recipe_id
          FROM recipe_ingredients
          WHERE ingredient_id = ANY($${count++})
          GROUP BY recipe_id
          HAVING COUNT(DISTINCT ingredient_id) = $${count++}
        )
      `;
      values.push(ingredientIds);
      values.push(ingredientIds.length);
    } else {
      // Match ANY selected ingredient
      query += `
        AND r.recipe_id IN (
          SELECT DISTINCT recipe_id
          FROM recipe_ingredients
          WHERE ingredient_id = ANY($${count++})
        )
      `;
      values.push(ingredientIds);
    }
  }

  try {
    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});



/** GET RANDOM RECIPE */
app.get('/api/recipes/random', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        r.recipe_id,
        r.recipe_name,
        r.recipe_steps,
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
      ORDER BY RANDOM()
      LIMIT 1
    `);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'No recipes found.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

app.listen(port, '0.0.0.0', () => console.log(`Server running on http://localhost:${port}`));
