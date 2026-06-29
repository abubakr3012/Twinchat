import 'dart:io';

import '../../core/api/api_helpers.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/stories_repository.dart';
import '../datasources/stories_remote.dart';
import '../mappers/stories_mapper.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  StoriesRepositoryImpl(this._remote, {required this.baseUrl});

  final StoriesRemote _remote;
  final String baseUrl;

  String _abs(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final origin = originFromBaseUrl(baseUrl);
    if (url.startsWith('/')) return '$origin$url';
    return '$origin/$url';
  }

  @override
  Future<List<Story>> feed() async {
    final dtos = await _remote.feed();
    return dtos
        .map((d) => d.toDomain().copyWithMediaUrl(_abs(d.mediaUrl)))
        .toList();
  }

  @override
  Future<List<Story>> myStories() async {
    final dtos = await _remote.myStories();
    return dtos
        .map((d) => d.toDomain().copyWithMediaUrl(_abs(d.mediaUrl)))
        .toList();
  }

  @override
  Future<Story> detail(int id) async {
    final dto = await _remote.detail(id);
    return dto.toDomain().copyWithMediaUrl(_abs(dto.mediaUrl));
  }

  @override
  Future<List<StoryViewer>> viewers(int id) async {
    final dtos = await _remote.viewers(id);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<CreateStoryResult> upload({
    required File file,
    required String mediaType,
    String? caption,
  }) async {
    final dto = await _remote.upload(
      file: file,
      mediaType: mediaType,
      caption: caption,
    );
    return CreateStoryResult(
      id: dto.id,
      mediaUrl: _abs(dto.mediaUrl),
    );
  }

  @override
  Future<void> delete(int id) => _remote.delete(id);
}

extension on Story {
  Story copyWithMediaUrl(String url) => Story(
        id: id,
        userId: userId,
        username: username,
        mediaUrl: url,
        mediaType: mediaType,
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewsCount: viewsCount,
        isExpired: isExpired,
      );
}