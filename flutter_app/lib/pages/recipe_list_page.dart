import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/filters_page.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'recipe_detail_page.dart';

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

class _RecipeListPageState extends State<RecipeListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  List<Recipe> _paginatedRecipes = [];
  bool _isLoading = true;
  final int _recipesPerPage = 6;
  int _currentPage = 1;
  Map<String, dynamic>? _activeFilters = {};

  @override
  void initState() {
    super.initState();
    fetchRecipes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        _currentPage = 1;
      });
      await fetchRecipes();
    }
  }

  void _showRandomRecipe() async {
    final baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.54.2:3000';

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/recipes/random'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final recipe = Recipe.fromJson(jsonData);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
        );
      } else {
        throw Exception('Failed to fetch random recipe');
      }
    } catch (e) {
      print('Error fetching random recipe: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load random recipe.')));
    }
  }

  Future<void> fetchRecipes() async {
    setState(() {
      _isLoading = true;
    });

    final baseUrl =
        kIsWeb ? 'http://localhost:3000' : 'http://192.168.54.2:3000';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recipes/filter'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_activeFilters),
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        List<Recipe> loadedRecipes =
            jsonResponse.map((r) => Recipe.fromJson(r)).toList();

        if (!mounted) return;

        setState(() {
          _allRecipes = loadedRecipes;
          _filteredRecipes = loadedRecipes;
          _currentPage = 1;
          _paginatedRecipes = _filteredRecipes.take(_recipesPerPage).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      setState(() {
        _isLoading = false;
        _allRecipes = [];
        _filteredRecipes = [];
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final matched =
        _allRecipes
            .where((recipe) => recipe.name.toLowerCase().contains(query))
            .toList();

    setState(() {
      _filteredRecipes = matched;
      _currentPage = 1;
      _paginatedRecipes = _filteredRecipes.take(_recipesPerPage).toList();
    });
  }

  void _loadMoreRecipes() {
    setState(() {
      _currentPage++;
      final totalToShow = _recipesPerPage * _currentPage;
      _paginatedRecipes = _filteredRecipes.take(totalToShow).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🍲 Food Recipes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 168, 75),
        elevation: 4,
        actions: [
          IconButton(icon: Icon(Icons.shuffle), onPressed: _showRandomRecipe),
          IconButton(icon: Icon(Icons.filter_alt), onPressed: _openFilterPage),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Center(
                      child: SizedBox(
                        width:
                            kIsWeb
                                ? 600
                                : double.infinity, // Make it smaller on web
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
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      children: [
                        _paginatedRecipes.isEmpty
                            ? Center(
                              child: Text('No recipes matching your filters.'),
                            )
                            : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: kIsWeb ? 3 : 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 12,
                                    childAspectRatio:
                                        kIsWeb ? 3 / 2.5 : 3 / 2.8,
                                  ),
                              itemCount: _paginatedRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _paginatedRecipes[index];
                                return GestureDetector(
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
                                  child: _buildRecipeCard(recipe),
                                );
                              },
                            ),
                        if (_paginatedRecipes.length < _filteredRecipes.length)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: SizedBox(
                                width: 200,
                                child: ElevatedButton.icon(
                                  onPressed: _loadMoreRecipes,
                                  icon: Icon(Icons.expand_more),
                                  label: Text('Load More'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 232, 195),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image section with fixed height
            SizedBox(
              height: 180, // Reduced height for the image
              width: double.infinity,
              child: Image.asset(
                'assets/images/recipe_${recipe.recipeId}.jpg',
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
              ),
            ),
            // Content section with scrollable internal content if needed
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        recipe.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepOrange.shade900,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Recipe details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${recipe.preparationTime} min',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 18,
                            color: Colors.deepOrange.shade400,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${recipe.servings} servings',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Wrap for badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildBadge(
                            recipe.categoryName,
                            Colors.orange.shade300,
                          ),
                          _buildBadge(
                            recipe.cuisineName,
                            Colors.green.shade300,
                          ),
                          _buildBadge(recipe.typeName, Colors.blue.shade300),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
