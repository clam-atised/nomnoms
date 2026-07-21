import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/recipe.dart';

void main() {
  group('Ingredient label', () {
    test('omits unit when null', () {
      const ingredient = Ingredient(quantity: 2, name: 'tomatoes');
      expect(ingredient.label, '2 tomatoes');
    });

    test('includes unit when set', () {
      const ingredient = Ingredient(
        quantity: 2,
        name: 'flour',
        unit: IngredientUnit.tbsp,
      );
      expect(ingredient.label, '2 tbsp flour');
    });

    test('formats quarter cup unit', () {
      const ingredient = Ingredient(
        quantity: 1,
        name: 'milk',
        unit: IngredientUnit.quarterCup,
      );
      expect(ingredient.label, '1 1/4 cup milk');
    });

    test('formats eighth cup unit', () {
      const ingredient = Ingredient(
        quantity: 1,
        name: 'oil',
        unit: IngredientUnit.eighthCup,
      );
      expect(ingredient.label, '1 1/8 cup oil');
    });

    test('formats third cup unit', () {
      const ingredient = Ingredient(
        quantity: 1,
        name: 'sugar',
        unit: IngredientUnit.thirdCup,
      );
      expect(ingredient.label, '1 1/3 cup sugar');
    });

    test('formats half cup unit', () {
      const ingredient = Ingredient(
        quantity: 1,
        name: 'rice',
        unit: IngredientUnit.halfCup,
      );
      expect(ingredient.label, '1 1/2 cup rice');
    });
  });

  group('Ingredient displayLabel', () {
    test('metric matches label', () {
      const ingredient = Ingredient(
        quantity: 400,
        name: 'flat rice noodles',
        unit: IngredientUnit.g,
      );
      expect(
        ingredient.displayLabel(MeasurementSystem.metric),
        '400 g flat rice noodles',
      );
    });

    test('custom converts g to ounces with full text', () {
      const ingredient = Ingredient(
        quantity: 400,
        name: 'flat rice noodles',
        unit: IngredientUnit.g,
      );
      expect(
        ingredient.displayLabel(MeasurementSystem.custom),
        '14 ounces flat rice noodles',
      );
    });

    test('custom converts ml to fluid ounces with full text', () {
      const ingredient = Ingredient(
        quantity: 100,
        name: 'water',
        unit: IngredientUnit.ml,
      );
      expect(
        ingredient.displayLabel(MeasurementSystem.custom),
        '3.4 fluid ounces water',
      );
    });

    test('custom leaves cup units unchanged', () {
      const ingredient = Ingredient(
        quantity: 2,
        name: 'basmati rice',
        unit: IngredientUnit.cup,
      );
      expect(
        ingredient.displayLabel(MeasurementSystem.custom),
        '2 cup basmati rice',
      );
    });
  });

  group('RecipeStore ingredient costs', () {
    RecipeStore storeWithRecipes() {
      final store = RecipeStore();
      store.addRecipe(
        Recipe(
          id: store.nextRecipeId(),
          name: 'Soup',
          ingredients: const [
            Ingredient(quantity: 2, name: 'Tomatoes'),
            Ingredient(quantity: 1, name: 'Salt'),
          ],
          preparationMinutes: 10,
          folderId: RecipeStore.recentFolderId,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      store.addRecipe(
        Recipe(
          id: store.nextRecipeId(),
          name: 'Salad',
          ingredients: const [
            Ingredient(quantity: 3, name: ' tomatoes '),
            Ingredient(quantity: 1, name: 'Cheese'),
          ],
          preparationMinutes: 5,
          folderId: RecipeStore.recentFolderId,
          createdAt: DateTime(2026, 1, 2),
        ),
      );
      return store;
    }

    test('uniqueIngredientNames normalizes and dedupes', () {
      final store = storeWithRecipes();
      expect(
        store.uniqueIngredientNames,
        ['cheese', 'salt', 'tomatoes'],
      );
    });

    test('setIngredientCost stores and clears values', () {
      final store = storeWithRecipes();
      expect(store.costFor('Tomatoes'), isNull);

      store.setIngredientCost('Tomatoes', 1.2);
      expect(store.costFor(' tomatoes '), 1.2);
      expect(store.costFor('TOMATOES'), 1.2);

      store.setIngredientCost('tomatoes', null);
      expect(store.costFor('tomatoes'), isNull);
    });

    test('setIngredientCalorie stores and clears values', () {
      final store = storeWithRecipes();
      expect(store.calorieFor('Tomatoes'), isNull);

      store.setIngredientCalorie('Tomatoes', 45);
      expect(store.calorieFor(' tomatoes '), 45);
      expect(store.calorieFor('TOMATOES'), 45);

      store.setIngredientCalorie('tomatoes', null);
      expect(store.calorieFor('tomatoes'), isNull);
    });

    test('setIngredientProtein stores and clears values', () {
      final store = storeWithRecipes();
      expect(store.proteinFor('Tomatoes'), isNull);

      store.setIngredientProtein('Tomatoes', 3.5);
      expect(store.proteinFor(' tomatoes '), 3.5);
      expect(store.proteinFor('TOMATOES'), 3.5);

      store.setIngredientProtein('tomatoes', null);
      expect(store.proteinFor('tomatoes'), isNull);
    });

    test('cost, calorie, and protein values are independent', () {
      final store = storeWithRecipes();
      store.setIngredientCost('Tomatoes', 1.2);
      store.setIngredientCalorie('Tomatoes', 45);
      store.setIngredientProtein('Tomatoes', 3.5);

      expect(store.costFor('Tomatoes'), 1.2);
      expect(store.calorieFor('Tomatoes'), 45);
      expect(store.proteinFor('Tomatoes'), 3.5);

      store.setIngredientCost('Tomatoes', null);
      expect(store.costFor('Tomatoes'), isNull);
      expect(store.calorieFor('Tomatoes'), 45);
      expect(store.proteinFor('Tomatoes'), 3.5);
    });
  });

  group('RecipeStore recipe estimates', () {
    Recipe soupRecipe() {
      return Recipe(
        id: 'recipe_1',
        name: 'Soup',
        ingredients: const [
          Ingredient(quantity: 2, name: 'Tomatoes'),
          Ingredient(quantity: 1, name: 'Salt'),
        ],
        preparationMinutes: 10,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('costEstimateFor sums quantity times stored cost', () {
      final store = RecipeStore();
      store.setIngredientCost('Tomatoes', 1.5);
      store.setIngredientCost('Salt', 0.25);

      final estimate = store.costEstimateFor(soupRecipe());
      expect(estimate.total, 3.25);
      expect(estimate.isComplete, isTrue);
    });

    test('costEstimateFor treats missing values as zero and incomplete', () {
      final store = RecipeStore();
      store.setIngredientCost('Tomatoes', 1.5);

      final estimate = store.costEstimateFor(soupRecipe());
      expect(estimate.total, 3.0);
      expect(estimate.isComplete, isFalse);
    });

    test('calorieEstimateFor sums quantity times stored calories', () {
      final store = RecipeStore();
      store.setIngredientCalorie(' tomatoes ', 40);
      store.setIngredientCalorie('SALT', 5);

      final estimate = store.calorieEstimateFor(soupRecipe());
      expect(estimate.total, 85);
      expect(estimate.isComplete, isTrue);
    });

    test('calorieEstimateFor treats missing values as zero and incomplete', () {
      final store = RecipeStore();
      store.setIngredientCalorie('Tomatoes', 40);

      final estimate = store.calorieEstimateFor(soupRecipe());
      expect(estimate.total, 80);
      expect(estimate.isComplete, isFalse);
    });

    test('proteinEstimateFor sums quantity times stored protein', () {
      final store = RecipeStore();
      store.setIngredientProtein(' tomatoes ', 2);
      store.setIngredientProtein('SALT', 0);

      final estimate = store.proteinEstimateFor(soupRecipe());
      expect(estimate.total, 4);
      expect(estimate.isComplete, isTrue);
    });

    test('proteinEstimateFor skips missing values and stays complete', () {
      final store = RecipeStore();
      store.setIngredientProtein('Tomatoes', 2);

      final estimate = store.proteinEstimateFor(soupRecipe());
      expect(estimate.total, 4);
      expect(estimate.isComplete, isTrue);
    });

    test('empty ingredient list is complete with zero total', () {
      final store = RecipeStore();
      final recipe = Recipe(
        id: 'recipe_1',
        name: 'Empty',
        ingredients: const [],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      );

      final cost = store.costEstimateFor(recipe);
      final calories = store.calorieEstimateFor(recipe);
      final protein = store.proteinEstimateFor(recipe);
      expect(cost.total, 0);
      expect(cost.isComplete, isTrue);
      expect(calories.total, 0);
      expect(calories.isComplete, isTrue);
      expect(protein.total, 0);
      expect(protein.isComplete, isTrue);
    });

    test('formatEstimate omits decimals for whole numbers', () {
      expect(RecipeStore.formatEstimate(52), '52');
      expect(RecipeStore.formatEstimate(1.2), '1.20');
    });

    test('formatEstimate uses k for values at or above 1000', () {
      expect(RecipeStore.formatEstimate(1000), '1k');
      expect(RecipeStore.formatEstimate(15000), '15k');
      expect(RecipeStore.formatEstimate(15200), '15.2k');
      expect(RecipeStore.formatEstimate(150.69), '150.69');
      expect(RecipeStore.formatEstimate(1500.5), '1.5k');
    });

    test('estimateForRecipes sums costs, calories, and protein', () {
      final store = RecipeStore();
      store.setIngredientCost('Tomatoes', 1.5);
      store.setIngredientCost('Salt', 0.25);
      store.setIngredientCalorie('Tomatoes', 20);
      store.setIngredientCalorie('Salt', 0);
      store.setIngredientProtein('Tomatoes', 2);

      final soup = soupRecipe();
      final salad = Recipe(
        id: 'recipe_2',
        name: 'Salad',
        ingredients: const [
          Ingredient(quantity: 3, name: 'tomatoes'),
          Ingredient(quantity: 1, name: 'Cheese'),
        ],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 2),
      );

      final cost = store.estimateForRecipes(
        [soup, salad],
        estimateFor: store.costEstimateFor,
      );
      final calories = store.estimateForRecipes(
        [soup, salad],
        estimateFor: store.calorieEstimateFor,
      );
      final protein = store.estimateForRecipes(
        [soup, salad],
        estimateFor: store.proteinEstimateFor,
      );

      // Soup: 3.25; Salad: 3*1.5 + missing Cheese → 4.5
      expect(cost.total, 7.75);
      expect(cost.isComplete, isFalse);
      // Soup: 40; Salad: 3*20 + missing Cheese → 60
      expect(calories.total, 100);
      expect(calories.isComplete, isFalse);
      // Soup: 4; Salad: 3*2 + missing Cheese → 6
      expect(protein.total, 10);
      expect(protein.isComplete, isTrue);
    });
  });
}
