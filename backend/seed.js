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
    await pool.query(`DROP TABLE IF EXISTS ingredients, recipe, recipe_type, cuisine, category CASCADE`);

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
        type_id SERIAL PRIMARY KEY,
        type_name VARCHAR(255) NOT NULL
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
        category_id INT REFERENCES category(category_id) ON DELETE CASCADE,
        cuisine_id INT REFERENCES cuisine(cuisine_id) ON DELETE CASCADE,
        type_id INT REFERENCES recipe_type(type_id) ON DELETE CASCADE
      );
    `);

    await pool.query(`
      CREATE TABLE ingredients (
        ingredient_id SERIAL PRIMARY KEY,
        ingredient_name VARCHAR(255) NOT NULL,
        quantity VARCHAR(255),
        calories_per_quantity INT,
        ingredient_type VARCHAR(255),
        cooking_method VARCHAR(255),
        recipe_id INT REFERENCES recipe(recipe_id) ON DELETE CASCADE
      );
    `);

    console.log("Database tables created successfully.");

    // Read the seed data from the JSON file
    const data = await fs.readFile('seedData.json', 'utf-8');
    const seedData = JSON.parse(data);

    // Insert categories
    for (const category of seedData.categories) {
      await pool.query('INSERT INTO category (category_name) VALUES ($1)', [category.category_name]);
    }

    // Insert cuisines
    for (const cuisine of seedData.cuisines) {
      await pool.query('INSERT INTO cuisine (cuisine_name) VALUES ($1)', [cuisine.cuisine_name]);
    }

    // Insert recipe types
    for (const recipeType of seedData.recipeTypes) {
      await pool.query('INSERT INTO recipe_type (type_name) VALUES ($1)', [recipeType.type_name]);
    }

    // Insert recipes (note: make sure category_id, cuisine_id, and type_id are already inserted)
    for (const recipe of seedData.recipes) {
      const { recipe_name, recipe_steps, image, preparation_time, total_calories, category_id, cuisine_id, type_id, ingredients } = recipe;

      const result = await pool.query(
        'INSERT INTO recipe (recipe_name, recipe_steps, image, preparation_time, total_calories, category_id, cuisine_id, type_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING recipe_id',
        [recipe_name, recipe_steps, image, preparation_time, total_calories, category_id, cuisine_id, type_id]
      );
      
      const recipeId = result.rows[0].recipe_id;

      // Insert ingredients for the recipe
      for (const ingredient of ingredients) {
        await pool.query(
          'INSERT INTO ingredients (ingredient_name, quantity, calories_per_quantity, ingredient_type, cooking_method, recipe_id) VALUES ($1, $2, $3, $4, $5, $6)',
          [ingredient.ingredient_name, ingredient.quantity, ingredient.calories_per_quantity, ingredient.ingredient_type, ingredient.cooking_method, recipeId]
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
