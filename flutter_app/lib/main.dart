import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/recipe.dart';
import 'package:flutter_app/pages/filters_page.dart';
import 'package:flutter_app/pages/recipe_detail_page.dart';
import 'package:flutter_app/pages/recipe_list_page.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Recipes',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
      routes: {'/filters': (context) => const FilterPage()},
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Map<String, dynamic> _activeFilters = {};
  Key _recipeListKey = UniqueKey();
  void _applyFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _activeFilters = newFilters;
      _recipeListKey = UniqueKey();
      _selectedIndex = 0;
    });
    // Ensure that filters are applied immediately after the update
    _navigateToRecipeList();
  }

  void _navigateToRecipeList() {
    setState(() {
      _selectedIndex = 0; // Navigate to the RecipeListPage
    });
  }

void _onItemTapped(int index) {
  if (index == 0 && _selectedIndex == 0) {
    _recipeListKey = UniqueKey();
    _navigateToRecipeList();
  } else if (index == 1) {
    _showRandomRecipe();
  } else {
    setState(() => _selectedIndex = index);
  }
}

void _showRandomRecipe() async {
  final response = await http.get(Uri.parse('http://localhost:3000/api/recipes/random'));

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final recipe = Recipe.fromJson(jsonData);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: recipe),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch random recipe.')),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      RecipeListPage(
        key: _recipeListKey,
        onNavigateToFilters: () async {
          final filters = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FilterPage(
                currentFilters: _activeFilters,
                onApply: _applyFilters,
              ),
            ),
          );

          if (filters != null) _applyFilters(filters as Map<String, dynamic>);
        },
        activeFilters: _activeFilters,
      ),
      FilterPage(
        currentFilters: _activeFilters,
        onApply: _applyFilters,
      ),
    ];


    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'All Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shuffle),
            label: 'Random',
          ),
        ],
      ),
    );
  }
}

