class ChatSettingsDto {
  ChatSettingsDto({
    required this.theme,
    required this.textSize,
    required this.notifications,
  });

  factory ChatSettingsDto.fromJson(Map<String, dynamic> json) => ChatSettingsDto(
        theme: json['theme'] as String? ?? 'system',
        textSize: (json['text_size'] as num?)?.toInt() ?? 14,
        notifications: json['notifications'] as bool? ?? true,
      );

  final String theme;
  final int textSize;
  final bool notifications;

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'text_size': textSize,
        'notifications': notifications,
      };
}

class PrivacyDto {
  PrivacyDto({
    required this.seePhoneNumber,
    required this.seeProfilePhoto,
    required this.seeLastSeen,
    required this.autoDeleteMessages,
    required this.messageTtlDays,
    required this.twoFactorAuth,
  });

  factory PrivacyDto.fromJson(Map<String, dynamic> json) => PrivacyDto(
        seePhoneNumber: json['see_phone_number'] as String? ?? 'contacts',
        seeProfilePhoto: json['see_profile_photo'] as String? ?? 'contacts',
        seeLastSeen: json['see_last_seen'] as String? ?? 'contacts',
        autoDeleteMessages: json['auto_delete_messages'] as bool? ?? false,
        messageTtlDays: (json['message_ttl_days'] as num?)?.toInt() ?? 30,
        twoFactorAuth: json['two_factor_auth'] as bool? ?? false,
      );

  final String seePhoneNumber;
  final String seeProfilePhoto;
  final String seeLastSeen;
  final bool autoDeleteMessages;
  final int messageTtlDays;
  final bool twoFactorAuth;

  Map<String, dynamic> toJson() => {
        'see_phone_number': seePhoneNumber,
        'see_profile_photo': seeProfilePhoto,
        'see_last_seen': seeLastSeen,
        'auto_delete_messages': autoDeleteMessages,
        'message_ttl_days': messageTtlDays,
        'two_factor_auth': twoFactorAuth,
      };
}

class LanguageDto {
  LanguageDto({required this.language, required this.autoTranslate});

  factory LanguageDto.fromJson(Map<String, dynamic> json) => LanguageDto(
        language: json['language'] as String? ?? 'ru',
        autoTranslate: json['auto_translate'] as bool? ?? false,
      );

  final String language;
  final bool autoTranslate;

  Map<String, dynamic> toJson() => {
        'language': language,
        'auto_translate': autoTranslate,
      };
}
