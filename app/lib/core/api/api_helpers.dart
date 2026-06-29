import 'package:dio/dio.dart';

/// Утилита для парсинга сообщения об ошибке из DRF-ответа.
///
/// Многие endpoints возвращают:
///   { "detail": "..." }
///   { "field_name": ["err1", "err2"] }
///   { "non_field_errors": ["..."] }
String extractErrorMessage(Object error, {String fallback = 'Ошибка запроса'}) {
  if (error is DioException) {
    final data = error.response?.data;
    return parseServerMessage(data) ?? _describeDio(error) ?? fallback;
  }
  return error.toString();
}

String? parseServerMessage(Object? data) {
  if (data is! Map) return null;
  if (data['detail'] is String) return data['detail'] as String;
  for (final entry in data.entries) {
    final v = entry.value;
    if (v is List && v.isNotEmpty) return v.first.toString();
    if (v is String) return v;
  }
  return null;
}

String? _describeDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Нет соединения с сервером';
    case DioExceptionType.connectionError:
      return 'Нет подключения к интернету';
    case DioExceptionType.badCertificate:
      return 'Ошибка сертификата';
    case DioExceptionType.cancel:
      return 'Запрос отменён';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) return 'Сессия истекла, войдите снова';
      if (code == 403) return 'Доступ запрещён';
      if (code == 404) return 'Не найдено';
      if (code != null && code >= 500) return 'Ошибка сервера ($code)';
      return null;
    case DioExceptionType.unknown:
      return null;
  }
}

/// Достаём host (origin) из baseUrl Dio — чтобы формировать абсолютные
/// ссылки на media (аватары, вложения, истории).
String originFromBaseUrl(String baseUrl) {
  final uri = Uri.parse(baseUrl);
  if (uri.hasScheme && uri.hasAuthority) {
    return '${uri.scheme}://${uri.authority}';
  }
  return baseUrl;
}
