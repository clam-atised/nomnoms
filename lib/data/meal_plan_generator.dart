import 'dart:math';

import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';

enum MealSlot {
  morning,
  noon,
  night;

  TimeOfDayOption get timeOfDay => switch (this) {
        MealSlot.morning => TimeOfDayOption.morning,
        MealSlot.noon => TimeOfDayOption.noon,
        MealSlot.night => TimeOfDayOption.night,
      };

  String get shortLabel => switch (this) {
        MealSlot.morning => 'M',
        MealSlot.noon => 'N',
        MealSlot.night => 'Ni',
      };
}

/// One assigned meal in a generated plan.
class PlannedMeal {
  const PlannedMeal({
    required this.dayKey,
    required this.slot,
    required this.recipe,
  });

  /// Week: 0=Mon … 6=Sun. Month: day of month (1–31).
  final int dayKey;
  final MealSlot slot;
  final Recipe recipe;
}

class MealPlanGenerator {
  MealPlanGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds one recipe per slot using hard meal/day tag rules and optional
  /// repeat placements.
  ///
  /// [weekdayForDayKey] maps a slot's dayKey to [DayOfWeekOption] (week index
  /// or calendar day-of-month depending on mode).
  List<PlannedMeal> generate({
    required List<Recipe> recipes,
    required List<(int dayKey, MealSlot slot)> slots,
    required DayOfWeekOption Function(int dayKey) weekdayForDayKey,
    List<RepeatRecipeCriterion> repeats = const [],
  }) {
    if (slots.isEmpty) return const [];

    final excludedIds = {
      for (final r in repeats)
        if (r.times == 0) r.recipeId,
    };

    final pool = recipes.where((r) => !excludedIds.contains(r.id)).toList()
      ..shuffle(_random);

    final assignments = <(int, MealSlot), Recipe>{};
    final remainingSlots = List<(int, MealSlot)>.of(slots)..shuffle(_random);

    // Force-place repeat recipes first.
    for (final repeat in repeats) {
      if (repeat.times <= 0) continue;
      final recipe = recipes.where((r) => r.id == repeat.recipeId).firstOrNull;
      if (recipe == null) continue;

      final eligible = remainingSlots
          .where(
            (s) => _isEligible(
              recipe,
              slot: s.$2,
              weekday: weekdayForDayKey(s.$1),
            ),
          )
          .toList()
        ..shuffle(_random);

      final placeCount = min(repeat.times, eligible.length);
      for (var i = 0; i < placeCount; i++) {
        final slot = eligible[i];
        assignments[slot] = recipe;
        remainingSlots.remove(slot);
      }
    }

    // Count how many times each forced recipe was already placed so we don't
    // over-cycle them when filling the rest — pool still can include them,
    // but we prefer other recipes when a forced count is saturated.
    final forcedCounts = <String, int>{};
    for (final entry in assignments.entries) {
      forcedCounts[entry.value.id] = (forcedCounts[entry.value.id] ?? 0) + 1;
    }
    final forcedLimits = {
      for (final r in repeats)
        if (r.times > 0) r.recipeId: r.times,
    };

    var index = 0;
    final fillOrder = List<(int, MealSlot)>.of(remainingSlots)..shuffle(_random);

    for (final slot in fillOrder) {
      final weekday = weekdayForDayKey(slot.$1);
      var candidates = pool
          .where(
            (r) => _isEligible(r, slot: slot.$2, weekday: weekday),
          )
          .where((r) {
            final limit = forcedLimits[r.id];
            if (limit == null) return true;
            return (forcedCounts[r.id] ?? 0) < limit;
          })
          .toList();

      // If everything was capped by repeat limits, fall back to any eligible.
      if (candidates.isEmpty) {
        candidates = pool
            .where(
              (r) => _isEligible(r, slot: slot.$2, weekday: weekday),
            )
            .toList();
      }

      if (candidates.isEmpty) continue;

      final recipe = candidates[index % candidates.length];
      index++;
      assignments[slot] = recipe;
      forcedCounts[recipe.id] = (forcedCounts[recipe.id] ?? 0) + 1;
    }

    return [
      for (final entry in assignments.entries)
        PlannedMeal(
          dayKey: entry.key.$1,
          slot: entry.key.$2,
          recipe: entry.value,
        ),
    ];
  }

  bool _isEligible(
    Recipe recipe, {
    required MealSlot slot,
    required DayOfWeekOption weekday,
  }) {
    final timeOk = recipe.timesOfDay.isEmpty ||
        recipe.timesOfDay.contains(slot.timeOfDay);
    final dayOk =
        recipe.daysOfWeek.isEmpty || recipe.daysOfWeek.contains(weekday);
    return timeOk && dayOk;
  }

  static List<(int dayKey, MealSlot slot)> weekSlots() {
    return [
      for (var day = 0; day < 7; day++)
        for (final slot in MealSlot.values) (day, slot),
    ];
  }

  /// Month meal slots from [startDay] through [daysInMonth] inclusive.
  static List<(int dayKey, MealSlot slot)> monthSlots({
    required int startDay,
    required int daysInMonth,
  }) {
    if (startDay > daysInMonth) return const [];
    return [
      for (var day = startDay; day <= daysInMonth; day++)
        for (final slot in MealSlot.values) (day, slot),
    ];
  }

  static DayOfWeekOption weekdayFromIndex(int mondayBasedIndex) {
    return DayOfWeekOption.values[mondayBasedIndex.clamp(0, 6)];
  }

  static DayOfWeekOption weekdayFromDate(DateTime date) {
    return DayOfWeekOption.values[date.weekday - 1];
  }
}
