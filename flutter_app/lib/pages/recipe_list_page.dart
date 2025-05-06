import 'dart:convert';
import 'package:flutter/foundation.dart'; // Detects if running on Web
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/filters_page.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'recipe_detail_page.dart';

/// Main widget displaying the list of recipes
class RecipeListPage extends StatefulWidget {
  final VoidCallback onNavigateToFilters;
  final Map<String, dynamic> activeFilters;
  const RecipeListPage({
    super.key,
    required this.onNavigateToFilters,
    required this.activeFilters,
  });

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
  Map<String, dynamic>? _activeFilters= {};
  bool _isLoading = true;

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

void _openFilterPage() async {
  final selectedFilters = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FilterPage(currentFilters: _activeFilters),
    ),
  );

  if (selectedFilters != null) {
    setState(() {
      _activeFilters = selectedFilters;
    });
    await fetchRecipes(); // refetch with filters
  }
}

void _showRandomRecipe() async {
  final baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.102:3000';

  try {
    final response = await http.get(Uri.parse('$baseUrl/api/recipes/random'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final recipe = Recipe.fromJson(jsonData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: recipe),
        ),
      );
    } else {
      throw Exception('Failed to fetch random recipe');
    }
  } catch (e) {
    print('Error fetching random recipe: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not load random recipe.')),
    );
  }
}


  /// Fetches recipes from the backend API
  Future<void> fetchRecipes() async {

 setState(() {
    _isLoading = true;
  });

  final baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://192.168.1.102:3000';

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/recipes/filter'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(_activeFilters), // send filters to backend
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<Recipe> loadedRecipes = jsonResponse.map((r) => Recipe.fromJson(r)).toList();

      if (!mounted) return;
      setState(() {
        _allRecipes = loadedRecipes;
        _filteredRecipes = loadedRecipes.isEmpty ? [] : loadedRecipes;
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  } catch (e) {
    print("Error fetching recipes: $e");
    _isLoading = false;
    _allRecipes = [];
    _filteredRecipes = [];
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
          IconButton(
            icon: Icon(Icons.shuffle),
            onPressed: _showRandomRecipe,
          ),
          // Filter icon navigates to filter screen
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed:_openFilterPage,
          ),
        ],
      ),

      // Main body content
      body:
              _isLoading
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
                            ? Center(child: Text('No recipes matching your filters.'))
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
                                    childAspectRatio: kIsWeb ? 3 / 2.5 : 3 / 2.8,
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
      height: kIsWeb ? 800 : 900,
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
              height: 250,
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

                  // Preparation Time
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

                  // Calories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 5),
                      Text(
                        '${recipe.totalCalories} kcal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  // Servings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 18, color: Colors.deepOrange.shade400),
                      const SizedBox(width: 5),
                      Text(
                        '${recipe.servings} servings',
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
