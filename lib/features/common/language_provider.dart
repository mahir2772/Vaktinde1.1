import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr'); // Varsayılan dil
  bool _isLanguageSelected = false; // Dil seçimi daha önce yapıldı mı?

  Locale get locale => _locale;
  bool get isLanguageSelected => _isLanguageSelected;

  LanguageProvider() {
    _loadLanguage();
  }

  // Hafızadan dili ve seçim durumunu yükle
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Dil daha önce seçilmiş mi?
    _isLanguageSelected = prefs.getBool('is_language_selected') ?? false;

    // 2. Hangi dil seçilmiş?
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Hiç seçilmediyse varsayılan TR (veya cihaz dili)
      _locale = const Locale('tr');
    }
    notifyListeners();
  }

  // Dili değiştir ve hafızaya kaydet
  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    _isLanguageSelected = true; // Artık seçim yapıldı sayıyoruz
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setBool('is_language_selected', true);
  }
}
