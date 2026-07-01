import 'package:flutter/material.dart';

/// Глобальный провайдер размера текста для чата.
/// Обновляется из настроек и читается в экране чата.
class TextSizeProvider extends ChangeNotifier {
  static final TextSizeProvider instance = TextSizeProvider._();
  TextSizeProvider._();

  int _textSize = 15;

  int get textSize => _textSize;

  set textSize(int value) {
    if (_textSize != value) {
      _textSize = value;
      notifyListeners();
    }
  }
}
