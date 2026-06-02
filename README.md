# DocScan — Production Document Scanner App

A production-quality Flutter document scanner app that captures, enhances,
and exports OCR-ready PDFs. Built as a FlutterFlow-compatible Flutter project.

---

## Project Structure

```
lib/
  core/
    models/          → ScanDocument, ScanPage, EnhancementSettings
    services/        → StorageService, ImageProcessor, PDFGenerator, AppState
  features/
    onboarding/      → 3-screen first-launch flow
    home/            → Dashboard with recent scans
    scanner/         → Camera capture screen
    preview/         → Page editing, rotation, reorder
    export/          → PDF generation and sharing
    history/         → Search, sort, manage all scans
    settings/        → App preferences
  shared/
    theme/           → Light/dark theme, colors, typography
    widgets/         → Reusable UI components
```

## Key Technical Notes

- Image processing runs in a background Isolate via `compute()` — no UI jank
- Adaptive thresholding uses summed area tables (O(n) not O(n·blockSize²))
- Shadow removal via background illumination normalization
- PDF generation uses dart `pdf` package with selectable compression
- SQLite (sqflite) stores metadata; files stored in app documents directory
- Supports ML Kit Document Scanner (replace ImagePicker in scanner_screen.dart)

## Upgrade: Enable ML Kit Document Scanner

In `scanner_screen.dart`, replace the `_startScan()` method:

```dart
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

Future<void> _startScan() async {
  final scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      isGalleryImport: true,
      pageLimit: 20,
    ),
  );
  final result = await scanner.scanDocument();
  await _processImages(result.images);
  scanner.close();
}
```

This provides automatic edge detection, perspective correction, and cropping.
