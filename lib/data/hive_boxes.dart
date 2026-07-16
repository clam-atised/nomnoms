import 'package:hive_flutter/hive_flutter.dart';
import 'package:nomnom/data/hive_adapters.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';

abstract final class HiveBoxes {
  static const folders = 'folders';
  static const recipes = 'recipes';
  static const ingredientCosts = 'ingredient_costs';
  static const ingredientCalories = 'ingredient_calories';
  static const meta = 'meta';

  static const metaNextRecipeId = 'nextRecipeId';
  static const metaNextFolderId = 'nextFolderId';
  static const metaNightMode = 'nightMode';
  static const metaShowCost = 'showCost';
  static const metaShowCalorie = 'showCalorie';
  static const metaSeedRecipesV1 = 'seedRecipesV1';
  static const metaSeedRecipesV2 = 'seedRecipesV2';
  static const metaSeedRecipesV3 = 'seedRecipesV3';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecipeFolderAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(IngredientAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RecipeAdapter());
    }

    await Future.wait([
      Hive.openBox<RecipeFolder>(folders),
      Hive.openBox<Recipe>(recipes),
      Hive.openBox<double>(ingredientCosts),
      Hive.openBox<double>(ingredientCalories),
      Hive.openBox(meta),
    ]);

    await _ensureMetaDefaults();
  }

  /// Seeds any missing meta keys so upgrades pick up the latest schema.
  static Future<void> _ensureMetaDefaults() async {
    final box = metaBox;
    final defaults = <String, dynamic>{
      metaNextRecipeId: 1,
      metaNextFolderId: 1,
      metaNightMode: false,
      metaShowCost: false,
      metaShowCalorie: false,
    };

    for (final entry in defaults.entries) {
      if (!box.containsKey(entry.key)) {
        await box.put(entry.key, entry.value);
      }
    }
  }

  static Box<RecipeFolder> get foldersBox =>
      Hive.box<RecipeFolder>(folders);

  static Box<Recipe> get recipesBox => Hive.box<Recipe>(recipes);

  static Box<double> get ingredientCostsBox =>
      Hive.box<double>(ingredientCosts);

  static Box<double> get ingredientCaloriesBox =>
      Hive.box<double>(ingredientCalories);

  static Box get metaBox => Hive.box(meta);
}
