import 'package:hijri/hijri_calendar.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../features/imsakiye/imsakiye_logic.dart' show parseTurkishDate;
import 'json_service.dart';

/// Ekranda gösterilen dini gün türleri (adlar dile göre çevrilir)
enum DiniGunTuru {
  hicriYilbasi,
  asureGunu,
  mevlidKandili,
  regaipKandili,
  miracKandili,
  beratKandili,
  ramazanBaslangici,
  kadirGecesi,
  ramazanBayrami,
  kurbanBayrami,
}

class DiniGunModel {
  final String isim;
  final DateTime tarih;
  final DiniGunTuru? tur;

  /// Tarih Diyanet listesinden mi (yoksa hicri hesap mı)
  final bool resmi;

  DiniGunModel({
    required this.isim,
    required this.tarih,
    this.tur,
    this.resmi = false,
  });
}

/// religious_days.json'daki resmi (Diyanet) bir gün
class ResmiDiniGun {
  final DiniGunTuru tur;
  final DateTime tarih;

  const ResmiDiniGun(this.tur, this.tarih);

  @override
  String toString() => 'ResmiDiniGun($tur, $tarih)';
}

/// Tür + tarih (+ resmi mi); [DiniGunlerService.yilinGunleri] sonucu
typedef DiniGunTarihi = ({DiniGunTuru tur, DateTime tarih, bool resmi});

class DiniGunlerService {
  /// Hicri hesapla resmi tarih eşleştirilirken kabul edilen en büyük fark
  /// (hijri paketi Diyanet'ten genelde 0-2 gün sapar)
  static const int _eslesmeGunu = 5;

  static Future<List<ResmiDiniGun>>? _resmiCache;

  /// Diyanet tarihleri uygulama boyunca bir kez okunur; okunamazsa boş liste
  /// (ekran tamamen hicri hesaba düşer).
  static Future<List<ResmiDiniGun>> loadResmiGunler() =>
      _resmiCache ??= _readResmi();

  static Future<List<ResmiDiniGun>> _readResmi() async {
    try {
      return parseResmiGunler(await JsonService().getReligiousDays());
    } catch (_) {
      return const [];
    }
  }

  /// Türkçe karakterleri sadeleştirip küçültür ("Kurban Bayramı" -> "kurban bayrami")
  static String _normalize(String text) {
    const map = {
      'İ': 'i',
      'I': 'i',
      'ı': 'i',
      'Ş': 's',
      'ş': 's',
      'Ğ': 'g',
      'ğ': 'g',
      'Ü': 'u',
      'ü': 'u',
      'Ö': 'o',
      'ö': 'o',
      'Ç': 'c',
      'ç': 'c',
      'Â': 'a',
      'â': 'a',
      'Î': 'i',
      'î': 'i',
      'Û': 'u',
      'û': 'u',
      '̇': '',
    };
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(map[ch] ?? ch.toLowerCase());
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Diyanet listesindeki adı ekrandaki türe çevirir. Ekranda karşılığı
  /// olmayanlar (Arefe, bayramın 2-4. günleri, tek başına "Üç Ayların
  /// Başlangıcı") ve bilinmeyen adlar null döner.
  static DiniGunTuru? turFromName(String name) {
    final n = _normalize(name);
    if (n.isEmpty || n.contains('arefe')) return null;
    if (n.contains('regaib') || n.contains('regaip')) {
      return DiniGunTuru.regaipKandili;
    }
    if (n.contains('mirac')) return DiniGunTuru.miracKandili;
    if (n.contains('berat')) return DiniGunTuru.beratKandili;
    if (n.contains('kadir')) return DiniGunTuru.kadirGecesi;
    if (n.contains('mevlid') || n.contains('mevlit')) {
      return DiniGunTuru.mevlidKandili;
    }
    if (n.contains('asure')) return DiniGunTuru.asureGunu;
    if (n.contains('hicri yilbasi') || n.contains('hicri yeni yil')) {
      return DiniGunTuru.hicriYilbasi;
    }
    if (n.contains('ramazan') && n.contains('baslangic')) {
      return DiniGunTuru.ramazanBaslangici;
    }
    // Bayram: sadece 1. gün (gün numarası yoksa da 1. gün sayılır)
    final bayramGunu = RegExp(r'(\d+)\s*\.?\s*gun').firstMatch(n);
    final birinciGun = bayramGunu == null || bayramGunu.group(1) == '1';
    if (n.contains('ramazan bayrami')) {
      return birinciGun ? DiniGunTuru.ramazanBayrami : null;
    }
    if (n.contains('kurban bayrami')) {
      return birinciGun ? DiniGunTuru.kurbanBayrami : null;
    }
    return null;
  }

  /// religious_days.json kayıtları -> resmi günler. Bozuk kayıt, okunamayan
  /// tarih ve ekranda karşılığı olmayan adlar atlanır (hata vermez).
  static List<ResmiDiniGun> parseResmiGunler(Iterable<Object?> entries) {
    final result = <ResmiDiniGun>[];
    for (final e in entries) {
      if (e is! Map) continue;
      final name = e['name'];
      final date = e['date'];
      if (name is! String || date is! String) continue;
      final tur = turFromName(name);
      final tarih = parseTurkishDate(date);
      if (tur == null || tarih == null) continue;
      result.add(ResmiDiniGun(tur, tarih));
    }
    result.sort((a, b) => a.tarih.compareTo(b.tarih));
    return result;
  }

  static String isimOf(DiniGunTuru tur, AppLocalizations loc) => switch (tur) {
    DiniGunTuru.hicriYilbasi => loc.hicriYilbasi,
    DiniGunTuru.asureGunu => loc.asureGunu,
    DiniGunTuru.mevlidKandili => loc.mevlidKandili,
    DiniGunTuru.regaipKandili => loc.regaipKandili,
    DiniGunTuru.miracKandili => loc.miracKandili,
    DiniGunTuru.beratKandili => loc.beratKandili,
    DiniGunTuru.ramazanBaslangici => loc.ramazanBaslangici,
    DiniGunTuru.kadirGecesi => loc.kadirGecesi,
    DiniGunTuru.ramazanBayrami => loc.ramazanBayrami,
    DiniGunTuru.kurbanBayrami => loc.kurbanBayrami,
  };

  /// Miladi yılın dini günleri: Diyanet tarihi varsa o, yoksa hicri hesap.
  ///
  /// Her hicri hesaplanan gün, aynı türden ±5 gün içindeki resmi kayıtla
  /// eşleşirse resmi tarihi alır (resmi tarih başka yıla düşüyorsa o yılda
  /// gösterilir); eşleşmeyen resmi kayıtlar da eklenir. Listede olmayan
  /// yıllar (ör. 2030) tamamen hicri hesaptır.
  static List<DiniGunTarihi> yilinGunleri(
    int miladiYil, {
    List<ResmiDiniGun> resmi = const [],
  }) {
    final out = <DiniGunTarihi>[];
    final used = <ResmiDiniGun>{};
    for (final (tur, tarih) in hicriGunler(miladiYil)) {
      ResmiDiniGun? best;
      var bestDiff = _eslesmeGunu + 1;
      for (final r in resmi) {
        if (r.tur != tur || used.contains(r)) continue;
        final diff = _daysBetween(tarih, r.tarih).abs();
        if (diff < bestDiff) {
          best = r;
          bestDiff = diff;
        }
      }
      if (best == null) {
        out.add((tur: tur, tarih: tarih, resmi: false));
        continue;
      }
      used.add(best);
      if (best.tarih.year == miladiYil) {
        out.add((tur: tur, tarih: best.tarih, resmi: true));
      }
    }
    for (final r in resmi) {
      if (r.tarih.year != miladiYil || used.contains(r)) continue;
      // Aynı gün aynı tür iki kez yazılmışsa bir kez
      final duplicate = out.any(
        (d) => d.tur == r.tur && _daysBetween(d.tarih, r.tarih) == 0,
      );
      if (!duplicate) out.add((tur: r.tur, tarih: r.tarih, resmi: true));
    }
    out.sort((a, b) => a.tarih.compareTo(b.tarih));
    return out;
  }

  /// Ekran modeli (dile göre adlar)
  static List<DiniGunModel> getYilinDiniGunleri(
    AppLocalizations loc,
    int miladiYil, {
    List<ResmiDiniGun> resmi = const [],
  }) => [
    for (final d in yilinGunleri(miladiYil, resmi: resmi))
      DiniGunModel(
        isim: isimOf(d.tur, loc),
        tarih: d.tarih,
        tur: d.tur,
        resmi: d.resmi,
      ),
  ];

  /// Yalnız hijri paketiyle hesaplanan günler (önceki davranış)
  static List<(DiniGunTuru, DateTime)> hicriGunler(int miladiYil) {
    final liste = <(DiniGunTuru, DateTime)>[];

    var baslangicHicri = HijriCalendar.fromDate(DateTime(miladiYil, 1, 1));
    var bitisHicri = HijriCalendar.fromDate(DateTime(miladiYil, 12, 31));

    for (int hYil = baslangicHicri.hYear; hYil <= bitisHicri.hYear; hYil++) {
      _addIfMatches(liste, miladiYil, DiniGunTuru.hicriYilbasi, hYil, 1, 1);
      _addIfMatches(liste, miladiYil, DiniGunTuru.asureGunu, hYil, 1, 10);
      _addIfMatches(liste, miladiYil, DiniGunTuru.mevlidKandili, hYil, 3, 12);
      _addIfMatches(liste, miladiYil, DiniGunTuru.miracKandili, hYil, 7, 27);
      _addIfMatches(liste, miladiYil, DiniGunTuru.beratKandili, hYil, 8, 15);
      _addIfMatches(
        liste,
        miladiYil,
        DiniGunTuru.ramazanBaslangici,
        hYil,
        9,
        1,
      );
      _addIfMatches(liste, miladiYil, DiniGunTuru.kadirGecesi, hYil, 9, 27);
      _addIfMatches(liste, miladiYil, DiniGunTuru.ramazanBayrami, hYil, 10, 1);
      _addIfMatches(liste, miladiYil, DiniGunTuru.kurbanBayrami, hYil, 12, 10);

      DateTime regaip = _regaipKandiliniHesapla(hYil);
      if (regaip.year == miladiYil) {
        liste.add((DiniGunTuru.regaipKandili, regaip));
      }
    }

    liste.sort((a, b) => a.$2.compareTo(b.$2));
    return liste;
  }

  static int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  static void _addIfMatches(
    List<(DiniGunTuru, DateTime)> liste,
    int miladiYil,
    DiniGunTuru tur,
    int hYil,
    int hAy,
    int hGun,
  ) {
    DateTime miladiTarih = HijriCalendar().hijriToGregorian(hYil, hAy, hGun);
    if (miladiTarih.year == miladiYil) {
      liste.add((tur, miladiTarih));
    }
  }

  static DateTime _regaipKandiliniHesapla(int hicriYil) {
    for (int gun = 1; gun <= 7; gun++) {
      DateTime miladiTarih = HijriCalendar().hijriToGregorian(hicriYil, 7, gun);
      if (miladiTarih.weekday == DateTime.thursday) {
        return miladiTarih;
      }
    }
    return HijriCalendar().hijriToGregorian(hicriYil, 7, 1);
  }
}
