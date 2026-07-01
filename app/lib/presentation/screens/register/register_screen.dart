import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
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
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
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
                            Icons.forum_rounded,
                            color: scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.createAccount,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.registrationHint,
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username
                          _buildTextField(
                            controller: _username,
                            label: l10n.username,
                            hint: 'twinchat_user',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().length < 3) {
                                return l10n.min3Chars;
                              }
                              return null;
                            },
                            enabled: !loading,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            controller: _email,
                            label: l10n.email,
                            hint: 'example@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n.enterEmail;
                              }
                              if (!v.contains('@')) return l10n.invalidEmail;
                              return null;
                            },
                            enabled: !loading,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          _buildTextField(
                            controller: _phone,
                            label: l10n.phone,
                            hint: l10n.phoneHint,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s\(\)]'),
                              ),
                            ],
                            validator: (v) {
                              final digits =
                                  (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 7) {
                                return l10n.invalidNumber;
                              }
                              return null;
                            },
                            enabled: !loading,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildTextField(
                            controller: _password,
                            label: l10n.password,
                            hint: l10n.min6Chars,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return l10n.min6Chars;
                              }
                              return null;
                            },
                            enabled: !loading,
                          ),
                          const SizedBox(height: 16),

                          // Confirm password
                          _buildTextField(
                            controller: _password2,
                            label: l10n.repeatPassword,
                            hint: l10n.repeatPassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword2,
                            textInputAction: TextInputAction.done,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword2
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword2 = !_obscurePassword2),
                            ),
                            validator: (v) =>
                                v == _password.text ? null : l10n.passwordsNoMatch,
                            onFieldSubmitted: (_) => _submit(context),
                            enabled: !loading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Button & Footer ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: loading ? null : () => _submit(context),
                            child: loading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : Text(
                                    l10n.registerButton,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${l10n.hasAccount} ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  loading ? null : () => context.go('/login'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.login,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 22),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
    );
  }
}
