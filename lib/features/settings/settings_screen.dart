import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/scan_document.dart';
import '../../core/services/app_state.dart';
import '../../core/services/storage_service.dart';
import '../../auth/auth_service.dart';
import '../../models/user_model.dart';
import '../../screens/login_screen.dart';
import '../../shared/theme/app_theme.dart';

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
              const _AccountSection(),
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

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final user = snapshot.data;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        if (user != null) {
          // Logged in
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader('Account'),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  user.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Logged in'),
                trailing: TextButton(
                  onPressed: () => _handleLogout(context),
                  child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          );
        } else {
          // Guest mode
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader('Account'),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                  child: Icon(Icons.person_outline, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                title: const Text(
                  'Guest User',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Sync disabled'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
}
