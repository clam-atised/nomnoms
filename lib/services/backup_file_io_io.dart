import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveBackupZip({
  required Uint8List bytes,
  required String fileName,
}) async {
  final savedPath = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (savedPath != null) {
    return fileName;
  }

  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$fileName');
  await tempFile.writeAsBytes(bytes, flush: true);

  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    final downloadsFile = File('${downloadsDir.path}/$fileName');
    await downloadsFile.writeAsBytes(bytes, flush: true);
    return downloadsFile.path.split(Platform.pathSeparator).last;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(tempFile.path, mimeType: 'application/zip', name: fileName),
      ],
      subject: 'Nomnoms backup',
      text: 'Save this backup file to restore your recipes later.',
    ),
  );
  return fileName;
}

Future<List<int>?> pickBackupZip() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  try {
    return await file.readAsBytes();
  } on StateError {
    return null;
  }
}
