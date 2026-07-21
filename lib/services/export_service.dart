import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/export_format.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  Future<void> exportAllRecipes({
    required RecipeStore store,
    required ExportFormat format,
  }) async {
    final groups = _groupRecipesByFolder(store);
    final fileName = 'nomnoms_recipes.${format.fileExtension}';
    final bytes = await _buildBytes(groups: groups, format: format);
    await _shareBytes(bytes: bytes, fileName: fileName, format: format);
  }

  @visibleForTesting
  String buildMarkdown(RecipeStore store) {
    return _buildMarkdown(_groupRecipesByFolder(store));
  }

  @visibleForTesting
  List<({RecipeFolder folder, List<Recipe> recipes})> groupRecipesByFolder(
    RecipeStore store,
  ) {
    return _groupRecipesByFolder(store);
  }

  List<({RecipeFolder folder, List<Recipe> recipes})> _groupRecipesByFolder(
    RecipeStore store,
  ) {
    final groups = <({RecipeFolder folder, List<Recipe> recipes})>[];

    for (final folder in store.assignableFolders) {
      final recipes = store.recipesInFolder(folder.id);
      groups.add((folder: folder, recipes: recipes));
    }

    final knownFolderIds = store.assignableFolders.map((f) => f.id).toSet();
    final unfiled = store.allRecipes
        .where((r) => !knownFolderIds.contains(r.folderId))
        .toList();
    if (unfiled.isNotEmpty) {
      groups.add((
        folder: const RecipeFolder(
          id: RecipeStore.recentFolderId,
          name: 'Recent recipes',
          color: Color(0xFF3D6F3D),
        ),
        recipes: unfiled,
      ));
    }

    return groups;
  }

  Future<List<int>> _buildBytes({
    required List<({RecipeFolder folder, List<Recipe> recipes})> groups,
    required ExportFormat format,
  }) {
    return switch (format) {
      ExportFormat.pdf => _buildPdfBytes(groups),
      ExportFormat.markdown => Future.value(utf8.encode(_buildMarkdown(groups))),
      ExportFormat.word => Future.value(utf8.encode(_buildRtf(groups))),
    };
  }

  Future<List<int>> _buildPdfBytes(
    List<({RecipeFolder folder, List<Recipe> recipes})> groups,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'Nomnoms Recipes',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
          ];

          if (groups.isEmpty) {
            widgets.add(pw.Text('No recipes to export.'));
            return widgets;
          }

          for (final group in groups) {
            widgets.add(
              pw.Text(
                group.folder.name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            if (group.recipes.isEmpty) {
              widgets.add(pw.Text('No recipes in this folder.'));
              widgets.add(pw.SizedBox(height: 16));
              continue;
            }

            for (final recipe in group.recipes) {
              widgets.addAll(_recipePdfWidgets(recipe));
            }
            widgets.add(pw.SizedBox(height: 12));
          }

          return widgets;
        },
      ),
    );
    return document.save();
  }

  List<pw.Widget> _recipePdfWidgets(Recipe recipe) {
    final widgets = <pw.Widget>[
      pw.Text(
        recipe.name,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text('Prep time: ${recipe.preparationMinutes} minutes'),
    ];

    if (recipe.timesOfDay.isNotEmpty) {
      widgets.add(
        pw.Text(
          'Times of day: ${recipe.timesOfDay.map((e) => e.label).join(', ')}',
        ),
      );
    }
    if (recipe.daysOfWeek.isNotEmpty) {
      widgets.add(
        pw.Text(
          'Days: ${recipe.daysOfWeek.map((e) => e.label).join(', ')}',
        ),
      );
    }
    if (recipe.link.trim().isNotEmpty) {
      widgets.add(pw.Text('Link: ${recipe.link}'));
    }

    widgets.add(pw.SizedBox(height: 4));
    widgets.add(pw.Text('Ingredients:'));
    for (final ingredient in recipe.ingredients) {
      widgets.add(pw.Bullet(text: ingredient.label));
    }

    if (recipe.instructions.trim().isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.Text('Instructions:'));
      widgets.add(pw.Text(recipe.instructions));
    }

    widgets.add(pw.SizedBox(height: 12));
    return widgets;
  }

  String _buildMarkdown(
    List<({RecipeFolder folder, List<Recipe> recipes})> groups,
  ) {
    final buffer = StringBuffer('# Nomnoms Recipes\n\n');
    if (groups.isEmpty) {
      buffer.writeln('No recipes to export.');
      return buffer.toString();
    }

    for (final group in groups) {
      buffer.writeln('# ${group.folder.name}\n');
      if (group.recipes.isEmpty) {
        buffer.writeln('No recipes in this folder.\n');
        continue;
      }
      for (final recipe in group.recipes) {
        buffer.writeln('## ${recipe.name}\n');
        buffer.writeln('- Prep time: ${recipe.preparationMinutes} minutes');
        if (recipe.timesOfDay.isNotEmpty) {
          buffer.writeln(
            '- Times of day: ${recipe.timesOfDay.map((e) => e.label).join(', ')}',
          );
        }
        if (recipe.daysOfWeek.isNotEmpty) {
          buffer.writeln(
            '- Days: ${recipe.daysOfWeek.map((e) => e.label).join(', ')}',
          );
        }
        if (recipe.link.trim().isNotEmpty) {
          buffer.writeln('- Link: ${recipe.link}');
        }
        buffer.writeln('\n### Ingredients\n');
        for (final ingredient in recipe.ingredients) {
          buffer.writeln('- ${ingredient.label}');
        }
        if (recipe.instructions.trim().isNotEmpty) {
          buffer.writeln('\n### Instructions\n');
          buffer.writeln(recipe.instructions);
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  String _buildRtf(
    List<({RecipeFolder folder, List<Recipe> recipes})> groups,
  ) {
    final buffer = StringBuffer(r'{\rtf1\ansi ');
    buffer.write(r'{\b Nomnoms Recipes}\par\par ');

    if (groups.isEmpty) {
      buffer.write(r'No recipes to export.\par ');
      buffer.write('}');
      return buffer.toString();
    }

    for (final group in groups) {
      buffer.write(r'{\b ');
      buffer.write(_escapeRtf(group.folder.name));
      buffer.write(r'}\par ');

      if (group.recipes.isEmpty) {
        buffer.write(r'No recipes in this folder.\par\par ');
        continue;
      }

      for (final recipe in group.recipes) {
        buffer.write(r'{\b ');
        buffer.write(_escapeRtf(recipe.name));
        buffer.write(r'}\par ');
        buffer.write(
          'Prep time: ${recipe.preparationMinutes} minutes',
        );
        buffer.write(r'\par ');

        if (recipe.timesOfDay.isNotEmpty) {
          buffer.write(
            'Times of day: ${recipe.timesOfDay.map((e) => e.label).join(', ')}',
          );
          buffer.write(r'\par ');
        }
        if (recipe.daysOfWeek.isNotEmpty) {
          buffer.write(
            'Days: ${recipe.daysOfWeek.map((e) => e.label).join(', ')}',
          );
          buffer.write(r'\par ');
        }
        if (recipe.link.trim().isNotEmpty) {
          buffer.write('Link: ${_escapeRtf(recipe.link)}');
          buffer.write(r'\par ');
        }

        buffer.write(r'Ingredients:\par ');
        for (final ingredient in recipe.ingredients) {
          buffer.write(r'\bullet ');
          buffer.write(_escapeRtf(ingredient.label));
          buffer.write(r'\par ');
        }

        if (recipe.instructions.trim().isNotEmpty) {
          buffer.write(r'Instructions:\par ');
          buffer.write(_escapeRtf(recipe.instructions));
          buffer.write(r'\par ');
        }
        buffer.write(r'\par ');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  String _escapeRtf(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}');
  }

  Future<void> _shareBytes({
    required List<int> bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: _mimeType(format),
          ),
        ],
        subject: fileName,
      ),
    );
  }

  String _mimeType(ExportFormat format) {
    return switch (format) {
      ExportFormat.pdf => 'application/pdf',
      ExportFormat.markdown => 'text/markdown',
      ExportFormat.word => 'application/msword',
    };
  }
}
