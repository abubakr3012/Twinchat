import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/repositories/users_repository.dart';

sealed class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => const [];
}

class ChatListLoad extends ChatListEvent {
  const ChatListLoad();
}

class ChatListCreate extends ChatListEvent {
  const ChatListCreate({required this.type, this.name});
  final ChatType type;
  final String? name;

  @override
  List<Object?> get props => [type, name];
}

class ChatListRefresh extends ChatListEvent {
  const ChatListRefresh();
}

sealed class ChatListState extends Equatable {
  const ChatListState();
  @override
  List<Object?> get props => const [];
}

class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListReady extends ChatListState {
  const ChatListReady({required this.chats, required this.me});
  final List<Chat> chats;
  final User me;

  @override
  List<Object?> get props => [chats, me];
}

class ChatListFailure extends ChatListState {
  const ChatListFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  ChatListBloc({
    required ChatsRepository chatsRepository,
    required UsersRepository usersRepository,
  })  : _chats = chatsRepository,
        _users = usersRepository,
        super(const ChatListInitial()) {
    on<ChatListLoad>(_onLoad);
    on<ChatListRefresh>(_onLoad);
    on<ChatListCreate>(_onCreate);
  }

  final ChatsRepository _chats;
  final UsersRepository _users;

  Future<void> _onLoad(ChatListEvent _, Emitter<ChatListState> emit) async {
    emit(const ChatListLoading());
    try {
      final me = await _users.me();
      final chats = await _chats.list();
      emit(ChatListReady(chats: chats, me: me));
    } on Object catch (e) {
      emit(ChatListFailure(extractErrorMessage(e)));
    }
  }

  Future<void> _onCreate(
    ChatListCreate event,
    Emitter<ChatListState> emit,
  ) async {
    final prev = state;
    try {
      await _chats.create(type: event.type, name: event.name);
      add(const ChatListRefresh());
    } on Object catch (e) {
      // Сохраняем прежний список и показываем ошибку.
      if (prev is ChatListReady) {
        emit(ChatListReady(chats: prev.chats, me: prev.me));
      }
      emit(ChatListFailure(extractErrorMessage(e)));
    }
  }
}