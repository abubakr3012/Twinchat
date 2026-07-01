import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthCodeSent || curr is AuthFailureState,
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
            return CustomScrollView(
              slivers: [
                // ─── Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.go('/login'),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Logo mark
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary,
                                scheme.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.sms_rounded,
                            color: scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Вход по SMS',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Мы отправим SMS с кодом подтверждения на ваш номер',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Form ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Phone number input
                          TextFormField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s\(\)]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Номер телефона',
                              hintText: '+998 90 123 45 67',
                              prefixIcon:
                                  const Icon(Icons.phone_outlined, size: 22),
                              prefixText: '+',
                              prefixStyle: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            validator: _validate,
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _submit(context),
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed:
                                  isLoading ? null : () => _submit(context),
                              icon: isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                isLoading ? 'Отправка...' : 'Получить код',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login with password link
                          TextButton.icon(
                            onPressed: isLoading ? null : () => context.go('/login'),
                            icon: Icon(
                              Icons.key_outlined,
                              size: 20,
                              color: scheme.primary,
                            ),
                            label: Text(
                              'Войти по логину и паролю',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
