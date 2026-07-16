import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';

class SeedData {
  const SeedData({required this.folders, required this.recipes});

  final List<RecipeFolder> folders;
  final List<Recipe> recipes;
}

Color parseSeedColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

Ingredient parseSeedIngredient(Map<String, dynamic> json) {
  final unitName = json['unit'] as String?;
  return Ingredient(
    quantity: (json['quantity'] as num).toDouble(),
    unit: unitName == null ? null : IngredientUnit.values.byName(unitName),
    name: json['name'] as String,
  );
}

RecipeFolder parseSeedFolder(Map<String, dynamic> json) {
  return RecipeFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    color: parseSeedColor(json['color'] as String),
  );
}

Recipe parseSeedRecipe(Map<String, dynamic> json, {DateTime? createdAt}) {
  final ingredientsJson = (json['ingredients'] as List).cast<Map<String, dynamic>>();
  return Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    ingredients: ingredientsJson.map(parseSeedIngredient).toList(),
    preparationMinutes: json['preparationMinutes'] as int,
    folderId: json['folderId'] as String,
    createdAt: createdAt ?? DateTime.now(),
    timesOfDay: (json['timesOfDay'] as List)
        .cast<String>()
        .map(TimeOfDayOption.values.byName)
        .toList(),
    daysOfWeek: (json['daysOfWeek'] as List)
        .cast<String>()
        .map(DayOfWeekOption.values.byName)
        .toList(),
    link: json['link'] as String? ?? '',
    instructions: json['instructions'] as String? ?? '',
  );
}

SeedData parseSeedJson(String source, {DateTime? createdAt}) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final foldersJson = (root['folders'] as List).cast<Map<String, dynamic>>();
  final recipesJson = (root['recipes'] as List).cast<Map<String, dynamic>>();
  final now = createdAt ?? DateTime.now();
  return SeedData(
    folders: foldersJson.map(parseSeedFolder).toList(),
    recipes: recipesJson
        .map((json) => parseSeedRecipe(json, createdAt: now))
        .toList(),
  );
}

Future<SeedData> loadBundledSeedRecipes({DateTime? createdAt}) async {
  final source = await rootBundle.loadString('assets/seed/recipes.json');
  return parseSeedJson(source, createdAt: createdAt);
}
