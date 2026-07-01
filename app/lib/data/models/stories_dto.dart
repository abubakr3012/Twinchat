class StoryViewerDto {
  StoryViewerDto({
    required this.id,
    required this.viewerId,
    required this.username,
    this.viewedAt,
  });

  factory StoryViewerDto.fromJson(Map<String, dynamic> json) => StoryViewerDto(
        id: (json['id'] as num).toInt(),
        viewerId: (json['viewer'] as num).toInt(),
        username: json['username'] as String? ?? '',
        viewedAt: json['viewed_at'] != null
            ? DateTime.tryParse(json['viewed_at'] as String)
            : null,
      );

  final int id;
  final int viewerId;
  final String username;
  final DateTime? viewedAt;
}

class StoryDto {
  StoryDto({
    required this.id,
    required this.userId,
    required this.username,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.createdAt,
    this.expiresAt,
    this.viewsCount = 0,
    this.isExpired = false,
  });

  factory StoryDto.fromJson(Map<String, dynamic> json) => StoryDto(
        id: (json['id'] as num).toInt(),
        userId: (json['user'] as num).toInt(),
        username: json['username'] as String? ?? '',
        // Prefer media_url (absolute) returned by backend; fall back to media
        mediaUrl: (json['media_url'] as String?)?.isNotEmpty == true
            ? json['media_url'] as String
            : (json['media'] as String? ?? ''),
        mediaType: json['media_type'] as String? ?? 'image',
        caption: json['caption'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
        isExpired: json['is_expired'] as bool? ?? false,
      );

  final int id;
  final int userId;
  final String username;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int viewsCount;
  final bool isExpired;
}
