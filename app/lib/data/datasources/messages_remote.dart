import 'package:dio/dio.dart';

import '../models/messages_dto.dart';

class MessagesRemote {
  MessagesRemote(this._dio);
  final Dio _dio;

  Future<List<MessageDto>> listForChat(int chatId) async {
    final res = await _dio.get<List<dynamic>>('messages/chat/$chatId/');
    return (res.data ?? const <dynamic>[])
        .map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageDto> send({
    required int chatId,
    required String content,
    required String messageType,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'messages/chat/$chatId/',
      data: {
        'chat': chatId,
        'content': content,
        'message_type': messageType,
      },
    );
    return MessageDto.fromJson(res.data ?? const {});
  }

  Future<MessageDto> edit({
    required int id,
    required String content,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'messages/$id/',
      data: {'content': content},
    );
    return MessageDto.fromJson(res.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _dio.delete('messages/$id/');
  }
}
