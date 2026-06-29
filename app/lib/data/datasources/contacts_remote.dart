import 'package:dio/dio.dart';

import '../models/contacts_dto.dart';

class ContactsRemote {
  ContactsRemote(this._dio);
  final Dio _dio;

  Future<List<ContactDto>> list() async {
    final res = await _dio.get<List<dynamic>>('contacts/');
    return (res.data ?? const <dynamic>[])
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ContactDto>> blocked() async {
    final res = await _dio.get<List<dynamic>>('contacts/blocked/');
    return (res.data ?? const <dynamic>[])
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContactDto> add({required int contactId, String? nickname}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'contacts/',
      data: {'contact': contactId, 'nickname': nickname},
    );
    return ContactDto.fromJson(res.data ?? const {});
  }

  Future<ContactDto> update({required int id, String? nickname}) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'contacts/$id/',
      data: {'nickname': nickname},
    );
    return ContactDto.fromJson(res.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _dio.delete('contacts/$id/');
  }

  Future<void> block(int id) async {
    await _dio.post('contacts/$id/block/');
  }

  Future<void> unblock(int id) async {
    await _dio.post('contacts/$id/unblock/');
  }
}
