// lib/features/preview/enhancement_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/scan_document.dart';
import '../../core/models/scan_page.dart';
import '../../core/services/image_processor.dart';
import '../../shared/theme/app_theme.dart';

class EnhancementSheet extends StatefulWidget {
  final ScanPage page;

  const EnhancementSheet({required this.page, super.key});

  @override
  State<EnhancementSheet> createState() => _EnhancementSheetState();
}

class _EnhancementSheetState extends State<EnhancementSheet> {
  late EnhancementSettings _settings;
  bool _isProcessing = false;
  String? _previewPath;

  static const _filters = [
    ('Auto', EnhancementMode.auto),
    ('Document', EnhancementMode.document),
    ('Photo', EnhancementMode.photo),
    ('Whiteboard', EnhancementMode.whiteboard),
    ('Grayscale', EnhancementMode.grayscale),
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.page.settings;
    _previewPath = widget.page.processedImagePath;
  }

  Future<void> _applySettings() async {
    setState(() => _isProcessing = true);
    try {
      final outPath = widget.page.processedImagePath;
      final result = await ImageProcessor().processImage(
        widget.page.originalImagePath,
        _settings,
        outPath,
      );
      setState(() => _previewPath = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enhancement failed: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _confirm() {
    final updatedPage = ScanPage(
      id: widget.page.id,
      documentId: widget.page.documentId,
      originalImagePath: widget.page.originalImagePath,
      processedImagePath: _previewPath ?? widget.page.processedImagePath,
      thumbnailPath: widget.page.thumbnailPath,
      capturedAt: widget.page.capturedAt,
      rotation: widget.page.rotation,
      settings: _settings,
      pageOrder: widget.page.pageOrder,
      cropPoints: widget.page.cropPoints,
    );
    Navigator.of(context).pop(updatedPage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Preview + title
          Padding(
            padding: const EdgeInsets.all(AppTheme.md),
            child: Row(
              children: [
                Text('Enhance', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (_isProcessing)
                  const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                TextButton(onPressed: _confirm, child: const Text('Apply')),
              ],
            ),
          ),

          // Preview image
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.md),
            decoration: const BoxDecoration(borderRadius: AppTheme.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: _previewPath != null
                ? Image.file(File(_previewPath!), fit: BoxFit.contain,
                    key: ValueKey(_previewPath))
                : const Center(child: Icon(Icons.image_outlined)),
          ).animate(key: ValueKey(_previewPath)).fadeIn(duration: 200.ms),

          const SizedBox(height: AppTheme.md),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
              children: _filters.map((f) {
                final isSelected = _settings.mode == f.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$1),
                    selected: isSelected,
                    onSelected: (_) async {
                      final preset = switch (f.$2) {
                        EnhancementMode.document   => EnhancementSettings.document,
                        EnhancementMode.photo      => EnhancementSettings.photo,
                        EnhancementMode.whiteboard => EnhancementSettings.whiteboard,
                        _                          => const EnhancementSettings(),
                      };
                      setState(() => _settings = preset);
                      await _applySettings();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppTheme.md),

          // Sliders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
            child: Column(
              children: [
                _SliderRow(
                  label: 'Contrast',
                  value: _settings.contrast,
                  min: 0.5, max: 3.0,
                  onChanged: (v) => setState(() =>
                    _settings = _settings.copyWith(contrast: v)),
                  onChangeEnd: (_) => _applySettings(),
                ),
                _SliderRow(
                  label: 'Brightness',
                  value: _settings.brightness,
                  min: -0.5, max: 0.5,
                  onChanged: (v) => setState(() =>
                    _settings = _settings.copyWith(brightness: v)),
                  onChangeEnd: (_) => _applySettings(),
                ),
                _SliderRow(
                  label: 'Sharpness',
                  value: _settings.sharpness,
                  min: 0.0, max: 1.0,
                  onChanged: (v) => setState(() =>
                    _settings = _settings.copyWith(sharpness: v)),
                  onChangeEnd: (_) => _applySettings(),
                ),
                SwitchListTile(
                  title: const Text('Shadow Removal', style: TextStyle(fontSize: 14)),
                  value: _settings.shadowRemoval,
                  onChanged: (v) async {
                    setState(() => _settings = _settings.copyWith(shadowRemoval: v));
                    await _applySettings();
                  },
                  activeThumbColor: AppTheme.primary,
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Denoise', style: TextStyle(fontSize: 14)),
                  value: _settings.denoise,
                  onChanged: (v) async {
                    setState(() => _settings = _settings.copyWith(denoise: v));
                    await _applySettings();
                  },
                  activeThumbColor: AppTheme.primary,
                  dense: true,
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min, max: max,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
