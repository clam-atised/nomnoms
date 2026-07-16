import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/theme/app_colors.dart';

Future<void> showAppSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const SettingsDialog(),
  );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final colors = nomnomTheme(context);
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 20,
    );
    final labelStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 16,
    );

    return AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Settings',
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
      content: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsToggleRow(
                label: 'Night Mode',
                value: settings.nightMode,
                labelStyle: labelStyle,
                colors: colors,
                onChanged: settings.setNightMode,
              ),
              _SettingsToggleRow(
                label: 'Show Cost',
                value: settings.showCost,
                labelStyle: labelStyle,
                colors: colors,
                onChanged: settings.setShowCost,
              ),
              _SettingsToggleRow(
                label: 'Show Calorie',
                value: settings.showCalorie,
                labelStyle: labelStyle,
                colors: colors,
                onChanged: settings.setShowCalorie,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final TextStyle labelStyle;
  final NomNomTheme colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: labelStyle),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.accent,
          activeTrackColor: colors.mint,
        ),
      ],
    );
  }
}
