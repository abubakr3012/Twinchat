import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/repositories/auth_repository.dart';

/// PhoneScreen — экран ввода номера телефона.
/// После ввода и нажатия «Получить код» переходит на /code.
class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(repository: GetIt.I<AuthRepository>()),
      child: const _PhoneView(),
    );
  }
}

class _PhoneView extends StatefulWidget {
  const _PhoneView();

  @override
  State<_PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<_PhoneView> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Введите номер телефона';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return 'Слишком короткий номер';
    if (digits.length > 15) return 'Слишком длинный номер';
    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final phone = _controller.text.trim();
    context.read<AuthBloc>().add(AuthRequestCode(phone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => curr is AuthCodeSent || curr is AuthFailureState,
          listener: (context, state) {
            if (state is AuthCodeSent) {
              context.go('/code', extra: state);
              return;
            }
            if (state is AuthFailureState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthRequestingCode;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Введите номер телефона',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Мы отправим SMS с кодом подтверждения.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Номер телефона',
                        hintText: '+998 90 123 45 67',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: _validate,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _submit(context),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Получить код'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/login'),
                      child: const Text('Войти по логину и паролю'),
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