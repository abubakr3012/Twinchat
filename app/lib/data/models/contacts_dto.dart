class ContactDto {
  ContactDto({
    required this.id,
    required this.contactId,
    required this.contactUsername,
    this.nickname,
    this.isBlocked = false,
    this.addedAt,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) => ContactDto(
        id: (json['id'] as num).toInt(),
        contactId:
            (json['contact_id'] as num?)?.toInt() ??
                (json['contact'] is num
                    ? (json['contact'] as num).toInt()
                    : 0),
        contactUsername: json['contact_username'] as String? ??
            (json['contact'] is Map
                ? (json['contact']['username'] as String? ?? '')
                : ''),
        nickname: json['nickname'] as String?,
        contactAvatar: json['contact_avatar'] as String?,
        isBlocked: json['is_blocked'] as bool? ?? false,
        addedAt: json['added_at'] != null
            ? DateTime.tryParse(json['added_at'] as String)
            : null,
      );

  final int id;
  final int contactId;
  final String contactUsername;
  final String? contactAvatar;
  final String? nickname;
  final bool isBlocked;
  final DateTime? addedAt;
}
