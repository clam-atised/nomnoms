import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

enum CalculateMode { cost, calories }

class CalculateCostPage extends StatefulWidget {
  const CalculateCostPage({super.key});

  @override
  State<CalculateCostPage> createState() => _CalculateCostPageState();
}

class _CalculateCostPageState extends State<CalculateCostPage> {
  CalculateMode _mode = CalculateMode.cost;

  String get _modeLabel => switch (_mode) {
        CalculateMode.cost => 'cost',
        CalculateMode.calories => 'calories',
      };

  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: nomnomTheme(context).background,
          content: Text(
            'Ingredient cost adds up, record estimate cost for a single item',
            style: GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.antic(color: nomnomTheme(context).text),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editValue(
    BuildContext context,
    RecipeStore store,
    String name,
  ) async {
    final existing = _mode == CalculateMode.cost
        ? store.costFor(name)
        : store.calorieFor(name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ValueEditDialog(
        ingredientName: name,
        initialText: existing == null ? '' : _formatValue(existing),
        hintText: _mode == CalculateMode.cost ? 'price' : 'calories',
      ),
    );

    if (result == null) return;

    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      if (_mode == CalculateMode.cost) {
        store.setIngredientCost(name, null);
      } else {
        store.setIngredientCalorie(name, null);
      }
      return;
    }

    final value = double.tryParse(trimmed);
    if (value == null || value < 0) return;
    if (_mode == CalculateMode.cost) {
      store.setIngredientCost(name, value);
    } else {
      store.setIngredientCalorie(name, value);
    }
  }

  static String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final names = store.uniqueIngredientNames;
    final titleStyle = GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 18);
    final sectionStyle = GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 22);
    final nameStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text.withValues(alpha: 0.7),
      fontSize: 16,
    );
    final priceStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text.withValues(alpha: 0.55),
      fontSize: 16,
    );

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
                  Text('Calculate:', style: titleStyle),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PopupMenuButton<CalculateMode>(
                      onSelected: (mode) {
                        setState(() => _mode = mode);
                      },
                      color: nomnomTheme(context).background,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: CalculateMode.cost,
                          child: Text(
                            'cost',
                            style: GoogleFonts.antic(color: nomnomTheme(context).text),
                          ),
                        ),
                        PopupMenuItem(
                          value: CalculateMode.calories,
                          child: Text(
                            'calories',
                            style: GoogleFonts.antic(color: nomnomTheme(context).text),
                          ),
                        ),
                      ],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _modeLabel,
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
                    onPressed: () => _showInfoDialog(context),
                    icon: Icon(Icons.info_outline),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text('Ingredients', style: sectionStyle),
            ),
            Expanded(
              child: names.isEmpty
                  ? Center(
                      child: Text(
                        'No ingredients in recipes yet',
                        style: nameStyle,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 16,
                        childAspectRatio: 4.5,
                      ),
                      itemCount: names.length,
                      itemBuilder: (context, index) {
                        final name = names[index];
                        final String valueLabel;
                        if (_mode == CalculateMode.cost) {
                          final cost = store.costFor(name);
                          valueLabel =
                              cost == null ? 'price' : _formatValue(cost);
                        } else {
                          final calories = store.calorieFor(name);
                          valueLabel = calories == null
                              ? '0'
                              : _formatValue(calories);
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: nameStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _editValue(context, store, name),
                              child: Text(valueLabel, style: priceStyle),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueEditDialog extends StatefulWidget {
  const _ValueEditDialog({
    required this.ingredientName,
    required this.initialText,
    required this.hintText,
  });

  final String ingredientName;
  final String initialText;
  final String hintText;

  @override
  State<_ValueEditDialog> createState() => _ValueEditDialogState();
}

class _ValueEditDialogState extends State<_ValueEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: nomnomTheme(context).background,
      title: Text(
        widget.ingredientName,
        style: GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 18),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: GoogleFonts.antic(color: nomnomTheme(context).text, fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.antic(
            color: nomnomTheme(context).text.withValues(alpha: 0.5),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: nomnomTheme(context).text),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: nomnomTheme(context).text, width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.antic(color: nomnomTheme(context).text),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(
            'Save',
            style: GoogleFonts.antic(color: nomnomTheme(context).text),
          ),
        ),
      ],
    );
  }
}
