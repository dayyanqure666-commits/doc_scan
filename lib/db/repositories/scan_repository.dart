import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename;
import 'package:sqflite/sqflite.dart';
import '../../core/models/scan_document.dart';
import '../../core/models/scan_page.dart';
import '../app_database.dart';
import '../tables/scan_table.dart';

class ScanRepository {
  final AppDatabase _appDatabase = AppDatabase();

  Future<int> insertScan(ScanDocument document) async {
    try {
      final db = await _appDatabase.database;

      final imagePath = document.pages.isNotEmpty
          ? document.pages.first.processedImagePath
          : '';
      final pdfPath = document.pdfPath ?? '';
      final createdAt = document.createdAt.toIso8601String();
      final filterType = document.pages.isNotEmpty
          ? document.pages.first.settings.mode.name
          : 'auto';
      final metaJson = jsonEncode(document.toMap());

      return await db.insert(
        ScanTable.tableName,
        {
          ScanTable.colImagePath: imagePath,
          ScanTable.colPdfPath: pdfPath,
          ScanTable.colCreatedAt: createdAt,
          ScanTable.colFilterType: filterType,
          ScanTable.colMetaJson: metaJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('SQLite insertScan error: $e');
      rethrow;
    }
  }

  Future<List<ScanDocument>> getAllScans() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        ScanTable.tableName,
        orderBy: '${ScanTable.colCreatedAt} DESC',
      );

      final List<ScanDocument> scans = [];
      for (final map in maps) {
        final metaJsonStr = map[ScanTable.colMetaJson] as String?;
        if (metaJsonStr != null && metaJsonStr.isNotEmpty) {
          try {
            final docMap = jsonDecode(metaJsonStr);
            docMap['id'] = map[ScanTable.colId].toString();
            docMap['pdf_path'] = map[ScanTable.colPdfPath];
            docMap['thumbnail_path'] = map[ScanTable.colImagePath];
            scans.add(ScanDocument.fromMap(docMap));
            continue;
          } catch (_) {
            // If decoding fails, fall back to manual reconstruction below
          }
        }

        // Manual fallback reconstruction
        final id = map[ScanTable.colId].toString();
        final createdAt =
            DateTime.tryParse(map[ScanTable.colCreatedAt] as String) ??
                DateTime.now();
        final imagePath = map[ScanTable.colImagePath] as String;
        final pdfPath = map[ScanTable.colPdfPath] as String?;

        scans.add(
          ScanDocument(
            id: id,
            name: pdfPath != null && pdfPath.isNotEmpty
                ? basename(pdfPath)
                : 'Scan $id',
            createdAt: createdAt,
            modifiedAt: createdAt,
            pages: [
              ScanPage(
                id: '${id}_page_0',
                documentId: id,
                originalImagePath: imagePath,
                processedImagePath: imagePath,
                thumbnailPath: imagePath,
                capturedAt: createdAt,
                pageOrder: 0,
              )
            ],
            thumbnailPath: imagePath,
            pdfPath: pdfPath,
          ),
        );
      }
      return scans;
    } catch (e) {
      debugPrint('SQLite getAllScans error: $e');
      return [];
    }
  }

  Future<int> deleteScan(dynamic id) async {
    try {
      final db = await _appDatabase.database;
      final intId = id is int ? id : int.tryParse(id.toString());
      if (intId == null) return 0;

      return await db.delete(
        ScanTable.tableName,
        where: '${ScanTable.colId} = ?',
        whereArgs: [intId],
      );
    } catch (e) {
      debugPrint('SQLite deleteScan error: $e');
      rethrow;
    }
  }
}
