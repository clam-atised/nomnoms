import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/theme/app_colors.dart';

/// Triple cell input: quantity + optional unit + name for ingredients.
/// Submits on Enter or when focus leaves the control group with valid data.
class IngredientDualInput extends StatefulWidget {
  const IngredientDualInput({
    super.key,
    required this.quantityController,
    required this.nameController,
    required this.unit,
    required this.onUnitChanged,
    required this.onSubmit,
  });

  final TextEditingController quantityController;
  final TextEditingController nameController;
  final IngredientUnit? unit;
  final ValueChanged<IngredientUnit?> onUnitChanged;
  final VoidCallback onSubmit;

  @override
  State<IngredientDualInput> createState() => _IngredientDualInputState();
}

class _IngredientDualInputState extends State<IngredientDualInput> {
  final _qtyFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _qtyFocus.addListener(_onFocusChange);
    _unitFocus.addListener(_onFocusChange);
    _nameFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _qtyFocus.removeListener(_onFocusChange);
    _unitFocus.removeListener(_onFocusChange);
    _nameFocus.removeListener(_onFocusChange);
    _qtyFocus.dispose();
    _unitFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _anyFocused =>
      _qtyFocus.hasFocus || _unitFocus.hasFocus || _nameFocus.hasFocus;

  void _onFocusChange() {
    if (_anyFocused) return;
    // Defer so focus can settle when moving between fields in this group.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _anyFocused) return;
      widget.onSubmit();
    });
  }

  InputDecoration _fieldDecoration(NomNomTheme colors, {String? hintText}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: hintText == null
          ? null
          : GoogleFonts.antic(
              color: colors.text.withValues(alpha: 0.5),
              fontSize: 16,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors.text),
        borderRadius: BorderRadius.circular(4),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.text),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.text, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final style = GoogleFonts.antic(color: colors.text, fontSize: 16);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 40,
          child: TextField(
            controller: widget.quantityController,
            focusNode: _qtyFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: style,
            decoration: _fieldDecoration(colors),
            onSubmitted: (_) => widget.onSubmit(),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 72,
          height: 40,
          child: InputDecorator(
            decoration: _fieldDecoration(colors),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<IngredientUnit?>(
                focusNode: _unitFocus,
                value: widget.unit,
                isExpanded: true,
                isDense: true,
                style: style,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: colors.text,
                  size: 18,
                ),
                dropdownColor: colors.background,
                items: [
                  DropdownMenuItem<IngredientUnit?>(
                    value: null,
                    child: Text('', style: style),
                  ),
                  ...IngredientUnit.values.map(
                    (unit) => DropdownMenuItem<IngredientUnit?>(
                      value: unit,
                      child: Text(
                        unit.label,
                        style: style,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: widget.onUnitChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 88,
          height: 40,
          child: TextField(
            controller: widget.nameController,
            focusNode: _nameFocus,
            style: style,
            inputFormatters: [
              LengthLimitingTextInputFormatter(100),
            ],
            decoration: _fieldDecoration(colors, hintText: 'Add..'),
            onSubmitted: (_) => widget.onSubmit(),
          ),
        ),
      ],
    );
  }
}
