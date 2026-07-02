import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Global locale provider for the app.
/// Syncs with settings and applies to MaterialApp.
class LocaleProvider extends ChangeNotifier {
  static final LocaleProvider instance = LocaleProvider._();
  LocaleProvider._();

  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  /// Set locale from settings string ('ru', 'en', 'tg').
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('language_code') ?? 'ru';
    setFromSettings(savedLocale, saveToPrefs: false);
  }

  void setFromSettings(String value, {bool saveToPrefs = true}) {
    Locale newLocale;
    switch (value) {
      case 'en':
        newLocale = const Locale('en');
        break;
      case 'tg':
        newLocale = const Locale('tg');
        break;
      case 'ru':
      default:
        newLocale = const Locale('ru');
        break;
    }
    if (newLocale != _locale) {
      _locale = newLocale;
      notifyListeners();
    }
    if (saveToPrefs) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('language_code', value);
      });
    }
  }

  /// Get the localized string for a key using the current locale.
  String translate(BuildContext context, String key) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (localizations == null) return key;
    return localizations.translate(key);
  }
}
