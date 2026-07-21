import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/export_format.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/services/backup_service.dart';
import 'package:nomnom/services/export_service.dart';
import 'package:nomnom/theme/app_colors.dart';

const Color _kDeleteColor = Color(0xFFC62828);
const Color _kBackupColor = Color(0xFF7CB87C);

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
    final store = RecipeStoreScope.of(context);
    final colors = nomnomTheme(context);
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 20,
    );
    final labelStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 16,
    );
    final sectionStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Settings',
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, store]),
          builder: (context, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  _SettingsToggleRow(
                    label: 'Show Protein',
                    value: settings.showProtein,
                    labelStyle: labelStyle,
                    colors: colors,
                    onChanged: settings.setShowProtein,
                  ),
                  _SettingsToggleRow(
                    label: 'Custom measuring system',
                    value:
                        settings.measurementSystem == MeasurementSystem.custom,
                    labelStyle: labelStyle,
                    colors: colors,
                    onChanged: settings.setCustomMeasuringSystem,
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 12),
                    Text('Data', style: sectionStyle),
                    const SizedBox(height: 4),
                    _SettingsActionRow(
                      label: 'Backup all recipes',
                      labelStyle: labelStyle,
                      onTap: () => _onBackupAll(context, store, settings),
                    ),
                    _SettingsActionRow(
                      label: 'Load data',
                      labelStyle: labelStyle,
                      onTap: () => _onLoadData(context, store, settings),
                    ),
                    if (store.hasUserData) ...[
                      _SettingsActionRow(
                        label: 'Delete all data',
                        labelStyle: labelStyle.copyWith(color: _kDeleteColor),
                        onTap: () => _onDeleteAll(context, store),
                      ),
                      _SettingsActionRow(
                        label: 'Export all data',
                        labelStyle: labelStyle,
                        onTap: () => _onExportAll(context, store),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Future<void> _onBackupAll(
    BuildContext context,
    RecipeStore store,
    AppSettings settings,
  ) async {
    final colors = nomnomTheme(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.background,
        title: Text(
          'Backup all recipes?',
          style: GoogleFonts.antic(color: colors.text),
        ),
        content: Text(
          'This will create a backup zip of all folders, recipes, ingredient values, and settings so you can restore them later.',
          style: GoogleFonts.antic(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.antic(color: colors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Backup',
              style: GoogleFonts.antic(color: _kBackupColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final fileName = await BackupService.exportBackup(
        store: store,
        settings: settings,
      );
      if (!context.mounted) return;
      if (fileName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved: $fileName')),
        );
      }
    } on BackupException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create backup')),
      );
    }
  }

  static Future<void> _onLoadData(
    BuildContext context,
    RecipeStore store,
    AppSettings settings,
  ) async {
    final colors = nomnomTheme(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.background,
        title: Text(
          'Load data?',
          style: GoogleFonts.antic(color: colors.text),
        ),
        content: Text(
          'This will replace all folders, recipes, ingredient values, and settings with the backup file. This cannot be undone.',
          style: GoogleFonts.antic(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.antic(color: colors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Load', style: GoogleFonts.antic(color: colors.text)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final backup = await BackupService.pickAndImportBackup();
      if (backup == null || !context.mounted) return;

      await BackupService.applyBackup(
        backup: backup,
        store: store,
        settings: settings,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data loaded')),
      );
      Navigator.of(context).pop();
    } on BackupException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data')),
      );
    }
  }

  static Future<void> _onDeleteAll(
    BuildContext context,
    RecipeStore store,
  ) async {
    final colors = nomnomTheme(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.background,
        title: Text(
          'Delete all data?',
          style: GoogleFonts.antic(color: colors.text),
        ),
        content: Text(
          'This will remove all folders, recipes, and ingredient values. Settings will be kept. This cannot be undone.',
          style: GoogleFonts.antic(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.antic(color: colors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.antic(color: _kDeleteColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await store.clearAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data deleted')),
    );
    Navigator.of(context).pop();
  }

  static Future<void> _onExportAll(
    BuildContext context,
    RecipeStore store,
  ) async {
    final colors = nomnomTheme(context);
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.background,
        title: Text(
          'Export all data',
          style: GoogleFonts.antic(color: colors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ExportFormat.values)
              ListTile(
                title: Text(
                  option.label,
                  style: GoogleFonts.antic(color: colors.text, fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.antic(color: colors.text)),
          ),
        ],
      ),
    );
    if (format == null || !context.mounted) return;

    try {
      await ExportService.instance.exportAllRecipes(
        store: store,
        format: format,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export data')),
      );
    }
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

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.label,
    required this.labelStyle,
    required this.onTap,
  });

  final String label;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: labelStyle),
      ),
    );
  }
}
