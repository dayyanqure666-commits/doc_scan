import 'dart:ui';
import 'package:flutter/material.dart' show Offset;
import 'scan_document.dart';

enum PageSize { a4, letter, auto }

class CropPoint {
  final double x;
  final double y;

  const CropPoint({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory CropPoint.fromMap(Map<String, dynamic> map) {
    return CropPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }

  CropPoint copyWith({
    double? x,
    double? y,
  }) {
    return CropPoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Offset toPixel(
    double width,
    double height,
  ) {
    return Offset(
      x * width,
      y * height,
    );
  }

  factory CropPoint.fromPixel(
    Offset offset,
    double width,
    double height,
  ) {
    return CropPoint(
      x: offset.dx / width,
      y: offset.dy / height,
    );
  }
}

class ScanPage {
  final String id;
  final String documentId;
  String originalImagePath;
  String processedImagePath;
  String? thumbnailPath;
  final DateTime capturedAt;
  int rotation;
  EnhancementSettings settings;
  PageSize pageSize;
  int pageOrder;
  List<CropPoint> cropPoints;

  ScanPage({
    required this.id,
    required this.documentId,
    required this.originalImagePath,
    required this.processedImagePath,
    this.thumbnailPath,
    required this.capturedAt,
    this.rotation = 0,
    EnhancementSettings? settings,
    this.pageSize = PageSize.auto,
    required this.pageOrder,
    this.cropPoints = const [],
  }) : settings = settings ?? const EnhancementSettings();

  Map<String, dynamic> toMap() => {
    'id': id,
    'document_id': documentId,
    'original_path': originalImagePath,
    'processed_path': processedImagePath,
    'thumbnail_path': thumbnailPath,
    'captured_at': capturedAt.millisecondsSinceEpoch,
    'page_order': pageOrder,
    'rotation': rotation,
    'settings': settings.toMap(),
    'page_size': pageSize.index,
    'crop_points': cropPoints.map((p) => p.toMap()).toList(),
  };

  factory ScanPage.fromMap(Map<String, dynamic> map) => ScanPage(
    id: map['id'],
    documentId: map['document_id'],
    originalImagePath: map['original_path'],
    processedImagePath: map['processed_path'],
    thumbnailPath: map['thumbnail_path'],
    capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at']),
    pageOrder: map['page_order'],
    rotation: map['rotation'] ?? 0,
    settings: map['settings'] != null ? EnhancementSettings.fromMap(map['settings']) : const EnhancementSettings(),
    pageSize: map['page_size'] != null ? PageSize.values[map['page_size']] : PageSize.auto,
    cropPoints: map['crop_points'] != null
        ? (map['crop_points'] as List)
            .map((p) => CropPoint.fromMap(p as Map<String, dynamic>))
            .toList()
        : const [],
  );
}
