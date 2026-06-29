import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote.dart';
import '../models/settings_dto.dart';
import '../mappers/settings_mapper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._remote);
  final SettingsRemote _remote;

  @override
  Future<ChatSettings> getChat() async =>
      (await _remote.getChat()).toDomain();

  @override
  Future<ChatSettings> updateChat(ChatSettings settings) async {
    final dto = await _remote.updateChat(_chatDtoFromDomain(settings));
    return dto.toDomain();
  }

  @override
  Future<PrivacySettings> getPrivacy() async =>
      (await _remote.getPrivacy()).toDomain();

  @override
  Future<PrivacySettings> updatePrivacy(PrivacySettings settings) async {
    final dto = await _remote.updatePrivacy(_privacyDtoFromDomain(settings));
    return dto.toDomain();
  }

  @override
  Future<LanguageSettings> getLanguage() async =>
      (await _remote.getLanguage()).toDomain();

  @override
  Future<LanguageSettings> updateLanguage(LanguageSettings settings) async {
    final dto = await _remote.updateLanguage(_languageDtoFromDomain(settings));
    return dto.toDomain();
  }

  ChatSettingsDto _chatDtoFromDomain(ChatSettings s) => ChatSettingsDto(
        theme: s.theme,
        textSize: s.textSize,
        notifications: s.notifications,
      );

  PrivacyDto _privacyDtoFromDomain(PrivacySettings s) => PrivacyDto(
        seePhoneNumber: s.seePhoneNumber,
        seeProfilePhoto: s.seeProfilePhoto,
        seeLastSeen: s.seeLastSeen,
        autoDeleteMessages: s.autoDeleteMessages,
        messageTtlDays: s.messageTtlDays,
        twoFactorAuth: s.twoFactorAuth,
      );

  LanguageDto _languageDtoFromDomain(LanguageSettings s) => LanguageDto(
        language: s.language,
        autoTranslate: s.autoTranslate,
      );
}