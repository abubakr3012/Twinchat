import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_constants.dart';

/// Интерцептор, который автоматически добавляет `Authorization: Bearer <jwt>`
/// ко всем исходящим запросам.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const _tokenKey = 'jwt_access';
  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Фабрика Dio-клиента с интерцепторами и базовыми таймаутами.
class DioClient {
  DioClient._(this.dio);

  static DioClient create({
    required FlutterSecureStorage storage,
    required void Function(String message) onError,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(AuthInterceptor(storage));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          onError(_describe(e));
          handler.next(e);
        },
      ),
    );

    return DioClient._(dio);
  }

  final Dio dio;

  static String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Нет соединения с сервером';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'Сессия истекла, войдите снова';
        if (code == 403) return 'Доступ запрещён';
        if (code != null && code >= 500) return 'Ошибка сервера ($code)';
        return 'Ошибка запроса ($code)';
      case DioExceptionType.cancel:
        return 'Запрос отменён';
      case DioExceptionType.connectionError:
        return 'Нет подключения к интернету';
      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата';
      case DioExceptionType.unknown:
        return 'Неизвестная ошибка сети';
    }
  }
}
