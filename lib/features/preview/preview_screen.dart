import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/scan_document.dart';
import '../../core/models/scan_page.dart';
import '../../core/services/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../crop/crop_screen.dart';
import 'enhancement_sheet.dart';
import '../export/export_screen.dart';
import '../../core/services/image_processor.dart';
class PreviewScreen extends StatefulWidget {
  final ScanDocument document;

  const PreviewScreen({
    super.key,
    required this.document,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late ScanDocument _doc;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
  }

  Future<void> _autoSave() async {
    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      await provider.addDocument(_doc);
    } catch (e) {
      debugPrint('Autosave error: $e');
    }
  }

  Future<void> _navigateToCrop(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropScreen(
          page: _doc.pages[_currentPage],
          onCancel: () {
            Navigator.of(context).pop();
          },
          onDone: (
            String croppedPath,
            List<CropPoint> cropPoints,
          ) async {
             final page = _doc.pages[_currentPage];

             final processor = ImageProcessor();

             final processedPath =
             await processor.getProcessedPath(
             page.documentId,
             page.id,
            );

             await processor.processImage(
              croppedPath,
              page.settings,
             processedPath,
            ); 
              debugPrint('CROPPED PATH   : $croppedPath');
              debugPrint('PROCESSED PATH : $processedPath');

            setState(() {
              final page = _doc.pages[_currentPage];
               page.processedImagePath = processedPath;
               page.cropPoints = List<CropPoint>.from(cropPoints);
               debugPrint(
                  'FINAL PAGE PATH : ${page.processedImagePath}',
              );
            });
            await _autoSave();
          },
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final page = _doc.pages[_currentPage];
    final updatedPage = await showModalBottomSheet<ScanPage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancementSheet(page: page),
    );

    if (updatedPage != null) {
      setState(() {
        _doc.pages[_currentPage] = updatedPage;
      });
      await _autoSave();
    }
  }

  void _rotatePage() {
    setState(() {
      final page = _doc.pages[_currentPage];
      page.rotation = (page.rotation + 90) % 360;
    });
    _autoSave();
  }

  void _deletePage() {
    if (_doc.pages.length <= 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Document'),
          content: const Text('Deleting the last page will delete the entire document. Do you want to delete this scan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final appState = Provider.of<AppStateProvider>(context, listen: false);
                await appState.deleteDocument(_doc.id);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Are you sure you want to delete Page ${_currentPage + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _doc.pages.removeAt(_currentPage);
                if (_currentPage >= _doc.pages.length) {
                  _currentPage = _doc.pages.length - 1;
                }
              });
              await _autoSave();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportScreen(document: _doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_doc.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preview'),
        ),
        body: const Center(
          child: Text('No pages available'),
        ),
      );
    }

    final page = _doc.pages[_currentPage];
    final imageFile = File(
      page.processedImagePath.isNotEmpty && File(page.processedImagePath).existsSync()
          ? page.processedImagePath
          : page.originalImagePath,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_doc.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export to PDF',
            onPressed: _proceedToExport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Preview Page
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Hero(
                    tag: 'preview_${page.id}',
                    child: InteractiveViewer(
                      child: RotatedBox(
                        quarterTurns: page.rotation ~/ 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Page Number Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Page ${_currentPage + 1} of ${_doc.pages.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
          ),

          // Thumbnail List (If multi-page)
          if (_doc.pages.length > 1)
            Container(
              height: 84,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _doc.pages.length,
                itemBuilder: (context, index) {
                  final p = _doc.pages[index];
                  final thumbnailFile = File(
                    p.thumbnailPath != null && File(p.thumbnailPath!).existsSync()
                        ? p.thumbnailPath!
                        : (p.processedImagePath.isNotEmpty && File(p.processedImagePath).existsSync()
                            ? p.processedImagePath
                            : p.originalImagePath),
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentPage == index
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width: 2.5,
                        ),
                      ),
                      child: RotatedBox(
                        quarterTurns: p.rotation ~/ 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            thumbnailFile,
                            width: 50,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom Toolbar Actions
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolbarButton(
                    icon: Icons.crop_outlined,
                    label: 'Crop',
                    onTap: () => _navigateToCrop(context),
                  ),
                  _ToolbarButton(
                    icon: Icons.color_lens_outlined,
                    label: 'Enhance',
                    onTap: () => _openFilters(context),
                  ),
                  _ToolbarButton(
                    icon: Icons.rotate_right_outlined,
                    label: 'Rotate',
                    onTap: _rotatePage,
                  ),
                  _ToolbarButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: _deletePage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
