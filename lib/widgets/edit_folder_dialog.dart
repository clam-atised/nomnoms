import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

Future<String?> showEditFolderDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => EditFolderDialog(initialName: initialName),
  );
}

class EditFolderDialog extends StatefulWidget {
  const EditFolderDialog({super.key, required this.initialName});

  final String initialName;

  @override
  State<EditFolderDialog> createState() => _EditFolderDialogState();
}

class _EditFolderDialogState extends State<EditFolderDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 20,
    );

    return AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit Folder Name',
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
      content: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.text, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: GoogleFonts.antic(color: colors.text),
            decoration: InputDecoration(
              hintText: 'Folder name...',
              hintStyle: GoogleFonts.antic(
                color: colors.text.withValues(alpha: 0.55),
              ),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _save,
          child: Text(
            'Save',
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
