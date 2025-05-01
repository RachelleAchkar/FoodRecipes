import 'dart:convert';
import 'package:flutter/foundation.dart'; // To check if app is running on Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import 'recipe_detail_page.dart';

// Main widget that shows the list of recipes
class RecipeListPage extends StatelessWidget {
  final VoidCallback
  onNavigateToFilters; // Callback function used for navigating to filters
  const RecipeListPage({super.key, required this.onNavigateToFilters});
  // fetch list of recipes from backend API
  Future<List<Recipe>> fetchRecipes() async {
    final baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.102:3000';
    final response = await http.get(Uri.parse('$baseUrl/api/recipes'));

    // Check if the HTTP response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Decode the response body (JSON string) into a list of dynamic objects
      List jsonResponse = json.decode(response.body);
      // Map each JSON object to a Recipe object and return the resulting list
      return jsonResponse.map((recipe) => Recipe.fromJson(recipe)).toList();
    } else {
      // If the response was not successful, throw an exception
      throw Exception('Failed to load recipes');
    }
  }

  // Build UI for the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //App bar setup
      appBar: AppBar(
        title: Text(
          '🍲 Food Recipes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 168, 75),
        elevation: 4,
        actions: [
          //Shuffle icon
          IconButton(icon: Icon(Icons.shuffle), onPressed: () {}),
          //Filter icon navigates to filter screen
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/filters');
            },
          ),
        ],
      ),

      //Body loads recipes using FutureBuilder
      body: FutureBuilder<List<Recipe>>(
        future: fetchRecipes(), // Call fetchRecipes() function
        builder: (context, snapshot) {
          //While waiting for response, show loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
            //If an error occured during API call
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
            //If no data returned
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recipes available.'));
          } else {
            //If data is successfully received
            final recipes =
                snapshot
                    .data!; //Retrieving the data returned from the snapshot(! tells Dart: “I’m sure this isn’t null.”)
            //Display recipes using GridView
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsWeb ? 3 : 1, // 3 columns on Web, 1 on Mobile
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: kIsWeb ? 3 / 2 : 3 / 2.8,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return GestureDetector(
                  // When user taps a recipe, navigate to detail page
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                  // Build card for individual recipe
                  child: _buildRecipeCard(recipe),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Widget to build the UI card for each recipe
  Widget _buildRecipeCard(Recipe recipe) {
    return SizedBox(
      height: kIsWeb ? 400 : 900,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300), // Smooth animation
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 232, 195),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 6), // shadow shifted 6 pixels down
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Ensures smooth curved edges
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Recipe image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.asset(
                'assets/images/recipe_${recipe.recipeId}.jpg', // Image file should match this pattern
                fit: BoxFit.cover,
                errorBuilder: // If image not found, show default icon
                    (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
              ),
            ),
            //Recipe details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Recipe name
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepOrange.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Preparation time with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 5),
                      Text(
                        '${recipe.preparationTime} min',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  // Total calories with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${recipe.totalCalories} kcal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tags like category, cuisine, and type
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildBadge(recipe.categoryName, Colors.orange.shade300),
                      _buildBadge(recipe.cuisineName, Colors.green.shade300),
                      _buildBadge(recipe.typeName, Colors.blue.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build colored label badges (e.g., category, cuisine)
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
