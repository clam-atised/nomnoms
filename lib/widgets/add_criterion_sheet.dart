import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/plan_criterion.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/gradient_chip.dart';

Future<PlanCriterion?> showAddCriterionFlow(
  BuildContext context, {
  required bool allowFolder,
  required RecipeStore store,
}) async {
  final type = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: nomnomTheme(context).background,
        title: Text(
          'Add Criteria',
          style: GoogleFonts.antic(color: nomnomTheme(context).text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Preparation time',
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
              ),
              onTap: () => Navigator.pop(context, 'prep'),
            ),
            ListTile(
              title: Text(
                'Contains ingredient',
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
              ),
              onTap: () => Navigator.pop(context, 'contains'),
            ),
            if (allowFolder)
              ListTile(
                title: Text(
                  'By folder',
                  style: GoogleFonts.antic(color: nomnomTheme(context).text),
                ),
                onTap: () => Navigator.pop(context, 'folder'),
              ),
            ListTile(
              title: Text(
                'Repeating recipe',
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
              ),
              onTap: () => Navigator.pop(context, 'repeat'),
            ),
          ],
        ),
      );
    },
  );

  if (type == null || !context.mounted) return null;

  return switch (type) {
    'prep' => _showPrepRangeDialog(context),
    'contains' => _showContainsDialog(context, store),
    'folder' => _showFolderDialog(context, store),
    'repeat' => _showRepeatDialog(context, store),
    _ => null,
  };
}

Future<PlanCriterion?> _showPrepRangeDialog(BuildContext context) {
  return showDialog<PlanCriterion>(
    context: context,
    builder: (context) => const _PrepRangeDialog(),
  );
}

class _PrepRangeDialog extends StatefulWidget {
  const _PrepRangeDialog();

  @override
  State<_PrepRangeDialog> createState() => _PrepRangeDialogState();
}

class _PrepRangeDialogState extends State<_PrepRangeDialog> {
  RangeValues _range = const RangeValues(0, 30);

  String get _label {
    final min = _range.start.round();
    final max = _range.end.round();
    if (min <= 0) return 'Under $max min';
    return '$min–$max min';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: nomnomTheme(context).background,
      title: Text(
        'Preparation time',
        style: GoogleFonts.antic(color: nomnomTheme(context).text),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label,
            style: GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 16),
          ),
          RangeSlider(
            values: _range,
            min: 0,
            max: 180,
            divisions: 180,
            activeColor: nomnomTheme(context).text,
            labels: RangeLabels(
              '${_range.start.round()}',
              '${_range.end.round()}',
            ),
            onChanged: (values) {
              if (values.end < 1) return;
              setState(() {
                _range = RangeValues(
                  values.start.clamp(0, values.end),
                  values.end,
                );
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              PrepTimeRangeCriterion(
                minMinutes: _range.start.round(),
                maxMinutes: _range.end.round(),
              ),
            );
          },
          child: Text('Add', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
      ],
    );
  }
}

Future<PlanCriterion?> _showContainsDialog(
  BuildContext context,
  RecipeStore store,
) {
  final options = store.recentRecipes
      .expand((r) => r.ingredients.map((i) => i.name.trim()))
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  return showDialog<PlanCriterion>(
    context: context,
    builder: (context) => _ContainsDialog(ingredientOptions: options),
  );
}

class _ContainsDialog extends StatefulWidget {
  const _ContainsDialog({required this.ingredientOptions});

  final List<String> ingredientOptions;

  @override
  State<_ContainsDialog> createState() => _ContainsDialogState();
}

class _ContainsDialogState extends State<_ContainsDialog> {
  final List<String> _selected = [];
  String? _dropdownValue;

  @override
  Widget build(BuildContext context) {
    final available = widget.ingredientOptions
        .where((o) => !_selected.contains(o))
        .toList();

    return AlertDialog(
      backgroundColor: nomnomTheme(context).background,
      title: Text(
        'Contains ingredients',
        style: GoogleFonts.antic(color: nomnomTheme(context).text),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.ingredientOptions.isEmpty)
              Text(
                'No ingredients in recipes yet',
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
              )
            else
              DropdownButton<String>(
                value: _dropdownValue,
                isExpanded: true,
                hint: Text(
                  'Select ingredient',
                  style: GoogleFonts.antic(
                    color: nomnomTheme(context).text.withValues(alpha: 0.55),
                  ),
                ),
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
                items: available
                    .map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selected.add(value);
                    _dropdownValue = null;
                  });
                },
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected
                  .map(
                    (name) => GradientChip(
                      label: name,
                      onDismiss: () {
                        setState(() => _selected.remove(name));
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    ContainsIngredientsCriterion(List.of(_selected)),
                  );
                },
          child: Text('Add', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
      ],
    );
  }
}

Future<PlanCriterion?> _showFolderDialog(
  BuildContext context,
  RecipeStore store,
) {
  final folders = store.assignableFolders;
  if (folders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No folders available')),
    );
    return Future.value(null);
  }

  return showDialog<PlanCriterion>(
    context: context,
    builder: (context) => _FolderDialog(folders: folders),
  );
}

class _FolderDialog extends StatefulWidget {
  const _FolderDialog({required this.folders});

  final List<RecipeFolder> folders;

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: nomnomTheme(context).background,
      title: Text(
        'By folder',
        style: GoogleFonts.antic(color: nomnomTheme(context).text),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final folder in widget.folders)
              CheckboxListTile(
                value: _selected.contains(folder.id),
                activeColor: nomnomTheme(context).text,
                title: Text(
                  folder.name,
                  style: GoogleFonts.antic(color: folder.color),
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(folder.id);
                    } else {
                      _selected.remove(folder.id);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  final names = widget.folders
                      .where((f) => _selected.contains(f.id))
                      .map((f) => f.name)
                      .toList();
                  Navigator.pop(
                    context,
                    FolderCriterion(
                      folderIds: Set.of(_selected),
                      folderNames: names,
                    ),
                  );
                },
          child: Text('Add', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
      ],
    );
  }
}

Future<PlanCriterion?> _showRepeatDialog(
  BuildContext context,
  RecipeStore store,
) {
  final recipes = store.recentRecipes;
  if (recipes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No recipes available')),
    );
    return Future.value(null);
  }

  return showDialog<PlanCriterion>(
    context: context,
    builder: (context) => _RepeatDialog(recipes: recipes),
  );
}

class _RepeatDialog extends StatefulWidget {
  const _RepeatDialog({required this.recipes});

  final List<Recipe> recipes;

  @override
  State<_RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<_RepeatDialog> {
  String? _recipeId;
  int _times = 1;

  static const _timeLabels = [
    'None (exclude)',
    'Once',
    'Twice',
    'Thrice',
    '4 times',
    '5 times',
    '6 times',
    '7 times',
  ];

  @override
  void initState() {
    super.initState();
    _recipeId = widget.recipes.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: nomnomTheme(context).background,
      title: Text(
        'Repeating recipe',
        style: GoogleFonts.antic(color: nomnomTheme(context).text),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recipe', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
          DropdownButton<String>(
            value: _recipeId,
            isExpanded: true,
            style: GoogleFonts.antic(color: nomnomTheme(context).text),
            items: widget.recipes
                .map(
                  (r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _recipeId = value);
            },
          ),
          SizedBox(height: 16),
          Text('Repeat', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
          DropdownButton<int>(
            value: _times,
            isExpanded: true,
            style: GoogleFonts.antic(color: nomnomTheme(context).text),
            items: [
              for (var i = 0; i <= 7; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(_timeLabels[i]),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _times = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
        TextButton(
          onPressed: () {
            final recipe = widget.recipes.firstWhere((r) => r.id == _recipeId);
            Navigator.pop(
              context,
              RepeatRecipeCriterion(
                recipeId: recipe.id,
                recipeName: recipe.name,
                times: _times,
              ),
            );
          },
          child: Text('Add', style: GoogleFonts.antic(color: nomnomTheme(context).text)),
        ),
      ],
    );
  }
}
