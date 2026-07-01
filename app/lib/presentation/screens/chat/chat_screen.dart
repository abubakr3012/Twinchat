import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:translator/translator.dart';
import 'dart:async';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/locale_provider.dart';
import '../../../core/utils/text_size_provider.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/attachments_repository.dart';
import '../../../domain/repositories/messages_repository.dart';
import '../../../domain/repositories/reactions_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/users_repository.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';

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
  final _translator = GoogleTranslator();
  final _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  bool _typing = false;
  bool _isUploading = false;
  bool _autoTranslate = false;
  String _userLanguage = 'ru';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsRepo = GetIt.I<SettingsRepository>();
      final language = await settingsRepo.getLanguage();
      setState(() {
        _autoTranslate = language.autoTranslate;
        _userLanguage = language.language;
      });
    } catch (e) {
      // Use defaults if settings fail
    }
  }

  Future<String> _translateIfNeeded(String text, String senderLanguage) async {
    if (!_autoTranslate || senderLanguage == _userLanguage) {
      return text;
    }
    try {
      final translation = await _translator.translate(
        text,
        from: senderLanguage,
        to: _userLanguage,
      );
      return translation.text;
    } catch (e) {
      return text; // Return original if translation fails
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
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

  Future<void> _recordAndSendVoice() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);
      _recordingTimer?.cancel();
      
      if (path != null) {
        await _sendVoiceFile(path);
      }
    } else {
      // Start recording — request permission through permission_handler first
      try {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Разрешение на запись микрофона не выдано')),
            );
          }
          return;
        }
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final filePath =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );
          if (mounted) setState(() => _isRecording = true);
          
          _recordingTimer?.cancel();
          _recordingTimer = Timer(const Duration(seconds: 60), () async {
            if (!mounted || !_isRecording) return;
            final path = await _audioRecorder.stop();
            if (mounted) setState(() => _isRecording = false);
            if (path != null) {
              await _sendVoiceFile(path);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка записи: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendVoiceFile(String path) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final messagesRepo = GetIt.I<MessagesRepository>();
      final attachmentsRepo = GetIt.I<AttachmentsRepository>();

      final message = await messagesRepo.send(
        chatId: widget.chatId,
        content: 'Voice message...',
        messageType: MessageType.audio,
      );

      final file = XFile(path);
      final bytes = await file.readAsBytes();
      final attachment = await attachmentsRepo.upload(
        bytes: bytes,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        messageId: message.id,
      );

      if (!mounted) return;
      context.read<ChatBloc>().add(ChatEdit(
            messageId: message.id,
            content: attachment.url,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки голосового: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _sendXFile(XFile xfile, MessageType type) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final messagesRepo = GetIt.I<MessagesRepository>();
      final attachmentsRepo = GetIt.I<AttachmentsRepository>();

      final message = await messagesRepo.send(
        chatId: widget.chatId,
        content: 'Uploading...',
        messageType: type,
      );

      final bytes = await xfile.readAsBytes();
      final attachment = await attachmentsRepo.upload(
        bytes: bytes,
        fileName: xfile.name,
        messageId: message.id,
      );

      if (!mounted) return;
      context.read<ChatBloc>().add(ChatEdit(
            messageId: message.id,
            content: attachment.url,
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

  void _showMediaViewer(BuildContext context, String url, String type) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            if (type == 'image')
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline,
                          size: 80, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Видео',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageMenu(BuildContext context, Message m) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.editMessage),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await _askEdit(context, m.content);
                if (result != null && mounted) {
                  context
                      .read<ChatBloc>()
                      .add(ChatEdit(messageId: m.id, content: result));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: Text(l10n.addReaction),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final emoji = await _askEmoji(context);
                if (emoji != null) {
                  try {
                    await GetIt.I<ReactionsRepository>()
                        .add(messageId: m.id, emoji: emoji);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$emoji ${l10n.addReaction}')),
                      );
                    }
                  } on Object catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.errorLoading}: $e')),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
              title: Text(l10n.deleteMessage, style: TextStyle(color: scheme.error)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(ChatDelete(m.id));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _askEdit(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.messageHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<String?> _askEmoji(BuildContext context) async {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉'];
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        children: emojis
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(e),
                child: Text(e, style: const TextStyle(fontSize: 32)),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.go('/chats'),
        ),
        title: Text(
          'Чат #${widget.chatId}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Позвонить',
            icon: const Icon(Icons.call_outlined, size: 22),
            onPressed: () => context.go('/call/${widget.chatId}'),
          ),
          IconButton(
            tooltip: 'Поиск',
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () {},
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
            final ready = state as ChatReady;
            final typing = ready.typingUsers.values.toList();
            return Container(
              color: scheme.surfaceContainerLow.withOpacity(0.5),
              child: Column(
                children: [
                  Expanded(
                    child: ready.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primaryContainer.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 40,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Нет сообщений',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Напишите первым!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: ready.messages.length,
                            itemBuilder: (_, i) {
                              final m = ready.messages[i];
                              return _MessageBubble(
                                message: m,
                                isMine: m.senderId == ready.currentUserId,
                                onLongPress: () =>
                                    _showMessageMenu(context, m),
                                onMediaTap: (m.messageType ==
                                                MessageType.image ||
                                            m.messageType ==
                                                MessageType.video) &&
                                        m.content.isNotEmpty
                                    ? () => _showMediaViewer(
                                        context,
                                        m.content,
                                        m.messageType == MessageType.image
                                            ? 'image'
                                            : 'video')
                                    : null,
                              );
                            },
                          ),
                  ),
                  if (typing.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${typing.join(', ')} печатает...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _Composer(
                    controller: _controller,
                    onSend: _send,
                    onChanged: _onTextChanged,
                    onPickImage: _pickAndSendImage,
                    onPickVideo: _pickAndSendVideo,
                    onRecordVoice: _recordAndSendVoice,
                    isUploading: _isUploading,
                  ),
                ],
              ),
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
    required this.onMediaTap,
  });

  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;
  final VoidCallback? onMediaTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isMine
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final onColor = isMine ? scheme.onPrimary : scheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    message.senderUsername,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.messageType == MessageType.image &&
                        message.content.isNotEmpty)
                      GestureDetector(
                        onTap: onMediaTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: message.content,
                            width: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 200,
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) =>
                                const SizedBox(
                              width: 200,
                              height: 150,
                              child: Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      ),
                    if (message.messageType == MessageType.video &&
                        message.content.isNotEmpty)
                      GestureDetector(
                        onTap: onMediaTap,
                        child: Container(
                          width: 200,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline,
                                size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                    if (message.content.isEmpty ||
                        message.messageType == MessageType.text ||
                        (message.messageType != MessageType.image &&
                            message.messageType != MessageType.video))
                      Text(
                        message.isDeleted ? 'Удалено' : message.content,
                        style: TextStyle(
                          color: onColor,
                          fontSize: TextSizeProvider.instance.textSize.toDouble(),
                          fontStyle: message.isDeleted
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.Hm().format(message.createdAt.toLocal()),
                          style: TextStyle(
                            color: onColor.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readBy.isNotEmpty
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 16,
                            color: message.readBy.isNotEmpty
                                ? const Color(0xFF34B7F1)
                                : onColor.withOpacity(0.6),
                          ),
                        ],
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'ред.',
                            style: TextStyle(
                              color: onColor.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
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

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.onPickImage,
    required this.onPickVideo,
    required this.isUploading,
    required this.onRecordVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onRecordVoice;
  final bool isUploading;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach button
            IconButton(
              tooltip: l10n.attachFile,
              icon: widget.isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.add_circle_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
              onPressed: widget.isUploading
                  ? null
                  : () {
                      showModalBottomSheet<void>(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                decoration: BoxDecoration(
                                  color: scheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              ListTile(
                                leading: Icon(Icons.photo_library_rounded,
                                    color: scheme.primary),
                                title: Text(l10n.photo),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onPickImage();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.video_library_rounded,
                                    color: scheme.primary),
                                title: Text(l10n.video),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onPickVideo();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.mic_rounded,
                                    color: scheme.primary),
                                title: Text(l10n.voiceMessage),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onRecordVoice();
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSend(),
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send / Voice button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: widget.controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: widget.onSend,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: scheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onRecordVoice,
                      icon: Icon(
                        Icons.mic_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
