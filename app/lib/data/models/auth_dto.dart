// DTO-модели для слоя data. Сделаны вручную (без freezed),
// чтобы не зависеть от кодогенерации.

/// GET/PATCH /api/users/me/, /api/users/{id}/, /api/users/search/
class UserDto {
  UserDto({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.bio,
    this.lastSeen,
    this.isOnline = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String?,
        phoneNumber: json['phone_number'] as String?,
        avatar: json['avatar'] as String?,
        bio: json['bio'] as String?,
        lastSeen: json['last_seen'] != null
            ? DateTime.tryParse(json['last_seen'] as String)
            : null,
        isOnline: json['is_online'] as bool? ?? false,
      );

  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final String? bio;
  final DateTime? lastSeen;
  final bool isOnline;
}

/// POST /api/users/phone/request-code/ → {sent, phone_number, debug_code?}
class PhoneCodeRequestDto {
  PhoneCodeRequestDto({
    required this.phoneNumber,
    required this.sent,
    this.debugCode,
  });

  factory PhoneCodeRequestDto.fromJson(Map<String, dynamic> json) =>
      PhoneCodeRequestDto(
        phoneNumber: json['phone_number'] as String? ?? '',
        sent: json['sent'] as bool? ?? true,
        debugCode: json['debug_code'] as String?,
      );

  final String phoneNumber;
  final bool sent;
  final String? debugCode;
}

/// POST /api/users/phone/verify/ → {access, refresh, user, is_new_user}
/// POST /api/users/register/ → {user, access, refresh}
/// POST /api/users/login/ → {access, refresh}
class AuthSessionDto {
  AuthSessionDto({
    required this.access,
    required this.refresh,
    this.isNewUser = false,
    this.user,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => AuthSessionDto(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
        isNewUser: json['is_new_user'] as bool? ?? false,
        user: json['user'] is Map<String, dynamic>
            ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );

  final String access;
  final String refresh;
  final bool isNewUser;
  final UserDto? user;
}
