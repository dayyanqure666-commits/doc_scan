import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/scan_page.dart';
import '../crop/crop_controller.dart';
import '../crop/crop_painter.dart';
import '../crop/perspective_transform_service.dart';
import 'package:docscan/core/services/image_processor.dart';
/// Screen for manual crop editing.
///
/// Receives the [page] to edit.
/// Calls [onDone] with:
/// - cropped image path
/// - updated crop points
class CropScreen extends StatefulWidget {
  final ScanPage page;

  final VoidCallback onCancel;

  final Function(
    String newImagePath,
    List<CropPoint> newCropPoints,
  ) onDone;

  const CropScreen({
    super.key,
    required this.page,
    required this.onCancel,
    required this.onDone,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late CropController _controller;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _controller = CropController(
      initialPoints: widget.page.cropPoints.isNotEmpty
          ? widget.page.cropPoints
          : CropController.defaultPoints(),
    );
  }

  Future<void> _applyCrop() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath =
         widget.page.processedImagePath.isNotEmpty &&
            File(widget.page.processedImagePath).existsSync()
        ? widget.page.processedImagePath
        : widget.page.originalImagePath;

      final imageFile = File(imagePath);

      final bytes = await imageFile.readAsBytes();

      final srcPoints =
          _controller.points
              .map(
                (p) => Point<double>(p.x, p.y),
              )
              .toList();

      final Uint8List transformed =
           PerspectiveTransformService.transform(
            imageBytes: bytes,
            srcPoints: srcPoints,
          );

      final dir = await getApplicationDocumentsDirectory();

      final newFileName = '${const Uuid().v4()}.png';

      final newPath = '${dir.path}/$newFileName';

      await File(newPath).writeAsBytes(transformed);
      final page = widget.page;

      await ImageProcessor().processImage(
      newPath,
      page.settings,
      newPath,
      );
      widget.onDone(
        newPath,
        _controller.points,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Crop error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(
      widget.page.processedImagePath.isNotEmpty &&
          File(widget.page.processedImagePath).existsSync()
      ? widget.page.processedImagePath
      : widget.page.originalImagePath,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),

        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),

        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _applyCrop,

            child:
                _isProcessing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                    : const Text('Done'),
          ),
        ],
      ),

      body: FutureBuilder<Size>(
        future: _getImageSize(imageFile),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final imageSize = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

              return GestureDetector(
                onPanStart: (details) {
                  _controller.startDrag(
                    details.localPosition,
                    imageSize,
                    widgetSize,
                    hitRadius: 40.0,
                  );
                },

                onPanUpdate: (details) {
                  setState(() {
                    _controller.updateDrag(
                      details.localPosition,
                      imageSize,
                      widgetSize,
                    );
                  });
                },

                onPanEnd: (_) {
                  _controller.endDrag();
                },

                child: Stack(
                  fit: StackFit.expand,

                  children: [
                    Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                    ),

                    CustomPaint(
                      painter: CropPainter(
                        controller: _controller,
                        imageSize: imageSize,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Size> _getImageSize(File file) async {
    final bytes = await file.readAsBytes();

    final decoded = await decodeImageFromList(bytes);

    return Size(
      decoded.width.toDouble(),
      decoded.height.toDouble(),
    );
  }
}