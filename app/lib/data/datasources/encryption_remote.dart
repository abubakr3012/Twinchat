import 'package:dio/dio.dart';

import '../models/encryption_dto.dart';

class EncryptionRemote {
  EncryptionRemote(this._dio);
  final Dio _dio;

  Future<SafeModeStatusDto> status() async {
    final res = await _dio.get<Map<String, dynamic>>('encryption/status/');
    return SafeModeStatusDto.fromJson(res.data ?? const {});
  }

  Future<SafeModeStatusDto> enable({
    required String encryptedKey,
    required String keyFingerprint,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'encryption/enable/',
      data: {
        'encrypted_key': encryptedKey,
        'key_fingerprint': keyFingerprint,
      },
    );
    return SafeModeStatusDto.fromJson(res.data ?? const {});
  }

  Future<void> disable() async {
    await _dio.post('encryption/disable/');
  }

  Future<List<SafeModeKeyShareDto>> shares() async {
    final res = await _dio.get<List<dynamic>>('encryption/shares/');
    return (res.data ?? const <dynamic>[])
        .map((e) => SafeModeKeyShareDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SafeModeKeyShareDto> share({
    required int sharedWithUserId,
    required String method,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'encryption/shares/',
      data: {'shared_with': sharedWithUserId, 'method': method},
    );
    return SafeModeKeyShareDto.fromJson(res.data ?? const {});
  }

  Future<void> revoke(int shareId) async {
    await _dio.post('encryption/shares/$shareId/revoke/');
  }

  Future<SafeModeUIDto> uiState() async {
    final res = await _dio.get<Map<String, dynamic>>('encryption/ui/');
    return SafeModeUIDto.fromJson(res.data ?? const {});
  }

  Future<SafeModeUIDto> updateUiState(SafeModeUIDto dto) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'encryption/ui/',
      data: dto.toJson(),
    );
    return SafeModeUIDto.fromJson(res.data ?? const {});
  }
}
