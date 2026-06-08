class ScanTable {
  static const String tableName = 'scans';

  static const String colId = 'id';
  static const String colImagePath = 'imagePath';
  static const String colPdfPath = 'pdfPath';
  static const String colCreatedAt = 'createdAt';
  static const String colFilterType = 'filterType';
  static const String colMetaJson = 'metaJson';

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colImagePath TEXT NOT NULL,
      $colPdfPath TEXT NOT NULL,
      $colCreatedAt TEXT NOT NULL,
      $colFilterType TEXT NOT NULL,
      $colMetaJson TEXT
    )
  ''';
}
