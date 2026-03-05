import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  String get modeLabel {
    switch (_mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void setMode(ThemeMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }
}
