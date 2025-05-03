const { Pool } = require('pg');
const fs = require('fs').promises; // to read JSON file asynchronously

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'foodrecipes',
  password: 'admin',
  port: 5432,
});

async function seedDatabase() {
  try {
    await pool.query(`DROP TABLE IF EXISTS ingredients, recipe, recipe_type, cuisine, category, cooking_method, ingredient_type, recipe_ingredients CASCADE`);

    await pool.query(`
      CREATE TABLE category (
        category_id SERIAL PRIMARY KEY,
        category_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE cuisine (
        cuisine_id SERIAL PRIMARY KEY,
        cuisine_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE recipe_type (
        recipe_type_id SERIAL PRIMARY KEY,
        recipe_type_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE cooking_method (
        cooking_method_id SERIAL PRIMARY KEY,
        cooking_method_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE ingredient_type (
        ingredient_type_id SERIAL PRIMARY KEY,
        ingredient_type_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE ingredients (
        ingredient_id SERIAL PRIMARY KEY,
        ingredient_name VARCHAR(255) NOT NULL
      );
    `);

    await pool.query(`
      CREATE TABLE recipe (
        recipe_id SERIAL PRIMARY KEY,
        recipe_name VARCHAR(255) NOT NULL,
        recipe_steps TEXT,
        image TEXT,
        preparation_time INT,
        total_calories INT,
        servings INT,
        category_id INT REFERENCES category(category_id) ON DELETE CASCADE,
        cuisine_id INT REFERENCES cuisine(cuisine_id) ON DELETE CASCADE,
        recipe_type_id INT REFERENCES recipe_type(recipe_type_id) ON DELETE CASCADE
      );
    `);

    await pool.query(`
      CREATE TABLE recipe_ingredients (
        recipe_ingredient_id SERIAL PRIMARY KEY,
        quantity VARCHAR(255),
        calories_per_quantity INT,
        recipe_id INT REFERENCES recipe(recipe_id) ON DELETE CASCADE,
        ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
        ingredient_type_id INT REFERENCES ingredient_type(ingredient_type_id) ON DELETE CASCADE,
        cooking_method_id INT REFERENCES cooking_method(cooking_method_id) ON DELETE CASCADE
      );
    `);

    console.log("Database tables created successfully.");

    // Read the seed data from the JSON file
    const data = await fs.readFile('seedData.json', 'utf-8');
    const seedData = JSON.parse(data);

    // Insert categories
    for (const category of seedData.category) {
      await pool.query('INSERT INTO category (category_name) VALUES ($1)', [category.category_name]);
    }

    // Insert cuisines
    for (const cuisine of seedData.cuisine) {
      await pool.query('INSERT INTO cuisine (cuisine_name) VALUES ($1)', [cuisine.cuisine_name]);
    }

    // Insert recipe types
    for (const recipeType of seedData.recipe_type) {
      await pool.query('INSERT INTO recipe_type (recipe_type_name) VALUES ($1)', [recipeType.recipe_type_name]);
    }

    // Insert cooking methods
    for (const method of seedData.cooking_method) {
      await pool.query('INSERT INTO cooking_method (cooking_method_name) VALUES ($1)', [method.cooking_method_name]);
    }

    // Insert ingredient types
    for (const type of seedData.ingredient_types) {
      await pool.query('INSERT INTO ingredient_type (ingredient_type_name) VALUES ($1)', [type.ingredient_type_name]);
    }

    // Insert ingredients (just the name)
    for (const ingredient of seedData.ingredients) {
      await pool.query('INSERT INTO ingredients (ingredient_name) VALUES ($1)', [ingredient.ingredient_name]);
    }

    // Insert recipes and recipe ingredients
    for (const recipe of seedData.recipe) {
      const {
        recipe_id,
        recipe_name,
        recipe_steps,
        image,
        preparation_time,
        total_calories,
        servings,
        category_id,
        cuisine_id,
        recipe_type_id
      } = recipe;

      const result = await pool.query(
        `INSERT INTO recipe (
          recipe_name, recipe_steps, image, preparation_time, total_calories, servings,
          category_id, cuisine_id, recipe_type_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING recipe_id`,
        [
          recipe_name, recipe_steps, image, preparation_time, total_calories, servings,
          category_id, cuisine_id, recipe_type_id
        ]
      );

      const recipeId = result.rows[0].recipe_id;

      // Insert each recipe_ingredient entry from the recipe_ingredients array
      const recipeIngredients = seedData.recipe_ingredients.filter(
        (ri) => ri.recipe_id === recipe_id
      );

      // Log cooking_method_id values to check for any issues
      console.log('Inserting recipe ingredients for recipe_id:', recipe_id);

      for (const ingredient of recipeIngredients) {
        console.log(`Inserting ingredient with cooking_method_id: ${ingredient.cooking_method_id}`);
        await pool.query(
          `INSERT INTO recipe_ingredients (
            quantity, calories_per_quantity, recipe_id,
            ingredient_id, ingredient_type_id, cooking_method_id
          ) VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            ingredient.quantity,
            ingredient.calories_per_quantity,
            recipeId,
            ingredient.ingredient_id,
            ingredient.ingredient_type_id,
            ingredient.cooking_method_id
          ]
        );
      }
    }

    console.log("Seed data inserted successfully.");
  } catch (err) {
    console.error("Error during seeding:", err);
  } finally {
    await pool.end();
  }
}


seedDatabase().catch((err) => console.error(err));
