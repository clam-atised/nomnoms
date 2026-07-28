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

  test('days-of-week criterion filters which slots are planned', () {
    final generator = MealPlanGenerator(random: Random(4));
    final recipe = _recipe(id: 'a', name: 'Any');

    final days = DaysOfWeekCriterion(
      selectedByDay: {
        DayOfWeekOption.monday: {...TimeOfDayOption.values},
        DayOfWeekOption.tuesday: {TimeOfDayOption.morning},
      },
    );

    final slots = MealPlanGenerator.weekSlots()
        .where(
          (s) => days.includes(
            MealPlanGenerator.weekdayFromIndex(s.$1),
            s.$2.timeOfDay,
          ),
        )
        .toList();

    // Mon M/N/Ni + Tue M = 4 slots
    expect(slots.length, 4);

    final planned = generator.generate(
      recipes: [recipe],
      slots: slots,
      weekdayForDayKey: MealPlanGenerator.weekdayFromIndex,
    );

    expect(planned.length, 4);
    expect(
      planned.every(
        (p) => days.includes(
          MealPlanGenerator.weekdayFromIndex(p.dayKey),
          p.slot.timeOfDay,
        ),
      ),
      isTrue,
    );
    expect(
      planned.any(
        (p) =>
            p.dayKey == 1 && p.slot == MealSlot.noon,
      ),
      isFalse,
    );
  });

  test('plan-month-days criterion filters which slots are planned', () {
    final generator = MealPlanGenerator(random: Random(5));
    final recipe = _recipe(id: 'a', name: 'Any');

    final monthDays = PlanMonthDaysCriterion(
      selectedDays: {1, 3},
      startDay: 1,
      daysInMonth: 31,
    );

    final slots = MealPlanGenerator.monthSlots(startDay: 1, daysInMonth: 31)
        .where((s) => monthDays.includes(s.$1))
        .toList();

    // Days 1 and 3 × morning/noon/night = 6 slots
    expect(slots.length, 6);

    final planned = generator.generate(
      recipes: [recipe],
      slots: slots,
      weekdayForDayKey: (dayKey) {
        final date = DateTime(2026, 7, dayKey);
        return MealPlanGenerator.weekdayFromDate(date);
      },
    );

    expect(planned.length, 6);
    expect(planned.every((p) => monthDays.includes(p.dayKey)), isTrue);
    expect(planned.any((p) => p.dayKey == 2), isFalse);
  });
}
