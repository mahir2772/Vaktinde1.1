import 'package:hijri/hijri_calendar.dart';
import 'package:ezan_saati/l10n/app_localizations.dart'; // Kendi loc yoluna göre ayarla

class DiniGunModel {
  final String isim;
  final DateTime tarih;

  DiniGunModel({required this.isim, required this.tarih});
}

class DiniGunlerService {
  static List<DiniGunModel> getYilinDiniGunleri(
    AppLocalizations loc,
    int miladiYil,
  ) {
    List<DiniGunModel> liste = [];

    var baslangicHicri = HijriCalendar.fromDate(DateTime(miladiYil, 1, 1));
    var bitisHicri = HijriCalendar.fromDate(DateTime(miladiYil, 12, 31));

    for (int hYil = baslangicHicri.hYear; hYil <= bitisHicri.hYear; hYil++) {
      _addIfMatches(liste, miladiYil, loc.hicriYilbasi, hYil, 1, 1);
      _addIfMatches(liste, miladiYil, loc.asureGunu, hYil, 1, 10);
      _addIfMatches(liste, miladiYil, loc.mevlidKandili, hYil, 3, 12);
      _addIfMatches(liste, miladiYil, loc.miracKandili, hYil, 7, 27);
      _addIfMatches(liste, miladiYil, loc.beratKandili, hYil, 8, 15);
      _addIfMatches(liste, miladiYil, loc.ramazanBaslangici, hYil, 9, 1);
      _addIfMatches(liste, miladiYil, loc.kadirGecesi, hYil, 9, 27);
      _addIfMatches(liste, miladiYil, loc.ramazanBayrami, hYil, 10, 1);
      _addIfMatches(liste, miladiYil, loc.kurbanBayrami, hYil, 12, 10);

      DateTime regaip = _regaipKandiliniHesapla(hYil);
      if (regaip.year == miladiYil) {
        liste.add(DiniGunModel(isim: loc.regaipKandili, tarih: regaip));
      }
    }

    liste.sort((a, b) => a.tarih.compareTo(b.tarih));
    return liste;
  }

  static void _addIfMatches(
    List<DiniGunModel> liste,
    int miladiYil,
    String isim,
    int hYil,
    int hAy,
    int hGun,
  ) {
    // HATA DÜZELTİLDİ: setHijri() kaldırılıp doğrudan dönüştürücü kullanıldı.
    DateTime miladiTarih = HijriCalendar().hijriToGregorian(hYil, hAy, hGun);
    if (miladiTarih.year == miladiYil) {
      liste.add(DiniGunModel(isim: isim, tarih: miladiTarih));
    }
  }

  static DateTime _regaipKandiliniHesapla(int hicriYil) {
    for (int gun = 1; gun <= 7; gun++) {
      // HATA DÜZELTİLDİ: setHijri() kaldırıldı.
      DateTime miladiTarih = HijriCalendar().hijriToGregorian(hicriYil, 7, gun);
      if (miladiTarih.weekday == DateTime.thursday) {
        return miladiTarih;
      }
    }
    return HijriCalendar().hijriToGregorian(hicriYil, 7, 1);
  }
}
