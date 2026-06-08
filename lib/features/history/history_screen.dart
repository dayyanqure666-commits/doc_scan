import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/scan_document.dart';
import '../../core/services/app_state.dart';
import '../../shared/widgets/app_widgets.dart';
import '../preview/preview_screen.dart';
import '../../db/repositories/scan_repository.dart';

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
  List<ScanDocument>? _scans;
  bool _dbLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _dbLoading = true);
    try {
      final repository = ScanRepository();
      final docs = await repository.getAllScans();
      setState(() {
        _scans = docs;
        _dbLoading = false;
      });
    } catch (e) {
      setState(() => _dbLoading = false);
    }
  }

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
        final docs = _filtered(_scans ?? []);

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
                child: _dbLoading
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
                              return _HistoryScanCard(
                                doc: doc,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scan'),
        content: Text('Delete "${doc.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool dbRemoved = false;
    try {
      final repository = ScanRepository();
      await repository.deleteScan(doc.id);
      dbRemoved = true;
    } catch (e) {
      debugPrint('Error deleting scan from DB: $e');
    }

    if (dbRemoved) {
      setState(() {
        _scans?.removeWhere((d) => d.id == doc.id);
      });

      try {
        await state.deleteDocument(doc.id);
      } catch (e) {
        debugPrint('Error deleting files from disk: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${doc.name} deleted'),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete')),
        );
      }
    }
  }

  Future<void> _shareDocument(ScanDocument doc) async {
    final List<XFile> filesToShare = [];

    // Check PDF path
    if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
      final pdfFile = File(doc.pdfPath!);
      if (pdfFile.existsSync()) {
        filesToShare.add(XFile(doc.pdfPath!));
      }
    }

    // Check Image path
    String? imagePath = doc.thumbnailPath;
    if ((imagePath == null || imagePath.isEmpty) && doc.pages.isNotEmpty) {
      final firstPage = doc.pages.first;
      imagePath = firstPage.processedImagePath.isNotEmpty
          ? firstPage.processedImagePath
          : firstPage.originalImagePath;
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final imgFile = File(imagePath);
      if (imgFile.existsSync()) {
        filesToShare.add(XFile(imagePath));
      }
    }

    if (filesToShare.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: filesToShare,
          text: doc.name,
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to share')),
        );
      }
    }
  }
}

class _HistoryScanCard extends StatelessWidget {
  final ScanDocument doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _HistoryScanCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 72,
              child: doc.thumbnailPath != null && doc.thumbnailPath!.isNotEmpty
                  ? Image.file(
                      File(doc.thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${doc.pageCount} page${doc.pageCount != 1 ? 's' : ''}  •  ${_formatSize(doc.fileSizeBytes)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  _formatDate(doc.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: onShare,
                tooltip: 'Share',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.description_outlined, color: Colors.grey),
      );

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
