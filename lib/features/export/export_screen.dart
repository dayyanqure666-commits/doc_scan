import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../../core/models/scan_document.dart';
import '../../core/services/app_state.dart';
import '../../core/services/pdf_generator.dart';
import '../../shared/widgets/app_widgets.dart';
import '../home/home_screen.dart';

class ExportScreen extends StatefulWidget {
  final ScanDocument document;
  const ExportScreen({super.key, required this.document});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late String _docName;
  ExportQuality _quality = ExportQuality.standard;
  String _pageSize = 'A4';
  bool _isGenerating = false;
  String? _generatedPDFPath;
  final _generator = PDFGenerator();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _docName = widget.document.name;
    _nameController = TextEditingController(text: _docName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _estimatedSize =>
      PDFGenerator.estimatePDFSize(widget.document.pages, _quality);

  Future<void> _generateAndSave() async {
    setState(() => _isGenerating = true);

    try {
      widget.document.name = _docName;
      final pdfPath = await _generator.generate(
        widget.document,
        _quality,
        PDFGenerator.getPageFormat(_pageSize),
      );

      // Save to app state
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        widget.document.pdfPath = pdfPath;
        await appState.addDocument(widget.document);
      }

      setState(() {
        _isGenerating = false;
        _generatedPDFPath = pdfPath;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePDF() async {
    if (_generatedPDFPath == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_generatedPDFPath!)],
        text: _docName,
      ),
    );
  }

  Future<void> _openPDF() async {
    if (_generatedPDFPath == null) return;
    await OpenFile.open(_generatedPDFPath!);
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export PDF')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Name
                const Text('Document Name',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (v) => _docName = v,
                  decoration: const InputDecoration(
                    hintText: 'Enter document name',
                    suffixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Quality Selector
                const Text('Export Quality',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                RadioGroup<ExportQuality>(
                  groupValue: _quality,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _quality = v);
                    }
                  },
                  child: Column(
                    children: ExportQuality.values.map((q) => _QualityOption(
                      quality: q,
                      selected: _quality == q,
                      onSelect: () => setState(() => _quality = q),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Page Size
                const Text('Page Size',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _pageSize,
                  decoration: const InputDecoration(),
                  items: ['A4', 'Letter', 'A3', 'Legal']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _pageSize = v!),
                ),
                const SizedBox(height: 24),

                // Summary
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow('Pages', '${widget.document.pageCount} pages'),
                      _InfoRow('Estimated Size', PDFGenerator.formatFileSize(_estimatedSize)),
                      const _InfoRow('Format', 'PDF 1.5 (OCR-ready)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // OCR note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This PDF is preprocessed for OCR. Connect to Google Document AI, AWS Textract, or Tesseract to extract text.',
                          style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                if (_generatedPDFPath == null) ...[
                  PrimaryButton(
                    label: 'Generate & Save PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: _isGenerating,
                    onPressed: _generateAndSave,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 40),
                        const SizedBox(height: 8),
                        Text('PDF Generated!',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                                fontSize: 16)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openPDF,
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Open'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _sharePDF,
                                icon: const Icon(Icons.share, size: 16),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _goHome,
                            child: const Text('Back to Home'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isGenerating) const LoadingOverlay(message: 'Generating PDF...'),
        ],
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final ExportQuality quality;
  final bool selected;
  final VoidCallback onSelect;

  const _QualityOption({
    required this.quality,
    required this.selected,
    required this.onSelect,
  });

  static const _labels = {
    ExportQuality.draft: ('Draft', 'Fast, smaller file', Icons.bolt_outlined),
    ExportQuality.standard: ('Standard', 'Balanced (recommended)', Icons.balance_outlined),
    ExportQuality.high: ('High', 'Best quality, larger file', Icons.hd_outlined),
    ExportQuality.archival: ('Archival', 'Maximum quality', Icons.archive_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final (label, desc, icon) = _labels[quality]!;
    return RadioListTile<ExportQuality>(
      value: quality,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
