import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/ingredient.dart';

// Stateful widget to show detailed information about a recipe
class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe; //Recipe passed from previous screen
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late Future<List<Ingredient>> _ingredientsFuture;
  // Define base URL based on whether app is running on web or mobile
  final String baseUrl =
      kIsWeb ? 'http://localhost:3000' : 'http://192.168.54.2:3000';

  @override
  void initState() {
    super.initState();
    // Start fetching ingredients when the widget is initialized
    _ingredientsFuture = fetchIngredients(widget.recipe.recipeId);
  }

  // Fetch ingredients for a specific recipe using HTTP GET
  Future<List<Ingredient>> fetchIngredients(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes/$recipeId/ingredients'),
      );

      if (response.statusCode == 200) {
        // Decode JSON and map to list of Ingredient objects
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((i) => Ingredient.fromJson(i)).toList();
      } else {
        // Handle error response
        throw Exception(
          'Failed to load ingredients. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching ingredients: $e');
    }
  }

  // Helper widget to display circular icon with a label and value
  Widget _buildInfoPill(IconData icon, String value, String label) {
    return Container(
      width: 80,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with a circular white background
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.deepOrange),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe; //Get the passed recipe object

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image with rounded corners and shadow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/recipe_${recipe.recipeId}.jpg',
                  height: 320,
                  width: MediaQuery.of(context).size.width * 0.5,
                  fit: BoxFit.cover,
                  // Show a fallback if image fails to load
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 100, color: Colors.grey),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recipe Name
            Text(
              recipe.name,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Category, Cuisine, Type
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(recipe.categoryName),
                  backgroundColor: Colors.orange[50],
                  labelStyle: TextStyle(color: Colors.deepOrange),
                ),
                Chip(
                  label: Text(recipe.cuisineName),
                  backgroundColor: Colors.orange[50],
                  labelStyle: TextStyle(color: Colors.deepOrange),
                ),
                Chip(
                  label: Text(recipe.typeName),
                  backgroundColor: Colors.orange[50],
                  labelStyle: TextStyle(color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Prep Time, servings and Calories
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align items to the left
              children: [
                // Prep Time Pill
                _buildInfoPill(
                  Icons.timer,
                  '${recipe.preparationTime}',
                  'Mins',
                ),
                const SizedBox(width: 20), // Adjust the space between the pills
                // Calories Pill
                _buildInfoPill(
                  Icons.local_fire_department,
                  '${recipe.totalCalories}',
                  'Cal',
                ),
                const SizedBox(width: 20), // Adjust the space between the pills
                // Servings Pill
                _buildInfoPill(
                  Icons.restaurant,
                  '${recipe.servings}', // Assuming the servings field exists in your Recipe model
                  'Servings',
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Ingredients
            Text(
              '🧂 Ingredients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Display ingredients from API using FutureBuilder
            FutureBuilder<List<Ingredient>>(
              future: _ingredientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error loading ingredients: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No ingredients found.');
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        snapshot.data!
                            .map(
                              (ingredient) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${ingredient.name} (${ingredient.quantity})',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 30),

            // Steps
            Text(
              '👨‍🍳 Steps',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Split the steps into a numbered list
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  recipe.steps
                      .split(
                        RegExp(r'\n+|\. '),
                      ) // split steps by newlines or dot+space
                      .map((s) => s.trim()) // trim whitespace
                      .where((s) => s.isNotEmpty) //remove empty line
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ', // Step number
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${entry.value}.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
