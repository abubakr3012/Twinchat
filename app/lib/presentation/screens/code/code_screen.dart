import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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
      // Без номера возвращаемся назад.
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

  void _pasteFromClipboard(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final data = await Clipboard.getData('text/plain');
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
    // Запускаем автозаполнение после первого кадра.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutofill());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Введите код'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/phone'),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthAuthenticated || curr is AuthFailureState || curr is AuthCodeSent,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/chats');
              return;
            }
            if (state is AuthCodeSent) {
              // Повторно отправили код — показываем SnackBar и обновим автозаполнение.
              _autoFillDone = false;
              _maybeAutofill();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Код отправлен повторно на ${state.phoneNumber}')),
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
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Код отправлен на ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 44,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _onChanged(i, v, context),
                          enabled: !isVerifying,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (isVerifying)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Вставить'),
                          onPressed: () => _pasteFromClipboard(context),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Отправить заново'),
                          onPressed: () => _resend(context),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}