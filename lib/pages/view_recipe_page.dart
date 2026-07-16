import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/gradient_chip.dart';
import 'package:nomnom/widgets/ingredient_dual_input.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

class ViewRecipePage extends StatefulWidget {
  const ViewRecipePage({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<ViewRecipePage> createState() => _ViewRecipePageState();
}

class _ViewRecipePageState extends State<ViewRecipePage> {
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _ingredientNameController = TextEditingController();
  final _linkController = TextEditingController();
  final _instructionsController = TextEditingController();

  final List<Ingredient> _ingredients = [];
  final List<TimeOfDayOption> _timesOfDay = [];
  final List<DayOfWeekOption> _daysOfWeek = [];

  IngredientUnit? _ingredientUnit;
  int? _preparationMinutes;
  String _folderId = '';
  DateTime? _createdAt;

  TextStyle get _labelStyle => GoogleFonts.antic(
        color: nomnomTheme(context).text,
        fontSize: 18,
      );

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _ingredientNameController.dispose();
    _linkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _loadRecipeIntoEditors(Recipe recipe) {
    _nameController.text = recipe.name;
    _linkController.text = recipe.link;
    _instructionsController.text = recipe.instructions;
    _qtyController.clear();
    _ingredientNameController.clear();
    _ingredientUnit = null;
    _ingredients
      ..clear()
      ..addAll(recipe.ingredients);
    _timesOfDay
      ..clear()
      ..addAll(recipe.timesOfDay);
    _daysOfWeek
      ..clear()
      ..addAll(recipe.daysOfWeek);
    _preparationMinutes = recipe.preparationMinutes;
    _folderId = recipe.folderId;
    _createdAt = recipe.createdAt;
  }

  void _enterEditMode(Recipe recipe) {
    _loadRecipeIntoEditors(recipe);
    setState(() => _isEditing = true);
  }

  void _addIngredient() {
    final qty = double.tryParse(_qtyController.text.trim());
    final name = _ingredientNameController.text.trim();
    if (qty == null || qty <= 0 || qty > 100 || name.isEmpty) return;
    if (name.length > 100) return;

    setState(() {
      _ingredients.add(
        Ingredient(quantity: qty, name: name, unit: _ingredientUnit),
      );
      _qtyController.clear();
      _ingredientNameController.clear();
      _ingredientUnit = null;
    });
  }

  Future<void> _pickPreparationTime() async {
    var duration = Duration(minutes: _preparationMinutes ?? 5);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: nomnomTheme(context).background,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 260,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Done',
                      style: GoogleFonts.antic(color: nomnomTheme(context).text),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: duration,
                    onTimerDurationChanged: (value) {
                      duration = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final minutes = duration.inMinutes;
    if (minutes > 0) {
      setState(() => _preparationMinutes = minutes);
    }
  }

  Future<void> _pickTimesOfDay() async {
    final selected = Set<TimeOfDayOption>.from(_timesOfDay);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: nomnomTheme(context).background,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Time of Day', style: _labelStyle),
                    const SizedBox(height: 12),
                    ...TimeOfDayOption.values.map((option) {
                      final checked = selected.contains(option);
                      return CheckboxListTile(
                        value: checked,
                        activeColor: nomnomTheme(context).text,
                        title: Text(option.label, style: _labelStyle),
                        onChanged: (value) {
                          setModalState(() {
                            if (value == true) {
                              selected.add(option);
                            } else {
                              selected.remove(option);
                            }
                          });
                        },
                      );
                    }),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Done',
                        style: GoogleFonts.antic(color: nomnomTheme(context).text),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    setState(() {
      _timesOfDay
        ..clear()
        ..addAll(selected);
    });
  }

  Future<void> _pickDaysOfWeek() async {
    final selected = Set<DayOfWeekOption>.from(_daysOfWeek);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: nomnomTheme(context).background,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Day of Week', style: _labelStyle),
                      const SizedBox(height: 12),
                      ...DayOfWeekOption.values.map((option) {
                        final checked = selected.contains(option);
                        return CheckboxListTile(
                          value: checked,
                          activeColor: nomnomTheme(context).text,
                          title: Text(option.label, style: _labelStyle),
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selected.add(option);
                              } else {
                                selected.remove(option);
                              }
                            });
                          },
                        );
                      }),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Done',
                          style: GoogleFonts.antic(color: nomnomTheme(context).text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    setState(() {
      _daysOfWeek
        ..clear()
        ..addAll(selected);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _saveEdits() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Recipe name is required');
      return;
    }
    if (_ingredients.isEmpty) {
      _showMessage('Add at least one ingredient');
      return;
    }
    if (_preparationMinutes == null || _preparationMinutes! <= 0) {
      _showMessage('Preparation time is required');
      return;
    }
    if (_folderId.isEmpty) {
      _showMessage('Recipe folder is required');
      return;
    }

    final store = RecipeStoreScope.of(context);
    final existing = store.recipeById(widget.recipeId);
    if (existing == null) {
      _showMessage('Failed to save. Try again later.');
      return;
    }

    final ok = store.updateRecipe(
      Recipe(
        id: widget.recipeId,
        name: name,
        ingredients: List.of(_ingredients),
        preparationMinutes: _preparationMinutes!,
        folderId: _folderId,
        createdAt: _createdAt ?? existing.createdAt,
        timesOfDay: List.of(_timesOfDay),
        daysOfWeek: List.of(_daysOfWeek),
        link: _linkController.text.trim(),
        instructions: _instructionsController.text,
      ),
    );

    if (ok) {
      _showMessage('Changes saved');
      setState(() => _isEditing = false);
    } else {
      _showMessage('Failed to save. Try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final recipe = store.recipeById(widget.recipeId);
    final titleStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text,
      fontSize: 24,
    );
    final fieldStyle = GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 16);

    if (recipe == null && !_isEditing) {
      return Scaffold(
        backgroundColor: nomnomTheme(context).background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back),
                      color: nomnomTheme(context).text,
                    ),
                    Expanded(
                      child: Text('View Recipe', style: titleStyle),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(child: Text('Recipe not found')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: nomnomTheme(context).background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_isEditing) {
                        setState(() => _isEditing = false);
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back),
                    color: nomnomTheme(context).text,
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Recipe' : 'View Recipe',
                      style: titleStyle,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_isEditing) {
                        _saveEdits();
                      } else if (recipe != null) {
                        _enterEditMode(recipe);
                      }
                    },
                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                    color: nomnomTheme(context).text,
                    tooltip: _isEditing ? 'Save' : 'Edit',
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
              child: _isEditing
                  ? _buildEditBody(store, fieldStyle)
                  : _buildViewBody(store, recipe!, fieldStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBody(
    RecipeStore store,
    Recipe recipe,
    TextStyle fieldStyle,
  ) {
    final folder = store.folderById(recipe.folderId);
    final instructionsLength = recipe.instructions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recipe Name:', style: _labelStyle),
          SizedBox(height: 4),
          Text(recipe.name, style: _labelStyle),
          SizedBox(height: 20),
          Text('Contains:', style: _labelStyle),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients
                .map((i) => GradientChip(label: i.label))
                .toList(),
          ),
          SizedBox(height: 20),
          Text(
            'Preparation Time: ${recipe.preparationMinutes} minutes',
            style: _labelStyle,
          ),
          SizedBox(height: 20),
          Text('Time of Day:', style: _labelStyle),
          if (recipe.timesOfDay.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.timesOfDay
                  .map((t) => GradientChip(label: t.label))
                  .toList(),
            ),
          ],
          SizedBox(height: 20),
          Text(
            'Recipe Folder: ${folder?.name ?? recipe.folderId}',
            style: _labelStyle,
          ),
          SizedBox(height: 20),
          Text('Day of Week:', style: _labelStyle),
          if (recipe.daysOfWeek.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.daysOfWeek
                  .map((d) => GradientChip(label: d.label))
                  .toList(),
            ),
          ],
          SizedBox(height: 20),
          Text('Link:', style: _labelStyle),
          SizedBox(height: 4),
          Text(
            recipe.link.isEmpty ? '—' : recipe.link,
            style: fieldStyle,
          ),
          SizedBox(height: 20),
          Text('Instructions:', style: _labelStyle),
          SizedBox(height: 8),
          Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                decoration: BoxDecoration(
                  border: Border.all(color: nomnomTheme(context).text),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  recipe.instructions.isEmpty ? '' : recipe.instructions,
                  style: fieldStyle,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  '$instructionsLength/5000',
                  style: GoogleFonts.antic(
                    color: nomnomTheme(context).text.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditBody(RecipeStore store, TextStyle fieldStyle) {
    final instructionsLength = _instructionsController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recipe Name:', style: _labelStyle),
          TextField(
            controller: _nameController,
            style: fieldStyle,
            inputFormatters: [
              LengthLimitingTextInputFormatter(250),
            ],
            decoration: InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Contains:', style: _labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._ingredients.map(
                (ingredient) => GradientChip(
                  label: ingredient.label,
                  onDismiss: () {
                    setState(() {
                      _ingredients.remove(ingredient);
                    });
                  },
                ),
              ),
              IngredientDualInput(
                quantityController: _qtyController,
                nameController: _ingredientNameController,
                unit: _ingredientUnit,
                onUnitChanged: (unit) {
                  setState(() => _ingredientUnit = unit);
                },
                onSubmit: _addIngredient,
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickPreparationTime,
            child: Row(
              children: [
                Text('Preparation Time:', style: _labelStyle),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _preparationMinutes == null
                        ? 'Set timer'
                        : '$_preparationMinutes minutes',
                    style: fieldStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickTimesOfDay,
            child: Text('Time of Day:', style: _labelStyle),
          ),
          if (_timesOfDay.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timesOfDay
                  .map(
                    (option) => GradientChip(
                      label: option.label,
                      onDismiss: () {
                        setState(() => _timesOfDay.remove(option));
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: 20),
          Row(
            children: [
              Text('Recipe Folder:', style: _labelStyle),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _folderId.isEmpty ? null : _folderId,
                  hint: Text(
                    'Select folder',
                    style: fieldStyle.copyWith(
                      color: nomnomTheme(context).text.withValues(alpha: 0.55),
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: fieldStyle,
                  items: [
                    DropdownMenuItem(
                      value: RecipeStore.recentFolderId,
                      child: Text(
                        store
                                .folderById(RecipeStore.recentFolderId)
                                ?.name ??
                            'Recent recipes',
                      ),
                    ),
                    ...store.assignableFolders.map(
                      (folder) => DropdownMenuItem(
                        value: folder.id,
                        child: Text(folder.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _folderId = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickDaysOfWeek,
            child: Text('Day of Week:', style: _labelStyle),
          ),
          if (_daysOfWeek.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek
                  .map(
                    (option) => GradientChip(
                      label: option.label,
                      onDismiss: () {
                        setState(() => _daysOfWeek.remove(option));
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: 20),
          Text('Link:', style: _labelStyle),
          TextField(
            controller: _linkController,
            style: fieldStyle,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1000),
            ],
            decoration: InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: nomnomTheme(context).text),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Instructions:', style: _labelStyle),
          SizedBox(height: 8),
          Stack(
            children: [
              TextField(
                controller: _instructionsController,
                style: fieldStyle,
                maxLines: 10,
                minLines: 8,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5000),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: nomnomTheme(context).text),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: nomnomTheme(context).text),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: nomnomTheme(context).text,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  '$instructionsLength/5000',
                  style: GoogleFonts.antic(
                    color: nomnomTheme(context).text.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
