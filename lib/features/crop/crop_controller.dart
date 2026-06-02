import 'package:flutter/material.dart';
import 'package:docscan/core/models/scan_page.dart';

/// Manages crop points and drag operations.
class CropController {
  /// Normalized crop points
  List<CropPoint> points;

  CropController({
    List<CropPoint>? initialPoints,
  }) : points =
            initialPoints !=null
              ? List<CropPoint>.from(initialPoints)
              : [
                   const CropPoint(x: 0.1, y: 0.1),
                   const CropPoint(x: 0.9, y: 0.1),
                   const CropPoint(x: 0.9, y: 0.9),
                   const CropPoint(x: 0.1, y: 0.9),
              ];

  /// Active dragging point index
  int activeIndex = -1;

  /// Returns crop points converted to pixel coordinates
  List<Offset> getPixelPoints(
    double width,
    double height,
  ) {
    return points
        .map((p) => p.toPixel(width, height))
        .toList();
  }

  /// Get single point in pixel coordinates
  Offset getPoint(
    int index,
    double width,
    double height,
  ) {
    return points[index].toPixel(width, height);
  }

  /// Update a point using pixel coordinates
  void updatePoint(
    int index,
    Offset pixelOffset,
    double width,
    double height,
  ) {
    if (index < 0 || index >= points.length) return;

    points[index] = CropPoint.fromPixel(
      pixelOffset,
      width,
      height,
    );
  }

  double _fitScale(Size image, Size widget) {
    final scaleX = widget.width / image.width;
    final scaleY = widget.height / image.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  Offset _fitOffset(Size image, Size widget, double scale) {
    final dx = (widget.width - image.width * scale) / 2;
    final dy = (widget.height - image.height * scale) / 2;
    return Offset(dx, dy);
  }

  /// Start dragging nearest point
  void startDrag(
    Offset touch,
    Size imageSize,
    Size widgetSize, {
    double hitRadius = 40.0,
  }) {
    final scale = _fitScale(imageSize, widgetSize);
    final offset = _fitOffset(imageSize, widgetSize, scale);

    double minDistance = double.infinity;
    int nearestIndex = -1;

    for (int i = 0; i < points.length; i++) {
      // Calculate handle position in widget space
      final handleWidget = Offset(
        points[i].x * imageSize.width * scale + offset.dx,
        points[i].y * imageSize.height * scale + offset.dy,
      );

      final distance = (handleWidget - touch).distance;
      debugPrint('Touch: $touch');
      debugPrint('Handle: $handleWidget');
      debugPrint('Distance: $distance');

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    if (minDistance < hitRadius) {
      activeIndex = nearestIndex;
    } else {
      activeIndex = -1;
    }
    debugPrint('Selected index: $activeIndex');
  }

  /// Update active dragged point
  void updateDrag(
    Offset touch,
    Size imageSize,
    Size widgetSize,
  ) {
    if (activeIndex == -1) return;

    final scale = _fitScale(imageSize, widgetSize);
    final offset = _fitOffset(imageSize, widgetSize, scale);

    // Clamp the touch position to the displayed image boundaries in widget space
    final clampedX = touch.dx.clamp(offset.dx, offset.dx + imageSize.width * scale);
    final clampedY = touch.dy.clamp(offset.dy, offset.dy + imageSize.height * scale);

    // Convert back from widget space to normalized coordinates [0.0, 1.0]
    final normalizedX = ((clampedX - offset.dx) / (imageSize.width * scale)).clamp(0.0, 1.0);
    final normalizedY = ((clampedY - offset.dy) / (imageSize.height * scale)).clamp(0.0, 1.0);

    points[activeIndex] = CropPoint(
      x: normalizedX,
      y: normalizedY,
    );
    debugPrint('controller.points: $points');
  }

  /// End dragging
  void endDrag() {
    activeIndex = -1;
  }

  /// Move all points together
  void moveAll(
    Offset delta,
    double width,
    double height,
  ) {
    final updated = <CropPoint>[];

    for (final point in points) {
      final pixel = point.toPixel(width, height);

      final moved = Offset(
        (pixel.dx + delta.dx).clamp(0.0, width),
        (pixel.dy + delta.dy).clamp(0.0, height),
      );

      updated.add(
        CropPoint.fromPixel(
          moved,
          width,
          height,
        ),
      );
    }

    points = updated;
  }

  /// Default normalized rectangle
  static List<CropPoint> defaultPoints() {
    return const [
      CropPoint(x: 0.0, y: 0.0),
      CropPoint(x: 1.0, y: 0.0),
      CropPoint(x: 1.0, y: 1.0),
      CropPoint(x: 0.0, y: 1.0),
    ];
  }
}