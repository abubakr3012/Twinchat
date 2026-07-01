import '../../domain/entities/message.dart';
import '../models/messages_dto.dart';

extension MessageDtoX on MessageDto {
  Message toDomain() => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderUsername: senderUsername,
        content: content,
        messageType: messageTypeFromString(messageType),
        createdAt: createdAt,
        isEdited: isEdited,
        isDeleted: isDeleted,
        readBy: readBy,
      );
}