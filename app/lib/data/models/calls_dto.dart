class CallParticipantDto {
  CallParticipantDto({
    required this.id,
    required this.userId,
    required this.username,
    this.joinedAt,
    this.leftAt,
  });

  factory CallParticipantDto.fromJson(Map<String, dynamic> json) =>
      CallParticipantDto(
        id: (json['id'] as num).toInt(),
        userId: (json['user'] as num).toInt(),
        username: json['username'] as String? ?? '',
        joinedAt: json['joined_at'] != null
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
        leftAt: json['left_at'] != null
            ? DateTime.tryParse(json['left_at'] as String)
            : null,
      );

  final int id;
  final int userId;
  final String username;
  final DateTime? joinedAt;
  final DateTime? leftAt;
}

class CallDto {
  CallDto({
    required this.id,
    required this.chatId,
    required this.initiatorId,
    required this.initiatorUsername,
    required this.callType,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.createdAt,
  });

  factory CallDto.fromJson(Map<String, dynamic> json) => CallDto(
        id: (json['id'] as num).toInt(),
        chatId: (json['chat'] as num).toInt(),
        initiatorId: (json['initiator'] as num).toInt(),
        initiatorUsername: json['initiator_username'] as String? ?? '',
        callType: json['call_type'] as String? ?? 'voice',
        status: json['status'] as String? ?? 'ringing',
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.tryParse(json['ended_at'] as String)
            : null,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final int id;
  final int chatId;
  final int initiatorId;
  final String initiatorUsername;
  final String callType;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final DateTime? createdAt;
}
