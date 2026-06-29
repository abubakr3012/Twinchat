import '../entities/user.dart';

/// Контракт аутентификации. Реализация лежит в data/.
abstract class AuthRepository {
  /// POST /api/users/phone/request-code/
  /// Возвращает результат отправки кода; при DEBUG=true сервер пришлёт debugCode.
  Future<PhoneCodeRequestResult> requestPhoneCode(String phoneNumber);

  /// POST /api/users/phone/verify/ → {access, refresh, user, is_new_user}
  /// Сохраняет токены в [TokenStorage].
  Future<AuthSession> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  });

  /// POST /api/users/login/ → {access, refresh}
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  /// POST /api/users/register/ → {user, access, refresh}
  Future<AuthSession> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Выход: очищает локальные токены.
  Future<void> logout();

  /// Текущий сохранённый access-токен (или null).
  Future<String?> currentAccessToken();

  /// Уже залогинен?
  Future<bool> isAuthenticated();
}
