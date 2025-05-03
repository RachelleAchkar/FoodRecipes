class Recipe {
  final int recipeId;
  final String name;
  final String steps;
  final String image;
  final int preparationTime;
  final int totalCalories;
  final int servings;
  final int categoryId;
  final String categoryName;
  final int cuisineId;
  final String cuisineName;
  final int typeId;
  final String typeName;

  Recipe({
    required this.recipeId,
    required this.name,
    required this.steps,
    required this.image,
    required this.preparationTime,
    required this.totalCalories,
    required this.servings,
    required this.categoryId,
    required this.categoryName,
    required this.cuisineId,
    required this.cuisineName,
    required this.typeId,
    required this.typeName,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeId: json['recipe_id'],
      name: json['recipe_name'],
      steps: json['recipe_steps'],
      image: json['image'] ?? '',
      preparationTime: json['preparation_time'] ?? 0,
      totalCalories: json['total_calories'] ?? 0,
      servings: json['servings'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      cuisineId: json['cuisine_id'],
      cuisineName: json['cuisine_name'] ?? '',
      typeId: json['recipe_type_id'],
      typeName: json['recipe_type_name'] ?? '',
    );
  }
}
