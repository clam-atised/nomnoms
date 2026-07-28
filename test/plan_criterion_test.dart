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

  group('DaysOfWeekCriterion', () {
    test('all() enables every day and meal time', () {
      final criterion = DaysOfWeekCriterion.all();
      expect(criterion.label, 'Days: Mon all, Tue all, Wed all, Thu all, Fri all, Sat all, Sun all');
      for (final day in DayOfWeekOption.values) {
        for (final time in TimeOfDayOption.values) {
          expect(criterion.includes(day, time), isTrue);
        }
      }
      expect(
        criterion.matches(
          _recipe(id: 'a', name: 'A', prep: 5, folderId: 'f'),
        ),
        isTrue,
      );
    });

    test('includes only selected day/slot pairs', () {
      final criterion = DaysOfWeekCriterion(
        selectedByDay: {
          DayOfWeekOption.monday: {
            TimeOfDayOption.morning,
            TimeOfDayOption.noon,
            TimeOfDayOption.night,
          },
          DayOfWeekOption.tuesday: {TimeOfDayOption.morning},
        },
      );

      expect(criterion.includes(DayOfWeekOption.monday, TimeOfDayOption.noon), isTrue);
      expect(
        criterion.includes(DayOfWeekOption.tuesday, TimeOfDayOption.morning),
        isTrue,
      );
      expect(
        criterion.includes(DayOfWeekOption.tuesday, TimeOfDayOption.noon),
        isFalse,
      );
      expect(
        criterion.includes(DayOfWeekOption.saturday, TimeOfDayOption.morning),
        isFalse,
      );
      expect(criterion.label, 'Days: Mon all, Tue M');
    });

    test('empty selection labels as none', () {
      final criterion = DaysOfWeekCriterion(selectedByDay: {});
      expect(criterion.label, 'Days: none');
    });
  });

  group('PlanMonthDaysCriterion', () {
    test('allEligible selects every day in range', () {
      final criterion = PlanMonthDaysCriterion.allEligible(
        startDay: 5,
        daysInMonth: 10,
      );
      expect(criterion.selectedDays, {5, 6, 7, 8, 9, 10});
      expect(criterion.label, 'Days: all');
      expect(criterion.includes(5), isTrue);
      expect(criterion.includes(4), isFalse);
      expect(
        criterion.matches(
          _recipe(id: 'a', name: 'A', prep: 5, folderId: 'f'),
        ),
        isTrue,
      );
    });

    test('includes only selected days and formats label ranges', () {
      final criterion = PlanMonthDaysCriterion(
        selectedDays: {1, 3, 5, 6, 7, 8, 12, 28},
        startDay: 1,
        daysInMonth: 31,
      );
      expect(criterion.includes(3), isTrue);
      expect(criterion.includes(2), isFalse);
      expect(criterion.label, 'Days: 1, 3, 5–8, 12, 28');
    });

    test('empty selection labels as none', () {
      final criterion = PlanMonthDaysCriterion(selectedDays: {});
      expect(criterion.label, 'Days: none');
    });
  });
}
