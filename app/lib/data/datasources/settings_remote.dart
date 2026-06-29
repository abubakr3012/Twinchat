import 'package:dio/dio.dart';

import '../models/settings_dto.dart';

class SettingsRemote {
  SettingsRemote(this._dio);
  final Dio _dio;

  Future<ChatSettingsDto> getChat() async {
    final res = await _dio.get<Map<String, dynamic>>('settings/chat/');
    return ChatSettingsDto.fromJson(res.data ?? const {});
  }

  Future<ChatSettingsDto> updateChat(ChatSettingsDto dto) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'settings/chat/',
      data: dto.toJson(),
    );
    return ChatSettingsDto.fromJson(res.data ?? const {});
  }

  Future<PrivacyDto> getPrivacy() async {
    final res = await _dio.get<Map<String, dynamic>>('settings/privacy/');
    return PrivacyDto.fromJson(res.data ?? const {});
  }

  Future<PrivacyDto> updatePrivacy(PrivacyDto dto) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'settings/privacy/',
      data: dto.toJson(),
    );
    return PrivacyDto.fromJson(res.data ?? const {});
  }

  Future<LanguageDto> getLanguage() async {
    final res = await _dio.get<Map<String, dynamic>>('settings/language/');
    return LanguageDto.fromJson(res.data ?? const {});
  }

  Future<LanguageDto> updateLanguage(LanguageDto dto) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      'settings/language/',
      data: dto.toJson(),
    );
    return LanguageDto.fromJson(res.data ?? const {});
  }
}
