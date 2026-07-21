import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/backup_data.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/services/backup_service.dart';
import 'package:nomnom/services/export_service.dart';

void main() {
  group('BackupData round-trip', () {
    test('serialize and deserialize preserves folders, recipes, maps, settings',
        () {
      final createdAt = DateTime.utc(2026, 7, 21, 6, 0);
      final backup = BackupData(
        nextRecipeId: 4,
        nextFolderId: 2,
        folders: [
          BackupFolderData(
            id: 'folder_1',
            name: 'Desserts',
            color: const Color(0xFFEDD312).toARGB32(),
          ),
        ],
        recipes: [
          BackupRecipeData(
            id: 'recipe_1',
            name: 'Cake',
            ingredients: [
              BackupIngredientData(
                quantity: 2,
                name: 'flour',
                unit: IngredientUnit.cup.name,
              ),
            ],
            preparationMinutes: 45,
            folderId: 'folder_1',
            createdAt: createdAt,
            timesOfDay: [TimeOfDayOption.noon.name],
            daysOfWeek: [DayOfWeekOption.saturday.name],
            link: 'https://example.com',
            instructions: 'Bake it.',
          ),
        ],
        ingredientCosts: {'flour': 1.5},
        ingredientCalories: {'flour': 100},
        ingredientProteins: {'flour': 3},
        settings: BackupSettingsData(
          nightMode: true,
          showCost: true,
          showCalorie: false,
          showProtein: true,
          measurementSystem: MeasurementSystem.custom.name,
        ),
      );

      final restored = BackupData.fromJson(
        jsonDecode(
          const JsonEncoder.withIndent('  ').convert(backup.toJson()),
        ) as Map<String, dynamic>,
      );

      expect(restored.version, BackupData.currentVersion);
      expect(restored.nextRecipeId, 4);
      expect(restored.nextFolderId, 2);
      expect(restored.folders, hasLength(1));
      expect(restored.folders.single.id, 'folder_1');
      expect(restored.folders.single.name, 'Desserts');
      expect(restored.recipes, hasLength(1));
      expect(restored.recipes.single.name, 'Cake');
      expect(restored.recipes.single.ingredients.single.name, 'flour');
      expect(restored.recipes.single.createdAt, createdAt);
      expect(restored.ingredientCosts['flour'], 1.5);
      expect(restored.ingredientCalories['flour'], 100);
      expect(restored.ingredientProteins['flour'], 3);
      expect(restored.settings?.nightMode, isTrue);
      expect(restored.settings?.measurementSystem, 'custom');

      final recipe = restored.recipes.single.toRecipe();
      expect(recipe.timesOfDay, [TimeOfDayOption.noon]);
      expect(recipe.daysOfWeek, [DayOfWeekOption.saturday]);
      expect(recipe.ingredients.single.unit, IngredientUnit.cup);
    });

    test('rejects unsupported version', () {
      expect(
        () => BackupData.fromJson({'version': 99}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RecipeStore.hasUserData', () {
    test('is false for seed-only data', () async {
      final store = RecipeStore();
      await store.replaceFromBackup(
        folders: const [
          RecipeFolder(
            id: RecipeStore.seedFolderMalaysianCuisine,
            name: 'Malaysian Cuisine',
            color: Color(0xFFEDD312),
          ),
        ],
        recipes: [
          Recipe(
            id: 'seed_recipe_nasi_lemak',
            name: 'Nasi Lemak',
            ingredients: const [
              Ingredient(quantity: 1, name: 'rice'),
            ],
            preparationMinutes: 30,
            folderId: RecipeStore.seedFolderMalaysianCuisine,
            createdAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        ingredientCosts: const {},
        ingredientCalories: const {},
        ingredientProteins: const {},
        nextRecipeId: 1,
        nextFolderId: 1,
      );

      expect(store.hasUserData, isFalse);
    });

    test('is true when a user recipe exists', () async {
      final store = RecipeStore();
      await store.replaceFromBackup(
        folders: const [
          RecipeFolder(
            id: 'folder_1',
            name: 'Mine',
            color: Color(0xFF3D6F3D),
          ),
        ],
        recipes: [
          Recipe(
            id: 'recipe_1',
            name: 'Soup',
            ingredients: const [
              Ingredient(quantity: 1, name: 'water'),
            ],
            preparationMinutes: 10,
            folderId: 'folder_1',
            createdAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        ingredientCosts: const {},
        ingredientCalories: const {},
        ingredientProteins: const {},
        nextRecipeId: 2,
        nextFolderId: 2,
      );

      expect(store.hasUserData, isTrue);
    });

    test('is true when ingredient costs exist with only seed recipes', () async {
      final store = RecipeStore();
      await store.replaceFromBackup(
        folders: const [
          RecipeFolder(
            id: RecipeStore.seedFolderMalaysianCuisine,
            name: 'Malaysian Cuisine',
            color: Color(0xFFEDD312),
          ),
        ],
        recipes: [
          Recipe(
            id: 'seed_recipe_tosai',
            name: 'Tosai',
            ingredients: const [
              Ingredient(quantity: 1, name: 'flour'),
            ],
            preparationMinutes: 20,
            folderId: RecipeStore.seedFolderMalaysianCuisine,
            createdAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        ingredientCosts: const {'flour': 2},
        ingredientCalories: const {},
        ingredientProteins: const {},
        nextRecipeId: 1,
        nextFolderId: 1,
      );

      expect(store.hasUserData, isTrue);
    });
  });

  group('BackupService.buildBackup', () {
    test('captures store and settings into BackupData', () async {
      final store = RecipeStore();
      await store.replaceFromBackup(
        folders: const [
          RecipeFolder(
            id: 'folder_1',
            name: 'Soups',
            color: Color(0xFF3D6F3D),
          ),
        ],
        recipes: [
          Recipe(
            id: 'recipe_1',
            name: 'Broth',
            ingredients: const [
              Ingredient(quantity: 1, name: 'stock'),
            ],
            preparationMinutes: 15,
            folderId: 'folder_1',
            createdAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        ingredientCosts: const {'stock': 0.5},
        ingredientCalories: const {},
        ingredientProteins: const {},
        nextRecipeId: 3,
        nextFolderId: 2,
      );

      final settings = AppSettings();
      settings.setNightMode(true);
      settings.setShowCost(true);

      final backup = BackupService.buildBackup(
        store: store,
        settings: settings,
      );

      expect(backup.folders.single.name, 'Soups');
      expect(backup.recipes.single.name, 'Broth');
      expect(backup.nextRecipeId, 3);
      expect(backup.ingredientCosts['stock'], 0.5);
      expect(backup.settings?.nightMode, isTrue);
      expect(backup.settings?.showCost, isTrue);
    });
  });

  group('ExportService markdown grouping', () {
    test('separates recipes by folder name', () async {
      final store = RecipeStore();
      await store.replaceFromBackup(
        folders: const [
          RecipeFolder(
            id: 'folder_1',
            name: 'Breakfast',
            color: Color(0xFF3D6F3D),
          ),
          RecipeFolder(
            id: 'folder_2',
            name: 'Dinner',
            color: Color(0xFFEDD312),
          ),
        ],
        recipes: [
          Recipe(
            id: 'recipe_1',
            name: 'Eggs',
            ingredients: const [
              Ingredient(quantity: 2, name: 'eggs'),
            ],
            preparationMinutes: 5,
            folderId: 'folder_1',
            createdAt: DateTime.utc(2026, 7, 21),
          ),
          Recipe(
            id: 'recipe_2',
            name: 'Stew',
            ingredients: const [
              Ingredient(quantity: 1, name: 'beef'),
            ],
            preparationMinutes: 60,
            folderId: 'folder_2',
            createdAt: DateTime.utc(2026, 7, 21),
          ),
        ],
        ingredientCosts: const {},
        ingredientCalories: const {},
        ingredientProteins: const {},
        nextRecipeId: 3,
        nextFolderId: 3,
      );

      final markdown = ExportService.instance.buildMarkdown(store);

      expect(markdown, contains('# Breakfast'));
      expect(markdown, contains('## Eggs'));
      expect(markdown, contains('# Dinner'));
      expect(markdown, contains('## Stew'));

      final breakfastIndex = markdown.indexOf('# Breakfast');
      final dinnerIndex = markdown.indexOf('# Dinner');
      final eggsIndex = markdown.indexOf('## Eggs');
      final stewIndex = markdown.indexOf('## Stew');
      expect(breakfastIndex, lessThan(eggsIndex));
      expect(eggsIndex, lessThan(dinnerIndex));
      expect(dinnerIndex, lessThan(stewIndex));
    });
  });
}
