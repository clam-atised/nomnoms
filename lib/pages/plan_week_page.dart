import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/meal_plan_generator.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/pages/view_recipe_page.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/add_criterion_sheet.dart';
import 'package:nomnom/widgets/gradient_chip.dart';
import 'package:nomnom/widgets/plan_month_calendar.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

enum PlanMode { week, month }

class PlanWeekPage extends StatefulWidget {
  const PlanWeekPage({super.key});

  @override
  State<PlanWeekPage> createState() => _PlanWeekPageState();
}

class _PlanWeekPageState extends State<PlanWeekPage> {
  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _meals = ['Morning', 'Noon', 'Night'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  PlanMode _mode = PlanMode.week;
  late final DateTime _focusedMonth;
  late final DateTime _today;
  final List<PlanCriterion> _criteria = [];

  final MealPlanGenerator _generator = MealPlanGenerator();

  /// (dayKey, slot) → recipe id
  Map<(int, MealSlot), String> _assignments = {};

  bool _didGenerate = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didGenerate) {
      _didGenerate = true;
      _assignments = _buildAssignments();
    }
  }

  String get _monthName => _monthNames[_focusedMonth.month - 1];

  String get _title => switch (_mode) {
        PlanMode.week => 'Plan Week',
        PlanMode.month => 'Plan Month: $_monthName',
      };

  String get _monthMenuLabel => 'Plan Month: $_monthName';

  int get _mondayBasedOffset {
    return DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;
  }

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  int get _monthPlanStartDay {
    final isCurrentMonth = _focusedMonth.year == _today.year &&
        _focusedMonth.month == _today.month;
    if (!isCurrentMonth) return 1;
    return _today.day;
  }

  List<List<int?>> _buildMonthWeeks() {
    final offset = _mondayBasedOffset;
    final daysInMonth = _daysInMonth;
    final totalCells = offset + daysInMonth;
    final weekCount = (totalCells / 7).ceil();
    final weeks = <List<int?>>[];

    var day = 1;
    for (var w = 0; w < weekCount; w++) {
      final week = <int?>[];
      for (var d = 0; d < 7; d++) {
        final cellIndex = w * 7 + d;
        if (cellIndex < offset || day > daysInMonth) {
          week.add(null);
        } else {
          week.add(day);
          day++;
        }
      }
      weeks.add(week);
    }
    return weeks;
  }

  DayOfWeekOption _weekdayForDayKey(int dayKey) {
    if (_mode == PlanMode.week) {
      return MealPlanGenerator.weekdayFromIndex(dayKey);
    }
    final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayKey);
    return MealPlanGenerator.weekdayFromDate(date);
  }

  Map<(int, MealSlot), String> _buildAssignments() {
    final store = RecipeStoreScope.of(context);
    final pool =
        filterRecipesByCriteria(store.recentRecipes, _criteria);

    var slots = _mode == PlanMode.week
        ? MealPlanGenerator.weekSlots()
        : MealPlanGenerator.monthSlots(
            startDay: _monthPlanStartDay,
            daysInMonth: _daysInMonth,
          );

    if (_mode == PlanMode.week) {
      final days = _criteria.whereType<DaysOfWeekCriterion>().firstOrNull;
      if (days != null) {
        slots = slots
            .where(
              (s) => days.includes(_weekdayForDayKey(s.$1), s.$2.timeOfDay),
            )
            .toList();
      }
    } else {
      final monthDays =
          _criteria.whereType<PlanMonthDaysCriterion>().firstOrNull;
      if (monthDays != null) {
        slots = slots.where((s) => monthDays.includes(s.$1)).toList();
      }
    }

    final repeats = _criteria.whereType<RepeatRecipeCriterion>().toList();

    final planned = _generator.generate(
      recipes: pool,
      slots: slots,
      weekdayForDayKey: _weekdayForDayKey,
      repeats: repeats,
    );
    return {
      for (final meal in planned) (meal.dayKey, meal.slot): meal.recipe.id,
    };
  }

  void _regeneratePlan() {
    setState(() {
      _assignments = _buildAssignments();
    });
  }

  Future<void> _addCriterion() async {
    final store = RecipeStoreScope.of(context);
    final isMonth = _mode == PlanMode.month;
    final criterion = await showAddCriterionFlow(
      context,
      allowFolder: true,
      allowDaysOfWeek: !isMonth,
      allowDaysOfMonth: isMonth,
      existingDaysOfWeek:
          _criteria.whereType<DaysOfWeekCriterion>().firstOrNull,
      existingMonthDays:
          _criteria.whereType<PlanMonthDaysCriterion>().firstOrNull,
      monthWeeks: isMonth ? _buildMonthWeeks() : null,
      monthStartDay: _monthPlanStartDay,
      daysInMonth: _daysInMonth,
      store: store,
    );
    if (!mounted || criterion == null) return;
    setState(() {
      if (criterion is DaysOfWeekCriterion) {
        _criteria.removeWhere((c) => c is DaysOfWeekCriterion);
      }
      if (criterion is PlanMonthDaysCriterion) {
        _criteria.removeWhere((c) => c is PlanMonthDaysCriterion);
      }
      _criteria.add(criterion);
    });
    _regeneratePlan();
  }

  bool _dayHasMeals(int day) {
    return MealSlot.values.any((slot) => _assignments.containsKey((day, slot)));
  }

  Future<void> _showDayMealsDialog(int day) async {
    final theme = nomnomTheme(context);
    final store = RecipeStoreScope.of(context);
    final titleStyle = GoogleFonts.antic(color: theme.text);
    final labelStyle = GoogleFonts.antic(color: theme.text, fontSize: 16);
    final mutedStyle = GoogleFonts.antic(
      color: theme.text.withValues(alpha: 0.45),
      fontSize: 16,
    );
    final linkStyle = GoogleFonts.antic(
      color: theme.text,
      fontSize: 16,
      decoration: TextDecoration.underline,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text('$_monthName $day', style: titleStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final slot in MealSlot.values) ...[
                if (slot != MealSlot.values.first) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(slot.timeOfDay.label, style: labelStyle),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final id = _assignments[(day, slot)];
                          final recipe =
                              id == null ? null : store.recipeById(id);
                          if (recipe == null) {
                            return Text('—', style: mutedStyle);
                          }
                          return InkWell(
                            onTap: () {
                              Navigator.of(dialogContext).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ViewRecipePage(recipeId: recipe.id),
                                ),
                              );
                            },
                            child: Text(recipe.name, style: linkStyle),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: titleStyle),
            ),
          ],
        );
      },
    );
  }

  List<Recipe> _assignedRecipes(RecipeStore store) {
    final recipes = <Recipe>[];
    for (final id in _assignments.values) {
      final recipe = store.recipeById(id);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }
    return recipes;
  }

  String? _recipeName(int dayKey, MealSlot slot) {
    final id = _assignments[(dayKey, slot)];
    if (id == null) return null;
    return RecipeStoreScope.of(context).recipeById(id)?.name;
  }

  List<Widget> _buildPlanEstimates(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    if (!settings.showCost && !settings.showCalorie && !settings.showProtein) {
      return const [];
    }

    final store = RecipeStoreScope.of(context);
    final recipes = _assignedRecipes(store);
    final colors = nomnomTheme(context);
    final labelStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 14,
    );
    final valueStyle = GoogleFonts.antic(
      color: colors.text.withValues(alpha: 0.7),
      fontSize: 14,
    );

    final widgets = <Widget>[];
    if (settings.showCost) {
      final estimate = store.estimateForRecipes(
        recipes,
        estimateFor: store.costEstimateFor,
      );
      widgets.add(
        _PlanEstimateLabel(
          label: 'Cost:',
          value: RecipeStore.formatEstimate(estimate.total),
          showInfo: !estimate.isComplete,
          infoMessage: RecipeStore.costEstimateInfoMessage,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      );
    }
    if (settings.showCalorie) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: 12));
      }
      final estimate = store.estimateForRecipes(
        recipes,
        estimateFor: store.calorieEstimateFor,
      );
      widgets.add(
        _PlanEstimateLabel(
          label: 'Calorie:',
          value: RecipeStore.formatEstimate(estimate.total),
          showInfo: !estimate.isComplete,
          infoMessage: RecipeStore.calorieEstimateInfoMessage,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      );
    }
    if (settings.showProtein) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: 12));
      }
      final estimate = store.estimateForRecipes(
        recipes,
        estimateFor: store.proteinEstimateFor,
      );
      widgets.add(
        _PlanEstimateLabel(
          label: 'Protein:',
          value: RecipeStore.formatEstimate(estimate.total),
          showInfo: false,
          infoMessage: '',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text,
      fontSize: 24,
    );
    final cellStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text,
      fontSize: 14,
    );
    final mealNameStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text,
      fontSize: 11,
    );

    return Scaffold(
      backgroundColor: nomnomTheme(context).background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back),
                    color: nomnomTheme(context).text,
                  ),
                  Expanded(
                    child: PopupMenuButton<PlanMode>(
                      onSelected: (mode) {
                        setState(() => _mode = mode);
                        _regeneratePlan();
                      },
                      color: nomnomTheme(context).background,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: PlanMode.week,
                          child: Text(
                            'Plan Week',
                            style: GoogleFonts.antic(
                              color: nomnomTheme(context).text,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: PlanMode.month,
                          child: Text(
                            _monthMenuLabel,
                            style: GoogleFonts.antic(
                              color: nomnomTheme(context).text,
                            ),
                          ),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _title,
                              style: titleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: nomnomTheme(context).text,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _regeneratePlan,
                    icon: Icon(Icons.refresh),
                    color: nomnomTheme(context).text,
                    tooltip: 'Regenerate plan',
                  ),
                  IconButton(
                    onPressed: () => showAppSettingsDialog(context),
                    icon: Icon(Icons.settings),
                    color: nomnomTheme(context).text,
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_mode == PlanMode.week)
                _buildWeekTable(cellStyle, mealNameStyle)
              else
                PlanMonthCalendar(
                  weeks: _buildMonthWeeks(),
                  startDay: _monthPlanStartDay,
                  mode: PlanMonthCalendarMode.tap,
                  mealLineFor: (day) => planMonthMealLines(
                    day: day,
                    recipeName: _recipeName,
                  ),
                  dayHasMeals: _dayHasMeals,
                  onDayTap: _showDayMealsDialog,
                ),
              SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: _addCriterion,
                    child: Text(
                      'Criteria:',
                      style: GoogleFonts.antic(
                        color: nomnomTheme(context).text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addCriterion,
                    icon: Icon(Icons.add),
                    color: nomnomTheme(context).text,
                  ),
                  const Spacer(),
                  ..._buildPlanEstimates(context),
                ],
              ),
              const SizedBox(height: 8),
              ..._criteria.map(
                (criterion) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GradientChip(
                    label: criterion.label,
                    onDismiss: () {
                      setState(() => _criteria.remove(criterion));
                      _regeneratePlan();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekTable(TextStyle cellStyle, TextStyle mealNameStyle) {
    return Table(
      border: TableBorder.all(color: nomnomTheme(context).text),
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          children: [
            const SizedBox(height: 40),
            ..._meals.map(
              (meal) => _TableCell(
                child: Text(
                  meal,
                  textAlign: TextAlign.center,
                  style: cellStyle,
                ),
              ),
            ),
          ],
        ),
        ...List.generate(_weekDays.length, (dayIndex) {
          return TableRow(
            children: [
              _TableCell(
                child: Text(
                  _weekDays[dayIndex],
                  textAlign: TextAlign.center,
                  style: cellStyle,
                ),
              ),
              ...MealSlot.values.map((slot) {
                final name = _recipeName(dayIndex, slot);
                return _TableCell(
                  child: Text(
                    name ?? '',
                    textAlign: TextAlign.center,
                    style: mealNameStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

class _PlanEstimateLabel extends StatelessWidget {
  const _PlanEstimateLabel({
    required this.label,
    required this.value,
    required this.showInfo,
    required this.infoMessage,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final bool showInfo;
  final String infoMessage;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label, style: labelStyle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showInfo)
          Tooltip(
            message: infoMessage,
            triggerMode: TooltipTriggerMode.tap,
            child: labelText,
          )
        else
          labelText,
        const SizedBox(width: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: child,
    );
  }
}
