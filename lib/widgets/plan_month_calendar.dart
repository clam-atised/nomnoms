import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/meal_plan_generator.dart';
import 'package:nomnom/theme/app_colors.dart';

enum PlanMonthCalendarMode {
  display,
  select,
  tap,
}

class PlanMonthCalendar extends StatelessWidget {
  const PlanMonthCalendar({
    super.key,
    required this.weeks,
    required this.startDay,
    required this.mode,
    this.selectedDays,
    this.onDaySelected,
    this.mealLineFor,
    this.onDayTap,
    this.dayHasMeals,
    this.cellHeight = 92,
  });

  final List<List<int?>> weeks;
  final int startDay;
  final PlanMonthCalendarMode mode;

  /// Used in [PlanMonthCalendarMode.select].
  final Set<int>? selectedDays;
  final ValueChanged<int>? onDaySelected;

  /// Used in [PlanMonthCalendarMode.display] / [PlanMonthCalendarMode.tap].
  /// Returns short meal lines for a day (e.g. "M Eggs").
  final List<String> Function(int day)? mealLineFor;

  /// Used in [PlanMonthCalendarMode.tap].
  final ValueChanged<int>? onDayTap;
  final bool Function(int day)? dayHasMeals;

  final double cellHeight;

  static const headers = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = nomnomTheme(context);
    final cellStyle = GoogleFonts.antic(color: theme.text, fontSize: 14);
    final mealNameStyle = GoogleFonts.antic(color: theme.text, fontSize: 11);
    final headerStyle = cellStyle.copyWith(fontSize: 12);

    return Table(
      border: TableBorder.all(color: theme.text),
      children: [
        TableRow(
          children: headers
              .map(
                (header) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: headerStyle,
                  ),
                ),
              )
              .toList(),
        ),
        ...weeks.map(
          (week) => TableRow(
            children: week.map((day) {
              if (day == null) {
                return SizedBox(height: cellHeight);
              }
              return _buildDayCell(
                context,
                day: day,
                cellStyle: cellStyle,
                mealNameStyle: mealNameStyle,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int day,
    required TextStyle cellStyle,
    required TextStyle mealNameStyle,
  }) {
    final theme = nomnomTheme(context);
    final eligible = day >= startDay;

    Widget content;
    switch (mode) {
      case PlanMonthCalendarMode.select:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$day', style: cellStyle),
                const Spacer(),
                if (eligible)
                  IgnorePointer(
                    child: Checkbox(
                      value: selectedDays?.contains(day) ?? false,
                      activeColor: theme.text,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) {},
                    ),
                  ),
              ],
            ),
          ],
        );
      case PlanMonthCalendarMode.display:
      case PlanMonthCalendarMode.tap:
        final lines = eligible ? (mealLineFor?.call(day) ?? const []) : const [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day', style: cellStyle),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 2),
              ...lines.map(
                (line) => Text(
                  line,
                  style: mealNameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
    }

    final padded = SizedBox(
      height: cellHeight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: content,
      ),
    );

    if (mode == PlanMonthCalendarMode.tap &&
        eligible &&
        (dayHasMeals?.call(day) ?? false)) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDayTap?.call(day),
          child: padded,
        ),
      );
    }

    if (mode == PlanMonthCalendarMode.select && eligible) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDaySelected?.call(day),
          child: padded,
        ),
      );
    }

    return padded;
  }
}

/// Convenience meal line builder matching Plan Month display style.
List<String> planMonthMealLines({
  required int day,
  required String? Function(int day, MealSlot slot) recipeName,
}) {
  return [
    for (final slot in MealSlot.values)
      '${slot.shortLabel} ${recipeName(day, slot) ?? ''}',
  ];
}
