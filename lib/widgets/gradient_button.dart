import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/theme/app_colors.dart';

/// Reusable button with a 135° gradient border and soft mint fill.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height,
    this.width,
  });

  final String label;
  final VoidCallback onPressed;
  final double? height;
  final double? width;

  static const double _radius = 24;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);

    return SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: colors.borderGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_borderWidth),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(_radius - _borderWidth),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius - _borderWidth),
                  gradient: colors.fillGradient,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.antic(
                      color: colors.text,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
