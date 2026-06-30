class AttachmentDto {
  AttachmentDto({
    required this.id,
    required this.url,
    required this.fileName,
    required this.contentType,
    this.sizeBytes,
    this.width,
    this.height,
    this.durationSeconds,
    this.thumbnailUrl,
    this.messageId,
  });

  factory AttachmentDto.fromJson(Map<String, dynamic> json) => AttachmentDto(
        id: (json['id'] as num).toInt(),
        url: json['file_url'] as String? ?? 
            json['file'] as String? ?? 
            json['url'] as String? ?? '',
        fileName: json['file_name'] as String? ??
            json['name'] as String? ??
            'file',
        contentType: json['content_type'] as String? ??
            json['mime_type'] as String? ??
            'application/octet-stream',
        sizeBytes: (json['size'] as num?)?.toInt() ??
            (json['size_bytes'] as num?)?.toInt() ??
            (json['file_size'] as num?)?.toInt(),
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ??
            (json['duration'] as num?)?.toInt(),
        thumbnailUrl: json['thumbnail'] as String?,
        messageId: (json['message'] as num?)?.toInt(),
      );

  final int id;
  final String url;
  final String fileName;
  final String contentType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final int? messageId;
}
