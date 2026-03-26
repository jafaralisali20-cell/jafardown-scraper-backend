import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/download_item.dart';
import '../../core/services/download_manager.dart';
import '../../core/theme/app_theme.dart';
import '../player/player_screen.dart';

/// Shows all completed downloaded media files (videos + audio).
/// Supports multi-select, delete, share, and tapping to play in the internal player.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final Set<String> _selected = {};
  bool _multiSelect = false;

  void _toggleSelect(DownloadItem item) {
    setState(() {
      if (_selected.contains(item.taskId)) {
        _selected.remove(item.taskId);
        if (_selected.isEmpty) _multiSelect = false;
      } else {
        _selected.add(item.taskId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final dm = DownloadManager.to;
    final toDelete = dm.completedDownloads
        .where((d) => _selected.contains(d.taskId))
        .toList();
    for (final item in toDelete) {
      await dm.deleteCompleted(item);
    }
    setState(() {
      _selected.clear();
      _multiSelect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _multiSelect ? 'تم تحديد ${_selected.length}' : 'مكتبتي',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          actions: _multiSelect
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorColor),
                    onPressed: _deleteSelected,
                    tooltip: 'حذف المحدد',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selected.clear();
                      _multiSelect = false;
                    }),
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    onPressed: () => setState(() => _multiSelect = true),
                    tooltip: 'تحديد متعدد',
                  ),
                ],
        ),
        body: Obx(() {
          final items = DownloadManager.to.completedDownloads;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.video_library_outlined, size: 72, color: AppTheme.surfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'مكتبتك فارغة\nحمّل شيئاً الآن!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isSelected = _selected.contains(item.taskId);
              return GestureDetector(
                onTap: () {
                  if (_multiSelect) {
                    _toggleSelect(item);
                  } else {
                    // Open internal player
                    Get.to(() => PlayerScreen(item: item));
                  }
                },
                onLongPress: () {
                  setState(() => _multiSelect = true);
                  _toggleSelect(item);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                    color: AppTheme.cardColor,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail or placeholder
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: _thumbnail(item),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.platform} • ${item.quality}',
                                  style: GoogleFonts.tajawal(fontSize: 10, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Selected overlay
                      if (isSelected)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                      // Play icon on video
                      if (!_multiSelect && item.isVideo)
                        Positioned(
                          top: 0, left: 0, right: 0, bottom: 40,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _thumbnail(DownloadItem item) {
    if (item.thumbnail != null && item.thumbnail!.isNotEmpty) {
      return Image.network(item.thumbnail!, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(item));
    }
    return _fallback(item);
  }

  Widget _fallback(DownloadItem item) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Center(
        child: Icon(
          item.isVideo ? Icons.movie_rounded : Icons.audiotrack_rounded,
          size: 48,
          color: item.isVideo ? AppTheme.primary : AppTheme.accent,
        ),
      ),
    );
  }
}
