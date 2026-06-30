import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:twinchat/core/error/failure.dart';
import 'package:twinchat/domain/entities/user.dart';
import 'package:twinchat/domain/repositories/auth_repository.dart';
import 'package:twinchat/presentation/blocs/auth/auth_bloc.dart';
import 'package:twinchat/presentation/blocs/auth/auth_event.dart';
import 'package:twinchat/presentation/blocs/auth/auth_state.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
  });

  AuthSession makeSession() => const AuthSession(
        access: 'a',
        refresh: 'r',
        isNewUser: false,
      );

  group('AuthBloc.login', () {
    test('при пустых полях сразу эмитит AuthFailureState', () async {
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthLogin(username: '', password: ''));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s is AuthFailureState && s.message == 'Введите логин и пароль'),
        ]),
      );
      await bloc.close();
      verifyNever(() => repo.login(username: any(named: 'username'), password: any(named: 'password')));
    });

    test('успешный login → AuthVerifying → AuthAuthenticated', () async {
      when(() => repo.login(username: 'alice', password: 'secret123'))
          .thenAnswer((_) async => makeSession());
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthLogin(username: 'alice', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthVerifying>(),
          isA<AuthAuthenticated>(),
        ]),
      );
      await bloc.close();
    });

    test('сетевая ошибка → AuthFailureState с сообщением', () async {
      when(() => repo.login(username: 'alice', password: 'secret123'))
          .thenThrow(const ServerFailure('Сервер недоступен'));
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthLogin(username: 'alice', password: 'secret123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthVerifying>(),
          predicate<AuthState>((s) => s is AuthFailureState && s.message == 'Сервер недоступен'),
        ]),
      );
      await bloc.close();
    });
  });

  group('AuthBloc.requestCode', () {
    test('короткий номер → AuthFailureState, репозиторий не вызывается', () async {
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthRequestCode('123'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s is AuthFailureState && s.message.contains('корректный')),
        ]),
      );
      await bloc.close();
      verifyNever(() => repo.requestPhoneCode(any()));
    });

    test('валидный номер → AuthRequestingCode → AuthCodeSent', () async {
      when(() => repo.requestPhoneCode('+79991234567')).thenAnswer(
        (_) async => const PhoneCodeRequestResult(
          phoneNumber: '+79991234567',
          sent: true,
          debugCode: '123456',
        ),
      );
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthRequestCode('+79991234567'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthRequestingCode>(),
          predicate<AuthState>((s) =>
              s is AuthCodeSent &&
              s.phoneNumber == '+79991234567' &&
              s.debugCode == '123456'),
        ]),
      );
      await bloc.close();
    });
  });

  group('AuthBloc.verifyCode', () {
    test('короткий код → AuthFailureState', () async {
      final bloc = AuthBloc(repository: repo);
      bloc.add(
        const AuthVerifyCode(phoneNumber: '+79991234567', code: '12'),
      );
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s is AuthFailureState && s.message == 'Код слишком короткий'),
        ]),
      );
      await bloc.close();
    });
  });

  group('AuthBloc.logout', () {
    test('logout очищает токены и возвращает AuthInitial', () async {
      when(() => repo.logout()).thenAnswer((_) async {});
      final bloc = AuthBloc(repository: repo);
      bloc.add(const AuthLogout());
      await expectLater(
        bloc.stream,
        emits(isA<AuthInitial>()),
      );
      await bloc.close();
      verify(() => repo.logout()).called(1);
    });
  });
}