import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/scan_document.dart';
import '../../core/services/app_state.dart';
import '../../core/services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        final s = state.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              const _SectionHeader('Scanning'),
              _SwitchTile(
                title: 'Auto-Capture',
                subtitle: 'Automatically capture when document is stable',
                value: s.autoCapture,
                onChanged: (v) => state.updateSettings(s.copyWith(autoCapture: v)),
              ),
              _SwitchTile(
                title: 'Blur Detection',
                subtitle: 'Warn when image is blurry',
                value: s.blurDetection,
                onChanged: (v) => state.updateSettings(s.copyWith(blurDetection: v)),
              ),
              _SelectTile(
                title: 'Default Page Size',
                value: s.pageSize,
                options: const ['A4', 'Letter', 'A3', 'Legal'],
                onChanged: (v) => state.updateSettings(s.copyWith(pageSize: v)),
              ),
              const _SectionHeader('Preprocessing'),
              _SwitchTile(
                title: 'Auto Crop',
                subtitle: 'Automatically detect document edges',
                value: s.enableAutoCrop,
                onChanged: (v) => state.updateSettings(s.copyWith(enableAutoCrop: v)),
              ),
              _SwitchTile(
                title: 'Deskew',
                subtitle: 'Straighten perspective projection',
                value: s.enableDeskew,
                onChanged: (v) => state.updateSettings(s.copyWith(enableDeskew: v)),
              ),
              _SwitchTile(
                title: 'Noise Reduction',
                subtitle: 'Reduce image noise and artifacts',
                value: s.enableNoiseReduction,
                onChanged: (v) => state.updateSettings(s.copyWith(enableNoiseReduction: v)),
              ),
              _SwitchTile(
                title: 'Contrast Enhancement',
                subtitle: 'Improve text readability and contrast',
                value: s.enableContrastEnhancement,
                onChanged: (v) => state.updateSettings(s.copyWith(enableContrastEnhancement: v)),
              ),
              _SwitchTile(
                title: 'Sharpening',
                subtitle: 'Sharpen text and fine details',
                value: s.enableSharpening,
                onChanged: (v) => state.updateSettings(s.copyWith(enableSharpening: v)),
              ),
              _SwitchTile(
                title: 'Background Cleanup',
                subtitle: 'Remove shadows and normalize background',
                value: s.enableBackgroundCleanup,
                onChanged: (v) => state.updateSettings(s.copyWith(enableBackgroundCleanup: v)),
              ),
              _SwitchTile(
                title: 'Grayscale',
                subtitle: 'Convert processed images to grayscale',
                value: s.enableGrayscale,
                onChanged: (v) => state.updateSettings(s.copyWith(enableGrayscale: v)),
              ),
              _SwitchTile(
                title: 'Thresholding',
                subtitle: 'Binarize images for sharp text contrast',
                value: s.enableThresholding,
                onChanged: (v) => state.updateSettings(s.copyWith(enableThresholding: v)),
              ),
              const _SectionHeader('Enhancement'),
              _SelectTile(
                title: 'Default Enhancement',
                value: s.defaultEnhancement.name,
                options: EnhancementMode.values.map((e) => e.name).toList(),
                onChanged: (v) {
                  final mode = EnhancementMode.values
                      .firstWhere((e) => e.name == v);
                  state.updateSettings(s.copyWith(defaultEnhancement: mode));
                },
              ),
              const _SectionHeader('Export'),
              _SelectTile(
                title: 'Default Quality',
                value: s.defaultQuality.name,
                options: ExportQuality.values.map((e) => e.name).toList(),
                onChanged: (v) {
                  final q = ExportQuality.values.firstWhere((e) => e.name == v);
                  state.updateSettings(s.copyWith(defaultQuality: q));
                },
              ),
              const _SectionHeader('Appearance'),
              _SwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark color scheme',
                value: s.darkMode,
                onChanged: (v) => state.updateSettings(s.copyWith(darkMode: v)),
              ),
              const _SectionHeader('Storage'),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Storage Used'),
                trailing: Text(
                  _formatSize(state.storageBytes),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Clear Cache'),
                onTap: () async {
                  await StorageService().clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Delete All Scans', style: TextStyle(color: Colors.red)),
                onTap: () => _confirmDeleteAll(context, state),
              ),
              const _SectionHeader('About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
              const ListTile(
                leading: Icon(Icons.code_outlined),
                title: Text('Built with Flutter'),
                trailing: Icon(Icons.open_in_new, size: 16),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _confirmDeleteAll(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Scans'),
        content: const Text('This will permanently delete all scans. Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final doc in state.documents.toList()) {
                await state.deleteDocument(doc.id);
              }
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }
}
