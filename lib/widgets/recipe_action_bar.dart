import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

class RecipeActionBar extends StatelessWidget {
  const RecipeActionBar({
    super.key,
    required this.onDelete,
    required this.onMove,
    this.enabled = true,
  });

  final VoidCallback onDelete;
  final VoidCallback onMove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final style = GoogleFonts.antic(color: colors.text, fontSize: 16);

    return Material(
      color: colors.background,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: enabled ? onDelete : null,
                  icon: Icon(Icons.delete, color: colors.text),
                  label: Text('Delete', style: style),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: enabled ? onMove : null,
                  icon: Icon(Icons.drive_file_move, color: colors.text),
                  label: Text('Move to folder', style: style),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
