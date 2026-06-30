import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';
import 'refresh_interceptor.dart';

/// Интерцептор, который автоматически добавляет `Authorization: Bearer <jwt>`
/// ко всем исходящим запросам (читает access из [FlutterSecureStorage]).
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
  DioClient._({required this.dio, required this.refreshDio});

  /// Создать клиента.
  ///
  /// [tokenStorage] — для доступа к токенам.
  /// [onError] — клиентский логгер (ошибки 4xx/5xx, таймауты).
  /// [onAuthFailure] — вызывается, когда refresh окончательно провалился
  /// (токен отозван, истёк, refresh-токен тоже невалиден).
  static DioClient create({
    required FlutterSecureStorage storage,
    required TokenStorage tokenStorage,
    required void Function(String message) onError,
    required Future<void> Function() onAuthFailure,
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

    // Отдельный Dio-инстанс для refresh, чтобы не зациклиться.
    final refreshDio = Dio(
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
      RefreshTokenInterceptor(
        tokenStorage: tokenStorage,
        refreshDio: refreshDio,
        onAuthFailure: onAuthFailure,
      ),
    );
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

    return DioClient._(dio: dio, refreshDio: refreshDio);
  }

  final Dio dio;

  /// Dio для refresh — без auth/refresh интерцепторов.
  final Dio refreshDio;

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