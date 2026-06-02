import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/models/scan_document.dart';
import '../../shared/widgets/app_widgets.dart';
import '../scanner/scanner_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  final _tabs = const [
    _HomeTab(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('DocScan', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Scan Card
                    _QuickScanCard(),
                    const SizedBox(height: 24),
                    // Recent
                    if (state.recentDocuments.isNotEmpty) ...[
                      const Text('Recent',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.recentDocuments.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) =>
                              _RecentCard(doc: state.recentDocuments[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Stats Row
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          label: 'Total Scans',
                          value: state.documents.length.toString(),
                          icon: Icons.description_outlined,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          label: 'Storage Used',
                          value: _formatSize(state.storageBytes),
                          icon: Icons.storage_outlined,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _QuickScanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ready to Scan',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tap to capture a document',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final ScanDocument doc;
  const _RecentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(child: Icon(Icons.description_outlined, size: 36, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(doc.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}
