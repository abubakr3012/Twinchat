import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный провайдер темы приложения.
/// Синхронизируется с настройками и применяется к MaterialApp.
class ThemeModeProvider extends ChangeNotifier {
  static final ThemeModeProvider instance = ThemeModeProvider._();
  ThemeModeProvider._();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get themeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'system';
    setFromSettings(savedTheme, saveToPrefs: false);
  }

  void setFromSettings(String value, {bool saveToPrefs = true}) {
    switch (value) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
    if (saveToPrefs) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('theme_mode', value);
      });
    }
  }
}
