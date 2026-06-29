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
}
