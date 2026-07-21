import 'package:flutter/material.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';

class BackupData {
  BackupData({
    this.version = currentVersion,
    required this.nextRecipeId,
    required this.nextFolderId,
    required this.folders,
    required this.recipes,
    required this.ingredientCosts,
    required this.ingredientCalories,
    required this.ingredientProteins,
    this.settings,
  });

  static const currentVersion = 1;
  static const backupJsonName = 'backup.json';

  final int version;
  final int nextRecipeId;
  final int nextFolderId;
  final List<BackupFolderData> folders;
  final List<BackupRecipeData> recipes;
  final Map<String, double> ingredientCosts;
  final Map<String, double> ingredientCalories;
  final Map<String, double> ingredientProteins;
  final BackupSettingsData? settings;

  Map<String, dynamic> toJson() => {
        'version': version,
        'nextRecipeId': nextRecipeId,
        'nextFolderId': nextFolderId,
        'folders': folders.map((f) => f.toJson()).toList(),
        'recipes': recipes.map((r) => r.toJson()).toList(),
        'ingredientCosts': ingredientCosts,
        'ingredientCalories': ingredientCalories,
        'ingredientProteins': ingredientProteins,
        if (settings != null) 'settings': settings!.toJson(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    if (version != currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    Map<String, double> readDoubles(String key) {
      final raw = json[key] as Map<String, dynamic>? ?? {};
      return raw.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }

    final foldersJson = json['folders'] as List<dynamic>? ?? [];
    final recipesJson = json['recipes'] as List<dynamic>? ?? [];
    final settingsJson = json['settings'] as Map<String, dynamic>?;

    return BackupData(
      version: version,
      nextRecipeId: json['nextRecipeId'] as int? ?? 1,
      nextFolderId: json['nextFolderId'] as int? ?? 1,
      folders: foldersJson
          .map((e) => BackupFolderData.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipes: recipesJson
          .map((e) => BackupRecipeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      ingredientCosts: readDoubles('ingredientCosts'),
      ingredientCalories: readDoubles('ingredientCalories'),
      ingredientProteins: readDoubles('ingredientProteins'),
      settings: settingsJson != null
          ? BackupSettingsData.fromJson(settingsJson)
          : null,
    );
  }
}

class BackupFolderData {
  BackupFolderData({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final int color;

  factory BackupFolderData.fromFolder(RecipeFolder folder) {
    return BackupFolderData(
      id: folder.id,
      name: folder.name,
      color: folder.color.toARGB32(),
    );
  }

  RecipeFolder toFolder() => RecipeFolder(
        id: id,
        name: name,
        color: Color(color),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };

  factory BackupFolderData.fromJson(Map<String, dynamic> json) {
    return BackupFolderData(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF3D6F3D,
    );
  }
}

class BackupIngredientData {
  BackupIngredientData({
    required this.quantity,
    required this.name,
    this.unit,
  });

  final double quantity;
  final String name;
  final String? unit;

  factory BackupIngredientData.fromIngredient(Ingredient ingredient) {
    return BackupIngredientData(
      quantity: ingredient.quantity,
      name: ingredient.name,
      unit: ingredient.unit?.name,
    );
  }

  Ingredient toIngredient() => Ingredient(
        quantity: quantity,
        name: name,
        unit: unit == null ? null : IngredientUnit.values.byName(unit!),
      );

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'name': name,
        if (unit != null) 'unit': unit,
      };

  factory BackupIngredientData.fromJson(Map<String, dynamic> json) {
    return BackupIngredientData(
      quantity: (json['quantity'] as num).toDouble(),
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String?,
    );
  }
}

class BackupRecipeData {
  BackupRecipeData({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.preparationMinutes,
    required this.folderId,
    required this.createdAt,
    this.timesOfDay = const [],
    this.daysOfWeek = const [],
    this.link = '',
    this.instructions = '',
  });

  final String id;
  final String name;
  final List<BackupIngredientData> ingredients;
  final int preparationMinutes;
  final String folderId;
  final DateTime createdAt;
  final List<String> timesOfDay;
  final List<String> daysOfWeek;
  final String link;
  final String instructions;

  factory BackupRecipeData.fromRecipe(Recipe recipe) {
    return BackupRecipeData(
      id: recipe.id,
      name: recipe.name,
      ingredients: recipe.ingredients
          .map(BackupIngredientData.fromIngredient)
          .toList(),
      preparationMinutes: recipe.preparationMinutes,
      folderId: recipe.folderId,
      createdAt: recipe.createdAt,
      timesOfDay: recipe.timesOfDay.map((e) => e.name).toList(),
      daysOfWeek: recipe.daysOfWeek.map((e) => e.name).toList(),
      link: recipe.link,
      instructions: recipe.instructions,
    );
  }

  Recipe toRecipe() => Recipe(
        id: id,
        name: name,
        ingredients: ingredients.map((e) => e.toIngredient()).toList(),
        preparationMinutes: preparationMinutes,
        folderId: folderId,
        createdAt: createdAt,
        timesOfDay: timesOfDay.map(TimeOfDayOption.values.byName).toList(),
        daysOfWeek: daysOfWeek.map(DayOfWeekOption.values.byName).toList(),
        link: link,
        instructions: instructions,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'preparationMinutes': preparationMinutes,
        'folderId': folderId,
        'createdAt': createdAt.toIso8601String(),
        'timesOfDay': timesOfDay,
        'daysOfWeek': daysOfWeek,
        'link': link,
        'instructions': instructions,
      };

  factory BackupRecipeData.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];
    return BackupRecipeData(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ingredients: ingredientsJson
          .map((e) => BackupIngredientData.fromJson(e as Map<String, dynamic>))
          .toList(),
      preparationMinutes: json['preparationMinutes'] as int? ?? 0,
      folderId: json['folderId'] as String? ?? 'recent',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      timesOfDay: (json['timesOfDay'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      link: json['link'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
    );
  }
}

class BackupSettingsData {
  BackupSettingsData({
    required this.nightMode,
    required this.showCost,
    required this.showCalorie,
    required this.showProtein,
    required this.measurementSystem,
  });

  final bool nightMode;
  final bool showCost;
  final bool showCalorie;
  final bool showProtein;
  final String measurementSystem;

  factory BackupSettingsData.fromAppSettings(AppSettings settings) {
    return BackupSettingsData(
      nightMode: settings.nightMode,
      showCost: settings.showCost,
      showCalorie: settings.showCalorie,
      showProtein: settings.showProtein,
      measurementSystem: settings.measurementSystem.name,
    );
  }

  void applyTo(AppSettings settings) {
    settings.setNightMode(nightMode);
    settings.setShowCost(showCost);
    settings.setShowCalorie(showCalorie);
    settings.setShowProtein(showProtein);
    settings.setMeasurementSystem(
      MeasurementSystem.values.byName(measurementSystem),
    );
  }

  Map<String, dynamic> toJson() => {
        'nightMode': nightMode,
        'showCost': showCost,
        'showCalorie': showCalorie,
        'showProtein': showProtein,
        'measurementSystem': measurementSystem,
      };

  factory BackupSettingsData.fromJson(Map<String, dynamic> json) {
    return BackupSettingsData(
      nightMode: json['nightMode'] as bool? ?? false,
      showCost: json['showCost'] as bool? ?? false,
      showCalorie: json['showCalorie'] as bool? ?? false,
      showProtein: json['showProtein'] as bool? ?? false,
      measurementSystem: json['measurementSystem'] as String? ??
          MeasurementSystem.metric.name,
    );
  }
}
