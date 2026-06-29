/// Базовые URL бэкенда TwinChat.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://171.22.174.50/';

  static String get wsBase => 'ws://171.22.174.50/ws/chat/';

  static String chatSocket(int chatId) => '$wsBase$chatId/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
