// Dini günler: Diyanet tarihleri (religious_days.json) öncelikli, listede
// olmayan yıl/günler hicri hesaptan.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/dini_gunler_service.dart';
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
}
