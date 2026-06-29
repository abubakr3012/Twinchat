import 'dart:io';

import 'package:dio/dio.dart';

import '../models/stories_dto.dart';

class StoriesRemote {
  StoriesRemote(this._dio);
  final Dio _dio;

  Future<List<StoryDto>> feed() async {
    final res = await _dio.get<List<dynamic>>('stories/');
    return (res.data ?? const <dynamic>[])
        .map((e) => StoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoryDto>> myStories() async {
    final res = await _dio.get<List<dynamic>>('stories/my/');
    return (res.data ?? const <dynamic>[])
        .map((e) => StoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryDto> detail(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('stories/$id/');
    return StoryDto.fromJson(res.data ?? const {});
  }

  Future<List<StoryViewerDto>> viewers(int id) async {
    final res = await _dio.get<List<dynamic>>('stories/$id/viewers/');
    return (res.data ?? const <dynamic>[])
        .map((e) => StoryViewerDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryDto> upload({
    required File file,
    required String mediaType,
    String? caption,
  }) async {
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path),
      'media_type': mediaType,
      if (caption != null) 'caption': caption,
    });
    final res = await _dio.post<Map<String, dynamic>>(
      'stories/',
      data: form,
    );
    return StoryDto.fromJson(res.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _dio.delete('stories/$id/');
  }
}
