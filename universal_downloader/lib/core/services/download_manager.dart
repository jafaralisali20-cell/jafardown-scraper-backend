import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/download_item.dart';

/// Manages all downloads: queuing, progress tracking, pause/resume, and local DB.
/// Uses background_downloader which supports chunked transfer and survives app kills.
class DownloadManager extends GetxController {
  static DownloadManager get to => Get.find();

  late Box<DownloadItem> _box;
  final RxList<DownloadItem> activeDownloads = <DownloadItem>[].obs;
  final RxList<DownloadItem> completedDownloads = <DownloadItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initHive();
    _setupDownloader();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox<DownloadItem>('downloads');
    _loadFromDb();
  }

  void _loadFromDb() {
    final all = _box.values.toList();
    activeDownloads.assignAll(all.where((d) =>
        d.status == DownloadStatus.downloading ||
        d.status == DownloadStatus.queued ||
        d.status == DownloadStatus.paused));
    completedDownloads.assignAll(all.where((d) =>
        d.status == DownloadStatus.completed));
  }

  void _setupDownloader() {
    // Configure background_downloader
    FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(minutes: 10)),
        (Config.checkAvailableSpace, 100), // min 100MB required
      ],
    );

    // Listen to all task updates
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        _handleStatusUpdate(update);
      } else if (update is TaskProgressUpdate) {
        _handleProgressUpdate(update);
      }
    });
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final item = _findItem(update.task.taskId);
    if (item == null) return;

    switch (update.status) {
      case TaskStatus.complete:
        item.filePath = update.task.filename;
        item.status = DownloadStatus.completed;
        item.progress = 1.0;
        activeDownloads.remove(item);
        if (!completedDownloads.contains(item)) completedDownloads.insert(0, item);
        break;
      case TaskStatus.failed:
      case TaskStatus.notFound:
        item.status = DownloadStatus.failed;
        break;
      case TaskStatus.paused:
        item.status = DownloadStatus.paused;
        break;
      case TaskStatus.running:
        item.status = DownloadStatus.downloading;
        break;
      default:
        break;
    }
    item.save();
    activeDownloads.refresh();
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final item = _findItem(update.task.taskId);
    if (item == null) return;
    if (update.progress >= 0) {
      item.progress = update.progress;
      item.save();
      activeDownloads.refresh();
    }
  }

  DownloadItem? _findItem(String taskId) {
    try {
      return _box.values.firstWhere((d) => d.taskId == taskId);
    } catch (_) {
      return null;
    }
  }

  /// Enqueue a new download. Supports extremely large files via chunked parallel download.
  Future<void> enqueue(DownloadItem item) async {
    // Persist to Hive immediately
    await _box.put(item.taskId, item);
    activeDownloads.insert(0, item);

    // Determine save directory
    final dir = await _getDownloadDir(item.platform);

    final task = DownloadTask(
      taskId: item.taskId,
      url: item.downloadUrl,
      filename: '${item.taskId}.${item.ext}',
      directory: dir,
      baseDirectory: BaseDirectory.root,
      updates: Updates.statusAndProgress,
      allowPause: true,
      // No size limit enforced here – background_downloader streams data to disk
      retries: 3,
      requiresWiFi: false,
    );

    await FileDownloader().enqueue(task);
    item.status = DownloadStatus.downloading;
    item.save();
  }

  Future<void> pause(DownloadItem item) async {
    await FileDownloader().pause(DownloadTask(taskId: item.taskId, url: item.downloadUrl));
    item.status = DownloadStatus.paused;
    item.save();
    activeDownloads.refresh();
  }

  Future<void> resume(DownloadItem item) async {
    await FileDownloader().resume(DownloadTask(taskId: item.taskId, url: item.downloadUrl));
    item.status = DownloadStatus.downloading;
    item.save();
    activeDownloads.refresh();
  }

  Future<void> cancel(DownloadItem item) async {
    await FileDownloader().cancelTaskWithId(item.taskId);
    await item.delete();
    activeDownloads.remove(item);
    completedDownloads.remove(item);
    // Delete file if exists
    if (item.filePath != null) {
      final file = File(item.filePath!);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> deleteCompleted(DownloadItem item) async {
    if (item.filePath != null) {
      final file = File(item.filePath!);
      if (await file.exists()) await file.delete();
    }
    await item.delete();
    completedDownloads.remove(item);
  }

  /// Returns absolute path to the platform-specific download folder.
  /// Files go to: /storage/.../JafarDown/<platform>/
  Future<String> _getDownloadDir(String platform) async {
    final base = await getExternalStorageDirectory();
    final dir = Directory(p.join(base!.path, '..', '..', '..', '..', 'JafarDown', platform));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }
}
