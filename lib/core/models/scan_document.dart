import 'scan_page.dart';

enum ExportQuality { draft, standard, high, archival }
enum EnhancementMode { auto, document, photo, whiteboard, grayscale }
enum ThresholdMode { adaptive, otsu, none }

class EnhancementSettings {
  final EnhancementMode mode;
  final double contrast;
  final double brightness;
  final double sharpness;
  final bool shadowRemoval;
  final bool denoise;
  final ThresholdMode threshold;

  const EnhancementSettings({
    this.mode = EnhancementMode.auto,
    this.contrast = 1.2,
    this.brightness = 0.0,
    this.sharpness = 0.5,
    this.shadowRemoval = true,
    this.denoise = true,
    this.threshold = ThresholdMode.adaptive,
  });

  static const document = EnhancementSettings(
    mode: EnhancementMode.document,
    contrast: 1.4,
    brightness: 0.1,
    sharpness: 0.7,
    shadowRemoval: true,
    denoise: true,
    threshold: ThresholdMode.adaptive,
  );

  static const photo = EnhancementSettings(
    mode: EnhancementMode.photo,
    contrast: 1.1,
    brightness: 0.0,
    sharpness: 0.3,
    shadowRemoval: false,
    denoise: false,
    threshold: ThresholdMode.none,
  );

  static const whiteboard = EnhancementSettings(
    mode: EnhancementMode.whiteboard,
    contrast: 1.5,
    brightness: 0.2,
    sharpness: 0.8,
    shadowRemoval: true,
    denoise: true,
    threshold: ThresholdMode.adaptive,
  );

  EnhancementSettings copyWith({
    EnhancementMode? mode,
    double? contrast,
    double? brightness,
    double? sharpness,
    bool? shadowRemoval,
    bool? denoise,
    ThresholdMode? threshold,
  }) {
    return EnhancementSettings(
      mode: mode ?? this.mode,
      contrast: contrast ?? this.contrast,
      brightness: brightness ?? this.brightness,
      sharpness: sharpness ?? this.sharpness,
      shadowRemoval: shadowRemoval ?? this.shadowRemoval,
      denoise: denoise ?? this.denoise,
      threshold: threshold ?? this.threshold,
    );
  }

  Map<String, dynamic> toMap() => {
    'mode': mode.index,
    'contrast': contrast,
    'brightness': brightness,
    'sharpness': sharpness,
    'shadowRemoval': shadowRemoval ? 1 : 0,
    'denoise': denoise ? 1 : 0,
    'threshold': threshold.index,
  };

  factory EnhancementSettings.fromMap(Map<String, dynamic> map) =>
      EnhancementSettings(
        mode: EnhancementMode.values[map['mode'] ?? 0],
        contrast: map['contrast'] ?? 1.2,
        brightness: map['brightness'] ?? 0.0,
        sharpness: map['sharpness'] ?? 0.5,
        shadowRemoval: (map['shadowRemoval'] ?? 1) == 1,
        denoise: (map['denoise'] ?? 1) == 1,
        threshold: ThresholdMode.values[map['threshold'] ?? 0],
      );
}

class ScanDocument {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime modifiedAt;
  List<ScanPage> pages;
  String? thumbnailPath;
  int fileSizeBytes;
  String? pdfPath;
  ExportQuality quality;

  ScanDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.pages,
    this.thumbnailPath,
    this.fileSizeBytes = 0,
    this.pdfPath,
    this.quality = ExportQuality.standard,
  });

  int get pageCount => pages.length;
  bool get hasExportedPDF => pdfPath != null;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.millisecondsSinceEpoch,
    'modified_at': modifiedAt.millisecondsSinceEpoch,
    'thumbnail_path': thumbnailPath,
    'pdf_path': pdfPath,
    'quality': quality.index,
    'page_count': pageCount,
    'file_size_bytes': fileSizeBytes,
    'pages': pages.map((p) => p.toMap()).toList(),
  };

  factory ScanDocument.fromMap(Map<String, dynamic> map) {
    final doc = ScanDocument(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modified_at']),
      pages: [],
      thumbnailPath: map['thumbnail_path'],
      pdfPath: map['pdf_path'],
      quality: ExportQuality.values[map['quality'] ?? 1],
      fileSizeBytes: map['file_size_bytes'] ?? 0,
    );
    if (map['pages'] != null) {
      doc.pages = (map['pages'] as List)
          .map((p) => ScanPage.fromMap(p as Map<String, dynamic>))
          .toList();
    }
    return doc;
  }
}
