import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../core/models/scan_page.dart';

class EdgeDetectionService {
  static Future<List<CropPoint>> detectEdges(String imagePath) async {
    return await compute(_detectEdgesInIsolate, imagePath);
  }

  static List<CropPoint> defaultCropPoints() {
    return const [
      CropPoint(x: 0.0, y: 0.0),
      CropPoint(x: 1.0, y: 0.0),
      CropPoint(x: 1.0, y: 1.0),
      CropPoint(x: 0.0, y: 1.0),
    ];
  }

  static Future<List<CropPoint>> _detectEdgesInIsolate(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final rawImg = img.decodeImage(bytes);
      if (rawImg == null) return defaultCropPoints();

      const sw = 100;
      final sh = (rawImg.height * (sw / rawImg.width)).toInt();
      
      // Resize to a small canvas for ultra-fast, low-memory analysis
      final smallImg = img.copyResize(rawImg, width: sw, height: sh);

      // 1. Grayscale & Histogram computation
      final hist = List<int>.filled(256, 0);
      final lums = List<int>.filled(sw * sh, 0);
      for (int y = 0; y < sh; y++) {
        for (int x = 0; x < sw; x++) {
          final pixel = smallImg.getPixel(x, y);
          final lum = img.getLuminance(pixel).toInt().clamp(0, 255);
          lums[y * sw + x] = lum;
          hist[lum]++;
        }
      }

      // 2. Otsu's Thresholding algorithm
      int total = sw * sh;
      double sum = 0;
      for (int i = 0; i < 256; i++) {
        sum += i * hist[i];
      }

      double sumB = 0;
      int wB = 0;
      double maxVar = 0;
      int threshold = 127;

      for (int t = 0; t < 256; t++) {
        wB += hist[t];
        if (wB == 0) continue;
        int wF = total - wB;
        if (wF == 0) break;
        sumB += t * hist[t];
        double mB = sumB / wB;
        double mF = (sum - sumB) / wF;
        double varBetween = wB.toDouble() * wF.toDouble() * pow(mB - mF, 2);
        if (varBetween > maxVar) {
          maxVar = varBetween;
          threshold = t;
        }
      }

      // 3. Coordinate scanning for extreme quadrilateral coordinates
      int fgCount = 0;
      double minSum = 1e9, maxSum = -1e9;
      double minDiff = 1e9, maxDiff = -1e9;

      Point<int> tl = const Point(0, 0);
      Point<int> tr = const Point(sw - 1, 0);
      Point<int> br = Point(sw - 1, sh - 1);
      Point<int> bl = Point(0, sh - 1);

      for (int y = 0; y < sh; y++) {
        for (int x = 0; x < sw; x++) {
          final lum = lums[y * sw + x];
          if (lum >= threshold) {
            fgCount++;
            final sumXY = (x + y).toDouble();
            final diffXY = (x - y).toDouble();

            // tl (minimizes x + y)
            if (sumXY < minSum) {
              minSum = sumXY;
              tl = Point(x, y);
            }
            // br (maximizes x + y)
            if (sumXY > maxSum) {
              maxSum = sumXY;
              br = Point(x, y);
            }
            // tr (maximizes x - y)
            if (diffXY > maxDiff) {
              maxDiff = diffXY;
              tr = Point(x, y);
            }
            // bl (minimizes x - y)
            if (diffXY < minDiff) {
              minDiff = diffXY;
              bl = Point(x, y);
            }
          }
        }
      }

      // 4. Validate output shape bounding area. If edge contrast is missing, fallback to full page.
      final fgRatio = fgCount / total;
      if (fgRatio < 0.15 || fgRatio > 0.85 || tl == br || tr == bl) {
        return defaultCropPoints();
      }

      // Return normalized crop points within boundaries
      return [
        CropPoint(x: (tl.x / sw).clamp(0.0, 1.0), y: (tl.y / sh).clamp(0.0, 1.0)),
        CropPoint(x: (tr.x / sw).clamp(0.0, 1.0), y: (tr.y / sh).clamp(0.0, 1.0)),
        CropPoint(x: (br.x / sw).clamp(0.0, 1.0), y: (br.y / sh).clamp(0.0, 1.0)),
        CropPoint(x: (bl.x / sw).clamp(0.0, 1.0), y: (bl.y / sh).clamp(0.0, 1.0)),
      ];
    } catch (e) {
      return defaultCropPoints();
    }
  }
}
