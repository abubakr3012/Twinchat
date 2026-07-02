import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/locale_provider.dart';
import '../../../core/utils/text_size_provider.dart';
import '../../../core/utils/theme_mode_provider.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../blocs/settings/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = SettingsBloc(repository: GetIt.I<SettingsRepository>())
      ..add(const SettingsLoad());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>.value(
      value: _bloc,
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (a, b) => b is SettingsReady,
        listener: (context, state) {
          if (state is SettingsReady) {
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
            // Sync providers in listener (not build) to avoid rebuild loops
            TextSizeProvider.instance.textSize = state.chat.textSize;
            ThemeModeProvider.instance.setFromSettings(state.chat.theme);
            LocaleProvider.instance.setFromSettings(state.language.language);
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial || state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as SettingsReady;
          return ListView(
            children: [
              // ─── Chat Section ──────────────────────────────────────
              _SectionTitle(l10n.chats),
              ListTile(
                title: Text(l10n.theme),
                subtitle: Text(_themeLabel(ready.chat.theme, l10n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final choice = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: Text(l10n.theme),
                      children: [
                        for (final v in const ['light', 'dark', 'system'])
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(v),
                            child: Text(_themeLabel(v, l10n)),
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
                title: Text(l10n.textSize),
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
                title: Text(l10n.notifications),
                value: ready.chat.notifications,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdateChat(
                          ready.chat.copyWith(notifications: v),
                        )),
              ),
              const Divider(),

              // ─── Privacy Section ───────────────────────────────────
              _SectionTitle(l10n.privacy),
              _VisibilityTile(
                label: l10n.seePhoneNumber,
                value: ready.privacy.seePhoneNumber,
                l10n: l10n,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seePhoneNumber: v),
                        )),
              ),
              _VisibilityTile(
                label: l10n.seeProfilePhoto,
                value: ready.privacy.seeProfilePhoto,
                l10n: l10n,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seeProfilePhoto: v),
                        )),
              ),
              _VisibilityTile(
                label: l10n.seeLastSeen,
                value: ready.privacy.seeLastSeen,
                l10n: l10n,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(seeLastSeen: v),
                        )),
              ),
              SwitchListTile(
                title: Text(l10n.autoDeleteMessages),
                value: ready.privacy.autoDeleteMessages,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(autoDeleteMessages: v),
                        )),
              ),
              ListTile(
                title: Text(l10n.storageDays),
                subtitle: Text('${ready.privacy.messageTtlDays}'),
              ),
              SwitchListTile(
                title: Text(l10n.twoFactorAuth),
                value: ready.privacy.twoFactorAuth,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdatePrivacy(
                          ready.privacy.copyWith(twoFactorAuth: v),
                        )),
              ),
              const Divider(),

              // ─── Language Section ──────────────────────────────────
              _SectionTitle(l10n.language),
              ListTile(
                title: Text(l10n.language),
                subtitle: Text(_langLabel(ready.language.language, l10n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final lang = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: Text(l10n.language),
                      children: [
                        for (final l in const ['ru', 'en', 'tg'])
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(l),
                            child: Text(_langLabel(l, l10n)),
                          ),
                      ],
                    ),
                  );
                  if (lang != null && context.mounted) {
                    context.read<SettingsBloc>().add(SettingsUpdateLanguage(
                          ready.language.copyWith(language: lang),
                        ));
                    // Apply locale change immediately
                    LocaleProvider.instance.setFromSettings(lang);
                  }
                },
              ),
              SwitchListTile(
                title: Text(l10n.autoTranslate),
                value: ready.language.autoTranslate,
                onChanged: (v) =>
                    context.read<SettingsBloc>().add(SettingsUpdateLanguage(
                          ready.language.copyWith(autoTranslate: v),
                        )),
              ),
              const Divider(),

              // ─── Links ─────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.safeMode),
                subtitle: const Text('E2E encryption'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/safe-mode'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.myProfile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/my-profile'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
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

  String _themeLabel(String v, AppLocalizations l10n) {
    switch (v) {
      case 'light':
        return l10n.lightTheme;
      case 'dark':
        return l10n.darkTheme;
      case 'system':
      default:
        return l10n.systemTheme;
    }
  }

  String _langLabel(String v, AppLocalizations l10n) {
    switch (v) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'tg':
        return 'Тоҷикӣ';
      default:
        return v;
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
    required this.l10n,
    required this.onChanged,
  });
  final String label;
  final String value;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  String _label(String v) {
    switch (v) {
      case 'everyone':
        return l10n.everyone;
      case 'nobody':
        return l10n.nobody;
      case 'contacts':
      default:
        return l10n.contactsOnly;
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
