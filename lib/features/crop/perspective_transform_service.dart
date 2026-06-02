import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Service that applies a perspective transform to an image
/// based on four source points.
class PerspectiveTransformService {
  /// srcPoints order:
  /// TL, TR, BR, BL
  static Uint8List transform({
    required Uint8List imageBytes,
    required List<Point<double>> srcPoints,
  }) {
    final original = img.decodeImage(imageBytes);

    if (original == null) {
      throw Exception('Failed to decode image');
    }

    // Convert normalized coordinates to image pixels
    final src = srcPoints
        .map(
          (p) => Point<double>(
            p.x * original.width,
            p.y * original.height,
          ),
        )
        .toList();

    // Calculate output size
    final topWidth = _distance(src[0], src[1]);
    final bottomWidth = _distance(src[3], src[2]);

    final leftHeight = _distance(src[0], src[3]);
    final rightHeight = _distance(src[1], src[2]);

    final width = max(topWidth, bottomWidth).round();
    final height = max(leftHeight, rightHeight).round();

    final dst = [
      const Point<double>(0, 0),
      Point<double>(width.toDouble(), 0),
      Point<double>(width.toDouble(), height.toDouble()),
      Point<double>(0, height.toDouble()),
    ];

    // Homography matrix
    final h = _computeHomography(dst, src);

    // Create output image
    final transformed = img.Image(
      width: width,
      height: height,
    );

    // Backward mapping
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcPoint = _applyHomography(
          h,
          Point<double>(
            x.toDouble(),
            y.toDouble(),
          ),
        );

        final color = _bilinearSample(
          original,
          srcPoint.x,
          srcPoint.y,
        );

        transformed.setPixel(
          x,
          y,
          color,
        );
      }
    }

    return Uint8List.fromList(
      img.encodePng(transformed),
    );
  }

  static double _distance(Point a, Point b) {
    return sqrt(
      pow(a.x - b.x, 2) +
          pow(a.y - b.y, 2),
    );
  }

  /// Computes homography matrix
  static List<double> _computeHomography(
    List<Point<double>> dst,
    List<Point<double>> src,
  ) {
    final matrix = List.generate(
      8,
      (_) => List<double>.filled(8, 0),
    );

    final rhs = List<double>.filled(8, 0);

    for (int i = 0; i < 4; i++) {
      final x = dst[i].x;
      final y = dst[i].y;

      final u = src[i].x;
      final v = src[i].y;

      final r1 = i * 2;
      final r2 = r1 + 1;

      matrix[r1][0] = x;
      matrix[r1][1] = y;
      matrix[r1][2] = 1;
      matrix[r1][6] = -x * u;
      matrix[r1][7] = -y * u;
      rhs[r1] = u;

      matrix[r2][3] = x;
      matrix[r2][4] = y;
      matrix[r2][5] = 1;
      matrix[r2][6] = -x * v;
      matrix[r2][7] = -y * v;
      rhs[r2] = v;
    }

    final solution = _gaussianElimination(
      matrix,
      rhs,
    );

    return [
      solution[0],
      solution[1],
      solution[2],
      solution[3],
      solution[4],
      solution[5],
      solution[6],
      solution[7],
      1.0,
    ];
  }

  static Point<double> _applyHomography(
    List<double> h,
    Point<double> p,
  ) {
    final x = p.x;
    final y = p.y;

    final denominator =
        h[6] * x +
            h[7] * y +
            h[8];

    final mappedX =
        (h[0] * x +
                h[1] * y +
                h[2]) /
            denominator;

    final mappedY =
        (h[3] * x +
                h[4] * y +
                h[5]) /
            denominator;

    return Point<double>(
      mappedX,
      mappedY,
    );
  }

  static List<double> _gaussianElimination(
    List<List<double>> a,
    List<double> b,
  ) {
    const n = 8;

    for (int i = 0; i < n; i++) {
      int maxRow = i;

      for (int k = i + 1; k < n; k++) {
        if (a[k][i].abs() >
            a[maxRow][i].abs()) {
          maxRow = k;
        }
      }

      final tempRow = a[i];
      a[i] = a[maxRow];
      a[maxRow] = tempRow;

      final tempVal = b[i];
      b[i] = b[maxRow];
      b[maxRow] = tempVal;

      for (int k = i + 1; k < n; k++) {
        final factor =
            a[k][i] / a[i][i];

        for (int j = i; j < n; j++) {
          a[k][j] -=
              factor * a[i][j];
        }

        b[k] -= factor * b[i];
      }
    }

    final x = List<double>.filled(n, 0);

    for (int i = n - 1; i >= 0; i--) {
      double sum = b[i];

      for (int j = i + 1; j < n; j++) {
        sum -= a[i][j] * x[j];
      }

      x[i] = sum / a[i][i];
    }

    return x;
  }

  /// Bilinear interpolation
  static img.ColorRgba8 _bilinearSample(
    img.Image src,
    double x,
    double y,
  ) {
    final x0 = x.floor();
    final y0 = y.floor();

    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final wx = x - x0;
    final wy = y - y0;

    img.Pixel getPixel(
      int px,
      int py,
    ) {
      final clampedX = px.clamp(
        0,
        src.width - 1,
      );

      final clampedY = py.clamp(
        0,
        src.height - 1,
      );

      return src.getPixel(
        clampedX,
        clampedY,
      );
    }

    final c00 = getPixel(x0, y0);
    final c10 = getPixel(x1, y0);
    final c01 = getPixel(x0, y1);
    final c11 = getPixel(x1, y1);

    int lerp(
      int a,
      int b,
      double t,
    ) {
      return (a + (b - a) * t)
          .round();
    }

    final r0 = lerp(
      c00.r.toInt(),
      c10.r.toInt(),
      wx,
    );

    final g0 = lerp(
      c00.g.toInt(),
      c10.g.toInt(),
      wx,
    );

    final b0 = lerp(
      c00.b.toInt(),
      c10.b.toInt(),
      wx,
    );

    final a0 = lerp(
      c00.a.toInt(),
      c10.a.toInt(),
      wx,
    );

    final r1 = lerp(
      c01.r.toInt(),
      c11.r.toInt(),
      wx,
    );

    final g1 = lerp(
      c01.g.toInt(),
      c11.g.toInt(),
      wx,
    );

    final b1 = lerp(
      c01.b.toInt(),
      c11.b.toInt(),
      wx,
    );

    final a1 = lerp(
      c01.a.toInt(),
      c11.a.toInt(),
      wx,
    );

    return img.ColorRgba8(
      lerp(r0, r1, wy),
      lerp(g0, g1, wy),
      lerp(b0, b1, wy),
      lerp(a0, a1, wy),
    );
  }
}
