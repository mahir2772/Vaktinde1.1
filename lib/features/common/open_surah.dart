import 'package:flutter/material.dart';

import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../quran/view/surah_reader_view.dart';

/// Sureyi Kur'an okuyucusunda açar (Namaz Hocası'nın Fâtiha bağlantısı, Cuma
/// bildiriminin "Kehf Suresi" düğmesi). Okunan yer "kaldığın yer" olarak
/// saklanmaz: kullanıcının Kur'an'da kaldığı yer ezilmez. Sure listesi
/// okunamazsa ya da sure yoksa SnackBar. [service]: test için (varsayılan:
/// alquran.cloud + cihazdaki kopya)
Future<void> openSurahReader(
  BuildContext context,
  int number, {
  QuranService? service,
}) async {
  final loc = AppLocalizations.of(context)!;
  final quran = service ?? QuranService();
  List<Surah>? surahs;
  try {
    surahs = await quran.loadSurahs();
  } catch (_) {}
  if (!context.mounted) return;
  final surah = surahs?.where((s) => s.number == number).firstOrNull;
  if (surah == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(loc.noDataFound)));
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SurahReaderView(
        surah: surah,
        service: quran,
        surahs: surahs,
        trackLastRead: false,
      ),
    ),
  );
}
