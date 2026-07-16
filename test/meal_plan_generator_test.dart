import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/data/meal_plan_generator.dart';
import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';

Recipe _recipe({
  required String id,
  required String name,
  List<TimeOfDayOption> timesOfDay = const [],
  List<DayOfWeekOption> daysOfWeek = const [],
}) {
  return Recipe(
    id: id,
    name: name,
    ingredients: const [Ingredient(quantity: 1, name: 'Eggs')],
    preparationMinutes: 10,
    folderId: 'folder_1',
    createdAt: DateTime(2026, 1, 1),
    timesOfDay: timesOfDay,
    daysOfWeek: daysOfWeek,
  );
}

void main() {
  test('morning-only recipe never fills noon or night', () {
    final generator = MealPlanGenerator(random: Random(1));
    final morningOnly = _recipe(
      id: 'm',
      name: 'Morning Toast',
      timesOfDay: const [TimeOfDayOption.morning],
    );

    final planned = generator.generate(
      recipes: [morningOnly],
      slots: MealPlanGenerator.weekSlots(),
      weekdayForDayKey: MealPlanGenerator.weekdayFromIndex,
    );

    expect(planned, isNotEmpty);
    expect(
      planned.every((p) => p.slot == MealSlot.morning),
      isTrue,
    );
    expect(planned.every((p) => p.recipe.name == 'Morning Toast'), isTrue);
  });

  test('monday-only recipe never fills other weekdays', () {
    final generator = MealPlanGenerator(random: Random(2));
    final mondayOnly = _recipe(
      id: 'mon',
      name: 'Monday Stew',
      daysOfWeek: const [DayOfWeekOption.monday],
    );

    final planned = generator.generate(
      recipes: [mondayOnly],
      slots: MealPlanGenerator.weekSlots(),
      weekdayForDayKey: MealPlanGenerator.weekdayFromIndex,
    );

    expect(planned, isNotEmpty);
    expect(planned.every((p) => p.dayKey == 0), isTrue);
    expect(planned.every((p) => p.recipe.name == 'Monday Stew'), isTrue);
  });

  test('repeat places recipe exactly three times when slots allow', () {
    final generator = MealPlanGenerator(random: Random(3));
    final target = _recipe(id: 'r', name: 'Repeat Me');
    final filler = _recipe(id: 'f', name: 'Filler');

    final planned = generator.generate(
      recipes: [target, filler],
      slots: MealPlanGenerator.weekSlots(),
      weekdayForDayKey: MealPlanGenerator.weekdayFromIndex,
      repeats: [
        RepeatRecipeCriterion(
          recipeId: 'r',
          recipeName: 'Repeat Me',
          times: 3,
        ),
      ],
    );

    final repeatCount =
        planned.where((p) => p.recipe.id == 'r').length;
    // Forced 3 times; remaining slots may add more unless capped.
    // Cap should keep total at most 3 for forced recipe when other recipes exist.
    expect(repeatCount, 3);
  });
}
