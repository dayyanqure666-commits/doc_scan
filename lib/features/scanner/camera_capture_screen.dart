import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/scan_document.dart';
import '../../core/models/scan_page.dart';
import '../../core/services/image_processor.dart';
import '../preview/preview_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasPermissionError = false;
  String _permissionErrorMessage = '';
  
  FlashMode _flashMode = FlashMode.off;
  final ImageProcessor _processor = ImageProcessor();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  final List<ScanPage> _sessionPages = [];
  late String _sessionDocId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionDocId = _uuid.v4();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changes (background / foreground)
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() {
        _isInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _hasPermissionError = true;
          _permissionErrorMessage = 'No cameras found on this device.';
        });
        return;
      }

      // Find the primary rear camera
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _initializeCameraController(rearCamera);
    } catch (e) {
      setState(() {
        _hasPermissionError = true;
        _permissionErrorMessage = 'Failed to access camera: $e';
      });
    }
  }

  Future<void> _initializeCameraController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      
      // Attempt to set default autofocus/exposure properties if available
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {}
      
      try {
        await controller.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasPermissionError = false;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasPermissionError = true;
          if (e.code == 'CameraAccessDenied') {
            _permissionErrorMessage = 'Camera permission was denied. Please grant permission in settings to continue.';
          } else {
            _permissionErrorMessage = 'Camera initialization failed: ${e.description}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasPermissionError = true;
          _permissionErrorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.off,
    };

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flash mode not supported: $e')),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      
      // Immediately run in background to process and save permanently
      final pageId = _uuid.v4();
      
      final originalPath = await _processor.getOriginalPath(_sessionDocId, pageId);
      final processedPath = await _processor.getProcessedPath(_sessionDocId, pageId);
      final thumbnailPath = await _processor.getThumbnailPath(_sessionDocId, pageId);

      // Copy captured photo to permanent original path
      final originalFile = File(photo.path);
      await originalFile.copy(originalPath);

      // Generate processed/enhanced copy
      await _processor.processImage(
        originalPath,
        const EnhancementSettings(),
        processedPath,
      );

      // Generate thumbnail copy
      await _processor.generateThumbnail(
        originalPath,
        thumbnailPath,
      );

      // Delete the original cache file
      try {
        await originalFile.delete();
      } catch (_) {}

      final newPage = ScanPage(
        id: pageId,
        documentId: _sessionDocId,
        originalImagePath: originalPath,
        processedImagePath: processedPath,
        thumbnailPath: thumbnailPath,
        capturedAt: DateTime.now(),
        pageOrder: _sessionPages.length,
      );

      if (mounted) {
        setState(() {
          _sessionPages.add(newPage);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _importFromGallery() async {
    if (_isCapturing) return;
    
    try {
      final images = await _picker.pickMultiImage(imageQuality: 95);
      if (images.isEmpty) return;

      setState(() => _isCapturing = true);

      for (final image in images) {
        final pageId = _uuid.v4();
        final originalPath = await _processor.getOriginalPath(_sessionDocId, pageId);
        final processedPath = await _processor.getProcessedPath(_sessionDocId, pageId);
        final thumbnailPath = await _processor.getThumbnailPath(_sessionDocId, pageId);

        // Copy source to original folder
        await File(image.path).copy(originalPath);

        // Process default enhanced version
        await _processor.processImage(
          originalPath,
          const EnhancementSettings(),
          processedPath,
        );

        // Generate thumbnail
        await _processor.generateThumbnail(
          originalPath,
          thumbnailPath,
        );

        final newPage = ScanPage(
          id: pageId,
          documentId: _sessionDocId,
          originalImagePath: originalPath,
          processedImagePath: processedPath,
          thumbnailPath: thumbnailPath,
          capturedAt: DateTime.now(),
          pageOrder: _sessionPages.length,
        );

        if (mounted) {
          setState(() {
            _sessionPages.add(newPage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _proceedToPreview() {
    if (_sessionPages.isEmpty) return;

    final doc = ScanDocument(
      id: _sessionDocId,
      name: 'Scan ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      pages: List.from(_sessionPages),
      thumbnailPath: _sessionPages.first.processedImagePath,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(document: doc)),
    );
  }

  Widget _buildFlashIcon() {
    return switch (_flashMode) {
      FlashMode.off => const Icon(Icons.flash_off, color: Colors.white),
      FlashMode.auto => const Icon(Icons.flash_auto, color: Colors.amber),
      FlashMode.always => const Icon(Icons.flash_on, color: Colors.amber),
      _ => const Icon(Icons.flash_off, color: Colors.white),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermissionError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  _permissionErrorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasPermissionError = false;
                      _isInitialized = false;
                    });
                    _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'DocScan Camera',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: _buildFlashIcon(),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),

            // Live Camera Preview or Placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey.shade900,
                  child: !_isInitialized
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                ),
              ),
            ),

            // Bottom Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery Import Button
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                    onPressed: _isCapturing ? null : _importFromGallery,
                  ),

                  // Capture Button
                  GestureDetector(
                    onTap: (_isInitialized && !_isCapturing) ? _capturePhoto : null,
                    child: Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.grey : Colors.white,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Done / Continue Button with Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
                        onPressed: _sessionPages.isNotEmpty ? _proceedToPreview : null,
                      ),
                      if (_sessionPages.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_sessionPages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
