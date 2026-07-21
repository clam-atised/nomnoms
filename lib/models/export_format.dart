enum ExportFormat {
  pdf,
  markdown,
  word;

  String get label {
    return switch (this) {
      ExportFormat.pdf => 'PDF file',
      ExportFormat.markdown => 'Markdown file',
      ExportFormat.word => 'Word document',
    };
  }

  String get fileExtension {
    return switch (this) {
      ExportFormat.pdf => 'pdf',
      ExportFormat.markdown => 'md',
      ExportFormat.word => 'doc',
    };
  }

  static List<String> get labels =>
      ExportFormat.values.map((format) => format.label).toList();

  static ExportFormat? fromLabel(String label) {
    for (final format in ExportFormat.values) {
      if (format.label == label) {
        return format;
      }
    }
    return null;
  }
}
