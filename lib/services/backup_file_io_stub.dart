Future<String?> saveBackupZip({
  required List<int> bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Backup is not supported on this platform.');
}

Future<List<int>?> pickBackupZip() async {
  throw UnsupportedError('Backup is not supported on this platform.');
}
