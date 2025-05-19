import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';

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
  List<Map<String, dynamic>> ingredients = [];

  Map<String, int> categoryMap = {};
  Map<String, int> typeMap = {};
  Map<String, int> cuisineMap = {};

  List<MultiSelectItem<int>> ingredientOptions = [];
  List<int> selectedIngredientIds = [];

  @override
  void initState() {
    super.initState();
    loadSeedData().then((data) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(data['category']);
        recipeTypes = List<Map<String, dynamic>>.from(data['recipe_type']);
        cuisines = List<Map<String, dynamic>>.from(data['cuisine']);
        ingredients = List<Map<String, dynamic>>.from(data['ingredients']);

        categoryMap = {
          for (var cat in categories) cat['category_name']: cat['category_id'],
        };
        typeMap = {
          for (var type in recipeTypes)
            type['recipe_type_name']: type['recipe_type_id'],
        };
        cuisineMap = {
          for (var cui in cuisines) cui['cuisine_name']: cui['cuisine_id'],
        };

        ingredientOptions =
            ingredients
                .map(
                  (ingredient) => MultiSelectItem<int>(
                    ingredient['ingredient_id'],
                    ingredient['ingredient_name'],
                  ),
                )
                .toList();
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
      'ingredientIds': selectedIngredientIds,
    };

    if (widget.onApply != null) {
      widget.onApply!(selected);
    }

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
      backgroundColor: Colors.orange.shade50,
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
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items:
                  categoryNames
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
              decoration: _inputDecoration('Category', Icons.restaurant_menu),
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedType,
              items:
                  typeNames
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (value) => setState(() => selectedType = value),
              decoration: _inputDecoration('Recipe Type', Icons.ramen_dining),
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedCuisine,
              items:
                  cuisineNames
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (value) => setState(() => selectedCuisine = value),
              decoration: _inputDecoration('Cuisine', Icons.public),
            ),
            SizedBox(height: 16),

            MultiSelectDialogField<int>(
              items: ingredientOptions,
              title: Text("Ingredients"),
              selectedColor: Colors.deepOrange,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
              ),
              buttonIcon: Icon(Icons.fastfood, color: Colors.deepOrange),
              buttonText: Text(
                "Select Ingredients",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onConfirm: (values) {
                selectedIngredientIds = values;
              },
            ),
            SizedBox(height: 16),

            Text(
              'Max Calories: ${maxCalories.toInt()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(171, 230, 73, 25),
              ),
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

            Center(
              child: Container(
                width: kIsWeb ? 200 : double.infinity,
                child: ElevatedButton(
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.orange.shade100,
      labelText: label,
      labelStyle: TextStyle(color: Colors.black),
      prefixIcon: Icon(icon, color: Colors.deepOrange),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepOrange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
