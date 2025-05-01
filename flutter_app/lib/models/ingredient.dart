class Ingredient {
  final int ingredientId;
  final int recipeId;
  final String name;
  final String quantity;

  Ingredient({
    required this.ingredientId,
    required this.recipeId,
    required this.name,
    required this.quantity,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      ingredientId: json['ingredient_id'] ?? 0,
      recipeId: json['recipe_id'] ?? 0,
      name: json['ingredient_name'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }
}
