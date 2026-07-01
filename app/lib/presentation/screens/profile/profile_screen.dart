import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/profile/other_profile_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtherProfileBloc>(
      create: (_) => OtherProfileBloc(repository: GetIt.I<UsersRepository>())
        ..add(OtherProfileLoad(userId)),
      child: _ProfileView(userId: userId),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.userId});
  final int userId;

  Future<void> _openChat(BuildContext context) async {
    final chatsRepo = GetIt.I<ChatsRepository>();
    final l10n = AppLocalizations.of(context);

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chats = await chatsRepo.list();

      // Look for an existing private chat with this user
      Chat? existingChat;
      for (final chat in chats) {
        if (chat.type == ChatType.private) {
          final isWithUser = chat.members.any((m) => m.userId == userId);
          if (isWithUser) {
            existingChat = chat;
            break;
          }
        }
      }

      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (existingChat != null) {
        if (context.mounted) {
          context.go('/chat/${existingChat.id}');
        }
      } else {
        // Create new private chat
        final newChat = await chatsRepo.create(type: ChatType.private);
        // Add member
        await chatsRepo.addMember(chatId: newChat.id, userId: userId);

        if (context.mounted) {
          context.go('/chat/${newChat.id}');
        }
      }
    } catch (e) {
      // Close the loading dialog if it's still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorOpeningChat}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<OtherProfileBloc, OtherProfileState>(
        listenWhen: (a, b) =>
            b is OtherProfileReady && b.user.id == 0 && b.error != null,
        listener: (context, state) {
          if (state is OtherProfileReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is OtherProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = (state as OtherProfileReady).user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 56,
                  child: Text(
                    user.username.isEmpty
                        ? '?'
                        : user.username.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.profile),
                subtitle: Text(user.bio ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(l10n.email),
                subtitle: Text(user.email ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(l10n.phone),
                subtitle: Text(user.phoneNumber ?? '—'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(l10n.openChat),
                onPressed: () => _openChat(context),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.call),
                label: Text(l10n.call),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.selectChatForCall),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}