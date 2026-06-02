// lib/core/models/pdf_export_settings.dart

enum ExportQuality { draft, standard, high, archival }
enum PageSize { a4, letter, legal, auto }

class PdfExportSettings {
  final ExportQuality quality;
  final PageSize pageSize;
  final bool compress;

  const PdfExportSettings({
    this.quality = ExportQuality.standard,
    this.pageSize = PageSize.a4,
    this.compress = true,
  });

  int get jpegQuality => switch (quality) {
    ExportQuality.draft    => 60,
    ExportQuality.standard => 80,
    ExportQuality.high     => 90,
    ExportQuality.archival => 100,
  };

  int get dpi => switch (quality) {
    ExportQuality.draft    => 150,
    ExportQuality.standard => 200,
    ExportQuality.high     => 300,
    ExportQuality.archival => 600,
  };

  String get qualityLabel => switch (quality) {
    ExportQuality.draft    => 'Draft',
    ExportQuality.standard => 'Standard',
    ExportQuality.high     => 'High',
    ExportQuality.archival => 'Archival',
  };

  String get qualityDescription => switch (quality) {
    ExportQuality.draft    => 'Smaller file, faster export',
    ExportQuality.standard => 'Balanced quality & size',
    ExportQuality.high     => 'Best for professional use',
    ExportQuality.archival => 'Maximum quality, larger file',
  };
}
