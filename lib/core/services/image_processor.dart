import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/scan_document.dart';
import '../models/scan_page.dart';
import 'app_state.dart';
import '../../features/crop/perspective_transform_service.dart';

class ImageProcessor {
  static final ImageProcessor _instance = ImageProcessor._internal();
  factory ImageProcessor() => _instance;
  ImageProcessor._internal();

  /// Main entry point — runs in a background isolate to prevent UI jank
  Future<String> processImage(
    String inputPath,
    EnhancementSettings settings,
    String outputPath, {
    AppSettings? appSettings,
    List<CropPoint>? cropPoints,
    int rotation = 0,
    bool isManualEdit = false,
  }) async {
    return await compute(
      _processInIsolate,
      _ProcessArgs(
        inputPath: inputPath,
        settings: settings,
        outputPath: outputPath,
        appSettings: appSettings,
        cropPoints: cropPoints,
        rotation: rotation,
        isManualEdit: isManualEdit,
      ),
    );
  }

  Future<String> processPage(
    ScanPage page, {
    AppSettings? appSettings,
  }) async {
    final processedPath = await getProcessedPath(page.documentId, page.id);
    await processImage(
      page.originalImagePath,
      page.settings,
      processedPath,
      appSettings: appSettings,
      cropPoints: page.cropPoints,
      rotation: page.rotation,
      isManualEdit: true,
    );
    final thumbnailPath = await getThumbnailPath(page.documentId, page.id);
    await generateThumbnail(processedPath, thumbnailPath);
    return processedPath;
  }

  static Future<String> _processInIsolate(_ProcessArgs args) async {
    Uint8List bytes = await File(args.inputPath).readAsBytes();
    
    final appSet = args.appSettings;
    // If all preprocessing options are disabled, copy original bytes directly and bypass everything
    if (!args.isManualEdit && appSet != null && !appSet.hasAnyPreprocessingEnabled) {
      await File(args.outputPath).writeAsBytes(bytes);
      return args.outputPath;
    }

    // Apply crop (Perspective Transform) if cropPoints is provided and not empty
    if (args.cropPoints != null && args.cropPoints!.isNotEmpty) {
      final srcPoints = args.cropPoints!.map((p) => Point<double>(p.x, p.y)).toList();
      final isDefault = srcPoints.length == 4 &&
          srcPoints[0].x == 0.0 && srcPoints[0].y == 0.0 &&
          srcPoints[1].x == 1.0 && srcPoints[1].y == 0.0 &&
          srcPoints[2].x == 1.0 && srcPoints[2].y == 1.0 &&
          srcPoints[3].x == 0.0 && srcPoints[3].y == 1.0;
      if (!isDefault) {
        bytes = PerspectiveTransformService.transform(
          imageBytes: bytes,
          srcPoints: srcPoints,
        );
      }
    }

    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: ${args.inputPath}');

    // Apply rotation if rotation is not 0
    if (args.rotation != 0) {
      image = img.copyRotate(image, angle: args.rotation);
    }

    // Step 1: Resize to 2MP max for processing speed (save memory)
    // Keeps enough resolution for OCR (200+ DPI equivalent)
    image = _resizeForProcessing(image);

    // Step 2: Grayscale (document and whiteboard modes)
    if ((args.settings.mode == EnhancementMode.document ||
        args.settings.mode == EnhancementMode.grayscale ||
        args.settings.mode == EnhancementMode.whiteboard) &&
        (appSet == null || appSet.enableGrayscale)) {
      image = img.grayscale(image);
    }

    // Step 3: Shadow removal via background normalization
    if (args.settings.shadowRemoval && (appSet == null || appSet.enableBackgroundCleanup)) {
      image = _removeShadows(image);
    }

    // Step 4: Adaptive thresholding (binarization for text clarity)
    if (appSet == null || appSet.enableThresholding) {
      if (args.settings.threshold == ThresholdMode.adaptive) {
        image = _adaptiveThreshold(image, blockSize: 21, C: 8);
      } else if (args.settings.threshold == ThresholdMode.otsu) {
        final t = _otsuThreshold(image);
        image = _applyThreshold(image, t);
      }
    }

    // Step 5: Contrast enhancement
    if (args.settings.contrast != 1.0 && (appSet == null || appSet.enableContrastEnhancement)) {
      image = img.adjustColor(image, contrast: args.settings.contrast);
    }

    // Step 6: Brightness normalization
    if (args.settings.brightness != 0.0) {
      image = img.adjustColor(
        image,
        brightness: (args.settings.brightness * 255).toInt(),
      );
    }

    // Step 7: Sharpening (unsharp mask approximation)
    if (args.settings.sharpness > 0.1 && (appSet == null || appSet.enableSharpening)) {
      image = img.convolution(image,
          filter: _buildSharpenKernel(args.settings.sharpness),
          div: 1,
          offset: 0);
    }

    // Step 8: Denoising (light Gaussian blur after sharpening)
    if (args.settings.denoise && (appSet == null || appSet.enableNoiseReduction)) {
      image = img.gaussianBlur(image, radius: 1);
    }

    // Step 9: Save at high quality
    await File(args.outputPath).writeAsBytes(
      img.encodeJpg(image, quality: 92),
    );

    return args.outputPath;
  }

  // ── Helper Methods ────────────────────────────────────────

  static img.Image _resizeForProcessing(img.Image src) {
    const maxPixels = 2000000; // 2MP
    final pixels = src.width * src.height;
    if (pixels <= maxPixels) return src;
    final scale = sqrt(maxPixels / pixels);
    return img.copyResize(
      src,
      width: (src.width * scale).toInt(),
      height: (src.height * scale).toInt(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Shadow removal via background illumination estimation.
  /// Heavily blurs the image (background), then divides pixel / background.
  static img.Image _removeShadows(img.Image src) {
    // Estimate background using strong Gaussian blur
    final background = img.gaussianBlur(img.Image.from(src), radius: 25);
    final output = img.Image.from(src);

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final fgPixel = src.getPixel(x, y);
        final bgPixel = background.getPixel(x, y);
        final fg = img.getLuminance(fgPixel).toDouble();
        final bg = img.getLuminance(bgPixel).toDouble();
        final normalized = ((fg / (bg < 1 ? 1 : bg)) * 255)
            .clamp(0, 255)
            .toInt();
        output.setPixelRgb(x, y, normalized, normalized, normalized);
      }
    }
    return output;
    
  }

  /// Adaptive thresholding using local mean.
  /// blockSize: neighborhood size (odd number), C: constant subtracted from mean.
  static img.Image _adaptiveThreshold(
    img.Image src, {
    int blockSize = 21,
    int C = 8,
  }) {
    final output = img.Image(width: src.width, height: src.height);
    final half = blockSize ~/ 2;

    // Build integral image for O(1) neighborhood sum
    final integral = List.generate(
      src.height + 1,
      (_) => List<int>.filled(src.width + 1, 0),
    );

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final lum = img.getLuminance(src.getPixel(x, y)).toInt();
        integral[y + 1][x + 1] =
            lum + integral[y][x + 1] + integral[y + 1][x] - integral[y][x];
      }
    }

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final x1 = (x - half).clamp(0, src.width - 1);
        final y1 = (y - half).clamp(0, src.height - 1);
        final x2 = (x + half).clamp(0, src.width - 1);
        final y2 = (y + half).clamp(0, src.height - 1);
        final count = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = integral[y2 + 1][x2 + 1] - integral[y1][x2 + 1] -
            integral[y2 + 1][x1] + integral[y1][x1];
        final mean = sum ~/ count;
        final lum = img.getLuminance(src.getPixel(x, y)).toInt();
        final newVal = lum < (mean - C) ? 0 : 255;
        output.setPixelRgb(x, y, newVal, newVal, newVal);
      }
    }
    return output;
  }

  /// Otsu's method: finds optimal global threshold by maximizing between-class variance.
  static int _otsuThreshold(img.Image src) {
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        histogram[img.getLuminance(src.getPixel(x, y)).toInt()]++;
      }
    }
    final total = src.width * src.height;
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0, wB = 0, maxVariance = 0;
    int threshold = 0;
    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;
      sumB += t * histogram[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;
      final variance = wB * wF * (mB - mF) * (mB - mF);
      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }
    return threshold;
  }

  static img.Image _applyThreshold(img.Image src, int threshold) {
    final output = img.Image(width: src.width, height: src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final lum = img.getLuminance(src.getPixel(x, y)).toInt();
        final v = lum < threshold ? 0 : 255;
        output.setPixelRgb(x, y, v, v, v);
      }
    }
    return output;
  }

  /// Unsharp mask kernel. strength 0.0–1.0.
  static List<int> _buildSharpenKernel(double strength) {
    final s = (strength * 2).clamp(0.5, 2.0);
    final center = (1 + 4 * s).round();
    final edge = (-s).round();
    return [
      0,     edge,  0,
      edge,  center, edge,
      0,     edge,  0,
    ];
  }

  Future<String> generateThumbnail(
    String inputPath,
    String outputPath,
  ) async {
    return await compute(
      _generateThumbnailInIsolate,
      _ProcessArgs(
        inputPath: inputPath,
        settings: const EnhancementSettings(),
        outputPath: outputPath,
        rotation: 0,
        isManualEdit: false,
      ),
    );
  }

  static Future<String> _generateThumbnailInIsolate(_ProcessArgs args) async {
    final bytes = await File(args.inputPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: ${args.inputPath}');

    // Resize down for thumbnail (width: 150px, height: 200px)
    final thumbnail = img.copyResize(
      image,
      width: 150,
      height: 200,
      interpolation: img.Interpolation.linear,
    );

    await File(args.outputPath).writeAsBytes(
      img.encodeJpg(thumbnail, quality: 75),
    );

    return args.outputPath;
  }

  Future<String> getProcessedPath(String docId, String pageId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/documents/doc_$docId/processed');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/${pageId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  Future<String> getThumbnailPath(String docId, String pageId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/documents/doc_$docId/thumbnails');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/${pageId}_${DateTime.now().millisecondsSinceEpoch}_thumbnail.jpg';
  }

  Future<String> getOriginalPath(String docId, String pageId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/documents/doc_$docId/original');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/${pageId}_${DateTime.now().millisecondsSinceEpoch}_original.jpg';
  }
}

class _ProcessArgs {
  final String inputPath;
  final EnhancementSettings settings;
  final String outputPath;
  final AppSettings? appSettings;
  final List<CropPoint>? cropPoints;
  final int rotation;
  final bool isManualEdit;

  const _ProcessArgs({
    required this.inputPath,
    required this.settings,
    required this.outputPath,
    this.appSettings,
    this.cropPoints,
    required this.rotation,
    required this.isManualEdit,
  });
}
