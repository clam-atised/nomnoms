enum MeasurementSystem {
  metric,
  custom;
}

enum IngredientUnit {
  ml,
  cup,
  eighthCup,
  quarterCup,
  thirdCup,
  halfCup,
  tsp,
  tbsp,
  g,
  mg;

  String get label => switch (this) {
        IngredientUnit.ml => 'ml',
        IngredientUnit.cup => 'cup',
        IngredientUnit.eighthCup => '1/8 cup',
        IngredientUnit.quarterCup => '1/4 cup',
        IngredientUnit.thirdCup => '1/3 cup',
        IngredientUnit.halfCup => '1/2 cup',
        IngredientUnit.tsp => 'tsp',
        IngredientUnit.tbsp => 'tbsp',
        IngredientUnit.g => 'g',
        IngredientUnit.mg => 'mg',
      };
}

class Ingredient {
  const Ingredient({
    required this.quantity,
    required this.name,
    this.unit,
  });

  static const mlToFluidOunces = 0.034;
  static const gToOunces = 0.035;

  final double quantity;
  final IngredientUnit? unit;
  final String name;

  static String formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }
    return quantity
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String get label {
    final qty = formatQuantity(quantity);
    if (unit == null) return '$qty $name';
    return '$qty ${unit!.label} $name';
  }

  /// Display label for the active measurement system.
  /// Custom converts ml → fluid ounces and g → ounces; other units unchanged.
  String displayLabel(MeasurementSystem system) {
    if (system == MeasurementSystem.metric || unit == null) {
      return label;
    }

    return switch (unit!) {
      IngredientUnit.ml =>
        '${formatQuantity(quantity * mlToFluidOunces)} fluid ounces $name',
      IngredientUnit.g =>
        '${formatQuantity(quantity * gToOunces)} ounces $name',
      _ => label,
    };
  }
}

enum TimeOfDayOption {
  morning,
  noon,
  night;

  String get label => switch (this) {
        TimeOfDayOption.morning => 'Morning',
        TimeOfDayOption.noon => 'Noon',
        TimeOfDayOption.night => 'Night',
      };
}

enum DayOfWeekOption {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get label => switch (this) {
        DayOfWeekOption.monday => 'Monday',
        DayOfWeekOption.tuesday => 'Tuesday',
        DayOfWeekOption.wednesday => 'Wednesday',
        DayOfWeekOption.thursday => 'Thursday',
        DayOfWeekOption.friday => 'Friday',
        DayOfWeekOption.saturday => 'Saturday',
        DayOfWeekOption.sunday => 'Sunday',
      };
}

class Recipe {
  const Recipe({
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
  final List<Ingredient> ingredients;
  final int preparationMinutes;
  final List<TimeOfDayOption> timesOfDay;
  final String folderId;
  final List<DayOfWeekOption> daysOfWeek;
  final String link;
  final String instructions;
  final DateTime createdAt;
}
