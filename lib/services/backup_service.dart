import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/backup_data.dart';
import 'package:nomnom/services/backup_file_io.dart';

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupService {
  static String _backupFileName() {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'nomnoms_backup_$timestamp.zip';
  }

  static BackupData buildBackup({
    required RecipeStore store,
    required AppSettings settings,
  }) {
    return BackupData(
      nextRecipeId: store.nextRecipeIdCounter,
      nextFolderId: store.nextFolderIdCounter,
      folders: store.assignableFolders
          .map(BackupFolderData.fromFolder)
          .toList(),
      recipes: store.allRecipes.map(BackupRecipeData.fromRecipe).toList(),
      ingredientCosts: Map.of(store.ingredientCosts),
      ingredientCalories: Map.of(store.ingredientCalories),
      ingredientProteins: Map.of(store.ingredientProteins),
      settings: BackupSettingsData.fromAppSettings(settings),
    );
  }

  static Future<String?> exportBackup({
    required RecipeStore store,
    required AppSettings settings,
  }) async {
    final backup = buildBackup(store: store, settings: settings);

    final archive = Archive();
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(backup.toJson()),
    );
    archive.addFile(
      ArchiveFile(BackupData.backupJsonName, jsonBytes.length, jsonBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);

    return saveBackupZip(
      bytes: Uint8List.fromList(zipBytes),
      fileName: _backupFileName(),
    );
  }

  static BackupData importBackupBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final jsonFile = archive.findFile(BackupData.backupJsonName);
    if (jsonFile == null) {
      throw BackupException('Invalid backup: missing backup.json.');
    }

    try {
      return BackupData.fromJson(
        jsonDecode(utf8.decode(jsonFile.content)) as Map<String, dynamic>,
      );
    } on FormatException catch (e) {
      throw BackupException(e.message);
    } catch (_) {
      throw BackupException('Invalid backup: could not read backup.json.');
    }
  }

  static Future<BackupData?> pickAndImportBackup() async {
    final bytes = await pickBackupZip();
    if (bytes == null) return null;
    return importBackupBytes(bytes);
  }

  static Future<void> applyBackup({
    required BackupData backup,
    required RecipeStore store,
    required AppSettings settings,
  }) async {
    await store.replaceFromBackup(
      folders: backup.folders.map((f) => f.toFolder()).toList(),
      recipes: backup.recipes.map((r) => r.toRecipe()).toList(),
      ingredientCosts: backup.ingredientCosts,
      ingredientCalories: backup.ingredientCalories,
      ingredientProteins: backup.ingredientProteins,
      nextRecipeId: backup.nextRecipeId,
      nextFolderId: backup.nextFolderId,
    );
    backup.settings?.applyTo(settings);
  }
}
