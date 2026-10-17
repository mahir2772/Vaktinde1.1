import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _backgroundImage;
  double _textScale = 1.0;

  /// Uygulama içi yazı boyutu (Görünüm Ayarları): Normal, Büyük, Çok büyük.
  /// MaterialApp.builder sistem yazı ölçeğiyle çarpar, toplam en çok
  /// [maxTextScale] (uygulama %200'e kadar denendi)
  static const String textScaleKey = 'app_text_scale';
  static const List<double> textScales = [1.0, 1.15, 1.3];
  static const double maxTextScale = 2.0;

  /// Seçilebilen arka plan görselleri (assets/images/backgrounds/); Ayarlar
  /// bunları listeler, kayıtlı seçim de bunlara göre doğrulanır. Sade: yumuşak
  /// renk geçişi + silik 8 köşeli yıldız (fotoğrafı kalabalık bulanlar için)
  static const List<String> plainBackgrounds = [
    'bg_plain1.webp',
    'bg_plain2.webp',
    'bg_plain3.webp',
    'bg_plain4.webp',
    'bg_plain5.webp',
    'bg_plain6.webp',
  ];
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
    return plainBackgrounds.contains(webp) ||
            mosqueBackgrounds.contains(webp) ||
            kaabaBackgrounds.contains(webp)
        ? webp
        : null;
  }

  ThemeMode get themeMode => _themeMode;
  String? get backgroundImage => _backgroundImage;
  double get textScale => _textScale;

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

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(textScaleKey, scale);
  }

  /// Yedekten geri yüklemeden sonra kayıttan yeniden okunur (kayıt yoksa
  /// sistem teması, arka plansız, normal yazı)
  Future<void> reload() async {
    _themeMode = ThemeMode.system;
    await _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    int? modeIndex = prefs.getInt('theme_mode');
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    final saved = prefs.getString('background_image');
    final valid = validBackground(saved);
    _backgroundImage = valid;

    // Seçeneklerden biri değilse (bozuk kayıt) normal yazı
    final scale = prefs.getDouble(textScaleKey);
    _textScale = textScales.contains(scale) ? scale! : 1.0;

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
