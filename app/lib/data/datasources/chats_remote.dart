import 'package:dio/dio.dart';

import '../models/chats_dto.dart';

class ChatsRemote {
  ChatsRemote(this._dio);
  final Dio _dio;

  Future<List<ChatDto>> list() async {
    final res = await _dio.get<List<dynamic>>('chats/');
    return (res.data ?? const <dynamic>[])
        .map((e) => ChatDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatDto> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('chats/$id/');
    return ChatDto.fromJson(res.data ?? const {});
  }

  Future<ChatDto> create({required String type, String? name}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'chats/',
      data: {'type': type, 'name': name},
    );
    return ChatDto.fromJson(res.data ?? const {});
  }

  Future<ChatDto> addMember(
      {required int chatId, required int userId}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'chats/$chatId/members/',
      data: {'user_id': userId},
    );
    return ChatDto.fromJson(res.data ?? const {});
  }

  Future<ChatDto> updateGroup({
    required int chatId,
    String? name,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatar'] = avatarUrl;
    final res = await _dio.patch<Map<String, dynamic>>(
      'chats/$chatId/',
      data: body,
    );
    return ChatDto.fromJson(res.data ?? const {});
  }
}
