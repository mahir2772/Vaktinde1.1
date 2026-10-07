import 'package:flutter/material.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// Kayıtlı zikir kimliğinin (Türkçe ad) seçili dildeki adı.
/// Özel zikirler kullanıcının yazdığı gibi döner.
String dhikrDisplayName(String id, AppLocalizations loc) {
  switch (id) {
    case "Sübhanallah":
      return loc.dhikrSubhanallah;
    case "Elhamdülillah":
      return loc.dhikrElhamdulillah;
    case "Allahu Ekber":
      return loc.dhikrAllahuEkber;
    case "Kelime-i Tevhid":
      return loc.dhikrKalima;
    case "Salavat":
      return loc.dhikrSalavat;
    case "Estağfirullah":
      return loc.dhikrEstagfirullah;
    case "La Havle":
      return loc.dhikrLaHavle;
    case "Hasbünallah":
      return loc.dhikrHasbunallah;
    case "Subhanallahi":
      return loc.dhikrSubhanallahi;
    case "Hz. Yunus":
      return loc.dhikrYunus;
    case "Ya Allah":
      return loc.dhikrYaAllah;
    case "Ya Rahman":
      return loc.dhikrYaRahman;
    case "Ya Rahim":
      return loc.dhikrYaRahim;
    case "Ya Şafi":
      return loc.dhikrYaSafi;
    case "Ya Rezzak":
      return loc.dhikrYaRezzak;
    case "Ya Fettah":
      return loc.dhikrYaFettah;
    default:
      return id;
  }
}

/// Arapça zikir metni stili (Amiri, sağdan sola)
TextStyle arabicDhikrStyle(BuildContext context, {double fontSize = 22}) {
  return TextStyle(
    fontFamily: AppTheme.arabicFamily,
    fontSize: fontSize,
    // Amiri'nin doğal satır yüksekliği ~1,76: daha azı harekeleri üst satıra
    // bindirir
    height: 1.8,
    color: Theme.of(context).colorScheme.primary,
  );
}
