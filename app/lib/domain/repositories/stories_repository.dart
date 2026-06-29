import 'dart:io';

import '../entities/story.dart';

class CreateStoryResult {
  const CreateStoryResult({required this.id, required this.mediaUrl});
  final int id;
  final String mediaUrl;
}

abstract class StoriesRepository {
  /// Лента активных историй контактов.
  Future<List<Story>> feed();

  /// Истории текущего пользователя.
  Future<List<Story>> myStories();

  Future<Story> detail(int id);
  Future<List<StoryViewer>> viewers(int id);
  Future<CreateStoryResult> upload({
    required File file,
    required String mediaType, // 'image' | 'video'
    String? caption,
  });
  Future<void> delete(int id);
}
