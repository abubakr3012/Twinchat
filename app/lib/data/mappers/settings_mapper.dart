import '../../domain/entities/settings.dart';
import '../models/settings_dto.dart';

extension ChatSettingsDtoX on ChatSettingsDto {
  ChatSettings toDomain() => ChatSettings(
        theme: theme,
        textSize: textSize,
        notifications: notifications,
      );
}

extension PrivacyDtoX on PrivacyDto {
  PrivacySettings toDomain() => PrivacySettings(
        seePhoneNumber: seePhoneNumber,
        seeProfilePhoto: seeProfilePhoto,
        seeLastSeen: seeLastSeen,
        autoDeleteMessages: autoDeleteMessages,
        messageTtlDays: messageTtlDays,
        twoFactorAuth: twoFactorAuth,
      );
}

extension LanguageDtoX on LanguageDto {
  LanguageSettings toDomain() =>
      LanguageSettings(language: language, autoTranslate: autoTranslate);
}