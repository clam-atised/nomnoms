import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

class AddFolderResult {
  const AddFolderResult({required this.name, required this.color});

  final String name;
  final Color color;
}

Future<AddFolderResult?> showAddFolderDialog(BuildContext context) {
  return showDialog<AddFolderResult>(
    context: context,
    builder: (context) => const AddFolderDialog(),
  );
}

class AddFolderDialog extends StatefulWidget {
  const AddFolderDialog({super.key});

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final _nameController = TextEditingController();
  Color? _selectedColor;
  bool _showColorPicker = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      AddFolderResult(
        name: name,
        color: _selectedColor ?? nomnomTheme(context).text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final selectedColor = _selectedColor ?? colors.text;
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 20,
    );

    return AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add New Recipe Folder',
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.text, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _showColorPicker = !_showColorPicker);
                      },
                      child: CustomPaint(
                        size: const Size(28, 22),
                        painter: _SmallFolderPainter(color: selectedColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.antic(color: colors.text),
                        decoration: InputDecoration(
                          hintText: 'Folder name...',
                          hintStyle: GoogleFonts.antic(
                            color: colors.text.withValues(alpha: 0.55),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showColorPicker) ...[
              const SizedBox(height: 16),
              HueRingPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) {
                  setState(() => _selectedColor = color);
                },
                enableAlpha: false,
                displayThumbColor: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Selected color and its material shades',
                style: GoogleFonts.antic(
                  color: colors.text.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              MaterialPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) {
                  setState(() => _selectedColor = color);
                },
                enableLabel: false,
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _create,
          child: Text(
            'Create',
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

class _SmallFolderPainter extends CustomPainter {
  _SmallFolderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final tabWidth = size.width * 0.4;
    final tabHeight = size.height * 0.18;
    final bodyTop = tabHeight * 0.7;

    final path = Path()
      ..moveTo(0, bodyTop)
      ..lineTo(0, tabHeight)
      ..lineTo(tabWidth * 0.15, 0)
      ..lineTo(tabWidth, 0)
      ..lineTo(tabWidth + tabHeight * 0.3, bodyTop)
      ..lineTo(size.width, bodyTop)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmallFolderPainter oldDelegate) =>
      oldDelegate.color != color;
}
