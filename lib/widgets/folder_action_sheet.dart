import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

enum FolderAction { edit, delete }

Future<FolderAction?> showFolderActionSheet(BuildContext context) {
  final colors = nomnomTheme(context);
  return showModalBottomSheet<FolderAction>(
    context: context,
    backgroundColor: colors.background,
    builder: (context) {
      final sheetColors = nomnomTheme(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: sheetColors.text),
              title: Text(
                'Edit folder name',
                style: GoogleFonts.antic(color: sheetColors.text),
              ),
              onTap: () => Navigator.of(context).pop(FolderAction.edit),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: sheetColors.text),
              title: Text(
                'Delete folder',
                style: GoogleFonts.antic(color: sheetColors.text),
              ),
              onTap: () => Navigator.of(context).pop(FolderAction.delete),
            ),
          ],
        ),
      );
    },
  );
}
