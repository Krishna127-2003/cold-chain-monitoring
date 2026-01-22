import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  static const _key = "theme_mode";

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    if (saved == "light") {
      _mode = ThemeMode.light;
    } else if (saved == "dark") {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setTheme(ThemeMode newMode) async {
    _mode = newMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    if (newMode == ThemeMode.light) {
      await prefs.setString(_key, "light");
    } else if (newMode == ThemeMode.dark) {
      await prefs.setString(_key, "dark");
    } else {
      await prefs.setString(_key, "system");
    }
  }
}
