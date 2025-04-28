class Recipe {
  final int id;
  final String name;
  final String steps;

  Recipe({required this.id, required this.name, required this.steps});

  // to convert JSON data to a Recipe object
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['recipe_id'], 
      name: json['recipe_name'], 
      steps: json['recipe_steps'],
    );
  }
}
