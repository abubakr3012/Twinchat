import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

/// Состояние экрана аутентификации по SMS-коду.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Начальное состояние: пользователь только открыл экран ввода номера.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Идёт запрос кода (спиннер на кнопке «Получить код»).
class AuthRequestingCode extends AuthState {
  const AuthRequestingCode();
}

/// Код отправлен, можно переходить к вводу кода.
class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.phoneNumber, this.debugCode});

  final String phoneNumber;
  final String? debugCode;

  @override
  List<Object?> get props => [phoneNumber, debugCode];
}

/// Идёт проверка кода (спиннер на кнопке «Подтвердить»).
class AuthVerifying extends AuthState {
  const AuthVerifying();
}

/// Успешный вход — переход на /chats.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

/// Ошибка: неверный номер, неверный код, нет сети и т.п.
class AuthFailureState extends AuthState {
  const AuthFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}