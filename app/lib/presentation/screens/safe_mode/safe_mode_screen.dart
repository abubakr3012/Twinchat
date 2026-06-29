import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/repositories/encryption_repository.dart';
import '../../blocs/safe_mode/safe_mode_bloc.dart';

class SafeModeScreen extends StatelessWidget {
  const SafeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SafeModeBloc>(
      create: (_) => SafeModeBloc(repository: GetIt.I<EncryptionRepository>())
        ..add(const SafeModeLoad()),
      child: const _SafeModeView(),
    );
  }
}

class _SafeModeView extends StatefulWidget {
  const _SafeModeView();

  @override
  State<_SafeModeView> createState() => _SafeModeViewState();
}

class _SafeModeViewState extends State<_SafeModeView> {
  final _keyController = TextEditingController();
  final _autoLockController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _autoLockController.dispose();
    super.dispose();
  }

  String _fingerprint(String s) =>
      s.length >= 8 ? s.substring(0, 8) : s.padRight(8, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: BlocConsumer<SafeModeBloc, SafeModeState>(
        listenWhen: (a, b) => b is SafeModeReady && b.error != null,
        listener: (context, state) {
          if (state is SafeModeReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is SafeModeInitial || state is SafeModeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as SafeModeReady;
          _autoLockController.text = ready.ui.autoLockMinutes.toString();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Safe Mode'),
                subtitle: Text(ready.status.isActive
                    ? 'Включён'
                    : 'Выключен'),
                value: ready.status.isActive,
                onChanged: (v) {
                  if (v) {
                    _showEnableDialog(context);
                  } else {
                    context.read<SafeModeBloc>().add(const SafeModeDisable());
                  }
                },
              ),
              if (ready.status.isActive && ready.status.fingerprint != null)
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Fingerprint ключа'),
                  subtitle: Text(ready.status.fingerprint!),
                ),
              const SizedBox(height: 12),
              if (ready.status.isActive) ...[
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Введите ключ для разблокировки',
                    prefixIcon: Icon(Icons.key),
                  ),
                  onSubmitted: (v) {
                    context.read<SafeModeBloc>().add(SafeModeUpdateUi(
                          keyEntered: v.isNotEmpty,
                          autoLockMinutes: ready.ui.autoLockMinutes,
                        ));
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _autoLockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Автоблокировка (минуты)',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  onSubmitted: (v) {
                    final mins = int.tryParse(v) ?? 10;
                    context.read<SafeModeBloc>().add(SafeModeUpdateUi(
                          keyEntered: ready.ui.keyEntered,
                          autoLockMinutes: mins,
                        ));
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const _SectionTitle('Журнал передачи ключей'),
                if (ready.shares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Пока никому не передавался'),
                  )
                else
                  ...ready.shares.map(
                    (s) => ListTile(
                      leading: Icon(_methodIcon(s.method)),
                      title: Text('${s.sharedWithUsername} (${s.method})'),
                      subtitle: Text(s.isRevoked
                          ? 'Отозвано'
                          : (s.sharedAt?.toLocal().toString() ?? '')),
                      trailing: IconButton(
                        icon: const Icon(Icons.block_outlined),
                        onPressed: s.isRevoked
                            ? null
                            : () => context
                                .read<SafeModeBloc>()
                                .add(SafeModeRevoke(s.id)),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  IconData _methodIcon(String m) {
    switch (m) {
      case 'qr':
        return Icons.qr_code_2;
      case 'copy':
        return Icons.copy;
      case 'link':
        return Icons.link;
      case 'nfc':
        return Icons.nfc;
      default:
        return Icons.share;
    }
  }

  void _showEnableDialog(BuildContext context) {
    final keyCtl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dctx) {
        return AlertDialog(
          title: const Text('Включить Safe Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Создайте ключ (любая строка). Сервер сохранит только его fingerprint.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ключ'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final raw = keyCtl.text.trim();
                if (raw.isEmpty) return;
                final fp = _fingerprint(raw);
                context.read<SafeModeBloc>().add(SafeModeEnable(
                      encryptedKey: raw,
                      fingerprint: fp,
                    ));
                Navigator.of(dctx).pop();
              },
              child: const Text('Включить'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
    );
  }
}