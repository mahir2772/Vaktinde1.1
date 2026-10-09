// Dini günler: Diyanet tarihleri (religious_days.json) öncelikli, listede
// olmayan yıl/günler hicri hesaptan.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  late List<ResmiDiniGun> resmi;
  late List<Map<String, dynamic>> raw;

  setUpAll(() {
    raw = List<Map<String, dynamic>>.from(
      jsonDecode(File('assets/data/religious_days.json').readAsStringSync()),
    );
    resmi = DiniGunlerService.parseResmiGunler(raw);
  });

  DateTime? dateOf(int year, DiniGunTuru tur, {bool? resmiMi}) {
    for (final d in DiniGunlerService.yilinGunleri(year, resmi: resmi)) {
      if (d.tur == tur && (resmiMi == null || d.resmi == resmiMi)) {
        return d.tarih;
      }
    }
    return null;
  }

  group('Ad eşleştirme', () {
    test('Diyanet adları türlere eşlenir', () {
      final cases = {
        'Ramazan Başlangıcı': DiniGunTuru.ramazanBaslangici,
        'RAMAZAN BAŞLANGICI': DiniGunTuru.ramazanBaslangici,
        'Kadir Gecesi': DiniGunTuru.kadirGecesi,
        'Ramazan Bayramı 1. Gün': DiniGunTuru.ramazanBayrami,
        'Ramazan Bayramı': DiniGunTuru.ramazanBayrami,
        'Kurban Bayramı 1. Gün': DiniGunTuru.kurbanBayrami,
        'Regaib Kandili': DiniGunTuru.regaipKandili,
        'Üç Ayların Başlangıcı ve Regaib Kandili': DiniGunTuru.regaipKandili,
        'Miraç Kandili': DiniGunTuru.miracKandili,
        'Berat Kandili': DiniGunTuru.beratKandili,
        'Hicri Yılbaşı': DiniGunTuru.hicriYilbasi,
        'Aşure Günü': DiniGunTuru.asureGunu,
        'Mevlid Kandili': DiniGunTuru.mevlidKandili,
      };
      cases.forEach((name, tur) {
        expect(DiniGunlerService.turFromName(name), tur, reason: name);
      });
    });

    test('ekranda karşılığı olmayan ve bilinmeyen adlar null', () {
      for (final name in [
        'Arefe (Ramazan)',
        'Arefe (Kurban)',
        'Ramazan Bayramı 2. Gün',
        'Kurban Bayramı 4. Gün',
        'Üç Ayların Başlangıcı',
        'Bilinmeyen Gün',
        '',
      ]) {
        expect(DiniGunlerService.turFromName(name), isNull, reason: name);
      }
    });

    test('bozuk kayıtlar hata vermeden atlanır', () {
      final parsed = DiniGunlerService.parseResmiGunler([
        null,
        42,
        'metin',
        {'name': 'Kadir Gecesi'},
        {'date': '16 Mart 2026'},
        {'name': 'Kadir Gecesi', 'date': '31 Şubat 2026'},
        {'name': 'Bilinmeyen Gün', 'date': '01 Ocak 2026'},
        {'name': 7, 'date': '01 Ocak 2026'},
        {'name': 'Kadir Gecesi', 'date': '16 Mart 2026'},
      ]);
      expect(parsed, hasLength(1));
      expect(parsed.single.tur, DiniGunTuru.kadirGecesi);
      expect(parsed.single.tarih, DateTime(2026, 3, 16));
    });

    test('dosyadaki tanınan her kayıt okunur', () {
      final taninan = raw.where(
        (e) => DiniGunlerService.turFromName(e['name'] as String) != null,
      );
      expect(resmi, hasLength(taninan.length));
      expect(resmi.length, greaterThan(40));
    });
  });

  group('Yılın günleri', () {
    test('Diyanet tarihleri hicri hesabın yerine geçer', () {
      expect(
        dateOf(2026, DiniGunTuru.ramazanBaslangici, resmiMi: true),
        DateTime(2026, 2, 19),
      );
      expect(
        dateOf(2027, DiniGunTuru.ramazanBaslangici, resmiMi: true),
        DateTime(2027, 2, 8),
      );
      expect(
        dateOf(2026, DiniGunTuru.ramazanBayrami, resmiMi: true),
        DateTime(2026, 3, 20),
      );
      expect(
        dateOf(2026, DiniGunTuru.regaipKandili, resmiMi: true),
        DateTime(2026, 12, 10),
      );
    });

    test('listedeki yıllarda her resmi gün tam bir kez görünür', () {
      for (final year in [2025, 2026, 2027, 2028]) {
        final days = DiniGunlerService.yilinGunleri(year, resmi: resmi);
        for (final r in resmi.where((r) => r.tarih.year == year)) {
          final matches = days.where(
            (d) => d.tur == r.tur && d.tarih == r.tarih && d.resmi,
          );
          expect(matches, hasLength(1), reason: '$year $r');
        }
        // Aynı tür aynı gün iki kez yok; liste tarihe göre sıralı
        final keys = days.map((d) => '${d.tur}-${d.tarih}').toList();
        expect(keys.toSet(), hasLength(keys.length), reason: '$year');
        for (var i = 1; i < days.length; i++) {
          expect(
            days[i - 1].tarih.isAfter(days[i].tarih),
            isFalse,
            reason: '$year sıra',
          );
        }
      }
      // 2025'te iki Regaib Kandili (Ocak ve Aralık)
      final regaib2025 = DiniGunlerService.yilinGunleri(
        2025,
        resmi: resmi,
      ).where((d) => d.tur == DiniGunTuru.regaipKandili).map((d) => d.tarih);
      expect(regaib2025, [DateTime(2025, 1, 2), DateTime(2025, 12, 25)]);
    });

    test('yedek hicri hesap 2025-2028 Diyanet tarihleriyle aynı '
        '(kandiller bir gün önce)', () {
      // Kadir Gecesi ve Ramazan başlangıcı listede tutarlı değil (±1 gün)
      const tutarli = [
        DiniGunTuru.miracKandili,
        DiniGunTuru.beratKandili,
        DiniGunTuru.mevlidKandili,
        DiniGunTuru.regaipKandili,
        DiniGunTuru.hicriYilbasi,
        DiniGunTuru.asureGunu,
        DiniGunTuru.ramazanBayrami,
        DiniGunTuru.kurbanBayrami,
      ];
      for (final year in [2025, 2026, 2027, 2028]) {
        final hijri = DiniGunlerService.hicriGunler(year);
        for (final tur in tutarli) {
          final hesap = [
            for (final h in hijri)
              if (h.$1 == tur) h.$2,
          ];
          final diyanet = [
            for (final r in resmi)
              if (r.tur == tur && r.tarih.year == year) r.tarih,
          ]..sort();
          expect(diyanet, isNotEmpty, reason: '$year $tur');
          expect(hesap, diyanet, reason: '$year $tur');
        }
      }
    });

    test('listede olmayan yıl (2030) tamamen hicri hesaptır', () {
      final days = DiniGunlerService.yilinGunleri(2030, resmi: resmi);
      expect(days, isNotEmpty);
      expect(days.every((d) => !d.resmi), isTrue);
      final hijri = DiniGunlerService.hicriGunler(2030);
      expect(days.map((d) => (d.tur, d.tarih)).toList(), hijri);
      expect(
        dateOf(2030, DiniGunTuru.ramazanBaslangici),
        HijriCalendar().hijriToGregorian(
          HijriCalendar.fromDate(DateTime(2030, 3, 1)).hYear,
          9,
          1,
        ),
      );
    });

    test('listede olmayan gün hicri hesaba düşer', () {
      final sadeceRamazan = [
        ResmiDiniGun(DiniGunTuru.ramazanBaslangici, DateTime(2026, 2, 19)),
      ];
      final days = DiniGunlerService.yilinGunleri(2026, resmi: sadeceRamazan);
      final hijri = DiniGunlerService.hicriGunler(2026);
      expect(days, hasLength(hijri.length));
      final ramazan = days.singleWhere(
        (d) => d.tur == DiniGunTuru.ramazanBaslangici,
      );
      expect(ramazan.tarih, DateTime(2026, 2, 19));
      expect(ramazan.resmi, isTrue);
      final kadir = days.singleWhere((d) => d.tur == DiniGunTuru.kadirGecesi);
      expect(kadir.resmi, isFalse);
      expect(
        kadir.tarih,
        hijri.firstWhere((h) => h.$1 == DiniGunTuru.kadirGecesi).$2,
      );
    });

    test('resmi veri yoksa önceki davranış (hicri hesap)', () {
      final days = DiniGunlerService.yilinGunleri(2026);
      expect(
        days.map((d) => (d.tur, d.tarih)).toList(),
        DiniGunlerService.hicriGunler(2026),
      );
    });

    test('ekran modeli adları dile göre verir', () {
      final loc = lookupAppLocalizations(const Locale('de'));
      final days = DiniGunlerService.getYilinDiniGunleri(
        loc,
        2026,
        resmi: resmi,
      );
      final ramazan = days.firstWhere(
        (d) => d.tur == DiniGunTuru.ramazanBaslangici,
      );
      expect(ramazan.isim, loc.ramazanBaslangici);
      expect(ramazan.tarih, DateTime(2026, 2, 19));
    });
  });

  group('Bildirim günleri', () {
    late List<ResmiDiniGun> gunler;
    setUpAll(() {
      gunler = DiniGunlerService.parseBildirimGunleri(raw);
    });
    List<DiniGunTuru> on(DateTime d) => [
      for (final g in gunler)
        if (g.tarih == d) g.tur,
    ];
    List<DateTime> of(DiniGunTuru tur) => [
      for (final g in gunler)
        if (g.tur == tur) g.tarih,
    ];

    test('ekrandaki günler + Üç Aylar ve arefeler; ortak kayıt iki gün, '
        'bayramın 2-4. günü yok', () {
      for (final r in resmi) {
        expect(on(r.tarih), contains(r.tur), reason: '$r');
      }
      expect(on(DateTime(2026, 12, 10)).toSet(), {
        DiniGunTuru.ucAylar,
        DiniGunTuru.regaipKandili,
      });
      expect(on(DateTime(2025, 1, 1)), [DiniGunTuru.ucAylar]);
      expect(on(DateTime(2027, 3, 8)), [DiniGunTuru.ramazanArefesi]);
      expect(on(DateTime(2027, 5, 15)), [DiniGunTuru.kurbanArefesi]);
      expect(on(DateTime(2027, 3, 10)), isEmpty);
      expect(on(DateTime(2027, 5, 19)), isEmpty);
      expect(of(DiniGunTuru.ucAylar), hasLength(5));
      expect(of(DiniGunTuru.ramazanArefesi), hasLength(4));
      expect(of(DiniGunTuru.kurbanArefesi), hasLength(4));
    });

    test('bozuk ve belirsiz kayıtlar atlanır', () {
      final parsed = DiniGunlerService.parseBildirimGunleri([
        null,
        {'name': 'Arefe', 'date': '01 Ocak 2026'},
        {'name': 'Üç Ayların Başlangıcı', 'date': '31 Şubat 2026'},
        {'name': 'Kurban Bayramı 2. Gün', 'date': '28 Mayıs 2026'},
        {'name': 'Arefe (Kurban)', 'date': '26 Mayıs 2026'},
      ]);
      expect(parsed, hasLength(1));
      expect(parsed.single.tur, DiniGunTuru.kurbanArefesi);
      expect(parsed.single.tarih, DateTime(2026, 5, 26));
    });

    test('religious_days.json tutarlı: gün adları tarihlere uyar, sıralı; '
        'Kadir = Ramazan + 25 gün, arefe bayramdan bir gün önce, Regaib '
        'perşembe ve Üç Aylar\'a en çok 6 gün', () {
      const gunAdlari = [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar',
      ];
      DateTime? onceki;
      for (final e in raw) {
        final tarih = parseTurkishDate(e['date'] as String)!;
        expect(e['day'], gunAdlari[tarih.weekday - 1], reason: '${e['date']}');
        expect(e['year'], tarih.year, reason: '${e['date']}');
        expect(
          onceki?.isAfter(tarih) ?? false,
          isFalse,
          reason: '${e['date']}',
        );
        onceki = tarih;
      }
      int fark(DateTime a, DateTime b) => PrayerTracker.daysBetween(a, b);
      final ramazan = of(DiniGunTuru.ramazanBaslangici);
      final bayram = of(DiniGunTuru.ramazanBayrami);
      final kadir = of(DiniGunTuru.kadirGecesi);
      expect(kadir, hasLength(ramazan.length));
      for (var i = 0; i < ramazan.length; i++) {
        expect(fark(ramazan[i], kadir[i]), 25, reason: '${kadir[i]}');
        expect(fark(ramazan[i], bayram[i]), inInclusiveRange(29, 30));
      }
      for (final (arefe, bayramlar) in [
        (DiniGunTuru.ramazanArefesi, bayram),
        (DiniGunTuru.kurbanArefesi, of(DiniGunTuru.kurbanBayrami)),
      ]) {
        expect([
          for (final d in of(arefe)) PrayerTracker.addDays(d, 1),
        ], bayramlar);
      }
      for (final ucAylar in of(DiniGunTuru.ucAylar)) {
        final regaib = of(
          DiniGunTuru.regaipKandili,
        ).where((d) => fark(ucAylar, d).abs() <= 6);
        expect(regaib, hasLength(1), reason: '$ucAylar');
        expect(regaib.single.weekday, DateTime.thursday);
      }
    });
  });
}
