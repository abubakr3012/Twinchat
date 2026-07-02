import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/app_localizations.dart';
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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocProvider<ChatListBloc>(
      create: (_) => ChatListBloc(
        chatsRepository: GetIt.I<ChatsRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
      )..add(const ChatListLoad()),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.search,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    )
                  : Text(
                      l10n.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
              elevation: 0,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
                  tooltip: 'Поиск',
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchController.clear();
                      } else {
                        _isSearching = true;
                      }
                    });
                  },
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
                           Text(l10n.myProfile),
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
                          Text(l10n.settings),
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
              children: [
                _ChatsTab(searchQuery: _searchController.text),
                _ContactsTab(searchQuery: _searchController.text),
                _StoriesTab(searchQuery: _searchController.text),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: const Icon(Icons.chat_bubble_rounded),
                  label: l10n.chats,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.contacts_outlined),
                  selectedIcon: const Icon(Icons.contacts_rounded),
                  label: l10n.contacts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories_rounded),
                  label: l10n.stories,
                ),
              ],
            ),
            floatingActionButton: _tab == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _showCreateChat(context),
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: Text(
                      l10n.newChat,
                      style: TextStyle(fontWeight: FontWeight.w600),
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
                        onPressed: () => context.push('/contacts'),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_add_rounded),
                      )
                    : FloatingActionButton(
                        onPressed: () => context.push('/stories'),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined),
                      )),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logout),
        content: Text('${l10n.logout}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showCreateChat(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ChatListBloc>(),
        child: const _CreateChatDialog(),
      ),
    );
  }

}

void _showGroupSettings(BuildContext context, Chat chat) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<ChatListBloc>(),
      child: _GroupSettingsDialog(chat: chat),
    ),
  );
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({required this.searchQuery});
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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
                    l10n.errorLoading,
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
                    label: Text(l10n.retry),
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
                        l10n.noChats,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noChatsHint,
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
            itemCount: ready.chats.where((c) {
              if (searchQuery.isEmpty) return true;
              return c.displayName(ready.me.username).toLowerCase().contains(searchQuery.toLowerCase());
            }).length,
            itemBuilder: (_, i) {
              final filteredChats = ready.chats.where((c) {
                if (searchQuery.isEmpty) return true;
                return c.displayName(ready.me.username).toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();
              final chat = filteredChats[i];
              final name = chat.displayName(ready.me.username);
              return _ChatListItem(
                chat: chat,
                name: name,
                onTap: () => context.go('/chat/${chat.id}'),
                onGroupSettings: chat.type == ChatType.group
                    ? () => _showGroupSettings(context, chat)
                    : null,
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
    this.onGroupSettings,
  });

  final Chat chat;
  final String name;
  final VoidCallback onTap;
  final VoidCallback? onGroupSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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
                      style: TextStyle(
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
                        chat.lastMessage ?? _chatTypeLabel(chat.type, l10n),
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
                if (onGroupSettings != null)
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: scheme.onSurfaceVariant, size: 22),
                    tooltip: 'Настройки группы',
                    onPressed: onGroupSettings,
                  ),
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

  String _chatTypeLabel(ChatType t, AppLocalizations l10n) {
    switch (t) {
      case ChatType.private:
        return l10n.personalChat;
      case ChatType.group:
        return l10n.groupChat;
      case ChatType.unknown:
        return l10n.chats;
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
  final _search = TextEditingController();
  ChatType _type = ChatType.private;
  String? _errorText;
  List<dynamic> _searchResults = [];
  bool _searching = false;
  // For private chat: selected user
  int? _selectedUserId;
  String? _selectedUsername;

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final users = await GetIt.I<UsersRepository>().search(q.trim());
      if (mounted) setState(() { _searchResults = users; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _submit(BuildContext context) {
    if (_type == ChatType.private) {
      if (_selectedUserId == null) {
        setState(() => _errorText = AppLocalizations.of(context).searchByUsername);
        return;
      }
      context.read<ChatListBloc>().add(
            ChatListCreate(
              type: _type,
              memberId: _selectedUserId,
            ),
          );
      Navigator.of(context).pop();
    } else {
      if (_name.text.trim().isEmpty) {
        setState(() => _errorText = AppLocalizations.of(context).emptyGroupName);
        return;
      }
      context.read<ChatListBloc>().add(
            ChatListCreate(
              type: _type,
              name: _name.text.trim(),
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.newChat,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<ChatType>(
              segments: [
                ButtonSegment(
                  value: ChatType.private,
                  label: Text(l10n.private),
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ChatType.group,
                  label: Text(l10n.group),
                  icon: const Icon(Icons.group_outlined, size: 18),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _errorText = null;
                _selectedUserId = null;
                _selectedUsername = null;
                _searchResults = [];
                _search.clear();
              }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: scheme.primaryContainer,
                selectedForegroundColor: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            if (_type == ChatType.private) ...[
              // Contact search field
              if (_selectedUserId == null) ...[
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: l10n.searchByUsername,
                    prefixIcon: const Icon(Icons.search_rounded),
                    errorText: _errorText,
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _doSearch,
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final u = _searchResults[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              (u.username as String).isNotEmpty
                                  ? (u.username as String)[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                          ),
                          title: Text(u.username as String),
                          onTap: () {
                            setState(() {
                              _selectedUserId = u.id as int;
                              _selectedUsername = u.username as String;
                              _searchResults = [];
                              _errorText = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                // Selected user display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primary,
                        child: Text(
                          _selectedUsername!.isNotEmpty
                              ? _selectedUsername![0].toUpperCase()
                              : '?',
                          style: TextStyle(color: scheme.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedUsername!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _selectedUserId = null;
                          _selectedUsername = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.groupName,
                  hintText: l10n.groupNameHint,
                  errorText: _errorText,
                  prefixIcon: const Icon(Icons.group_outlined, size: 22),
                ),
                onChanged: (val) {
                  if (_errorText != null && val.trim().isNotEmpty) {
                    setState(() => _errorText = null);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chatLimitNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: Text(l10n.create),
        ),
      ],
    );
  }
}


class _GroupSettingsDialog extends StatelessWidget {
  const _GroupSettingsDialog({required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(chat.name ?? l10n.groupNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: scheme.primary),
            title: Text(l10n.title),
            subtitle: Text(chat.name ?? l10n.noName),
          ),
          ListTile(
            leading: Icon(Icons.people_outline, color: scheme.primary),
            title: Text(l10n.members),
            subtitle: Text('${chat.members.length}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

// ─── Stub tabs ──────────────────────────────────────────────────────

class _ContactsTab extends StatefulWidget {
  const _ContactsTab({required this.searchQuery});
  final String searchQuery;

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  bool _hasPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.contacts.status;
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _requestPermission(BuildContext context) async {
    final status = await Permission.contacts.request();
    if (mounted) {
      setState(() => _hasPermission = status.isGranted);
      if (status.isGranted) {
        // Auto-sync device contacts after permission granted
        _syncDeviceContacts(context);
      }
    }
  }

  Future<void> _syncDeviceContacts(BuildContext context) async {
    try {
      final contacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final phoneContacts = contacts
          .where((c) => c.phones.isNotEmpty && c.phones.first.number.isNotEmpty)
          .toList();
      if (!mounted) return;
      final bloc = context.read<ContactsBloc>();
      for (final contact in phoneContacts) {
        final phone = contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
        bloc.add(ContactsSyncDeviceContact(
          name: contact.displayName,
          phone: phone,
        ));
      }
      // Reload contacts list after sync
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) bloc.add(const ContactsLoad());
    } catch (_) {
      // silently ignore sync errors
    }
  }

  Future<void> _openChatWithContact(BuildContext context, Contact c) async {
    try {
      final chatsRepo = GetIt.I<ChatsRepository>();
      final chats = await chatsRepo.list();
      Chat? existing;
      try {
        existing = chats.firstWhere(
          (ch) =>
              ch.type == ChatType.private &&
              ch.members.any((m) => m.userId == c.contactId),
        );
      } catch (_) {
        existing = null;
      }
      if (existing != null) {
        if (context.mounted) context.go('/chat/${existing.id}');
      } else {
        final newChat = await chatsRepo.create(type: ChatType.private);
        await chatsRepo.addMember(chatId: newChat.id, userId: c.contactId);
        if (context.mounted) context.go('/chat/${newChat.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия чата: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    if (_checkingPermission) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    // Always show contacts from server, even without device permission
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
          return Column(
            children: [
              // Sync device contacts banner if no permission
              if (!_hasPermission)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, color: scheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.allowContactAccess,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _requestPermission(context),
                        child: Text(l10n.allowContactAccess),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ready.contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contacts_outlined,
                                size: 64, color: scheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noContacts,
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
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ContactsBloc>().add(const ContactsLoad()),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: ready.contacts.where((c) {
                            if (widget.searchQuery.isEmpty) return true;
                            return c.displayName.toLowerCase().contains(widget.searchQuery.toLowerCase()) || 
                                   c.username.toLowerCase().contains(widget.searchQuery.toLowerCase());
                          }).length,
                          itemBuilder: (_, i) {
                            final filteredContacts = ready.contacts.where((c) {
                              if (widget.searchQuery.isEmpty) return true;
                              return c.displayName.toLowerCase().contains(widget.searchQuery.toLowerCase()) || 
                                     c.username.toLowerCase().contains(widget.searchQuery.toLowerCase());
                            }).toList();
                            final c = filteredContacts[i];
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.message_rounded,
                                        color: scheme.primary, size: 22),
                                    tooltip: l10n.openChat,
                                    onPressed: () => _openChatWithContact(context, c),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                              onTap: () => context.go('/profile/${c.contactId}'),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoriesTab extends StatelessWidget {
  const _StoriesTab({required this.searchQuery});
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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
                    l10n.noStoriesHint,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstStory,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/stories'),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.addStory),
                  ),
                ],
              ),
            );
          }
          final allStories = ready.feed.where((s) {
            if (searchQuery.isEmpty) return true;
            return s.username.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

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
                      story.username.isNotEmpty
                          ? story.username.characters.first.toUpperCase()
                          : '?',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(story.username),
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
