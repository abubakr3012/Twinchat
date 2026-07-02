/// Базовые URL бэкенда TwinChat.
class ApiConstants {
  ApiConstants._();

  /// Web: localhost; Android-эмулятор: 10.0.2.2; Physical device: IP компьютера.
  static const String baseUrl = 'https://abubakr.softclub.win/api/';

  static String get wsBase => 'wss://abubakr.softclub.win/ws/chat/';

  static String chatSocket(int chatId) => '$wsBase$chatId/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  /// Относительные пути из API (без слэша в конце).
  static const String refreshTokenPath = 'auth/token/refresh/';
}
