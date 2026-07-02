import 'package:flutter/widgets.dart';

import 'strings_ru.dart';
import 'strings_en.dart';
import 'strings_tg.dart';

/// Lightweight localization system.
/// No code generation — pure Map-based translations.
class AppLocalizations {
  AppLocalizations._(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('tg'),
  ];

  late final Map<String, String> _strings = _loadStrings(locale.languageCode);

  Map<String, String> _loadStrings(String lang) {
    switch (lang) {
      case 'en':
        return enStrings;
      case 'tg':
        return tgStrings;
      case 'ru':
      default:
        return ruStrings;
    }
  }

  String translate(String key) => _strings[key] ?? key;

  // ─── Convenience getters ──────────────────────────────────────────────

  // App
  String get appName => translate('app_name');
  String get tagline => translate('tagline');

  // Auth
  String get login => translate('login');
  String get register => translate('register');
  String get logout => translate('logout');
  String get phone => translate('phone');
  String get code => translate('code');
  String get password => translate('password');
  String get username => translate('username');
  String get email => translate('email');
  String get enterPhone => translate('enter_phone');
  String get enterCode => translate('enter_code');
  String get getCode => translate('get_code');
  String get resendCode => translate('resend_code');
  String get loginWithPassword => translate('login_with_password');
  String get loginWithPhone => translate('login_with_phone');
  String get phoneHint => translate('phone_hint');
  String get codeSentTo => translate('code_sent_to');
  String get pasteFromClipboard => translate('paste_from_clipboard');
  String get codeResent => translate('code_resent');
  String get invalidPhone => translate('invalid_phone');
  String get codeTooShort => translate('code_too_short');
  String get loginOrPasswordEmpty => translate('login_or_password_empty');
  String get usernameTooShort => translate('username_too_short');
  String get passwordTooShort => translate('password_too_short');
  String get registration => translate('registration');
  String get registrationHint => translate('registration_hint');
  String get alreadyHaveAccount => translate('already_have_account');
  String get dontHaveAccount => translate('dont_have_account');

  // Navigation
  String get chats => translate('chats');
  String get contacts => translate('contacts');
  String get stories => translate('stories');
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get myProfile => translate('my_profile');
  String get safeMode => translate('safe_mode');
  String get savedMessages => translate('saved_messages');

  // Chat
  String get noChats => translate('no_chats');
  String get noChatsHint => translate('no_chats_hint');
  String get newChat => translate('new_chat');
  String get personalChat => translate('personal_chat');
  String get groupChat => translate('group_chat');
  String get messageHint => translate('message_hint');
  String get noMessages => translate('no_messages');
  String get writeFirst => translate('write_first');
  String get typing => translate('typing');
  String get deleted => translate('deleted');
  String get edited => translate('edited');
  String get voiceMessage => translate('voice_message');
  String get uploading => translate('uploading');
  String get chatNotFound => translate('chat_not_found');

  // Message actions
  String get editMessage => translate('edit_message');
  String get addReaction => translate('add_reaction');
  String get deleteMessage => translate('delete_message');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get close => translate('close');
  String get confirm => translate('confirm');

  // Contacts
  String get noContacts => translate('no_contacts');
  String get addContact => translate('add_contact');
  String get searchByUsername => translate('search_by_username');
  String get nicknameOptional => translate('nickname_optional');
  String get syncContacts => translate('sync_contacts');
  String get contactsSynced => translate('contacts_synced');
  String get allowContactAccess => translate('allow_contact_access');
  String get allowContactAccessHint => translate('allow_contact_access_hint');
  String get openChat => translate('open_chat');

  // Stories
  String get noStories => translate('no_stories');
  String get createFirstStory => translate('create_first_story');
  String get views => translate('views');
  String get addStory => translate('add_story');
  String get photo => translate('photo');
  String get video => translate('video');
  String get attachFile => translate('attach_file');

  // Settings
  String get theme => translate('theme');
  String get lightTheme => translate('light_theme');
  String get darkTheme => translate('dark_theme');
  String get systemTheme => translate('system_theme');
  String get textSize => translate('text_size');
  String get notifications => translate('notifications');
  String get privacy => translate('privacy');
  String get language => translate('language');
  String get autoTranslate => translate('auto_translate');
  String get autoDeleteMessages => translate('auto_delete_messages');
  String get twoFactorAuth => translate('two_factor_auth');
  String get seePhoneNumber => translate('see_phone_number');
  String get seeProfilePhoto => translate('see_profile_photo');
  String get seeLastSeen => translate('see_last_seen');
  String get storageDays => translate('storage_days');
  String get everyone => translate('everyone');
  String get nobody => translate('nobody');
  String get contactsOnly => translate('contacts_only');

  // Profile
  String get editProfile => translate('edit_profile');
  String get avatarUpdated => translate('avatar_updated');
  String get profileUpdated => translate('profile_updated');
  String get notSpecified => translate('not_specified');
  String get wasOnline => translate('was_online');

  // Safe Mode
  String get safeModeEnabled => translate('safe_mode_enabled');
  String get safeModeDisabled => translate('safe_mode_disabled');
  String get enableSafeMode => translate('enable_safe_mode');
  String get disableSafeMode => translate('disable_safe_mode');
  String get keyFingerprint => translate('key_fingerprint');
  String get enterKeyToUnlock => translate('enter_key_to_unlock');
  String get autoLockMinutes => translate('auto_lock_minutes');
  String get keyShareLog => translate('key_share_log');
  String get noSharesYet => translate('no_shares_yet');
  String get keyRevoked => translate('key_revoked');

  // Errors
  String get errorLoading => translate('error_loading');
  String get noConnection => translate('no_connection');
  String get serverError => translate('server_error');
  String get sessionExpired => translate('session_expired');
  String get accessDenied => translate('access_denied');
  String get notFound => translate('not_found');
  String get unknownError => translate('unknown_error');

  // Misc
  String get retry => translate('retry');
  String get loading => translate('loading');
  String get online => translate('online');
  String get offline => translate('offline');
  String get yes => translate('yes');
  String get no => translate('no');

  // Login
  String get welcome => translate('welcome');
  String get loginHint => translate('login_hint');
  String get enterUsername => translate('enter_username');
  String get enterPassword => translate('enter_password');
  String get or => translate('or');
  String get smsLogin => translate('sms_login');
  String get noAccount => translate('no_account');
  String get registerButton => translate('register_button');

  // Register
  String get createAccount => translate('create_account');
  // registerHint already exists as registrationHint
  String get min3Chars => translate('min_3_chars');
  String get enterEmail => translate('enter_email');
  String get invalidEmail => translate('invalid_email');
  String get invalidNumber => translate('invalid_number');
  String get min6Chars => translate('min_6_chars');
  String get repeatPassword => translate('repeat_password');
  String get passwordsNoMatch => translate('passwords_no_match');
  String get hasAccount => translate('has_account');

  // Code resend
  String get codeResentTo => translate('code_resent_to');

  // Contacts sync
  String get contactsSyncedCount => translate('contacts_synced_count');
  String get syncError => translate('sync_error');

  // Chat dialogs
  String get private => translate('private');
  String get group => translate('group');
  String get groupName => translate('group_name');
  String get groupNameHint => translate('group_name_hint');
  String get create => translate('create');
  String get chatLimitNote => translate('chat_limit_note');
  String get groupNameTitle => translate('group_name_title');
  String get noName => translate('no_name');
  String get title => translate('title');
  String get members => translate('members');
  String get emptyGroupName => translate('empty_group_name');

  // Stories
  String get noStoriesHint => translate('no_stories_hint');
  String get viewsCount => translate('views_count');
  String get storyNumber => translate('story_number');
  String get addPhoto => translate('add_photo');

  // Error on chat open
  String get errorOpeningChat => translate('error_opening_chat');
  String get call => translate('call');
  String get selectChatForCall => translate('select_chat_for_call');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ru', 'en', 'tg'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations._(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
