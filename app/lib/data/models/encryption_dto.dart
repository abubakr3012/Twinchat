class SafeModeStatusDto {
  SafeModeStatusDto({required this.isActive, this.fingerprint});

  factory SafeModeStatusDto.fromJson(Map<String, dynamic> json) =>
      SafeModeStatusDto(
        isActive: json['is_active'] as bool? ?? false,
        fingerprint: json['key_fingerprint'] as String?,
      );

  final bool isActive;
  final String? fingerprint;
}

class SafeModeKeyShareDto {
  SafeModeKeyShareDto({
    required this.id,
    required this.userId,
    required this.username,
    required this.sharedWithId,
    required this.sharedWithUsername,
    required this.method,
    this.sharedAt,
    this.isRevoked = false,
  });

  factory SafeModeKeyShareDto.fromJson(Map<String, dynamic> json) =>
      SafeModeKeyShareDto(
        id: (json['id'] as num).toInt(),
        userId: (json['user'] as num).toInt(),
        username: json['username'] as String? ?? '',
        sharedWithId: (json['shared_with'] as num?)?.toInt() ?? 0,
        sharedWithUsername: json['shared_with_username'] as String? ?? '',
        method: json['method'] as String? ?? 'qr',
        sharedAt: json['shared_at'] != null
            ? DateTime.tryParse(json['shared_at'] as String)
            : null,
        isRevoked: json['is_revoked'] as bool? ?? false,
      );

  final int id;
  final int userId;
  final String username;
  final int sharedWithId;
  final String sharedWithUsername;
  final String method;
  final DateTime? sharedAt;
  final bool isRevoked;
}

class SafeModeUIDto {
  SafeModeUIDto({required this.keyEntered, required this.autoLockMinutes});

  factory SafeModeUIDto.fromJson(Map<String, dynamic> json) => SafeModeUIDto(
        keyEntered: json['key_entered'] as bool? ?? false,
        autoLockMinutes:
            (json['auto_lock_minutes'] as num?)?.toInt() ?? 10,
      );

  final bool keyEntered;
  final int autoLockMinutes;

  Map<String, dynamic> toJson() => {
        'key_entered': keyEntered,
        'auto_lock_minutes': autoLockMinutes,
      };
}
