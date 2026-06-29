import 'package:equatable/equatable.dart';

/// Доменная сущность вложения к сообщению.
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.contentType,
    this.sizeBytes,
    this.width,
    this.height,
    this.durationSeconds,
    this.thumbnailUrl,
  });

  final int id;
  final String url;
  final String fileName;
  final String contentType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [
        id,
        url,
        fileName,
        contentType,
        sizeBytes,
        width,
        height,
        durationSeconds,
        thumbnailUrl,
      ];
}
