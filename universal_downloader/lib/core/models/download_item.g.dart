// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a manual implementation of the Hive TypeAdapter for DownloadItem.

part of 'download_item.dart';

class DownloadItemAdapter extends TypeAdapter<DownloadItem> {
  @override
  final int typeId = 0;

  @override
  DownloadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadItem(
      taskId: fields[0] as String,
      title: fields[1] as String,
      sourceUrl: fields[2] as String,
      downloadUrl: fields[3] as String,
      platform: fields[4] as String,
      thumbnail: fields[5] as String?,
      quality: fields[6] as String,
      ext: fields[7] as String,
      filePath: fields[8] as String?,
      statusIndex: fields[9] as int,
      createdAt: fields[10] as DateTime,
      progress: fields[11] as double,
      filesize: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sourceUrl)
      ..writeByte(3)
      ..write(obj.downloadUrl)
      ..writeByte(4)
      ..write(obj.platform)
      ..writeByte(5)
      ..write(obj.thumbnail)
      ..writeByte(6)
      ..write(obj.quality)
      ..writeByte(7)
      ..write(obj.ext)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.statusIndex)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.progress)
      ..writeByte(12)
      ..write(obj.filesize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
