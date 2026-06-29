import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/contact.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/contacts_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/contacts/contacts_bloc.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContactsBloc>(
      create: (_) => ContactsBloc(
        contactsRepository: GetIt.I<ContactsRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
      )..add(const ContactsLoad()),
      child: const _ContactsView(),
    );
  }
}

class _ContactsView extends StatefulWidget {
  const _ContactsView();

  @override
  State<_ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<_ContactsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContact(BuildContext context, User user) async {
    final nickname = await showDialog<String>(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Добавить ${user.username}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Никнейм (опционально)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    context.read<ContactsBloc>().add(
          ContactsAdd(user: user, nickname: nickname),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: BlocConsumer<ContactsBloc, ContactsState>(
        listenWhen: (a, b) => b is ContactsReady && b.error != null,
        listener: (context, state) {
          if (state is ContactsReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is ContactsInitial || state is ContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as ContactsReady;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Поиск по username',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => context
                      .read<ContactsBloc>()
                      .add(ContactsSearch(v)),
                ),
              ),
              if (ready.searchResults.isNotEmpty)
                _SearchResults(
                  results: ready.searchResults,
                  onTap: (u) => _showAddContact(context, u),
                ),
              Expanded(
                child: ready.contacts.isEmpty
                    ? const Center(child: Text('Контактов пока нет'))
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<ContactsBloc>()
                            .add(const ContactsLoad()),
                        child: ListView.separated(
                          itemCount: ready.contacts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = ready.contacts[i];
                            return _ContactTile(
                              contact: c,
                              onTap: () =>
                                  context.go('/profile/${c.contactId}'),
                              onDelete: () => context
                                  .read<ContactsBloc>()
                                  .add(ContactsDelete(c.id)),
                              onBlock: () => context
                                  .read<ContactsBloc>()
                                  .add(ContactsBlock(c.id)),
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

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onTap,
    required this.onDelete,
    required this.onBlock,
  });

  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('contact-${contact.id}'),
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.block, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onBlock();
        } else {
          onDelete();
        }
        return false; // управляем состоянием через bloc.
      },
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            contact.displayName.isEmpty
                ? '?'
                : contact.displayName.characters.first.toUpperCase(),
          ),
        ),
        title: Text(contact.displayName),
        subtitle: Text('@${contact.username}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onTap});
  final List<User> results;
  final ValueChanged<User> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (_, i) {
          final u = results[i];
          return ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(u.username),
            subtitle: u.phoneNumber == null ? null : Text(u.phoneNumber!),
            onTap: () => onTap(u),
          );
        },
      ),
    );
  }
}