import 'package:flutter/material.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// Zikir kimliğinin seçili dildeki adı: hazır zikirde [dhikr] başlığı,
/// çevirisi olan esmada ARB, yoksa (özel zikir, diğer esmalar) kimliğin kendisi.
String dhikrDisplayName(String id, AppLocalizations loc, {Dua? dhikr}) {
  if (dhikr != null) return dhikr.titleFor(loc.localeName);
  switch (id) {
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
