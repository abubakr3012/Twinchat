import 'package:equatable/equatable.dart';

/// Тип сообщения.
enum MessageType { text, image, audio, video, file, system, unknown }

MessageType messageTypeFromString(String? value) {
  switch (value) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'audio':
      return MessageType.audio;
    case 'video':
      return MessageType.video;
    case 'file':
      return MessageType.file;
    case 'system':
      return MessageType.system;
    default:
      return MessageType.unknown;
  }
}

/// Доменная сущность сообщения.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.readBy = const [],
  });

  final int id;
  final int chatId;
  final int senderId;
  final String senderUsername;
  final String content;
  final MessageType messageType;
  final DateTime createdAt;
  final bool isEdited;
  final bool isDeleted;
  final List<int> readBy;

  Message copyWith({
    int? id,
    String? content,
    bool? isEdited,
    bool? isDeleted,
    List<int>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId,
      senderId: senderId,
      senderUsername: senderUsername,
      content: content ?? this.content,
      messageType: messageType,
      createdAt: createdAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderUsername,
        content,
        messageType,
        createdAt,
        isEdited,
        isDeleted,
        readBy,
      ];
}
