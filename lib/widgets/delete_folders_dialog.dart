import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

Future<bool> showDeleteFoldersDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const DeleteFoldersDialog(),
  );
  return result ?? false;
}

class DeleteFoldersDialog extends StatelessWidget {
  const DeleteFoldersDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final textStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 18,
    );

    return AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(
        'Delete forever?',
        textAlign: TextAlign.center,
        style: textStyle,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'No',
            style: GoogleFonts.antic(
              color: colors.text,
              fontSize: 18,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Yes',
            style: GoogleFonts.antic(
              color: colors.text,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
