import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/chat_list/chat_list_bloc.dart';

/// ChatListScreen — список чатов с BottomNavigationBar.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatListBloc>(
      create: (_) => ChatListBloc(
        chatsRepository: GetIt.I<ChatsRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
      )..add(const ChatListLoad()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleFor(_tab)),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Мой профиль',
              onPressed: () => context.go('/my-profile'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Настройки',
              onPressed: () => context.go('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: () async {
                await GetIt.I<AuthRepository>().logout();
                if (!context.mounted) return;
                context.go('/phone');
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: const [
            _ChatsTab(),
            _ContactsStub(),
            _StoriesStub(),
            _SettingsStub(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Чаты'),
            NavigationDestination(
                icon: Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts),
                label: 'Контакты'),
            NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                selectedIcon: Icon(Icons.auto_stories),
                label: 'Истории'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Настройки'),
          ],
        ),
        floatingActionButton: _tab == 0
            ? FloatingActionButton(
                onPressed: () => _showCreateChat(context),
                child: const Icon(Icons.add),
              )
            : (_tab == 1
                ? FloatingActionButton(
                    onPressed: () => context.go('/contacts'),
                    child: const Icon(Icons.person_add_alt_1),
                  )
                : null),
      ),
    );
  }

  String _titleFor(int tab) {
    switch (tab) {
      case 0:
        return 'Чаты';
      case 1:
        return 'Контакты';
      case 2:
        return 'Истории';
      case 3:
        return 'Настройки';
      default:
        return 'TwinChat';
    }
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
    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) {
        if (state is ChatListLoading || state is ChatListInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ChatListFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<ChatListBloc>()
                        .add(const ChatListRefresh()),
                    child: const Text('Повторить'),
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
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'У вас пока нет чатов.\nНажмите + чтобы создать.',
                    textAlign: TextAlign.center,
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
          child: ListView.separated(
            itemCount: ready.chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final chat = ready.chats[i];
              final name = chat.displayName(ready.me.username);
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(name),
                subtitle: Text(_chatTypeLabel(chat.type)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/chat/${chat.id}'),
              );
            },
          ),
        );
      },
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
    return AlertDialog(
      title: const Text('Новый чат'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<ChatType>(
            segments: const [
              ButtonSegment(value: ChatType.private, label: Text('Личный')),
              ButtonSegment(value: ChatType.group, label: Text('Группа')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          if (_type == ChatType.group) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название группы'),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Сейчас сервер поддерживает создание чата одним участником. '
            'Добавление членов появится в следующей версии.',
            style: TextStyle(fontSize: 12),
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

// Заглушки-переходы для остальных вкладок. Вкладки навигации можно
// просто тапнуть — здесь же показываем «открыть полный экран».
class _ContactsStub extends StatelessWidget {
  const _ContactsStub();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contacts_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Управление контактами'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/contacts'),
              child: const Text('Открыть'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesStub extends StatelessWidget {
  const _StoriesStub();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Истории ваших контактов'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/stories'),
              child: const Text('Открыть'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsStub extends StatelessWidget {
  const _SettingsStub();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Все настройки приложения'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/settings'),
              child: const Text('Открыть'),
            ),
          ],
        ),
      ),
    );
  }
}