import 'package:equatable/equatable.dart';

/// Настройки чата: тема/размер текста/уведомления.
class ChatSettings extends Equatable {
  const ChatSettings({
    required this.theme,
    required this.textSize,
    required this.notifications,
  });

  final String theme; // 'light' | 'dark' | 'system'
  final int textSize; // 12..24
  final bool notifications;

  ChatSettings copyWith({
    String? theme,
    int? textSize,
    bool? notifications,
  }) =>
      ChatSettings(
        theme: theme ?? this.theme,
        textSize: textSize ?? this.textSize,
        notifications: notifications ?? this.notifications,
      );

  @override
  List<Object?> get props => [theme, textSize, notifications];
}

/// Настройки приватности.
class PrivacySettings extends Equatable {
  const PrivacySettings({
    required this.seePhoneNumber,
    required this.seeProfilePhoto,
    required this.seeLastSeen,
    required this.autoDeleteMessages,
    required this.messageTtlDays,
    required this.twoFactorAuth,
  });

  final String seePhoneNumber; // 'everyone' | 'contacts' | 'nobody'
  final String seeProfilePhoto;
  final String seeLastSeen;
  final bool autoDeleteMessages;
  final int messageTtlDays;
  final bool twoFactorAuth;

  PrivacySettings copyWith({
    String? seePhoneNumber,
    String? seeProfilePhoto,
    String? seeLastSeen,
    bool? autoDeleteMessages,
    int? messageTtlDays,
    bool? twoFactorAuth,
  }) =>
      PrivacySettings(
        seePhoneNumber: seePhoneNumber ?? this.seePhoneNumber,
        seeProfilePhoto: seeProfilePhoto ?? this.seeProfilePhoto,
        seeLastSeen: seeLastSeen ?? this.seeLastSeen,
        autoDeleteMessages: autoDeleteMessages ?? this.autoDeleteMessages,
        messageTtlDays: messageTtlDays ?? this.messageTtlDays,
        twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      );

  @override
  List<Object?> get props => [
        seePhoneNumber,
        seeProfilePhoto,
        seeLastSeen,
        autoDeleteMessages,
        messageTtlDays,
        twoFactorAuth,
      ];
}

/// Язык и автоперевод.
class LanguageSettings extends Equatable {
  const LanguageSettings({required this.language, required this.autoTranslate});

  final String language; // 'ru' | 'en' | ...
  final bool autoTranslate;

  LanguageSettings copyWith({String? language, bool? autoTranslate}) =>
      LanguageSettings(
        language: language ?? this.language,
        autoTranslate: autoTranslate ?? this.autoTranslate,
      );

  @override
  List<Object?> get props => [language, autoTranslate];
}
