import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nomnom/data/hive_boxes.dart';
import 'package:nomnom/data/seed_recipes.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/theme/app_colors.dart';

class RecipeEstimate {
  const RecipeEstimate({required this.total, required this.isComplete});

  final double total;
  final bool isComplete;
}

class RecipeStore extends ChangeNotifier {
  static const String recentFolderId = 'recent';
  static const String seedFolderMalaysianCuisine =
      'seed_folder_malaysian_cuisine';
  static const Set<String> seedRecipeIds = {
    'seed_recipe_nasi_lemak',
    'seed_recipe_tosai',
    'seed_recipe_wat_tan_hor',
  };

  RecipeStore() {
    _folders.add(
      const RecipeFolder(
        id: recentFolderId,
        name: 'Recent recipes',
        color: kTextGreen,
      ),
    );
  }

  final List<RecipeFolder> _folders = [];
  final List<Recipe> _recipes = [];
  final Map<String, double> _ingredientCosts = {};
  final Map<String, double> _ingredientCalories = {};
  final Map<String, double> _ingredientProteins = {};
  int _nextId = 1;
  int _nextFolderId = 1;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<Recipe> get allRecipes => List.unmodifiable(_recipes);

  Map<String, double> get ingredientCosts =>
      Map.unmodifiable(_ingredientCosts);
  Map<String, double> get ingredientCalories =>
      Map.unmodifiable(_ingredientCalories);
  Map<String, double> get ingredientProteins =>
      Map.unmodifiable(_ingredientProteins);

  int get nextRecipeIdCounter => _nextId;
  int get nextFolderIdCounter => _nextFolderId;

  /// True when the store has anything beyond the bundled seed set.
  bool get hasUserData {
    if (_ingredientCosts.isNotEmpty ||
        _ingredientCalories.isNotEmpty ||
        _ingredientProteins.isNotEmpty) {
      return true;
    }
    if (_recipes.any((r) => !seedRecipeIds.contains(r.id))) {
      return true;
    }
    return _folders.any(
      (f) =>
          f.id != recentFolderId && f.id != seedFolderMalaysianCuisine,
    );
  }

  bool get _hiveReady => Hive.isBoxOpen(HiveBoxes.folders);

  Future<void> load() async {
    if (!_hiveReady) {
      _loaded = true;
      notifyListeners();
      return;
    }

    final foldersBox = HiveBoxes.foldersBox;
    final recipesBox = HiveBoxes.recipesBox;
    final costsBox = HiveBoxes.ingredientCostsBox;
    final caloriesBox = HiveBoxes.ingredientCaloriesBox;
    final proteinsBox = HiveBoxes.ingredientProteinsBox;
    final metaBox = HiveBoxes.metaBox;

    _folders
      ..clear()
      ..addAll(foldersBox.values);

    if (_folders.every((f) => f.id != recentFolderId)) {
      final recent = const RecipeFolder(
        id: recentFolderId,
        name: 'Recent recipes',
        color: kTextGreen,
      );
      _folders.insert(0, recent);
      await foldersBox.put(recent.id, recent);
    } else {
      _folders.sort((a, b) {
        if (a.id == recentFolderId) return -1;
        if (b.id == recentFolderId) return 1;
        return 0;
      });
    }

    _recipes
      ..clear()
      ..addAll(recipesBox.values);

    _ingredientCosts
      ..clear()
      ..addAll(Map<String, double>.from(costsBox.toMap()));

    _ingredientCalories
      ..clear()
      ..addAll(Map<String, double>.from(caloriesBox.toMap()));

    _ingredientProteins
      ..clear()
      ..addAll(Map<String, double>.from(proteinsBox.toMap()));

    _nextId = metaBox.get(HiveBoxes.metaNextRecipeId, defaultValue: 1) as int;
    _nextFolderId =
        metaBox.get(HiveBoxes.metaNextFolderId, defaultValue: 1) as int;

    for (final recipe in _recipes) {
      final match = RegExp(r'^recipe_(\d+)$').firstMatch(recipe.id);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n >= _nextId) _nextId = n + 1;
      }
    }
    for (final folder in _folders) {
      final match = RegExp(r'^folder_(\d+)$').firstMatch(folder.id);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n >= _nextFolderId) _nextFolderId = n + 1;
      }
    }

    await _ensureBundledSeed();

    _loaded = true;
    notifyListeners();
  }

  static const _seedRecipeNasiLemak = 'seed_recipe_nasi_lemak';
  static const _seedRecipeTosai = 'seed_recipe_tosai';
  static const _seedRecipeWatTanHor = 'seed_recipe_wat_tan_hor';

  Future<void> _ensureBundledSeed() async {
    if (!_hiveReady) return;

    final metaBox = HiveBoxes.metaBox;
    final needV1 = metaBox.get(HiveBoxes.metaSeedRecipesV1) != true;
    final needV2 = metaBox.get(HiveBoxes.metaSeedRecipesV2) != true;
    final needV3 = metaBox.get(HiveBoxes.metaSeedRecipesV3) != true;
    if (!needV1 && !needV2 && !needV3) return;

    try {
      final seed = await loadBundledSeedRecipes();

      if (needV1) {
        await _insertSeedFolder(
          seed,
          id: seedFolderMalaysianCuisine,
        );
        await _insertSeedRecipe(seed, id: _seedRecipeNasiLemak);
        await metaBox.put(HiveBoxes.metaSeedRecipesV1, true);
      }

      if (needV2) {
        await _insertSeedFolder(
          seed,
          id: seedFolderMalaysianCuisine,
        );
        await _insertSeedRecipe(seed, id: _seedRecipeTosai);
        await metaBox.put(HiveBoxes.metaSeedRecipesV2, true);
      }

      if (needV3) {
        await _insertSeedFolder(
          seed,
          id: seedFolderMalaysianCuisine,
        );
        await _insertSeedRecipe(seed, id: _seedRecipeWatTanHor);
        await metaBox.put(HiveBoxes.metaSeedRecipesV3, true);
      }
    } catch (_) {
      // Leave unset flags so a later launch can retry if the asset failed to load.
    }
  }

  Future<void> _insertSeedFolder(
    SeedData seed, {
    required String id,
  }) async {
    if (_folders.any((f) => f.id == id)) return;
    RecipeFolder? folder;
    for (final candidate in seed.folders) {
      if (candidate.id == id) {
        folder = candidate;
        break;
      }
    }
    if (folder == null) return;
    _folders.add(folder);
    await HiveBoxes.foldersBox.put(folder.id, folder);
  }

  Future<void> _insertSeedRecipe(
    SeedData seed, {
    required String id,
  }) async {
    if (_recipes.any((r) => r.id == id)) return;
    Recipe? recipe;
    for (final candidate in seed.recipes) {
      if (candidate.id == id) {
        recipe = candidate;
        break;
      }
    }
    if (recipe == null) return;
    _recipes.add(recipe);
    await HiveBoxes.recipesBox.put(recipe.id, recipe);
  }

  Future<void> _persistMeta() async {
    if (!_hiveReady) return;
    final metaBox = HiveBoxes.metaBox;
    await metaBox.put(HiveBoxes.metaNextRecipeId, _nextId);
    await metaBox.put(HiveBoxes.metaNextFolderId, _nextFolderId);
  }

  static String normalizeIngredientName(String name) =>
      name.trim().toLowerCase();

  /// Unique ingredient names across all recipes, normalized and sorted.
  List<String> get uniqueIngredientNames {
    final names = <String>{};
    for (final recipe in _recipes) {
      for (final ingredient in recipe.ingredients) {
        final normalized = normalizeIngredientName(ingredient.name);
        if (normalized.isNotEmpty) names.add(normalized);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  double? costFor(String name) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return null;
    return _ingredientCosts[key];
  }

  void setIngredientCost(String name, double? cost) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return;

    if (cost == null) {
      if (!_ingredientCosts.containsKey(key)) return;
      _ingredientCosts.remove(key);
      if (_hiveReady) HiveBoxes.ingredientCostsBox.delete(key);
    } else {
      _ingredientCosts[key] = cost;
      if (_hiveReady) HiveBoxes.ingredientCostsBox.put(key, cost);
    }
    notifyListeners();
  }

  double? calorieFor(String name) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return null;
    return _ingredientCalories[key];
  }

  void setIngredientCalorie(String name, double? calories) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return;

    if (calories == null) {
      if (!_ingredientCalories.containsKey(key)) return;
      _ingredientCalories.remove(key);
      if (_hiveReady) HiveBoxes.ingredientCaloriesBox.delete(key);
    } else {
      _ingredientCalories[key] = calories;
      if (_hiveReady) HiveBoxes.ingredientCaloriesBox.put(key, calories);
    }
    notifyListeners();
  }

  double? proteinFor(String name) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return null;
    return _ingredientProteins[key];
  }

  void setIngredientProtein(String name, double? protein) {
    final key = normalizeIngredientName(name);
    if (key.isEmpty) return;

    if (protein == null) {
      if (!_ingredientProteins.containsKey(key)) return;
      _ingredientProteins.remove(key);
      if (_hiveReady) HiveBoxes.ingredientProteinsBox.delete(key);
    } else {
      _ingredientProteins[key] = protein;
      if (_hiveReady) HiveBoxes.ingredientProteinsBox.put(key, protein);
    }
    notifyListeners();
  }

  RecipeEstimate costEstimateFor(Recipe recipe) {
    return _estimateFor(
      recipe,
      valueFor: costFor,
    );
  }

  RecipeEstimate calorieEstimateFor(Recipe recipe) {
    return _estimateFor(
      recipe,
      valueFor: calorieFor,
    );
  }

  /// Sums protein for ingredients that have a value; missing values are skipped
  /// and the estimate is always treated as complete.
  RecipeEstimate proteinEstimateFor(Recipe recipe) {
    if (recipe.ingredients.isEmpty) {
      return const RecipeEstimate(total: 0, isComplete: true);
    }

    var total = 0.0;
    for (final ingredient in recipe.ingredients) {
      final value = proteinFor(ingredient.name);
      if (value != null) {
        total += ingredient.quantity * value;
      }
    }
    return RecipeEstimate(total: total, isComplete: true);
  }

  RecipeEstimate _estimateFor(
    Recipe recipe, {
    required double? Function(String name) valueFor,
  }) {
    if (recipe.ingredients.isEmpty) {
      return const RecipeEstimate(total: 0, isComplete: true);
    }

    var total = 0.0;
    var complete = true;
    for (final ingredient in recipe.ingredients) {
      final value = valueFor(ingredient.name);
      if (value == null) {
        complete = false;
      } else {
        total += ingredient.quantity * value;
      }
    }
    return RecipeEstimate(total: total, isComplete: complete);
  }

  static const costEstimateInfoMessage =
      'Estimated cost. Please fill for more accurate estimate cost';
  static const calorieEstimateInfoMessage =
      'Estimated calories. Please fill for more accurate estimate calorie count';

  static String formatEstimate(double value) {
    if (value.abs() >= 1000) {
      final scaled = value / 1000;
      if (scaled == scaled.roundToDouble()) {
        return '${scaled.toStringAsFixed(0)}k';
      }
      final trimmed = scaled
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
      return '${trimmed}k';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  /// Sums [costEstimateFor] / [calorieEstimateFor] / [proteinEstimateFor]
  /// across [recipes].
  RecipeEstimate estimateForRecipes(
    Iterable<Recipe> recipes, {
    required RecipeEstimate Function(Recipe recipe) estimateFor,
  }) {
    var total = 0.0;
    var complete = true;
    for (final recipe in recipes) {
      final estimate = estimateFor(recipe);
      total += estimate.total;
      if (!estimate.isComplete) {
        complete = false;
      }
    }
    return RecipeEstimate(total: total, isComplete: complete);
  }

  List<RecipeFolder> get folders => List.unmodifiable(_folders);

  /// Folders that can own a recipe (excludes the virtual Recent recipes folder).
  List<RecipeFolder> get assignableFolders =>
      _folders.where((f) => f.id != recentFolderId).toList();

  List<Recipe> get recentRecipes => recipesInFolder(recentFolderId);

  RecipeFolder? folderById(String id) {
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  Recipe? recipeById(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  List<Recipe> recipesInFolder(String folderId) {
    if (folderId == recentFolderId) {
      final all = List<Recipe>.of(_recipes);
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }
    return _recipes.where((r) => r.folderId == folderId).toList();
  }

  void addFolder({required String name, required Color color}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final folder = RecipeFolder(
      id: 'folder_${_nextFolderId++}',
      name: trimmed,
      color: color,
    );
    _folders.add(folder);
    if (_hiveReady) HiveBoxes.foldersBox.put(folder.id, folder);
    _persistMeta();
    notifyListeners();
  }

  void renameFolder({required String id, required String name}) {
    if (id == recentFolderId) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final index = _folders.indexWhere((f) => f.id == id);
    if (index < 0) return;

    final existing = _folders[index];
    final updated = RecipeFolder(
      id: existing.id,
      name: trimmed,
      color: existing.color,
    );
    _folders[index] = updated;
    if (_hiveReady) HiveBoxes.foldersBox.put(updated.id, updated);
    notifyListeners();
  }

  void deleteFolders(Iterable<String> ids) {
    final toDelete = ids.where((id) => id != recentFolderId).toSet();
    if (toDelete.isEmpty) return;

    final recipeIdsInDeletedFolders = _recipes
        .where((r) => toDelete.contains(r.folderId))
        .map((r) => r.id)
        .toList();

    _folders.removeWhere((f) => toDelete.contains(f.id));
    _recipes.removeWhere((r) => toDelete.contains(r.folderId));

    if (_hiveReady) {
      final foldersBox = HiveBoxes.foldersBox;
      final recipesBox = HiveBoxes.recipesBox;
      for (final id in toDelete) {
        foldersBox.delete(id);
      }
      for (final id in recipeIdsInDeletedFolders) {
        recipesBox.delete(id);
      }
    }

    notifyListeners();
  }

  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
    if (_hiveReady) HiveBoxes.recipesBox.put(recipe.id, recipe);
    _persistMeta();
    notifyListeners();
  }

  bool updateRecipe(Recipe recipe) {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index < 0) return false;
    _recipes[index] = recipe;
    if (_hiveReady) HiveBoxes.recipesBox.put(recipe.id, recipe);
    notifyListeners();
    return true;
  }

  void deleteRecipes(Iterable<String> ids) {
    final toDelete = ids.toSet();
    if (toDelete.isEmpty) return;
    _recipes.removeWhere((r) => toDelete.contains(r.id));
    if (_hiveReady) {
      final recipesBox = HiveBoxes.recipesBox;
      for (final id in toDelete) {
        recipesBox.delete(id);
      }
    }
    notifyListeners();
  }

  void moveRecipes({
    required Iterable<String> ids,
    required String folderId,
  }) {
    if (folderId == recentFolderId) return;
    if (folderById(folderId) == null) return;

    final toMove = ids.toSet();
    if (toMove.isEmpty) return;

    var changed = false;
    for (var i = 0; i < _recipes.length; i++) {
      final recipe = _recipes[i];
      if (!toMove.contains(recipe.id)) continue;
      if (recipe.folderId == folderId) continue;
      final updated = Recipe(
        id: recipe.id,
        name: recipe.name,
        ingredients: recipe.ingredients,
        preparationMinutes: recipe.preparationMinutes,
        folderId: folderId,
        createdAt: recipe.createdAt,
        timesOfDay: recipe.timesOfDay,
        daysOfWeek: recipe.daysOfWeek,
        link: recipe.link,
        instructions: recipe.instructions,
      );
      _recipes[i] = updated;
      if (_hiveReady) HiveBoxes.recipesBox.put(updated.id, updated);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  String nextRecipeId() => 'recipe_${_nextId++}';

  /// Clears all recipes, assignable folders, and ingredient maps.
  /// Keeps the virtual Recent folder and seed meta flags.
  Future<void> clearAllData() async {
    final folderIdsToDelete =
        _folders.where((f) => f.id != recentFolderId).map((f) => f.id).toList();
    final recipeIds = _recipes.map((r) => r.id).toList();

    _folders.removeWhere((f) => f.id != recentFolderId);
    _recipes.clear();
    _ingredientCosts.clear();
    _ingredientCalories.clear();
    _ingredientProteins.clear();
    _nextId = 1;
    _nextFolderId = 1;

    if (_hiveReady) {
      final foldersBox = HiveBoxes.foldersBox;
      final recipesBox = HiveBoxes.recipesBox;
      for (final id in folderIdsToDelete) {
        await foldersBox.delete(id);
      }
      for (final id in recipeIds) {
        await recipesBox.delete(id);
      }
      await HiveBoxes.ingredientCostsBox.clear();
      await HiveBoxes.ingredientCaloriesBox.clear();
      await HiveBoxes.ingredientProteinsBox.clear();
      await _persistMeta();
    }

    notifyListeners();
  }

  /// Full replace of folders, recipes, and ingredient maps from a backup.
  Future<void> replaceFromBackup({
    required List<RecipeFolder> folders,
    required List<Recipe> recipes,
    required Map<String, double> ingredientCosts,
    required Map<String, double> ingredientCalories,
    required Map<String, double> ingredientProteins,
    required int nextRecipeId,
    required int nextFolderId,
  }) async {
    final recent = const RecipeFolder(
      id: recentFolderId,
      name: 'Recent recipes',
      color: kTextGreen,
    );

    final assignable = folders.where((f) => f.id != recentFolderId).toList();

    _folders
      ..clear()
      ..add(recent)
      ..addAll(assignable);
    _recipes
      ..clear()
      ..addAll(recipes);
    _ingredientCosts
      ..clear()
      ..addAll(ingredientCosts);
    _ingredientCalories
      ..clear()
      ..addAll(ingredientCalories);
    _ingredientProteins
      ..clear()
      ..addAll(ingredientProteins);
    _nextId = nextRecipeId < 1 ? 1 : nextRecipeId;
    _nextFolderId = nextFolderId < 1 ? 1 : nextFolderId;

    if (_hiveReady) {
      await HiveBoxes.foldersBox.clear();
      await HiveBoxes.recipesBox.clear();
      await HiveBoxes.ingredientCostsBox.clear();
      await HiveBoxes.ingredientCaloriesBox.clear();
      await HiveBoxes.ingredientProteinsBox.clear();

      await HiveBoxes.foldersBox.put(recent.id, recent);
      for (final folder in assignable) {
        await HiveBoxes.foldersBox.put(folder.id, folder);
      }
      for (final recipe in recipes) {
        await HiveBoxes.recipesBox.put(recipe.id, recipe);
      }
      for (final entry in ingredientCosts.entries) {
        await HiveBoxes.ingredientCostsBox.put(entry.key, entry.value);
      }
      for (final entry in ingredientCalories.entries) {
        await HiveBoxes.ingredientCaloriesBox.put(entry.key, entry.value);
      }
      for (final entry in ingredientProteins.entries) {
        await HiveBoxes.ingredientProteinsBox.put(entry.key, entry.value);
      }
      await _persistMeta();
    }

    notifyListeners();
  }
}

class RecipeStoreScope extends InheritedNotifier<RecipeStore> {
  const RecipeStoreScope({
    super.key,
    required RecipeStore store,
    required super.child,
  }) : super(notifier: store);

  static RecipeStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RecipeStoreScope>();
    assert(scope != null, 'No RecipeStoreScope found in context');
    return scope!.notifier!;
  }
}
