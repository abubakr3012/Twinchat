import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/attachments_repository.dart';
import '../../../domain/repositories/chats_repository.dart';

class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key, required this.chatId});
  final int chatId;

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  bool _loading = true;
  Chat? _chat;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    setState(() => _loading = true);
    try {
      final repo = GetIt.I<ChatsRepository>();
      final chat = await repo.getById(widget.chatId);
      if (mounted) {
        setState(() {
          _chat = chat;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat info: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_chat == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final fileName = 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final attachmentsRepo = GetIt.I<AttachmentsRepository>();
      final attachment = await attachmentsRepo.upload(
        bytes: bytes,
        fileName: fileName,
      );

      final chatsRepo = GetIt.I<ChatsRepository>();
      await chatsRepo.updateGroup(
        chatId: widget.chatId,
        avatarUrl: attachment.url,
      );

      if (mounted) {
        Navigator.of(context).pop(); // close dialog
        _loadChat(); // reload
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  void _addMember() {
    context.push('/contacts', extra: {
      'onSelect': (int selectedUserId) async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        try {
          final chatsRepo = GetIt.I<ChatsRepository>();
          await chatsRepo.addMember(chatId: widget.chatId, userId: selectedUserId);
          if (mounted) {
            Navigator.of(context).pop();
            _loadChat();
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding member: $e')),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_chat?.type == ChatType.group ? 'Group Info' : 'Chat Info'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chat == null
              ? const Center(child: Text('Chat not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_chat!.type == ChatType.group)
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _chat!.avatarUrl != null
                                    ? CachedNetworkImageProvider(_chat!.avatarUrl!)
                                    : null,
                                child: _chat!.avatarUrl == null
                                    ? const Icon(Icons.group, size: 60)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt, color: scheme.onPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _chat!.avatarUrl != null
                              ? CachedNetworkImageProvider(_chat!.avatarUrl!)
                              : null,
                          child: _chat!.avatarUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _chat!.name ?? 'Chat',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Members',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_chat!.type == ChatType.group)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.person_add, color: scheme.onPrimaryContainer),
                        ),
                        title: const Text('Add Member'),
                        onTap: _addMember,
                      ),
                    ..._chat!.members.map((m) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                                ? NetworkImage(m.avatarUrl!)
                                : null,
                            child: m.avatarUrl == null || m.avatarUrl!.isEmpty
                                ? Text(m.username.isNotEmpty ? m.username[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Text(m.username),
                          subtitle: Text(m.isAdmin ? 'Admin' : 'Member'),
                          onTap: () {
                            context.push('/profile/${m.userId}');
                          },
                        )),
                  ],
                ),
    );
  }
}
