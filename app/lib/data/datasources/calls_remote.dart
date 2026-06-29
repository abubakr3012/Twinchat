import 'package:dio/dio.dart';

import '../models/calls_dto.dart';

class CallsRemote {
  CallsRemote(this._dio);
  final Dio _dio;

  Future<List<CallDto>> list() async {
    final res = await _dio.get<List<dynamic>>('calls/');
    return (res.data ?? const <dynamic>[])
        .map((e) => CallDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CallDto> getById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('calls/$id/');
    return CallDto.fromJson(res.data ?? const {});
  }

  Future<CallDto> create({required int chatId, required String callType}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'calls/',
      data: {'chat': chatId, 'call_type': callType},
    );
    return CallDto.fromJson(res.data ?? const {});
  }

  Future<void> accept(int id) => _dio.post('calls/$id/accept/');
  Future<void> reject(int id) => _dio.post('calls/$id/reject/');
  Future<void> end(int id) => _dio.post('calls/$id/end/');
  Future<void> leave(int id) => _dio.post('calls/$id/leave/');
}
