import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/token_storage.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/attachments_repository.dart';
import '../../../domain/repositories/messages_repository.dart';
import '../../../domain/repositories/reactions_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/chat/chat_bloc.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.chatId});

  final int chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(
        chatId: chatId,
        messagesRepository: GetIt.I<MessagesRepository>(),
        usersRepository: GetIt.I<UsersRepository>(),
        tokenStorage: GetIt.I<TokenStorage>(),
      ),
      child: _ChatView(chatId: chatId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.chatId});
  final int chatId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  bool _typing = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    context.read<ChatBloc>().add(ChatSend(txt));
    _controller.clear();
    _setTyping(false);
  }

  void _setTyping(bool v) {
    if (_typing == v) return;
    _typing = v;
    context.read<ChatBloc>().add(ChatTyping(v));
  }

  void _onTextChanged(String v) {
    _setTyping(v.isNotEmpty);
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      await _sendXFile(file, MessageType.image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      await _sendXFile(file, MessageType.video);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора видео: $e')),
        );
      }
    }
  }

  Future<void> _sendXFile(XFile xfile, MessageType type) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final bytes = await xfile.readAsBytes();
      final attachmentsRepo = GetIt.I<AttachmentsRepository>();
      final attachment = await attachmentsRepo.upload(
        bytes: bytes,
        fileName: xfile.name,
      );

      if (!mounted) return;
      context.read<ChatBloc>().add(ChatSend(
        attachment.url,
        messageType: type,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки файла: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMessageMenu(BuildContext context, Message m) {
    final bloc = context.read<ChatBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await _askEdit(context, m.content);
                if (result != null) {
                  bloc.add(ChatEdit(messageId: m.id, content: result));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Поставить реакцию'),
              onTap: () async {
                Navigator.of(context).pop();
                final emoji = await _askEmoji(context);
                if (emoji != null) {
                  try {
                    await GetIt.I<ReactionsRepository>()
                        .add(messageId: m.id, emoji: emoji);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Реакция $emoji добавлена')),
                      );
                    }
                  } on Object catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить'),
              onTap: () {
                Navigator.of(context).pop();
                bloc.add(ChatDelete(m.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askEdit(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askEmoji(BuildContext context) async {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        children: emojis
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(e),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат #${widget.chatId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            tooltip: 'Позвонить',
            icon: const Icon(Icons.call_outlined),
            onPressed: () => context.go('/call/${widget.chatId}'),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ChatBloc, ChatState>(
          listenWhen: (a, b) => b is ChatReady && b.error != null,
          listener: (context, state) {
            if (state is ChatReady && state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state is ChatInitial || state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final ready = state as ChatReady;
            final typing = ready.typingUsers.values.toList();
            return Column(
              children: [
                Expanded(
                  child: ready.messages.isEmpty
                      ? const Center(
                          child: Text('Сообщений пока нет.\nНапишите первым!',
                              textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(8),
                          itemCount: ready.messages.length,
                          itemBuilder: (_, i) {
                            final m = ready.messages[i];
                            return _MessageBubble(
                              message: m,
                              isMine: m.senderId == ready.currentUserId,
                              onLongPress: () => _showMessageMenu(context, m),
                            );
                          },
                        ),
                ),
                if (typing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Text(
                      '${typing.join(', ')} печатает...',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                _Composer(
                  controller: _controller,
                  onSend: _send,
                  onChanged: _onTextChanged,
                  onPickImage: _pickAndSendImage,
                  onPickVideo: _pickAndSendVideo,
                  isUploading: _isUploading,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final onColor = isMine ? scheme.onPrimary : scheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    message.senderUsername,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.messageType == MessageType.image && message.content.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.content,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 200,
                            height: 150,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const SizedBox(
                            width: 200,
                            height: 150,
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    if (message.messageType == MessageType.video && message.content.isNotEmpty)
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_outline, 
                            size: 50, 
                            color: Colors.white),
                        ),
                      ),
                    if (message.messageType == MessageType.text || message.content.isEmpty)
                      Text(
                        message.isDeleted ? 'Удалено' : message.content,
                        style: TextStyle(
                          color: onColor,
                          fontStyle: message.isDeleted
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.Hm().format(message.createdAt.toLocal()),
                          style: TextStyle(
                              color: onColor.withValues(alpha: 0.7),
                              fontSize: 11),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 6),
                          Text('ред.',
                              style: TextStyle(
                                  color: onColor.withValues(alpha: 0.7),
                                  fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.onPickImage,
    required this.onPickVideo,
    required this.isUploading,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Прикрепить файл',
            icon: isUploading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            onPressed: isUploading 
                ? null 
                : () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Фото'),
                              onTap: () {
                                Navigator.of(context).pop();
                                onPickImage();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.video_library),
                              title: const Text('Видео'),
                              onTap: () {
                                Navigator.of(context).pop();
                                onPickVideo();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Сообщение',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
