import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/download_item.dart';
import '../../core/services/download_manager.dart';
import '../../core/theme/app_theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('التنزيلات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'قيد التنزيل'),
                Tab(text: 'مكتمل'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ActiveDownloadsTab(),
              _CompletedDownloadsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active Downloads Tab ──

class _ActiveDownloadsTab extends StatelessWidget {
  final _dm = DownloadManager.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _dm.activeDownloads;
      if (items.isEmpty) {
        return _emptyState(Icons.download_rounded, 'لا توجد تنزيلات جارية');
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _ActiveDownloadCard(item: items[i]),
      );
    });
  }
}

class _ActiveDownloadCard extends StatelessWidget {
  final DownloadItem item;
  const _ActiveDownloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Platform icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.isVideo ? Icons.videocam_rounded : Icons.audiotrack_rounded,
                    color: item.isVideo ? AppTheme.primary : AppTheme.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${item.platform} • ${item.quality}',
                        style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Pause / Resume button
                Obx(() {
                  final status = item.status;
                  if (status == DownloadStatus.paused) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.accent),
                      onPressed: () => DownloadManager.to.resume(item),
                    );
                  }
                  return IconButton(
                    icon: const Icon(Icons.pause_rounded, color: AppTheme.textSecondary),
                    onPressed: () => DownloadManager.to.pause(item),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.errorColor),
                  onPressed: () => DownloadManager.to.cancel(item),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(
                      item.status == DownloadStatus.paused
                          ? AppTheme.textSecondary
                          : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusLabel(item.status),
                      style: GoogleFonts.tajawal(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${(item.progress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.tajawal(fontSize: 11, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.downloading: return 'يتم التنزيل...';
      case DownloadStatus.paused: return 'متوقف';
      case DownloadStatus.queued: return 'في الانتظار';
      default: return '';
    }
  }
}

// ── Completed Downloads Tab ──

class _CompletedDownloadsTab extends StatelessWidget {
  final _dm = DownloadManager.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _dm.completedDownloads;
      if (items.isEmpty) {
        return _emptyState(Icons.check_circle_outline, 'لا توجد تنزيلات مكتملة');
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _CompletedCard(item: items[i]),
      );
    });
  }
}

class _CompletedCard extends StatelessWidget {
  final DownloadItem item;
  const _CompletedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.isVideo ? Icons.videocam_rounded : Icons.audiotrack_rounded,
            color: AppTheme.successColor, size: 20,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.platform} • ${item.quality}',
          style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
          onPressed: () => DownloadManager.to.deleteCompleted(item),
        ),
      ),
    );
  }
}

Widget _emptyState(IconData icon, String text) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppTheme.surfaceVariant),
        const SizedBox(height: 16),
        Text(text, style: GoogleFonts.tajawal(color: AppTheme.textSecondary, fontSize: 16)),
      ],
    ),
  );
}
