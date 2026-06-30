import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Колбэк, вызываемый когда refresh окончательно провалился.
/// Приложение должно очистить состояние и перенаправить на экран логина.
typedef OnAuthFailure = Future<void> Function();

/// Интерцептор, который автоматически обновляет access-токен по refresh-токену
/// при получении 401, и повторяет исходный запрос.
///
/// Особенности:
/// - Защищён от зацикливания (флаг `_refreshing`).
/// - Не пытается refresh'ить запросы на сам `/auth/token/refresh/` или login/register.
/// - При провале refresh вызывает [onAuthFailure] и помечает оригинальную ошибку.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    required OnAuthFailure onAuthFailure,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio,
        _onAuthFailure = onAuthFailure;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final OnAuthFailure _onAuthFailure;

  /// Защита от зацикливания: пока true, повторные 401 не запускают новый refresh.
  bool _refreshing = false;

  /// Очередь ожидающих запросов на время refresh.
  final List<Completer<String?>> _waiters = <Completer<String?>>[];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccess();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Не refresh-им запросы на сам refresh и аутентификацию.
    final isAuthEndpoint = path.contains('token/refresh') ||
        path.contains('users/login') ||
        path.contains('users/register') ||
        path.contains('users/phone/');

    if (status != 401 || isAuthEndpoint || err.requestOptions.extra['retry'] == true) {
      return handler.next(err);
    }

    final newAccess = await _ensureRefreshed();
    if (newAccess == null) {
      await _onAuthFailure();
      return handler.next(err);
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['retry'] = true;

      final response = await _refreshDio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<String?> _ensureRefreshed() async {
    if (_refreshing) {
      final completer = Completer<String?>();
      _waiters.add(completer);
      return completer.future;
    }
    _refreshing = true;

    try {
      final refresh = await _tokenStorage.readRefresh();
      if (refresh == null || refresh.isEmpty) {
        _failAll(null);
        return null;
      }
      try {
        final response = await _refreshDio.post<Map<String, dynamic>>(
          'auth/token/refresh/',
          data: {'refresh': refresh},
        );
        final data = response.data ?? const <String, dynamic>{};
        final newAccess = data['access'] as String?;
        if (newAccess == null || newAccess.isEmpty) {
          _failAll(null);
          return null;
        }
        await _tokenStorage.saveAccess(newAccess);
        // Если сервер выдал новый refresh — заменим (ротация токенов).
        final newRefresh = data['refresh'] as String?;
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _tokenStorage.saveTokens(
            access: newAccess,
            refresh: newRefresh,
          );
        }
        _resolveAll(newAccess);
        return newAccess;
      } on DioException {
        await _tokenStorage.clear();
        _failAll(null);
        return null;
      }
    } finally {
      _refreshing = false;
    }
  }

  void _resolveAll(String token) {
    for (final w in _waiters) {
      if (!w.isCompleted) w.complete(token);
    }
    _waiters.clear();
  }

  void _failAll(Object? error) {
    for (final w in _waiters) {
      if (!w.isCompleted) w.complete(null);
    }
    _waiters.clear();
  }
}