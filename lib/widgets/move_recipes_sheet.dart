import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/theme/app_colors.dart';

Future<String?> showMoveRecipesSheet(
  BuildContext context, {
  required List<RecipeFolder> folders,
}) {
  if (folders.isEmpty) return Future.value(null);

  final colors = nomnomTheme(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: colors.background,
    builder: (context) {
      final sheetColors = nomnomTheme(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Move to folder',
                style: GoogleFonts.antic(
                  color: sheetColors.text,
                  fontSize: 18,
                ),
              ),
            ),
            ...folders.map(
              (folder) => ListTile(
                leading: Icon(Icons.folder, color: folder.color),
                title: Text(
                  folder.name,
                  style: GoogleFonts.antic(color: sheetColors.text),
                ),
                onTap: () => Navigator.of(context).pop(folder.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
