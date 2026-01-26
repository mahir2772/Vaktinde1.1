import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _backgroundImage;

  ThemeMode get themeMode => _themeMode;
  String? get backgroundImage => _backgroundImage;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadThemeSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setBackgroundImage(String? imagePath) async {
    _backgroundImage = imagePath;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (imagePath == null) {
      await prefs.remove('background_image');
    } else {
      await prefs.setString('background_image', imagePath);
    }
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    int? modeIndex = prefs.getInt('theme_mode');
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    _backgroundImage = prefs.getString('background_image');

    notifyListeners();
  }
}
