import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// SMS-вход: пользователь нажал «Получить код».
class AuthRequestCode extends AuthEvent {
  const AuthRequestCode(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

/// SMS-вход: пользователь ввёл код.
class AuthVerifyCode extends AuthEvent {
  const AuthVerifyCode({required this.phoneNumber, required this.code});
  final String phoneNumber;
  final String code;

  @override
  List<Object?> get props => [phoneNumber, code];
}

/// Вход по username + password.
class AuthLogin extends AuthEvent {
  const AuthLogin({required this.username, required this.password});
  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

/// Регистрация нового аккаунта.
class AuthRegister extends AuthEvent {
  const AuthRegister({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });
  final String username;
  final String email;
  final String phoneNumber;
  final String password;

  @override
  List<Object?> get props => [username, email, phoneNumber, password];
}

/// Выход из аккаунта.
class AuthLogout extends AuthEvent {
  const AuthLogout();
}

/// Сброс ошибки (например, при возврате к экрану).
class AuthReset extends AuthEvent {
  const AuthReset();
}
