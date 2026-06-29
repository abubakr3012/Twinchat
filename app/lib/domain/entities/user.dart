import 'package:equatable/equatable.dart';

/// Доменная сущность пользователя TwinChat.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.lastSeen,
    this.isOnline = false,
  });

  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final DateTime? lastSeen;
  final bool isOnline;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phoneNumber,
        avatarUrl,
        bio,
        lastSeen,
        isOnline,
      ];
}

/// Результат успешного SMS-входа: пара токенов + (если есть) пользователь.
class AuthSession extends Equatable {
  const AuthSession({
    required this.access,
    required this.refresh,
    required this.isNewUser,
    this.user,
  });

  final String access;
  final String refresh;
  final bool isNewUser;

  /// Может быть null, если сервер его не возвращает (старый /login).
  final User? user;

  @override
  List<Object?> get props => [access, refresh, isNewUser, user];
}

/// Ответ сервера на запрос кода.
class PhoneCodeRequestResult extends Equatable {
  const PhoneCodeRequestResult({
    required this.phoneNumber,
    this.sent = true,
    this.debugCode,
  });

  /// Нормализованный номер, вернувшийся с сервера.
  final String phoneNumber;

  /// Подтверждение отправки (на случай, если API возвращает его).
  final bool sent;

  /// В DEBUG-режиме сервер возвращает сам код (для удобства тестирования
  /// без подключённого SMS-шлюза). В проде всегда null.
  final String? debugCode;

  @override
  List<Object?> get props => [phoneNumber, sent, debugCode];
}
