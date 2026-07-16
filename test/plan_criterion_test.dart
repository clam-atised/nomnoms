import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';

Recipe _recipe({
  required String id,
  required String name,
  required int prep,
  required String folderId,
  List<Ingredient> ingredients = const [],
  List<TimeOfDayOption> timesOfDay = const [],
  List<DayOfWeekOption> daysOfWeek = const [],
}) {
  return Recipe(
    id: id,
    name: name,
    ingredients: ingredients,
    preparationMinutes: prep,
    folderId: folderId,
    createdAt: DateTime(2026, 1, 1),
    timesOfDay: timesOfDay,
    daysOfWeek: daysOfWeek,
  );
}

void main() {
  group('PrepTimeRangeCriterion', () {
    test('keeps recipes inside inclusive range', () {
      final criterion = PrepTimeRangeCriterion(minMinutes: 10, maxMinutes: 20);
      final keep = _recipe(id: 'a', name: 'A', prep: 15, folderId: 'f');
      final low = _recipe(id: 'b', name: 'B', prep: 5, folderId: 'f');
      final high = _recipe(id: 'c', name: 'C', prep: 60, folderId: 'f');

      expect(criterion.matches(keep), isTrue);
      expect(criterion.matches(low), isFalse);
      expect(criterion.matches(high), isFalse);
    });

    test('min 0 means under max only', () {
      final criterion = PrepTimeRangeCriterion(minMinutes: 0, maxMinutes: 30);
      expect(criterion.label, 'Preparation: under 30 min');
      expect(
        criterion.matches(
          _recipe(id: 'a', name: 'A', prep: 30, folderId: 'f'),
        ),
        isTrue,
      );
      expect(
        criterion.matches(
          _recipe(id: 'b', name: 'B', prep: 31, folderId: 'f'),
        ),
        isFalse,
      );
    });
  });

  group('ContainsIngredientsCriterion', () {
    test('requires all ingredients (AND)', () {
      final criterion = ContainsIngredientsCriterion(['Eggs', 'Milk']);
      final both = _recipe(
        id: 'a',
        name: 'A',
        prep: 10,
        folderId: 'f',
        ingredients: const [
          Ingredient(quantity: 1, name: 'Eggs'),
          Ingredient(quantity: 1, name: 'Milk'),
        ],
      );
      final eggsOnly = _recipe(
        id: 'b',
        name: 'B',
        prep: 10,
        folderId: 'f',
        ingredients: const [Ingredient(quantity: 1, name: 'Eggs')],
      );

      expect(criterion.matches(both), isTrue);
      expect(criterion.matches(eggsOnly), isFalse);
    });
  });

  group('FolderCriterion', () {
    test('matches any selected folder', () {
      final criterion = FolderCriterion(
        folderIds: {'folder_1', 'folder_2'},
        folderNames: ['Desserts', 'Snacks'],
      );
      expect(
        criterion.matches(
          _recipe(id: 'a', name: 'A', prep: 5, folderId: 'folder_1'),
        ),
        isTrue,
      );
      expect(
        criterion.matches(
          _recipe(id: 'b', name: 'B', prep: 5, folderId: 'folder_3'),
        ),
        isFalse,
      );
    });
  });

  group('RepeatRecipeCriterion', () {
    test('times 0 excludes recipe', () {
      final criterion = RepeatRecipeCriterion(
        recipeId: 'a',
        recipeName: 'A',
        times: 0,
      );
      expect(
        criterion.matches(
          _recipe(id: 'a', name: 'A', prep: 5, folderId: 'f'),
        ),
        isFalse,
      );
      expect(
        criterion.matches(
          _recipe(id: 'b', name: 'B', prep: 5, folderId: 'f'),
        ),
        isTrue,
      );
    });
  });
}
