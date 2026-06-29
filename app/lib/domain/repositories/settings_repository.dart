import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<ChatSettings> getChat();
  Future<ChatSettings> updateChat(ChatSettings settings);

  Future<PrivacySettings> getPrivacy();
  Future<PrivacySettings> updatePrivacy(PrivacySettings settings);

  Future<LanguageSettings> getLanguage();
  Future<LanguageSettings> updateLanguage(LanguageSettings settings);
}
