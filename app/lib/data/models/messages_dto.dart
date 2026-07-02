class MessageDto {
  MessageDto({
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

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
        id: (json['id'] as num).toInt(),
        chatId: (json['chat'] as num).toInt(),
        senderId: (json['sender'] as num).toInt(),
        senderUsername: json['sender_username'] as String? ?? '',
        senderAvatar: json['sender_avatar'] as String?,
        content: json['content'] as String? ?? '',
        messageType: json['message_type'] as String? ?? 'text',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        isEdited: json['is_edited'] as bool? ?? false,
        isDeleted: json['is_deleted'] as bool? ?? false,
        readBy: (json['read_by'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
      );

  final int id;
  final int chatId;
  final int senderId;
  final String senderUsername;
  final String? senderAvatar;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool isEdited;
  final bool isDeleted;
  final List<int> readBy;
}
