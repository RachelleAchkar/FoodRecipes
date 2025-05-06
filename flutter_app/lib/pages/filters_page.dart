import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class FilterPage extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;
  final Function(Map<String, dynamic>)? onApply;

  const FilterPage({super.key, this.currentFilters, this.onApply});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? selectedCategory;
  String? selectedType;
  String? selectedCuisine;
  double maxCalories = 1000;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> recipeTypes = [];
  List<Map<String, dynamic>> cuisines = [];

  Map<String, int> categoryMap = {};
  Map<String, int> typeMap = {};
  Map<String, int> cuisineMap = {};

  @override
  void initState() {
    super.initState();
    loadSeedData().then((data) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(data['category']);
        recipeTypes = List<Map<String, dynamic>>.from(data['recipe_type']);
        cuisines = List<Map<String, dynamic>>.from(data['cuisine']);

        categoryMap = {
          for (var cat in categories) cat['category_name']: cat['category_id'],
        };
        typeMap = {
          for (var type in recipeTypes) type['recipe_type_name']: type['recipe_type_id'],
        };
        cuisineMap = {
          for (var cui in cuisines) cui['cuisine_name']: cui['cuisine_id'],
        };
      });
    });
  }

  Future<Map<String, dynamic>> loadSeedData() async {
    String jsonString = await rootBundle.loadString('assets/seedData.json');
    final jsonResponse = json.decode(jsonString);
    return jsonResponse;
  }

void applyFilters() {
  final selected = {
    'categoryId': categoryMap[selectedCategory],
    'recipeTypeId': typeMap[selectedType],
    'cuisineId': cuisineMap[selectedCuisine],
    'maxCalories': maxCalories.toInt(),
  };

  if (widget.onApply != null) {
    widget.onApply!(selected);
  }

  // Only pop if this page was pushed (not in bottom nav)
  if (Navigator.of(context).canPop()) {
    Navigator.pop(context, selected);
  }
}


  @override
  Widget build(BuildContext context) {
    List<String> categoryNames = categoryMap.keys.toList();
    List<String> typeNames = typeMap.keys.toList();
    List<String> cuisineNames = cuisineMap.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('🍴 Recipe Filters'),
        backgroundColor: const Color.fromARGB(255, 255, 168, 75),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categoryNames
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Recipe Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedType,
              items: typeNames
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value),
              decoration: InputDecoration(
                labelText: 'Recipe Type',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Cuisine Dropdown
            DropdownButtonFormField<String>(
              value: selectedCuisine,
              items: cuisineNames
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCuisine = value),
              decoration: InputDecoration(
                labelText: 'Cuisine',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Max Calories Slider
            Text(
              'Max Calories: ${maxCalories.toInt()}',
              style: TextStyle(color: Colors.black),
            ),
            Slider(
              value: maxCalories,
              min: 0,
              max: 2000,
              divisions: 40,
              label: maxCalories.toInt().toString(),
              onChanged: (value) => setState(() => maxCalories = value),
              activeColor: Colors.orange.shade700,
              inactiveColor: Colors.orange.shade300,
            ),
            Spacer(),
            
            // Apply Filters Button
            ElevatedButton(
              onPressed: applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
