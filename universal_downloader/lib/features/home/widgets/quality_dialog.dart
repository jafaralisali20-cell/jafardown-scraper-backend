import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/download_item.dart';
import '../../../core/models/media_info_model.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_theme.dart';

/// Shows a bottom sheet with quality / format selection.
/// Returns the selected [MediaFormat] after enqueueing the download or null.
Future<MediaFormat?> showQualityDialog(BuildContext context, MediaInfoModel info) {
  return showModalBottomSheet<MediaFormat>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QualitySheet(info: info),
  );
}

class _QualitySheet extends StatefulWidget {
  final MediaInfoModel info;
  const _QualitySheet({required this.info});

  @override
  State<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends State<_QualitySheet> {
  String _filter = 'all'; // 'all' | 'video' | 'audio'
  bool _enqueueing = false;

  List<MediaFormat> get _filtered {
    final formats = widget.info.formats;
    if (_filter == 'video') return formats.where((f) => !f.isAudioOnly).toList();
    if (_filter == 'audio') return formats.where((f) => f.isAudioOnly).toList();
    return formats;
  }

  Future<void> _enqueue(MediaFormat fmt) async {
    setState(() => _enqueueing = true);
    final item = DownloadItem(
      taskId: const Uuid().v4(),
      title: widget.info.title,
      sourceUrl: '',
      downloadUrl: fmt.url,
      platform: widget.info.extractor,
      thumbnail: widget.info.thumbnail,
      quality: fmt.quality,
      ext: fmt.ext,
      createdAt: DateTime.now(),
      filesize: fmt.filesize,
    );
    await DownloadManager.to.enqueue(item);
    if (!mounted) return;
    setState(() => _enqueueing = false);
    Navigator.of(context).pop(fmt);
    Get.snackbar(
      'بدأ التنزيل ✓',
      widget.info.title,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Media info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (widget.info.thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.info.thumbnail!,
                        width: 80, height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.info.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.info.platformName,
                              style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.primary),
                            ),
                            if (widget.info.durationLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.timer, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                widget.info.durationLabel,
                                style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _chip('فيديو', 'video'),
                  const SizedBox(width: 8),
                  _chip('صوت فقط', 'audio'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Format list, max 60% height
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'لا توجد صيغ متاحة لهذا الفلتر',
                        style: GoogleFonts.tajawal(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.surfaceVariant),
                      itemBuilder: (ctx, i) {
                        final fmt = _filtered[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: fmt.isAudioOnly
                                  ? AppTheme.accent.withOpacity(0.15)
                                  : AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              fmt.isAudioOnly ? Icons.audiotrack : Icons.videocam,
                              color: fmt.isAudioOnly ? AppTheme.accent : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            fmt.label,
                            style: GoogleFonts.tajawal(fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          subtitle: fmt.filesizeLabel.isNotEmpty
                              ? Text(fmt.filesizeLabel, style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary))
                              : null,
                          trailing: _enqueueing
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download_rounded, color: AppTheme.primary),
                          onTap: _enqueueing ? null : () => _enqueue(fmt),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
