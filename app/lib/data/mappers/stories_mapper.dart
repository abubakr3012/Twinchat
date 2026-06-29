import '../../domain/entities/story.dart';
import '../models/stories_dto.dart';

extension StoryViewerDtoX on StoryViewerDto {
  StoryViewer toDomain() => StoryViewer(
        id: id,
        viewerId: viewerId,
        username: username,
        viewedAt: viewedAt,
      );
}

extension StoryDtoX on StoryDto {
  Story toDomain() => Story(
        id: id,
        userId: userId,
        username: username,
        mediaUrl: mediaUrl,
        mediaType: storyMediaTypeFromString(mediaType),
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewsCount: viewsCount,
        isExpired: isExpired,
      );
}