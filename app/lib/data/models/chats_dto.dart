class ChatMemberDto {
  ChatMemberDto({
    required this.id,
    required this.userId,
    required this.username,
    this.isAdmin = false,
  });

  factory ChatMemberDto.fromJson(Map<String, dynamic> json) => ChatMemberDto(
        id: (json['id'] as num).toInt(),
        userId: (json['user'] as num).toInt(),
        username: json['username'] as String? ?? '',
        isAdmin: json['is_admin'] as bool? ?? false,
      );

  final int id;
  final int userId;
  final String username;
  final bool isAdmin;
}

class ChatDto {
  ChatDto({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.members = const <ChatMemberDto>[],
    this.createdAt,
  });

  factory ChatDto.fromJson(Map<String, dynamic> json) => ChatDto(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? 'private',
        name: json['name'] as String?,
        avatar: json['avatar'] as String?,
        members: (json['members'] as List?)
                ?.map((e) => ChatMemberDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <ChatMemberDto>[],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        lastMessage: json['last_message']?['content'] as String?,
      );

  final int id;
  final String type;
  final String? name;
  final String? avatar;
  final List<ChatMemberDto> members;
  final DateTime? createdAt;
  final String? lastMessage;
}
