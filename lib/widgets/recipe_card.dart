import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/gradient_chip.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final Recipe recipe;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final colors = nomnomTheme(context);
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 16,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colors.text.withValues(alpha: 0.08)
                : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.text,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contains:', style: labelStyle),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListenableBuilder(
                          listenable: settings,
                          builder: (context, _) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: recipe.ingredients
                                  .map(
                                    (i) => GradientChip(
                                      label: i.displayLabel(
                                        settings.measurementSystem,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preparation Time: ${recipe.preparationMinutes} minutes',
                    style: labelStyle,
                  ),
                  if (recipe.timesOfDay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Time of Day: ${recipe.timesOfDay.map((t) => t.label).join(', ')}',
                      style: labelStyle,
                    ),
                  ],
                  if (recipe.daysOfWeek.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Day of Week: ${recipe.daysOfWeek.map((d) => d.label).join(', ')}',
                      style: labelStyle,
                    ),
                  ],
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: colors.text,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
