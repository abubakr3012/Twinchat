import '../../domain/entities/chat.dart';
import '../models/chats_dto.dart';

extension ChatMemberDtoX on ChatMemberDto {
  ChatMember toDomain() => ChatMember(
        id: id,
        userId: userId,
        username: username,
        avatarUrl: avatar,
        isAdmin: isAdmin,
      );
}

extension ChatDtoX on ChatDto {
  Chat toDomain() => Chat(
        id: id,
        type: chatTypeFromString(type),
        name: name,
        avatarUrl: avatar,
        members: members.map((m) => m.toDomain()).toList(),
        createdAt: createdAt,
        lastMessage: lastMessage,
      );
}
