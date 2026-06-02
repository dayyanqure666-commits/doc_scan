import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_document.dart';
import '../models/scan_page.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<File> get _dbFile async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/documents.json');
  }

  // Helper to convert absolute path to relative for persistence
  Future<String> _toRelative(String? path) async {
    if (path == null || path.isEmpty) return '';
    final appDir = await getApplicationDocumentsDirectory();
    final base = appDir.path;
    final normalizedPath = path.replaceAll('\\', '/');
    final normalizedBase = base.replaceAll('\\', '/');
    if (normalizedPath.startsWith(normalizedBase)) {
      return normalizedPath.substring(normalizedBase.length);
    }
    return path;
  }

  // Helper to convert relative path back to absolute for runtime use
  Future<String> _toAbsolute(String? path) async {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('/') || path.contains(':/') || path.contains(':\\')) {
      return path;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final relativePath = path.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);
    final cleanRelative = relativePath.startsWith(Platform.pathSeparator) ? relativePath.substring(1) : relativePath;
    return join(appDir.path, cleanRelative);
  }

  // ── Documents ─────────────────────────────────────────────
  Future<void> saveDocument(ScanDocument doc) async {
    // 1. Ensure permanent directories exist
    final docDir = await getDocumentDir(doc.id);
    final originalDir = Directory('$docDir/original');
    final processedDir = Directory('$docDir/processed');
    final thumbnailsDir = Directory('$docDir/thumbnails');

    if (!originalDir.existsSync()) originalDir.createSync(recursive: true);
    if (!processedDir.existsSync()) processedDir.createSync(recursive: true);
    if (!thumbnailsDir.existsSync()) thumbnailsDir.createSync(recursive: true);

    // 2. Move/copy each page's images to permanent storage if not already there
    for (final ScanPage page in doc.pages) {
      // Copy original image
      if (page.originalImagePath.isNotEmpty && File(page.originalImagePath).existsSync()) {
        final targetOriginal = '${originalDir.path}/${page.id}_original.jpg';
        if (page.originalImagePath != targetOriginal) {
          final sourceFile = File(page.originalImagePath);
          await sourceFile.copy(targetOriginal);
          // Delete temporary cache file to free up device space
          if (page.originalImagePath.contains('cache') || page.originalImagePath.contains('tmp')) {
            try { await sourceFile.delete(); } catch (_) {}
          }
          page.originalImagePath = targetOriginal;
        }
      }

      // Copy processed image
      if (page.processedImagePath.isNotEmpty && File(page.processedImagePath).existsSync()) {
        final targetProcessed = '${processedDir.path}/${page.id}_processed.jpg';
        if (page.processedImagePath != targetProcessed) {
          final sourceFile = File(page.processedImagePath);
          await sourceFile.copy(targetProcessed);
          if (page.processedImagePath.contains('cache') || page.processedImagePath.contains('tmp')) {
            try { await sourceFile.delete(); } catch (_) {}
          }
          page.processedImagePath = targetProcessed;
        }
      }

      // Copy thumbnail image
      if (page.thumbnailPath != null && page.thumbnailPath!.isNotEmpty && File(page.thumbnailPath!).existsSync()) {
        final targetThumbnail = '${thumbnailsDir.path}/${page.id}_thumbnail.jpg';
        if (page.thumbnailPath != targetThumbnail) {
          final sourceFile = File(page.thumbnailPath!);
          await sourceFile.copy(targetThumbnail);
          if (page.thumbnailPath!.contains('cache') || page.thumbnailPath!.contains('tmp')) {
            try { await sourceFile.delete(); } catch (_) {}
          }
          page.thumbnailPath = targetThumbnail;
        }
      }
    }

    // Update document level thumbnail
    if (doc.pages.isNotEmpty) {
      doc.thumbnailPath = doc.pages.first.processedImagePath;
    }

    // 3. Save serialized metadata to JSON database
    final rawDocs = await _readAllDocsRaw();
    rawDocs.removeWhere((d) => d['id'] == doc.id);

    final docMap = doc.toMap();

    // Convert paths to relative
    docMap['thumbnail_path'] = await _toRelative(docMap['thumbnail_path']);
    docMap['pdf_path'] = await _toRelative(docMap['pdf_path']);
    if (docMap['pages'] != null) {
      for (final pageMap in docMap['pages']) {
        pageMap['original_path'] = await _toRelative(pageMap['original_path']);
        pageMap['processed_path'] = await _toRelative(pageMap['processed_path']);
        pageMap['thumbnail_path'] = await _toRelative(pageMap['thumbnail_path']);
      }
    }

    rawDocs.insert(0, docMap);
    await _writeAllDocsRaw(rawDocs);
  }

  Future<List<ScanDocument>> getAllDocuments() async {
    final rawDocs = await _readAllDocsRaw();
    final docs = <ScanDocument>[];
    for (final raw in rawDocs) {
      // Reconstruct absolute paths for runtime compatibility
      raw['thumbnail_path'] = await _toAbsolute(raw['thumbnail_path']);
      raw['pdf_path'] = await _toAbsolute(raw['pdf_path']);
      if (raw['pages'] != null) {
        for (final rawPage in raw['pages']) {
          rawPage['original_path'] = await _toAbsolute(rawPage['original_path']);
          rawPage['processed_path'] = await _toAbsolute(rawPage['processed_path']);
          rawPage['thumbnail_path'] = await _toAbsolute(rawPage['thumbnail_path']);
        }
      }
      docs.add(ScanDocument.fromMap(raw));
    }
    return docs;
  }

  Future<void> updateDocument(ScanDocument doc) async {
    doc.modifiedAt = DateTime.now();
    await saveDocument(doc);
  }

  Future<void> deleteDocument(String id) async {
    final rawDocs = await _readAllDocsRaw();
    final targetRaw = rawDocs.firstWhere((d) => d['id'] == id, orElse: () => null);
    if (targetRaw != null) {
      // 1. Remove from local list
      rawDocs.removeWhere((d) => d['id'] == id);
      await _writeAllDocsRaw(rawDocs);

      // 2. Delete physical document folder recursively
      final docDirPath = await getDocumentDir(id);
      final docDir = Directory(docDirPath);
      if (docDir.existsSync()) {
        await docDir.delete(recursive: true);
      }

      // 3. Delete PDF file if exists
      final pdfPath = await _toAbsolute(targetRaw['pdf_path'] as String?);
      if (pdfPath.isNotEmpty) {
        final pdfFile = File(pdfPath);
        if (pdfFile.existsSync()) {
          try { await pdfFile.delete(); } catch (_) {}
        }
      }
    }
  }

  // ── Settings ──────────────────────────────────────────────
  Future<void> saveSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // ── Paths ─────────────────────────────────────────────────
  Future<String> getDocumentDir(String docId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/documents/doc_$docId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<String> getPDFDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/pdfs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<int> getTotalStorageBytes() async {
    final appDir = await getApplicationDocumentsDirectory();
    int total = 0;
    final docsDir = Directory('${appDir.path}/documents');
    final pdfsDir = Directory('${appDir.path}/pdfs');
    for (final dir in [docsDir, pdfsDir]) {
      if (dir.existsSync()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      }
    }
    return total;
  }

  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      try {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      } catch (_) {}
    }
  }

  // ── Internal Helpers ──────────────────────────────────────
  Future<List<dynamic>> _readAllDocsRaw() async {
    try {
      final file = await _dbFile;
      if (!file.existsSync()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      return jsonDecode(content) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeAllDocsRaw(List<dynamic> list) async {
    final file = await _dbFile;
    await file.writeAsString(jsonEncode(list));
  }
}
