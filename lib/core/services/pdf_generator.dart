import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/scan_document.dart';
import '../models/scan_page.dart';
import 'app_state.dart';

class PDFGenerator {
  static final PDFGenerator _instance = PDFGenerator._internal();
  factory PDFGenerator() => _instance;
  PDFGenerator._internal();
 Future<String> generate(
  ScanDocument document,
  ExportQuality quality,
  PdfPageFormat pageFormat, {
  void Function(int current, int total)? onProgress,
  AppSettings? appSettings,
}) async {

  // MAIN ISOLATE ONLY
  final appDir = await getApplicationDocumentsDirectory();

  final pdfDir = Directory('${appDir.path}/pdfs');

  if (!pdfDir.existsSync()) {
    pdfDir.createSync(recursive: true);
  }

  final safeFileName = document.name
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');

  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final outputPath =
      '${pdfDir.path}/${safeFileName}_$timestamp.pdf';

  return await compute(
    _generateInIsolate,
    _PDFArgs(
      documentName: document.name,
      pages: document.pages,
      quality: quality,
      pageFormat: pageFormat,
      outputPath: outputPath,
      appSettings: appSettings,
    ),
  );
}
  

  static Future<String> _generateInIsolate(_PDFArgs args) async {
    final pdf = pw.Document(compress: true, version: PdfVersion.pdf_1_5);

    final useOriginal = args.appSettings != null && !args.appSettings!.hasAnyPreprocessingEnabled;

    for (int i = 0; i < args.pages.length; i++) {
      final page = args.pages[i];
       debugPrint('====================');
       debugPrint('EXPORT PAGE ${i + 1}');
       debugPrint('ORIGINAL : ${page.originalImagePath}');
       debugPrint('PROCESSED: ${page.processedImagePath}');
       debugPrint('====================');
      final imagePath = useOriginal ? page.originalImagePath : page.processedImagePath;
      final file = File(imagePath);
      if (!file.existsSync()) {
       debugPrint('FILE NOT FOUND: $imagePath');
       continue;
       }

      final imageBytes = await file.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: args.pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              // Full-page image
              pw.Positioned.fill(
                child: pw.Image(
                  pdfImage,
                  fit: pw.BoxFit.contain,
                ),
              ),
              // Page number watermark (bottom right)
              pw.Positioned(
                bottom: 8,
                right: 8,
                child: pw.Text(
                  'Page ${i + 1} of ${args.pages.length}',
                  style:const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Save to pdfs directory
    final filePath = args.outputPath;
    final pdfBytes = await pdf.save();
    await File(filePath).writeAsBytes(pdfBytes);

    return filePath;
  }

  static PdfPageFormat getPageFormat(String format) {
    return switch (format.toLowerCase()) {
      'letter' => PdfPageFormat.letter,
      'a3'     => PdfPageFormat.a3,
      'legal'  => PdfPageFormat.legal,
      _        => PdfPageFormat.a4,
    };
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static int estimatePDFSize(List<ScanPage> pages, ExportQuality quality) {
    const baseBytesPerPage = {
      ExportQuality.draft:    150000,
      ExportQuality.standard: 400000,
      ExportQuality.high:     800000,
      ExportQuality.archival: 2000000,
    };
    return pages.length * (baseBytesPerPage[quality] ?? 400000);
  }
}

class _PDFArgs {
  final String documentName;
  final List<ScanPage> pages;
  final ExportQuality quality;
  final PdfPageFormat pageFormat;
  final String outputPath;
  final AppSettings? appSettings;
  const _PDFArgs({
    required this.documentName,
    required this.pages,
    required this.quality,
    required this.pageFormat,
    required this.outputPath,
    this.appSettings,
  });
}
