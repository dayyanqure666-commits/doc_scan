import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/scan_document.dart';
import '../../core/services/app_state.dart';
import '../../shared/widgets/app_widgets.dart';
import '../preview/preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _sortMode = 'date_desc';
  String _dateFilter = 'all';
  final _searchController = TextEditingController();

  List<ScanDocument> _filtered(List<ScanDocument> docs) {
    var result = docs.where((d) {
      if (_searchQuery.isNotEmpty &&
          !d.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_dateFilter != 'all') {
        final now = DateTime.now();
        final cutoff = switch (_dateFilter) {
          'today' => DateTime(now.year, now.month, now.day),
          'week'  => now.subtract(const Duration(days: 7)),
          'month' => now.subtract(const Duration(days: 30)),
          _       => DateTime(2000),
        };
        if (d.createdAt.isBefore(cutoff)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => switch (_sortMode) {
      'date_asc'  => a.createdAt.compareTo(b.createdAt),
      'name_asc'  => a.name.compareTo(b.name),
      'name_desc' => b.name.compareTo(a.name),
      'size_desc' => b.fileSizeBytes.compareTo(a.fileSizeBytes),
      _           => b.createdAt.compareTo(a.createdAt),
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        final docs = _filtered(state.documents);

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (v) => setState(() => _sortMode = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'date_desc', child: Text('Newest first')),
                  PopupMenuItem(value: 'date_asc', child: Text('Oldest first')),
                  PopupMenuItem(value: 'name_asc', child: Text('Name A–Z')),
                  PopupMenuItem(value: 'name_desc', child: Text('Name Z–A')),
                  PopupMenuItem(value: 'size_desc', child: Text('Largest first')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Date filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['all', 'today', 'week', 'month'].map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: _dateFilter == f,
                        onSelected: (_) => setState(() => _dateFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Document list
              Expanded(
                child: state.isLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (_, __) => const ShimmerListItem(),
                      )
                    : docs.isEmpty
                        ? EmptyState(
                            icon: Icons.description_outlined,
                            title: _searchQuery.isNotEmpty
                                ? 'No results'
                                : 'No scans yet',
                            subtitle: _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Start scanning your first document',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final doc = docs[i];
                              return ScanCard(
                                name: doc.name,
                                pageCount: doc.pageCount,
                                fileSizeBytes: doc.fileSizeBytes,
                                date: doc.createdAt,
                                thumbnailPath: doc.thumbnailPath,
                                onTap: () => _openDocument(context, doc),
                                onDelete: () => _deleteDocument(context, state, doc),
                                onShare: () => _shareDocument(doc),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDocument(BuildContext context, ScanDocument doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(document: doc)),
    );
  }

  Future<void> _deleteDocument(
      BuildContext context, AppStateProvider state, ScanDocument doc) async {
    await state.deleteDocument(doc.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.name} deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () {}),
        ),
      );
    }
  }

  void _shareDocument(ScanDocument doc) {
    if (doc.pdfPath != null) {
      // share_plus
    }
  }
}
