import 'package:flutter/material.dart';

import 'crop_controller.dart';

/// Paints the cropping UI overlay.
///
/// * Dark semi-transparent mask outside the crop quadrilateral.
/// * Green border for the crop area.
/// * Circular handles at each corner.
/// * Optional 3×3 grid inside the crop.
class CropPainter extends CustomPainter {
  final CropController controller;
  final Size imageSize;

  CropPainter({
    required this.controller,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Scale factor from image to widget size
    final scale = _fitScale(imageSize, size);

    final offset = _fitOffset(
      imageSize,
      size,
      scale,
    );

    // Convert normalized points to widget coordinates
    final points = controller.points
        .map(
          (p) => Offset(
            p.x * imageSize.width,
            p.y * imageSize.height,
          ),
        )
        .map(
          (pt) => Offset(
            pt.dx * scale + offset.dx,
            pt.dy * scale + offset.dy,
          ),
        )
        .toList();

    // Create crop polygon path
    final path = Path()..addPolygon(points, true);

    // Draw dark overlay outside the crop quadrilateral
    final outerPath = Path()..addRect(Offset.zero & size);
    final combinedPath = Path.combine(PathOperation.difference, outerPath, path);

    paint
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(combinedPath, paint);

    // Draw border
    paint
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, paint);

    // Draw handles
    const handleRadius = 10.0;

    for (final pt in points) {
      paint
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        pt,
        handleRadius,
        paint,
      );

      paint
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        pt,
        handleRadius,
        paint,
      );
    }

    // Draw 3x3 grid
    paint
      ..color = Colors.white70
      ..strokeWidth = 1;

    for (int i = 1; i < 3; i++) {
      final t = i / 3;

      // Horizontal lines
      final startH = Offset.lerp(
        points[0],
        points[3],
        t,
      )!;

      final endH = Offset.lerp(
        points[1],
        points[2],
        t,
      )!;

      canvas.drawLine(
        startH,
        endH,
        paint,
      );

      // Vertical lines
      final startV = Offset.lerp(
        points[0],
        points[1],
        t,
      )!;

      final endV = Offset.lerp(
        points[3],
        points[2],
        t,
      )!;

      canvas.drawLine(
        startV,
        endV,
        paint,
      );
    }
  }

  double _fitScale(
    Size image,
    Size widget,
  ) {
    final scaleX = widget.width / image.width;
    final scaleY = widget.height / image.height;

    return scaleX < scaleY ? scaleX : scaleY;
  }

  Offset _fitOffset(
    Size image,
    Size widget,
    double scale,
  ) {
    final dx = (widget.width - image.width * scale) / 2;

    final dy = (widget.height - image.height * scale) / 2;

    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant CropPainter oldDelegate) => true;
}