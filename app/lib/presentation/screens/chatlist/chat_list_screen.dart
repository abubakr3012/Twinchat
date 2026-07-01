import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/chat.dart';
import '../../../domain/entities/contact.dart';
import '../../../domain/entities/story.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/repositories/contacts_repository.dart';
import '../../../domain/repositories/stories_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/chat_list/chat_list_bloc.dart';
import '../../blocs/contacts/contacts_bloc.dart';
import '../../blocs/stories/stories_bloc.dart';

/// ChatListScreen — список чатов в стиле WhatsApp.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<ChatListBloc>(
      create: (_) => ChatListBloc(
        chatsRepository: GetIt.I<ChatsRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
      )..add(const ChatListLoad()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'TwinChat',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Поиск',
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    context.go('/my-profile');
                    break;
                  case 'settings':
                    context.go('/settings');
                    break;
                  case 'logout':
                    _showLogoutDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          color: scheme.onSurface, size: 22),
                      const SizedBox(width: 12),
                      const Text('Мой профиль'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined,
                          color: scheme.onSurface, size: 22),
                      const SizedBox(width: 12),
                      const Text('Настройки'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          color: scheme.error, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Выйти',
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: const [
            _ChatsTab(),
            _ContactsTab(),
            _StoriesTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts_rounded),
              label: 'Контакты',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Истории',
            ),
          ],
        ),
        floatingActionButton: _tab == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateChat(context),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text(
                  'Новый чат',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
            : (_tab == 1
                ? FloatingActionButton(
                    onPressed: () => context.go('/contacts'),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_rounded),
                  )
                : null),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              await GetIt.I<AuthRepository>().logout();
              if (!context.mounted) return;
              context.go('/phone');
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showCreateChat(BuildContext context) {
    final bloc = context.read<ChatListBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _CreateChatDialog(),
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) {
        if (state is ChatListLoading || state is ChatListInitial) {
          return Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
          );
        }
        if (state is ChatListFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<ChatListBloc>()
                        .add(const ChatListRefresh()),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        final ready = state as ChatListReady;
        if (ready.chats.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ChatListBloc>().add(const ChatListRefresh()),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Нет чатов',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите кнопку "Новый чат"\nчтобы начать общение',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ChatListBloc>().add(const ChatListRefresh());
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ready.chats.length,
            itemBuilder: (_, i) {
              final chat = ready.chats[i];
              final name = chat.displayName(ready.me.username);
              return _ChatListItem(
                chat: chat,
                name: name,
                onTap: () => context.go('/chat/${chat.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.name,
    required this.onTap,
  });

  final Chat chat;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _chatTypeLabel(chat.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Trailing
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _chatTypeLabel(ChatType t) {
    switch (t) {
      case ChatType.private:
        return 'Личный чат';
      case ChatType.group:
        return 'Групповой чат';
      case ChatType.unknown:
        return 'Чат';
    }
  }
}

class _CreateChatDialog extends StatefulWidget {
  const _CreateChatDialog();

  @override
  State<_CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<_CreateChatDialog> {
  final _name = TextEditingController();
  ChatType _type = ChatType.private;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<ChatListBloc>().add(
          ChatListCreate(
            type: _type,
            name: _type == ChatType.group ? _name.text.trim() : null,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Новый чат',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<ChatType>(
            segments: const [
              ButtonSegment(
                value: ChatType.private,
                label: Text('Личный'),
                icon: Icon(Icons.person_outline_rounded, size: 18),
              ),
              ButtonSegment(
                value: ChatType.group,
                label: Text('Группа'),
                icon: Icon(Icons.group_outlined, size: 18),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: scheme.primaryContainer,
              selectedForegroundColor: scheme.onPrimaryContainer,
            ),
          ),
          if (_type == ChatType.group) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Название группы',
                hintText: 'Моя группа',
                prefixIcon: const Icon(Icons.group_outlined, size: 22),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Сейчас сервер поддерживает создание чата одним участником. '
            'Добавление членов появится в следующей версии.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

// ─── Stub tabs ──────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<ContactsBloc>(
      create: (_) => ContactsBloc(
        contactsRepository: GetIt.I<ContactsRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
      )..add(const ContactsLoad()),
      child: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, state) {
          if (state is ContactsInitial || state is ContactsLoading) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }
          final ready = state as ContactsReady;
          if (ready.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.contacts_outlined, size: 64, color: scheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Контактов пока нет',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы добавить',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ContactsBloc>().add(const ContactsLoad()),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ready.contacts.length,
              itemBuilder: (_, i) {
                final c = ready.contacts[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      c.displayName.isEmpty
                          ? '?'
                          : c.displayName.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(c.displayName),
                  subtitle: Text('@${c.username}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/profile/${c.contactId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StoriesTab extends StatelessWidget {
  const _StoriesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider<StoriesBloc>(
      create: (_) => StoriesBloc(repository: GetIt.I<StoriesRepository>())
        ..add(const StoriesLoad()),
      child: BlocBuilder<StoriesBloc, StoriesState>(
        builder: (context, state) {
          if (state is StoriesInitial || state is StoriesLoading) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }
          final ready = state as StoriesReady;
          if (ready.feed.isEmpty && ready.myStories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_outlined, size: 64, color: scheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Историй пока нет',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Создайте первую историю',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          final allStories = [...ready.feed];
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<StoriesBloc>().add(const StoriesLoad()),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allStories.length,
              itemBuilder: (_, i) {
                final story = allStories[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      story.username?.isNotEmpty == true
                          ? story.username!.characters.first.toUpperCase()
                          : '?',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(story.username ?? 'Пользователь'),
                  subtitle: Text(
                    story.mediaType == 'video' ? 'Видео' : 'Фото',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }
}
