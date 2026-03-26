import 'package:hive/hive.dart';

part 'download_item.g.dart';

/// Status of a download task
enum DownloadStatus { queued, downloading, paused, completed, failed }

/// Stores a single downloaded or in-progress file in the local Hive DB.
@HiveType(typeId: 0)
class DownloadItem extends HiveObject {
  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String sourceUrl; // original social media URL

  @HiveField(3)
  final String downloadUrl; // direct CDN URL

  @HiveField(4)
  final String platform; // e.g. youtube, tiktok

  @HiveField(5)
  final String? thumbnail;

  @HiveField(6)
  final String quality; // e.g. 1080p, audio-only

  @HiveField(7)
  final String ext; // mp4 / m4a / webm

  @HiveField(8)
  String? filePath; // Set when download completes

  @HiveField(9)
  int statusIndex; // DownloadStatus index

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  double progress; // 0.0 → 1.0

  @HiveField(12)
  int? filesize;

  DownloadItem({
    required this.taskId,
    required this.title,
    required this.sourceUrl,
    required this.downloadUrl,
    required this.platform,
    this.thumbnail,
    required this.quality,
    required this.ext,
    this.filePath,
    this.statusIndex = 0,
    required this.createdAt,
    this.progress = 0,
    this.filesize,
  });

  DownloadStatus get status => DownloadStatus.values[statusIndex];
  set status(DownloadStatus s) => statusIndex = s.index;

  bool get isVideo => ext != 'm4a' && ext != 'mp3' && ext != 'ogg' && ext != 'opus';
}
