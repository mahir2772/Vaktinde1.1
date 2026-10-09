import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _backgroundImage;

  /// Seçilebilen arka plan görselleri (assets/images/backgrounds/); Ayarlar
  /// bunları listeler, kayıtlı seçim de bunlara göre doğrulanır
  static const List<String> mosqueBackgrounds = [
    'bg_mosque1.webp',
    'bg_mosque2.webp',
    'bg_mosque3.webp',
    'bg_mosque4.webp',
    'bg_mosque5.webp',
    'bg_mosque6.webp',
  ];
  static const List<String> kaabaBackgrounds = [
    'bg_kaaba1.webp',
    'bg_kaaba2.webp',
    'bg_kaaba3.webp',
    'bg_kaaba4.webp',
  ];

  /// Kayıtlı arka plan adını doğrular: listedeyse aynen; eski sürümlerin .jpg
  /// adı (1.1.0'da .webp oldu) .webp karşılığına taşınır; kalanlar (kaldırılan
  /// bg_quran, bozuk kayıt) null → arka plansız. Listede olmayan varlık
  /// yüklenemez, arka plan boş kalırdı.
  static String? validBackground(String? name) {
    if (name == null) return null;
    final webp = name.endsWith('.jpg')
        ? '${name.substring(0, name.length - 4)}.webp'
        : name;
    return mosqueBackgrounds.contains(webp) || kaabaBackgrounds.contains(webp)
        ? webp
        : null;
  }

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

    final saved = prefs.getString('background_image');
    final valid = validBackground(saved);
    _backgroundImage = valid;

    notifyListeners();

    // Eski/geçersiz kayıt bir kez düzeltilir
    if (valid != saved) {
      if (valid == null) {
        await prefs.remove('background_image');
      } else {
        await prefs.setString('background_image', valid);
      }
    }
  }
}
