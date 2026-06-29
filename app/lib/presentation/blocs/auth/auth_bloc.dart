import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc координирует все варианты аутентификации:
/// SMS (request-code → verify), username+password (login), регистрацию.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthRequestCode>(_onRequestCode);
    on<AuthVerifyCode>(_onVerifyCode);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthReset>(_onReset);
  }

  final AuthRepository _repository;

  Future<void> _onRequestCode(
    AuthRequestCode event,
    Emitter<AuthState> emit,
  ) async {
    final phone = event.phoneNumber.trim();
    if (phone.length < 7) {
      emit(const AuthFailureState('Введите корректный номер телефона'));
      return;
    }
    emit(const AuthRequestingCode());
    await _run(
      () => _repository.requestPhoneCode(phone),
      onSuccess: (result) => AuthCodeSent(
        phoneNumber: result.phoneNumber,
        debugCode: result.debugCode,
      ),
      emit: emit,
    );
  }

  Future<void> _onVerifyCode(
    AuthVerifyCode event,
    Emitter<AuthState> emit,
  ) async {
    final code = event.code.trim();
    if (code.length < 4) {
      emit(const AuthFailureState('Код слишком короткий'));
      return;
    }
    emit(const AuthVerifying());
    await _run(
      () => _repository.verifyPhoneCode(
        phoneNumber: event.phoneNumber,
        code: code,
      ),
      onSuccess: (session) => AuthAuthenticated(session),
      emit: emit,
    );
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    final username = event.username.trim();
    final password = event.password;
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthFailureState('Введите логин и пароль'));
      return;
    }
    emit(const AuthVerifying());
    await _run(
      () => _repository.login(username: username, password: password),
      onSuccess: (session) => AuthAuthenticated(session),
      emit: emit,
    );
  }

  Future<void> _onRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    final username = event.username.trim();
    final email = event.email.trim();
    final phone = event.phoneNumber.trim();
    final password = event.password;
    if (username.length < 3) {
      emit(const AuthFailureState('Логин должен быть не короче 3 символов'));
      return;
    }
    if (password.length < 6) {
      emit(const AuthFailureState('Пароль должен быть не короче 6 символов'));
      return;
    }
    if (phone.length < 7) {
      emit(const AuthFailureState('Введите корректный номер телефона'));
      return;
    }
    emit(const AuthVerifying());
    await _run(
      () => _repository.register(
        username: username,
        email: email,
        phoneNumber: phone,
        password: password,
      ),
      onSuccess: (session) => AuthAuthenticated(session),
      emit: emit,
    );
  }

  Future<void> _onLogout(AuthLogout _, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthInitial());
  }

  void _onReset(AuthReset _, Emitter<AuthState> emit) {
    emit(const AuthInitial());
  }

  /// Запустить запрос с приведением ошибок к AuthFailureState.
  Future<void> _run<T>(
    Future<T> Function() body, {
    required AuthState Function(T) onSuccess,
    required Emitter<AuthState> emit,
  }) async {
    try {
      final result = await body();
      emit(onSuccess(result));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      emit(AuthFailureState(msg));
    } catch (e) {
      emit(AuthFailureState('Неизвестная ошибка: $e'));
    }
  }

  /// Достаём человеко-читаемое сообщение из ответа сервера (поле detail).
  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (data is Map) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }
    return 'Не удалось выполнить запрос';
  }
}
