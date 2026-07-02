import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../core/api/chat_socket.dart';
import '../../../core/storage/token_storage.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/messages_repository.dart';
import '../../../domain/repositories/users_repository.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => const [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted(this.chatId);
  final int chatId;
  @override
  List<Object?> get props => [chatId];
}

class ChatLoadHistory extends ChatEvent {
  const ChatLoadHistory();
}

class ChatSend extends ChatEvent {
  const ChatSend(this.content, {this.messageType = MessageType.text});
  final String content;
  final MessageType messageType;
  @override
  List<Object?> get props => [content, messageType];
}

class ChatEdit extends ChatEvent {
  const ChatEdit({required this.messageId, required this.content});
  final int messageId;
  final String content;
  @override
  List<Object?> get props => [messageId, content];
}

class ChatDelete extends ChatEvent {
  const ChatDelete(this.messageId);
  final int messageId;
  @override
  List<Object?> get props => [messageId];
}

class ChatTyping extends ChatEvent {
  const ChatTyping(this.isTyping);
  final bool isTyping;
  @override
  List<Object?> get props => [isTyping];
}

class ChatRead extends ChatEvent {
  const ChatRead(this.messageId);
  final int messageId;
  @override
  List<Object?> get props => [messageId];
}

class _ChatMessageReceived extends ChatEvent {
  const _ChatMessageReceived(this.message);
  final Message message;
  @override
  List<Object?> get props => [message];
}

class _ChatTypingChanged extends ChatEvent {
  const _ChatTypingChanged({required this.userId, required this.username, required this.isTyping});
  final int userId;
  final String username;
  final bool isTyping;
  @override
  List<Object?> get props => [userId, username, isTyping];
}

class _ChatReadAck extends ChatEvent {
  const _ChatReadAck({required this.messageId, required this.userId});
  final int messageId;
  final int userId;
  @override
  List<Object?> get props => [messageId, userId];
}

class _ChatAppendMessage extends ChatEvent {
  const _ChatAppendMessage(this.message);
  final Message message;
  @override
  List<Object?> get props => [message];
}

class _ChatReplaceMessage extends ChatEvent {
  const _ChatReplaceMessage(this.message);
  final Message message;
  @override
  List<Object?> get props => [message];
}

sealed class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => const [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading(this.chatId);
  final int chatId;
  @override
  List<Object?> get props => [chatId];
}

class ChatReady extends ChatState {
  const ChatReady({
    required this.chatId,
    required this.messages,
    required this.currentUserId,
    required this.typingUsers,
    this.error,
  });

  final int chatId;
  final List<Message> messages;
  final int currentUserId;
  final Map<int, String> typingUsers; // userId → username
  final String? error;

  ChatReady copyWith({
    List<Message>? messages,
    Map<int, String>? typingUsers,
    String? error,
    bool clearError = false,
  }) {
    return ChatReady(
      chatId: chatId,
      messages: messages ?? this.messages,
      currentUserId: currentUserId,
      typingUsers: typingUsers ?? this.typingUsers,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [chatId, messages, currentUserId, typingUsers, error];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required int chatId,
    required MessagesRepository messagesRepository,
    required UsersRepository usersRepository,
    required TokenStorage tokenStorage,
  })  : _chatId = chatId,
        _messagesRepo = messagesRepository,
        _usersRepo = usersRepository,
        _tokenStorage = tokenStorage,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatSend>(_onSend);
    on<ChatEdit>(_onEdit);
    on<ChatDelete>(_onDelete);
    on<ChatTyping>(_onTyping);
    on<ChatRead>(_onRead);
    on<_ChatMessageReceived>(_onIncoming);
    on<_ChatTypingChanged>(_onTypingChanged);
    on<_ChatReadAck>(_onReadAck);
    on<_ChatAppendMessage>(_onAppendMessage);
    on<_ChatReplaceMessage>(_onReplaceMessage);

    add(ChatStarted(chatId));
  }

  final int _chatId;
  final MessagesRepository _messagesRepo;
  final UsersRepository _usersRepo;
  final TokenStorage _tokenStorage;
  ChatSocket? _socket;
  StreamSubscription<SocketEvent>? _socketSub;
  StreamSubscription<SocketConnectionState>? _connSub;
  int _currentUserId = 0;

  Future<void> _onStarted(ChatStarted _, Emitter<ChatState> emit) async {
    emit(ChatLoading(_chatId));
    try {
      final me = await _usersRepo.me();
      _currentUserId = me.id;
      final history = await _messagesRepo.listForChat(_chatId);
      emit(ChatReady(
        chatId: _chatId,
        messages: history,
        currentUserId: me.id,
        typingUsers: const {},
      ));
      _connectSocket();
    } on Object catch (e) {
      emit(ChatReady(
        chatId: _chatId,
        messages: const [],
        currentUserId: _currentUserId,
        typingUsers: const {},
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onLoadHistory(_, Emitter<ChatState> emit) async {
    if (state is! ChatReady) return;
    try {
      final list = await _messagesRepo.listForChat(_chatId);
      final ready = state as ChatReady;
      emit(ready.copyWith(messages: list));
    } on Object catch (e) {
      final ready = state as ChatReady;
      emit(ready.copyWith(error: extractErrorMessage(e)));
    }
  }

  Future<void> _onSend(ChatSend event, Emitter<ChatState> emit) async {
    // Always use HTTP for reliable message sending
    try {
      final msg = await _messagesRepo.send(
        chatId: _chatId,
        content: event.content,
        messageType: event.messageType,
      );
      add(_ChatAppendMessage(msg));
      
      // Also try to send via WebSocket for real-time sync to other users
      final socket = _socket;
      if (socket != null) {
        try {
          socket.sendMessage(
            content: event.content,
            messageType: _messageTypeToString(event.messageType),
          );
        } catch (_) {
          // Ignore WebSocket errors, message already sent via HTTP
        }
      }
    } on Object catch (e) {
      if (state is ChatReady) {
        emit((state as ChatReady)
            .copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onEdit(ChatEdit event, Emitter<ChatState> emit) async {
    try {
      final updated = await _messagesRepo.edit(
        messageId: event.messageId,
        content: event.content,
      );
      add(_ChatReplaceMessage(updated));
    } on Object catch (e) {
      if (state is ChatReady) {
        emit((state as ChatReady).copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onDelete(ChatDelete event, Emitter<ChatState> emit) async {
    try {
      await _messagesRepo.delete(event.messageId);
      if (state is ChatReady) {
        final ready = state as ChatReady;
        emit(ready.copyWith(
          messages: ready.messages
              .map((m) => m.id == event.messageId
                  ? m.copyWith(isDeleted: true, content: 'Удалено')
                  : m)
              .toList(),
        ));
      }
    } on Object catch (e) {
      if (state is ChatReady) {
        emit((state as ChatReady).copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  void _onTyping(ChatTyping event, Emitter<ChatState> emit) {
    _socket?.sendTyping(event.isTyping);
  }

  void _onRead(ChatRead event, Emitter<ChatState> emit) {
    _socket?.sendRead(event.messageId);
  }

  void _onIncoming(_ChatMessageReceived event, Emitter<ChatState> emit) {
    add(_ChatAppendMessage(event.message));
  }

  void _onTypingChanged(
    _ChatTypingChanged event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatReady) return;
    final ready = state as ChatReady;
    final next = Map<int, String>.from(ready.typingUsers);
    if (event.isTyping) {
      next[event.userId] = event.username;
    } else {
      next.remove(event.userId);
    }
    emit(ready.copyWith(typingUsers: next));
  }

  void _onReadAck(_ChatReadAck event, Emitter<ChatState> emit) {
    // Просто лог для отладки; статус «прочитано» в этой версии не отслеживаем.
  }

  String _messageTypeToString(MessageType t) {
    switch (t) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.audio:
        return 'audio';
      case MessageType.video:
        return 'video';
      case MessageType.file:
        return 'file';
      case MessageType.system:
      case MessageType.unknown:
        return 'text';
    }
  }

  void _onAppendMessage(_ChatAppendMessage event, Emitter<ChatState> emit) {
    if (state is! ChatReady) return;
    final ready = state as ChatReady;
    final m = event.message;
    if (ready.messages.any((e) => e.id == m.id)) return;
    final list = [...ready.messages, m]..sort((a, b) =>
        a.createdAt.compareTo(b.createdAt));
    emit(ready.copyWith(messages: list, clearError: true));
  }

  void _onReplaceMessage(_ChatReplaceMessage event, Emitter<ChatState> emit) {
    if (state is! ChatReady) return;
    final ready = state as ChatReady;
    final m = event.message;
    final list = ready.messages
        .map((e) => e.id == m.id ? m : e)
        .toList();
    emit(ready.copyWith(messages: list, clearError: true));
  }

  Future<void> _connectSocket() async {
    final token = await _tokenStorage.readAccess();
    if (token == null || token.isEmpty) return;
    _socket = ChatSocket(chatId: _chatId, token: token)
      ..connect();
    _socketSub = _socket!.events.listen((ev) {
      if (ev.type == SocketEvent.message) {
        final p = ev.payload;
        final id = (p['message_id'] as num?)?.toInt();
        final content = p['content'] as String? ?? '';
        final type = messageTypeFromString(p['message_type'] as String?);
        final senderId = (p['sender_id'] as num?)?.toInt() ?? 0;
        final senderName = p['sender_username'] as String? ?? '';
        final sent = p['sent_at'] != null
            ? DateTime.tryParse(p['sent_at'] as String) ?? DateTime.now()
            : DateTime.now();
        if (id == null) return;
        add(_ChatMessageReceived(Message(
          id: id,
          chatId: _chatId,
          senderId: senderId,
          senderUsername: senderName,
          content: content,
          messageType: type,
          createdAt: sent,
        )));
      } else if (ev.type == SocketEvent.typing) {
        final p = ev.payload;
        final uid = (p['user_id'] as num?)?.toInt() ?? 0;
        if (uid == _currentUserId) return;
        add(_ChatTypingChanged(
          userId: uid,
          username: p['username'] as String? ?? '',
          isTyping: p['is_typing'] as bool? ?? false,
        ));
      } else if (ev.type == SocketEvent.edit) {
        final p = ev.payload;
        final mid = (p['message_id'] as num?)?.toInt();
        final content = p['content'] as String?;
        if (mid != null && content != null && state is ChatReady) {
           final ready = state as ChatReady;
           final msg = ready.messages.firstWhere((m) => m.id == mid, orElse: () => ready.messages.first);
           if (msg.id == mid) {
             add(_ChatReplaceMessage(msg.copyWith(content: content, isEdited: true)));
           }
        }
      } else if (ev.type == SocketEvent.read) {
        final p = ev.payload;
        final mid = (p['message_id'] as num?)?.toInt() ?? 0;
        final uid = (p['user_id'] as num?)?.toInt() ?? 0;
        add(_ChatReadAck(messageId: mid, userId: uid));
      }
    });
    _connSub = _socket!.connection.listen((c) {
      // При желании — пробросить статус в state. Сейчас просто лог.
    });
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();
    await _connSub?.cancel();
    await _socket?.dispose();
    _socket = null;
    return super.close();
  }
}