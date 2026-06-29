import 'package:equatable/equatable.dart';

/// Тип медиа у истории.
enum StoryMediaType { image, video, unknown }

StoryMediaType storyMediaTypeFromString(String? value) {
  switch (value) {
    case 'image':
      return StoryMediaType.image;
    case 'video':
      return StoryMediaType.video;
    default:
      return StoryMediaType.unknown;
  }
}

/// Доменная сущность истории.
class Story extends Equatable {
  const Story({
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

  final int id;
  final int userId;
  final String username;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final String? caption;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int viewsCount;
  final bool isExpired;

  /// Сколько секунд осталось до истечения.
  int get secondsLeft {
    final exp = expiresAt;
    if (exp == null) return 0;
    return exp.difference(DateTime.now()).inSeconds.clamp(0, 86400);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        mediaUrl,
        mediaType,
        caption,
        createdAt,
        expiresAt,
        viewsCount,
        isExpired,
      ];
}

/// Информация о просмотре истории.
class StoryViewer extends Equatable {
  const StoryViewer({
    required this.id,
    required this.viewerId,
    required this.username,
    this.viewedAt,
  });

  final int id;
  final int viewerId;
  final String username;
  final DateTime? viewedAt;

  @override
  List<Object?> get props => [id, viewerId, username, viewedAt];
}
