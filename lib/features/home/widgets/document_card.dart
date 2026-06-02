// lib/features/home/widgets/document_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/models/scan_document.dart';
import '../../../shared/theme/app_theme.dart';

class DocumentCard extends StatelessWidget {
  final ScanDocument document;
  final VoidCallback? onDelete;

  const DocumentCard({required this.document, this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(document.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          color: AppTheme.error,
          borderRadius: AppTheme.radiusMd,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: AppTheme.radiusMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/document', arguments: document),
          borderRadius: AppTheme.radiusMd,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: AppTheme.radiusSm,
                  child: _buildThumbnail(),
                ),
                const SizedBox(width: AppTheme.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.pageCount} ${document.pageCount == 1 ? "page" : "pages"} · ${document.formattedSize}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy').format(document.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  color: AppTheme.primary,
                  onPressed: () => _sharePdf(context),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildThumbnail() {
    if (document.thumbnailPath != null) {
      final file = File(document.thumbnailPath!);
      if (file.existsSync()) {
        return Image.file(file, width: 52, height: 64, fit: BoxFit.cover);
      }
    }
    return Container(
      width: 52,
      height: 64,
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary, size: 28),
    );
  }

  void _sharePdf(BuildContext context) {
    // Share action implemented in export service
    Navigator.of(context).pushNamed('/export', arguments: document);
  }
}

// ── Recent Card ──────────────────────────────────────────────────────────
// lib/features/home/widgets/recent_card.dart

class RecentCard extends StatelessWidget {
  final ScanDocument document;

  const RecentCard({required this.document, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/document', arguments: document),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: _buildThumb(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                document.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildThumb() {
    if (document.thumbnailPath != null) {
      final f = File(document.thumbnailPath!);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover, width: double.infinity);
      }
    }
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary, size: 32),
      ),
    );
  }
}
