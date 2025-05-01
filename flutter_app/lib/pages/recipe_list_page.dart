import 'dart:convert';
import 'package:flutter/foundation.dart'; // Detects if running on Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'recipe_detail_page.dart';

/// Main widget displaying the list of recipes
class RecipeListPage extends StatefulWidget {
  final VoidCallback
  onNavigateToFilters; // Callback to navigate to filter screen

  const RecipeListPage({super.key, required this.onNavigateToFilters});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

// This is the private state class associated with the RecipeListPage widget.
class _RecipeListPageState extends State<RecipeListPage> {
  // Controller for managing and listening to changes in the search TextField input.
  // It helps update the UI based on the user's search query.
  TextEditingController _searchController = TextEditingController();

  List<Recipe> _allRecipes = []; // All recipes fetched from the API
  List<Recipe> _filteredRecipes = []; // Recipes filtered by the search query

  @override
  void initState() {
    super.initState();
    fetchRecipes(); // Fetch data on load
    _searchController.addListener(
      _onSearchChanged,
    ); // Add listener to search field
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up controller
    super.dispose();
  }

  /// Fetches recipes from the backend API
  Future<void> fetchRecipes() async {
    final baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.102:3000';

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/recipes'));
      // Check if the HTTP response status code is 200 (OK)
      if (response.statusCode == 200) {
        //Decode the response body (JSON string) into a list of dynamic objects
        List jsonResponse = json.decode(response.body);
        // Convert the JSON response into a list of Recipe objects
        List<Recipe> loadedRecipes =
            jsonResponse.map((recipe) => Recipe.fromJson(recipe)).toList();

        // Update the state with the loaded recipes
        setState(() {
          _allRecipes = loadedRecipes; // Store the full list of recipes
          _filteredRecipes =
              loadedRecipes; // Initialize the filtered list with all recipes (before any search/filtering)
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print("Error fetching recipes: $e");
    }
  }

  // Updates the filtered list of recipes as the user types in the search box
  void _onSearchChanged() {
    // Get the current text from the search field and convert it to lowercase for case-insensitive comparison
    final query = _searchController.text.toLowerCase();

    // Update the state so the UI reflects the filtered recipe list
    setState(() {
      // Filter the list of all recipes to include only those whose names contain the query string
      _filteredRecipes =
          _allRecipes
              .where((recipe) => recipe.name.toLowerCase().contains(query))
              .toList();
    });
  }

  // Build UI for the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar with title and filter button
      appBar: AppBar(
        title: Text(
          '🍲 Food Recipes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 168, 75),
        elevation: 4,
        actions: [
          // Shuffle icon
          IconButton(icon: Icon(Icons.shuffle), onPressed: () {}),
          // Filter icon navigates to filter screen
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: widget.onNavigateToFilters,
          ),
        ],
      ),

      // Main body content
      body:
          _allRecipes.isEmpty
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loader while fetching
              : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search recipes...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.deepOrange,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Recipe List
                  Expanded(
                    child:
                        _filteredRecipes.isEmpty
                            ? Center(child: Text('No recipes found.'))
                            : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        kIsWeb
                                            ? 3
                                            : 1, // 3 columns on Web, 1 on Mobile
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: kIsWeb ? 3 / 2 : 3 / 2.8,
                                  ),
                              itemCount: _filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _filteredRecipes[index];
                                return GestureDetector(
                                  // When user taps a recipe, navigate to detail page
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => RecipeDetailPage(
                                              recipe: recipe,
                                            ),
                                      ),
                                    );
                                  },
                                  // Build card for individual recipe
                                  child: _buildRecipeCard(recipe),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  /// Builds each recipe card UI
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
            // Recipe image
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

            // Text and details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Recipe Name
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

                  // Preparation time
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

                  // Calories info
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

                  // Tags: Category, Cuisine, Type
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

  // Helper to build styled badges (categoty, cuisine, type)
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
