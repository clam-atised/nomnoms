import 'package:nomnom/models/recipe.dart';

sealed class PlanCriterion {
  String get label;

  bool matches(Recipe recipe);
}

class PrepTimeRangeCriterion extends PlanCriterion {
  PrepTimeRangeCriterion({
    required this.minMinutes,
    required this.maxMinutes,
  });

  final int minMinutes;
  final int maxMinutes;

  @override
  String get label {
    if (minMinutes <= 0) {
      return 'Preparation: under $maxMinutes min';
    }
    return 'Preparation: $minMinutes–$maxMinutes min';
  }

  @override
  bool matches(Recipe recipe) {
    final prep = recipe.preparationMinutes;
    if (minMinutes <= 0) {
      return prep <= maxMinutes;
    }
    return prep >= minMinutes && prep <= maxMinutes;
  }
}

class ContainsIngredientsCriterion extends PlanCriterion {
  ContainsIngredientsCriterion(this.ingredients);

  final List<String> ingredients;

  @override
  String get label => 'Contains: ${ingredients.join(', ')}';

  @override
  bool matches(Recipe recipe) {
    if (ingredients.isEmpty) return true;
    final names =
        recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
    return ingredients.every((needed) {
      final query = needed.toLowerCase();
      return names.any((n) => n.contains(query));
    });
  }
}

class FolderCriterion extends PlanCriterion {
  FolderCriterion({
    required this.folderIds,
    required this.folderNames,
  });

  final Set<String> folderIds;
  final List<String> folderNames;

  @override
  String get label => 'Folders: ${folderNames.join(', ')}';

  @override
  bool matches(Recipe recipe) => folderIds.contains(recipe.folderId);
}

class RepeatRecipeCriterion extends PlanCriterion {
  RepeatRecipeCriterion({
    required this.recipeId,
    required this.recipeName,
    required this.times,
  });

  final String recipeId;
  final String recipeName;

  /// 0 = exclude from pool; 1–7 = place exactly that many times in plan.
  final int times;

  @override
  String get label => times == 0
      ? 'Exclude: $recipeName'
      : 'Repeat: $recipeName × $times';

  @override
  bool matches(Recipe recipe) {
    if (times == 0) return recipe.id != recipeId;
    return true;
  }
}

/// Which weekdays and meal times should receive planned meals.
///
/// Does not filter recipes — slot selection is applied when building the plan.
class DaysOfWeekCriterion extends PlanCriterion {
  DaysOfWeekCriterion({required this.selectedByDay});

  /// Only days present with a non-empty slot set are enabled.
  final Map<DayOfWeekOption, Set<TimeOfDayOption>> selectedByDay;

  factory DaysOfWeekCriterion.all() {
    return DaysOfWeekCriterion(
      selectedByDay: {
        for (final day in DayOfWeekOption.values)
          day: {...TimeOfDayOption.values},
      },
    );
  }

  bool includes(DayOfWeekOption day, TimeOfDayOption time) =>
      selectedByDay[day]?.contains(time) ?? false;

  @override
  String get label {
    final parts = <String>[];
    for (final day in DayOfWeekOption.values) {
      final slots = selectedByDay[day];
      if (slots == null || slots.isEmpty) continue;
      final short = day.label.substring(0, 3);
      if (slots.length == TimeOfDayOption.values.length) {
        parts.add('$short all');
      } else {
        final slotPart = TimeOfDayOption.values
            .where(slots.contains)
            .map((t) => switch (t) {
                  TimeOfDayOption.morning => 'M',
                  TimeOfDayOption.noon => 'N',
                  TimeOfDayOption.night => 'Ni',
                })
            .join('/');
        parts.add('$short $slotPart');
      }
    }
    if (parts.isEmpty) return 'Days: none';
    return 'Days: ${parts.join(', ')}';
  }

  @override
  bool matches(Recipe recipe) => true;
}

/// Which calendar days of the month should receive planned meals.
///
/// Does not filter recipes — slot selection is applied when building the plan.
class PlanMonthDaysCriterion extends PlanCriterion {
  PlanMonthDaysCriterion({
    required this.selectedDays,
    this.startDay = 1,
    this.daysInMonth = 31,
  });

  /// Day-of-month numbers (1–31) that should be planned.
  final Set<int> selectedDays;

  /// Inclusive range used for the "all" label when every eligible day is selected.
  final int startDay;
  final int daysInMonth;

  factory PlanMonthDaysCriterion.allEligible({
    required int startDay,
    required int daysInMonth,
  }) {
    return PlanMonthDaysCriterion(
      selectedDays: {for (var d = startDay; d <= daysInMonth; d++) d},
      startDay: startDay,
      daysInMonth: daysInMonth,
    );
  }

  bool includes(int dayKey) => selectedDays.contains(dayKey);

  @override
  String get label {
    if (selectedDays.isEmpty) return 'Days: none';

    final eligibleCount =
        daysInMonth >= startDay ? daysInMonth - startDay + 1 : 0;
    if (eligibleCount > 0 && selectedDays.length == eligibleCount) {
      final allEligible = selectedDays.every(
        (d) => d >= startDay && d <= daysInMonth,
      );
      if (allEligible) return 'Days: all';
    }

    final sorted = selectedDays.toList()..sort();
    final parts = <String>[];
    var rangeStart = sorted.first;
    var rangeEnd = sorted.first;

    void flush() {
      if (rangeStart == rangeEnd) {
        parts.add('$rangeStart');
      } else if (rangeEnd == rangeStart + 1) {
        parts.add('$rangeStart, $rangeEnd');
      } else {
        parts.add('$rangeStart–$rangeEnd');
      }
    }

    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == rangeEnd + 1) {
        rangeEnd = sorted[i];
      } else {
        flush();
        rangeStart = sorted[i];
        rangeEnd = sorted[i];
      }
    }
    flush();

    return 'Days: ${parts.join(', ')}';
  }

  @override
  bool matches(Recipe recipe) => true;
}

List<Recipe> filterRecipesByCriteria(
  List<Recipe> recipes,
  List<PlanCriterion> criteria,
) {
  var result = List<Recipe>.of(recipes);
  for (final criterion in criteria) {
    result = result.where(criterion.matches).toList();
  }
  return result;
}
