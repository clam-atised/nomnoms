import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/pages/view_recipe_page.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/add_criterion_sheet.dart';
import 'package:nomnom/widgets/gradient_chip.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

class SpinWheelPage extends StatefulWidget {
  const SpinWheelPage({super.key});

  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage>
    with SingleTickerProviderStateMixin {
  int _folderIndex = 0;
  bool _didInitFolder = false;
  final List<PlanCriterion> _criteria = [];
  final StreamController<int> _selectedController = StreamController<int>();
  bool _isSpinning = false;
  int? _pendingIndex;
  List<Recipe> _spinRecipes = [];
  late final AnimationController _hintBlinkController;
  int _hintBlinkCount = 0;
  static const _maxHintBlinks = 6;

  @override
  void initState() {
    super.initState();
    _hintBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener(_onHintBlinkStatus);
    _hintBlinkController.forward();
  }

  void _onHintBlinkStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    _hintBlinkCount++;
    if (_hintBlinkCount >= _maxHintBlinks) {
      _hintBlinkController.stop();
      _hintBlinkController.value = 1.0;
      return;
    }
    if (status == AnimationStatus.completed) {
      _hintBlinkController.reverse();
    } else {
      _hintBlinkController.forward();
    }
  }

  void _restartHintBlink() {
    _hintBlinkCount = 0;
    _hintBlinkController
      ..stop()
      ..value = 0.0
      ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitFolder) {
      _folderIndex = 0;
      _didInitFolder = true;
    }
  }

  @override
  void dispose() {
    _hintBlinkController.dispose();
    _selectedController.close();
    super.dispose();
  }

  RecipeFolder _currentFolder(RecipeStore store) => store.folders[_folderIndex];

  List<Recipe> _filteredRecipes(RecipeStore store) {
    return filterRecipesByCriteria(
      store.recipesInFolder(_currentFolder(store).id),
      _criteria,
    );
  }

  Color _lightTint(Color color) {
    return Color.lerp(color, Colors.white, 0.45) ?? color;
  }

  Future<void> _addCriterion() async {
    final store = RecipeStoreScope.of(context);
    final criterion = await showAddCriterionFlow(
      context,
      allowFolder: false,
      store: store,
    );
    if (!mounted || criterion == null) return;
    setState(() => _criteria.add(criterion));
  }

  void _spin(List<Recipe> recipes) {
    if (recipes.isEmpty || _isSpinning) return;
    final index = Random().nextInt(recipes.length);
    _spinRecipes = List.of(recipes);
    _pendingIndex = index;
    setState(() => _isSpinning = true);
    _selectedController.add(index);
  }

  Future<void> _onSpinComplete() async {
    final index = _pendingIndex;
    if (index == null || index < 0 || index >= _spinRecipes.length) {
      if (mounted) setState(() => _isSpinning = false);
      return;
    }
    final recipe = _spinRecipes[index];
    if (!mounted) return;
    setState(() {
      _isSpinning = false;
      _pendingIndex = null;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final store = RecipeStoreScope.of(context);
        final settings = AppSettingsScope.of(context);
        final colors = nomnomTheme(context);
        final costEstimate = store.costEstimateFor(recipe);
        final calorieEstimate = store.calorieEstimateFor(recipe);
        final proteinEstimate = store.proteinEstimateFor(recipe);
        final labelStyle = GoogleFonts.antic(
          color: colors.text,
          fontSize: 16,
        );
        final valueStyle = GoogleFonts.antic(
          color: colors.text.withValues(alpha: 0.7),
          fontSize: 16,
        );

        return AlertDialog(
          backgroundColor: colors.background,
          title: Text(
            'Selected',
            style: GoogleFonts.antic(color: colors.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewRecipePage(recipeId: recipe.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    recipe.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.antic(
                      color: colors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              if (settings.showCost) ...[
                const SizedBox(height: 12),
                _EstimateRow(
                  label: 'Cost',
                  value: RecipeStore.formatEstimate(costEstimate.total),
                  showInfo: !costEstimate.isComplete,
                  infoMessage: RecipeStore.costEstimateInfoMessage,
                  labelStyle: labelStyle,
                  valueStyle: valueStyle,
                  iconColor: colors.text,
                ),
              ],
              if (settings.showCalorie) ...[
                const SizedBox(height: 8),
                _EstimateRow(
                  label: 'Calories',
                  value: RecipeStore.formatEstimate(calorieEstimate.total),
                  showInfo: !calorieEstimate.isComplete,
                  infoMessage: RecipeStore.calorieEstimateInfoMessage,
                  labelStyle: labelStyle,
                  valueStyle: valueStyle,
                  iconColor: colors.text,
                ),
              ],
              if (settings.showProtein) ...[
                const SizedBox(height: 8),
                _EstimateRow(
                  label: 'Protein',
                  value: RecipeStore.formatEstimate(proteinEstimate.total),
                  showInfo: false,
                  infoMessage: '',
                  labelStyle: labelStyle,
                  valueStyle: valueStyle,
                  iconColor: colors.text,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.antic(color: colors.text),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    if (_folderIndex >= store.folders.length) {
      _folderIndex = 0;
    }
    final folder = _currentFolder(store);
    final recipes = _filteredRecipes(store);
    // FortuneWheel requires at least 2 items; duplicate a lone recipe.
    final wheelRecipes = recipes.length == 1
        ? <Recipe>[recipes.first, recipes.first]
        : recipes;
    final titleStyle = GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 18);

    return Scaffold(
      backgroundColor: nomnomTheme(context).background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back),
                    color: nomnomTheme(context).text,
                  ),
                  Text('Spin Wheel:', style: titleStyle),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PopupMenuButton<int>(
                      onSelected: (index) {
                        setState(() {
                          _folderIndex = index;
                          _isSpinning = false;
                          _pendingIndex = null;
                        });
                        _restartHintBlink();
                      },
                      color: nomnomTheme(context).background,
                      itemBuilder: (context) => [
                        for (var i = 0; i < store.folders.length; i++)
                          PopupMenuItem(
                            value: i,
                            child: Text(
                              store.folders[i].name,
                              style: GoogleFonts.antic(
                                color: store.folders[i].color,
                              ),
                            ),
                          ),
                      ],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              folder.name,
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
                    onPressed: () {
                      setState(() {
                        _criteria.clear();
                        _isSpinning = false;
                        _pendingIndex = null;
                      });
                      _restartHintBlink();
                    },
                    icon: Icon(Icons.refresh),
                    color: nomnomTheme(context).text,
                  ),
                  IconButton(
                    onPressed: () => showAppSettingsDialog(context),
                    icon: Icon(Icons.settings),
                    color: nomnomTheme(context).text,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: recipes.isEmpty
                    ? Center(
                        child: Text(
                          'No recipes match these criteria',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.antic(
                            color: nomnomTheme(context).text,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          if (!_isSpinning)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 12),
                              child: FadeTransition(
                                opacity: _hintBlinkController,
                                child: Center(
                                  child: Text(
                                    'tap on wheel to spin',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.antic(
                                      color: nomnomTheme(context).text,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _spin(wheelRecipes),
                              child: FortuneWheel(
                                selected: _selectedController.stream,
                                animateFirst: false,
                                onAnimationEnd: _onSpinComplete,
                                indicators: [
                                  FortuneIndicator(
                                    alignment: Alignment.topCenter,
                                    child: TriangleIndicator(
                                      color: nomnomTheme(context).text,
                                    ),
                                  ),
                                ],
                                items: [
                                  for (var i = 0; i < wheelRecipes.length; i++)
                                    FortuneItem(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          wheelRecipes[i].name,
                                          style: GoogleFonts.antic(
                                            color: i.isEven
                                                ? Colors.white
                                                : nomnomTheme(context).text,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      style: FortuneItemStyle(
                                        color: i.isEven
                                            ? folder.color
                                            : _lightTint(folder.color),
                                        borderColor:
                                            nomnomTheme(context).background,
                                        borderWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.label,
    required this.value,
    required this.showInfo,
    required this.infoMessage,
    required this.labelStyle,
    required this.valueStyle,
    required this.iconColor,
  });

  final String label;
  final String value;
  final bool showInfo;
  final String infoMessage;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label, style: labelStyle);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showInfo)
          Tooltip(
            message: infoMessage,
            triggerMode: TooltipTriggerMode.tap,
            child: labelText,
          )
        else
          labelText,
        if (showInfo) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: infoMessage,
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: iconColor.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Text(value, style: valueStyle),
      ],
    );
  }
}
