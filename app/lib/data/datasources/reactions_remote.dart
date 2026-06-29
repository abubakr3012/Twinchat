import 'package:dio/dio.dart';

import '../models/reactions_dto.dart';

class ReactionsRemote {
  ReactionsRemote(this._dio);
  final Dio _dio;

  Future<List<ReactionDto>> listForMessage(int messageId) async {
    final res = await _dio.get<List<dynamic>>(
      'reactions/',
      queryParameters: {'message': messageId},
    );
    return (res.data ?? const <dynamic>[])
        .map((e) => ReactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReactionDto> add({required int messageId, required String emoji}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'reactions/',
      data: {'message': messageId, 'emoji': emoji},
    );
    return ReactionDto.fromJson(res.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _dio.delete('reactions/$id/');
  }
}
