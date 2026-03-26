/// Represents a single downloadable format (e.g., 1080p MP4, 360p MP4, audio-only M4A).
class MediaFormat {
  final String formatId;
  final String ext;
  final String resolution;
  final int? filesize;
  final String url;
  final String? vcodec;
  final String? acodec;
  final String quality;
  final double? fps;

  bool get isAudioOnly => vcodec == 'none' || vcodec == null || resolution == 'audio only';

  MediaFormat({
    required this.formatId,
    required this.ext,
    required this.resolution,
    this.filesize,
    required this.url,
    this.vcodec,
    this.acodec,
    required this.quality,
    this.fps,
  });

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    return MediaFormat(
      formatId: json['format_id']?.toString() ?? '',
      ext: json['ext']?.toString() ?? 'mp4',
      resolution: json['resolution']?.toString() ?? 'غير معروف',
      filesize: json['filesize'] as int?,
      url: json['url']?.toString() ?? '',
      vcodec: json['vcodec']?.toString(),
      acodec: json['acodec']?.toString(),
      quality: json['quality']?.toString() ?? 'غير معروف',
      fps: (json['fps'] as num?)?.toDouble(),
    );
  }

  /// Human-friendly label shown in quality dialog
  String get label {
    if (isAudioOnly) return 'صوت فقط • ${ext.toUpperCase()}';
    return '$quality • ${ext.toUpperCase()}';
  }

  String get filesizeLabel {
    if (filesize == null) return '';
    if (filesize! > 1024 * 1024 * 1024) {
      return '${(filesize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (filesize! > 1024 * 1024) {
      return '${(filesize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(filesize! / 1024).toStringAsFixed(0)} KB';
  }
}

/// Full media info returned by the backend for a given URL.
class MediaInfoModel {
  final String id;
  final String title;
  final String? thumbnail;
  final int? duration;
  final String extractor; // e.g. "youtube", "tiktok"
  final List<MediaFormat> formats;

  MediaInfoModel({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    required this.extractor,
    required this.formats,
  });

  factory MediaInfoModel.fromJson(Map<String, dynamic> json) {
    final rawFormats = (json['formats'] as List<dynamic>?) ?? [];
    return MediaInfoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'بدون عنوان',
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] as int?,
      extractor: json['extractor']?.toString() ?? 'unknown',
      formats: rawFormats
          .map((f) => MediaFormat.fromJson(f as Map<String, dynamic>))
          .where((f) => f.url.isNotEmpty)
          .toList(),
    );
  }

  String get platformName {
    switch (extractor.toLowerCase()) {
      case 'youtube': return 'يوتيوب';
      case 'instagram': return 'إنستغرام';
      case 'tiktok': return 'تيك توك';
      case 'facebook': return 'فيسبوك';
      case 'twitter': return 'تويتر';
      case 'pinterest': return 'بينتريست';
      case 'telegram': return 'تيليغرام';
      case 'snapchat': return 'سناب شات';
      default: return extractor;
    }
  }

  String get durationLabel {
    if (duration == null) return '';
    final d = Duration(seconds: duration!);
    if (d.inHours > 0) return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
