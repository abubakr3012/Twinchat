import 'dart:io';

import 'package:dio/dio.dart';

import '../models/attachments_dto.dart';

class AttachmentsRemote {
  AttachmentsRemote(this._dio);
  final Dio _dio;

  Future<AttachmentDto> upload({
    required File file,
    int? messageId,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (messageId != null) 'message': messageId.toString(),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      'attachments/upload/',
      data: form,
    );
    return AttachmentDto.fromJson(res.data ?? const {});
  }

  Future<List<AttachmentDto>> listForMessage(int messageId) async {
    final res = await _dio.get<List<dynamic>>(
      'attachments/',
      queryParameters: {'message': messageId},
    );
    return (res.data ?? const <dynamic>[])
        .map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(int id) async {
    await _dio.delete('attachments/$id/');
  }
}
