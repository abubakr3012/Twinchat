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

/// CodeScreen — экран ввода SMS-кода.
/// Принимает [phoneNumber] и опциональный [debugCode] (если сервер вернул).
class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key, this.phoneNumber, this.debugCode});

  final String? phoneNumber;
  final String? debugCode;

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    String? phone = phoneNumber;
    String? dbg = debugCode;
    if (extra is AuthCodeSent) {
      phone = extra.phoneNumber;
      dbg = extra.debugCode;
    }

    if (phone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/phone');
      });
    }

    return BlocProvider(
      create: (_) => AuthBloc(repository: GetIt.I<AuthRepository>()),
      child: _CodeView(phoneNumber: phone ?? '', debugCode: dbg),
    );
  }
}

class _CodeView extends StatefulWidget {
  const _CodeView({required this.phoneNumber, this.debugCode});

  final String phoneNumber;
  final String? debugCode;

  @override
  State<_CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<_CodeView> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _autoFillDone = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _maybeAutofill() {
    if (_autoFillDone) return;
    final dbg = widget.debugCode;
    if (dbg == null || dbg.length != 6) return;
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = dbg[i];
    }
    _autoFillDone = true;
    setState(() {});
  }

  void _onChanged(int index, String value, BuildContext context) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == 6) {
      context.read<AuthBloc>().add(
            AuthVerifyCode(
              phoneNumber: widget.phoneNumber,
              code: _code,
            ),
          );
    }
  }

  void _resend(BuildContext context) {
    context.read<AuthBloc>().add(AuthRequestCode(widget.phoneNumber));
  }

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final data = await Clipboard.getData('text/plain');
    if (!mounted) return;
    final text = (data?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length >= 4) {
      for (var i = 0; i < 6 && i < text.length; i++) {
        _controllers[i].text = text[i];
      }
      if (text.length >= 6) {
        bloc.add(
          AuthVerifyCode(
            phoneNumber: widget.phoneNumber,
            code: text.substring(0, 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutofill());

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthAuthenticated ||
              curr is AuthFailureState ||
              curr is AuthCodeSent,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/chats');
              return;
            }
            if (state is AuthCodeSent) {
              _autoFillDone = false;
              _maybeAutofill();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                        '${l10n.codeResentTo} ${state.phoneNumber}'),
                  ),
                );
              return;
            }
            if (state is AuthFailureState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final isVerifying = state is AuthVerifying;
            return CustomScrollView(
              slivers: [
                // ─── Header ──────────────────────────────────────
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
                            onPressed: () => context.go('/phone'),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Icon
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
                            Icons.pin_outlined,
                            color: scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.enterCode,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            text: '${l10n.codeSentTo} ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(
                                text: widget.phoneNumber,
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Code Input ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _controllers[i].text.isNotEmpty
                                  ? scheme.primaryContainer.withOpacity(0.3)
                                  : scheme.surfaceContainerHighest
                                      .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: scheme.primary,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _controllers[i].text.isNotEmpty
                                      ? scheme.primary.withOpacity(0.5)
                                      : scheme.outline.withOpacity(0.3),
                                ),
                              ),
                            ),
                            onChanged: (v) => _onChanged(i, v, context),
                            enabled: !isVerifying,
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ─── Actions ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        if (isVerifying)
                          Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: scheme.primary,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              // Paste button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () => _pasteFromClipboard(context),
                                  icon: Icon(
                                    Icons.content_paste_rounded,
                                    color: scheme.primary,
                                  ),
                                  label: Text(
                                    l10n.pasteFromClipboard,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: scheme.primary.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Resend button
                              TextButton.icon(
                                onPressed: () => _resend(context),
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                                label: Text(
                                  l10n.resendCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurfaceVariant,
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
}
