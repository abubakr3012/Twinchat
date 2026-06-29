class ReactionDto {
  ReactionDto({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.username,
    required this.emoji,
  });

  factory ReactionDto.fromJson(Map<String, dynamic> json) => ReactionDto(
        id: (json['id'] as num).toInt(),
        messageId: (json['message'] as num).toInt(),
        userId: (json['user'] as num).toInt(),
        username: json['username'] as String? ??
            (json['user'] is Map
                ? (json['user']['username'] as String? ?? '')
                : ''),
        emoji: json['emoji'] as String? ?? '👍',
      );

  final int id;
  final int messageId;
  final int userId;
  final String username;
  final String emoji;
}
