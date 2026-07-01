import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/text_size_provider.dart';
import '../../../core/utils/theme_mode_provider.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../blocs/settings/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (_) => SettingsBloc(repository: GetIt.I<SettingsRepository>())
        ..add(const SettingsLoad()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (a, b) => b is SettingsReady && b.error != null,
        listener: (context, state) {
          if (state is SettingsReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial || state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as SettingsReady;
          // Sync textSize to global provider
          TextSizeProvider.instance.textSize = ready.chat.textSize;
          // Sync theme to global provider
          ThemeModeProvider.instance.setFromSettings(ready.chat.theme);
          return ListView(
            children: [
              const _SectionTitle('Чат'),
              ListTile(
                title: const Text('Тема'),
                subtitle: Text(_themeLabel(ready.chat.theme)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final choice = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('Тема'),
                      children: [
                        for (final v in const ['light', 'dark', 'system'])
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(v),
                            child: Text(_themeLabel(v)),
                          ),
                      ],
                    ),
                  );
                  if (choice != null && context.mounted) {
                    context.read<SettingsBloc>().add(SettingsUpdateChat(
                          ready.chat.copyWith(theme: choice),
                        ));
                  }
                },
              ),
              ListTile(
                title: const Text('Размер текста'),
                subtitle: Text('${ready.chat.textSize}'),
                trailing: SizedBox(
                  width: 160,
                  child: Slider(
                    value: ready.chat.textSize.toDouble(),
                    min: 12,
                    max: 22,
                    divisions: 10,
                    label: '${ready.chat.textSize}',
                    onChanged: (v) {},
                    onChangeEnd: (v) =>
                        context.read<SettingsBloc>().add(SettingsUpdateChat(
                              ready.chat.copyWith(textSize: v.round()),
                            )),
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Уведомления'),
                value: ready.chat.notifications,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdateChat(
                          ready.chat.copyWith(notifications: v),
                        )),
              ),
              const Divider(),
              const _SectionTitle('Приватность'),
              _VisibilityTile(
                label: 'Кто видит номер телефона',
                value: ready.privacy.seePhoneNumber,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seePhoneNumber: v),
                        )),
              ),
              _VisibilityTile(
                label: 'Кто видит фото профиля',
                value: ready.privacy.seeProfilePhoto,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seeProfilePhoto: v),
                        )),
              ),
              _VisibilityTile(
                label: 'Кто видит «был в сети»',
                value: ready.privacy.seeLastSeen,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seeLastSeen: v),
                        )),
              ),
              SwitchListTile(
                title: const Text('Автоудаление сообщений'),
                value: ready.privacy.autoDeleteMessages,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(autoDeleteMessages: v),
                        )),
              ),
              ListTile(
                title: const Text('Срок хранения (дней)'),
                subtitle: Text('${ready.privacy.messageTtlDays}'),
              ),
              SwitchListTile(
                title: const Text('Двухфакторная аутентификация'),
                value: ready.privacy.twoFactorAuth,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(twoFactorAuth: v),
                        )),
              ),
              const Divider(),
              const _SectionTitle('Язык'),
              ListTile(
                title: const Text('Язык интерфейса'),
                subtitle: Text(ready.language.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final lang = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('Язык'),
                      children: [
                        for (final l in const ['ru', 'en', 'uz'])
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(l),
                            child: Text(l),
                          ),
                      ],
                    ),
                  );
                  if (lang != null && context.mounted) {
                    context.read<SettingsBloc>().add(SettingsUpdateLanguage(
                          ready.language.copyWith(language: lang),
                        ));
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Автоперевод входящих'),
                value: ready.language.autoTranslate,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdateLanguage(
                          ready.language.copyWith(autoTranslate: v),
                        )),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Safe Mode'),
                subtitle: const Text('Шифрование сообщений и медиа'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/safe-mode'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Мой профиль'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/my-profile'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Выйти', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await GetIt.I<AuthRepository>().logout();
                  if (!context.mounted) return;
                  context.go('/phone');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static String _themeLabel(String v) {
    switch (v) {
      case 'light':
        return 'Светлая';
      case 'dark':
        return 'Тёмная';
      case 'system':
      default:
        return 'Как в системе';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  String _label(String v) {
    switch (v) {
      case 'everyone':
        return 'Все';
      case 'nobody':
        return 'Никто';
      case 'contacts':
      default:
        return 'Контакты';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(_label(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final v = await showDialog<String>(
          context: context,
          builder: (_) => SimpleDialog(
            title: Text(label),
            children: [
              for (final opt in const ['everyone', 'contacts', 'nobody'])
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(opt),
                  child: Text(_label(opt)),
                ),
            ],
          ),
        );
        if (v != null) onChanged(v);
      },
    );
  }
}