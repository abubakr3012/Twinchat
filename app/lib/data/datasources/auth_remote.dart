import 'package:dio/dio.dart';

import '../models/auth_dto.dart';

/// Удалённый источник данных для аутентификации.
/// Использует уже сконфигурированный Dio-клиент (с интерцепторами).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PhoneCodeRequestDto> requestPhoneCode(String phoneNumber) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'users/phone/request-code/',
      data: {'phone_number': phoneNumber},
    );
    return PhoneCodeRequestDto.fromJson(res.data ?? const {});
  }

  Future<AuthSessionDto> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'users/phone/verify/',
      data: {'phone_number': phoneNumber, 'code': code},
    );
    return AuthSessionDto.fromJson(res.data ?? const {});
  }

  /// Вход по username + password.
  Future<AuthSessionDto> login({
    required String username,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'users/login/',
      data: {'username': username, 'password': password},
    );
    return AuthSessionDto.fromJson(res.data ?? const {});
  }

  /// Регистрация по username + email + phone + password.
  Future<AuthSessionDto> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'users/register/',
      data: {
        'username': username,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      },
    );
    return AuthSessionDto.fromJson(res.data ?? const {});
  }

  /// Обновление пары токенов по refresh.
  /// NOTE: эндпоинт из ТЗ (/api/users/token/refresh/) сейчас не проброшен
  /// в конфигурации Django (urls.py), поэтому используем SimpleJWT — клиент
  /// просто сделает POST на api/token/refresh/. Если бэкенд пробросит — поменяем путь.
  Future<AuthSessionDto> refreshToken(String refresh) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'auth/token/refresh/',
      data: {'refresh': refresh},
    );
    final data = res.data ?? const {};
    final access = data['access'] as String?;
    if (access == null || access.isEmpty) {
      throw Exception('Server did not return access token');
    }
    return AuthSessionDto(
      access: access,
      refresh: (data['refresh'] as String?) ?? refresh,
      isNewUser: false,
    );
  }
}
