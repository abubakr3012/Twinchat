/// Базовые URL бэкенда TwinChat.
class ApiConstants {
  ApiConstants._();

  /// Подключение с физического устройства по USB (используется `adb reverse tcp:8000 tcp:8000`).
  /// Для Android-эмулятора замените на `http://10.0.2.2:8000/api/`.
  /// Для физического устройства используйте IP-адрес компьютера в локальной сети.
  static const String baseUrl = 'http://10.0.2.2:8000/api/';

  static String get wsBase => 'ws://10.0.2.2:8000/ws/chat/';

  static String chatSocket(int chatId) => '$wsBase$chatId/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  /// Относительные пути из API (без слэша в конце).
  static const String refreshTokenPath = 'auth/token/refresh/';
}
