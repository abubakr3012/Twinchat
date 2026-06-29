import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/repositories/auth_repository.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(repository: GetIt.I<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegister(
            username: _username.text.trim(),
            email: _email.text.trim(),
            phoneNumber: _phone.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthAuthenticated || curr is AuthFailureState,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/chats');
            } else if (state is AuthFailureState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is AuthVerifying;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Создать аккаунт',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return 'Не менее 3 символов';
                        }
                        return null;
                      },
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Введите email';
                        }
                        if (!v.contains('@')) return 'Некорректный email';
                        return null;
                      },
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        hintText: '+998 90 123 45 67',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length < 7) return 'Введите корректный номер';
                        return null;
                      },
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Не менее 6 символов';
                        }
                        return null;
                      },
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password2,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Повторите пароль',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v == _password.text ? null : 'Пароли не совпадают',
                      enabled: !loading,
                      onFieldSubmitted: (_) => _submit(context),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : () => _submit(context),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: loading ? null : () => context.go('/login'),
                      child: const Text('Уже есть аккаунт'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}