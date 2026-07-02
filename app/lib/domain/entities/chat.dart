import 'package:equatable/equatable.dart';

/// Тип чата.
enum ChatType { private, group, saved, unknown }

ChatType chatTypeFromString(String? value) {
  switch (value) {
    case 'private':
      return ChatType.private;
    case 'group':
      return ChatType.group;
    case 'saved':
      return ChatType.saved;
    default:
      return ChatType.unknown;
  }
}

/// Один участник чата.
class ChatMember extends Equatable {
  const ChatMember({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isAdmin = false,
  });

  final int id;
  final int userId;
  final String username;
  final String? avatarUrl;
  final bool isAdmin;

  @override
  List<Object?> get props => [id, userId, username, avatarUrl, isAdmin];
}

/// Доменная сущность чата.
class Chat extends Equatable {
  const Chat({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.members = const <ChatMember>[],
    this.createdAt,
    this.lastMessage,
  });

  final int id;
  final ChatType type;
  final String? name;
  final String? avatarUrl;
  final List<ChatMember> members;
  final DateTime? createdAt;
  final String? lastMessage;

  /// Имя для отображения: для личных — никнейм собеседника, иначе name.
  String displayName(String currentUsername) {
    if (type == ChatType.private && (name == null || name!.isEmpty)) {
      final other = members.firstWhere(
        (m) => m.username != currentUsername,
        orElse: () => const ChatMember(id: 0, userId: 0, username: ''),
      );
      if (other.username.isNotEmpty) return other.username;
    }
    return name ?? 'Чат #${id.toString()}';
  }

  /// URL аватарки для приватного чата — аватар собеседника.
  /// (На текущем этапе сервер не отдаёт это; помечаем как null.)
  String? displayAvatar() => avatarUrl;

  @override
  List<Object?> get props => [id, type, name, avatarUrl, members, createdAt, lastMessage];
}
