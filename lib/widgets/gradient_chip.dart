import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

/// Pill chip with the shared 135° gradient border/fill.
/// When [onDismiss] is null, the close control is hidden (display-only).
class GradientChip extends StatelessWidget {
  const GradientChip({
    super.key,
    required this.label,
    this.onDismiss,
  });

  final String label;
  final VoidCallback? onDismiss;

  static const double _radius = 100;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: colors.borderGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_borderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius - _borderWidth),
            gradient: colors.fillGradient,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, onDismiss != null ? 8 : 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.antic(
                      color: colors.text,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: colors.closeButtonBackground,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDismiss,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: colors.closeButtonIcon,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
