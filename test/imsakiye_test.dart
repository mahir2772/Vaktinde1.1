import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

PrayerTimesModel _times({String imsak = '05:00', String aksam = '19:00'}) =>
    PrayerTimesModel(
      imsak: imsak,
      gunes: '06:30',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: aksam,
      yatsi: '20:30',
    );

DateTime _plusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

const _hijri = RamadanCalendar.hijriOnly;

void main() {
  group('Ramazan aralığı', () {
    test('29/30 gün, hicri 9/1 ile başlar, ertesi gün Şevval 1', () {
      for (var year = 1440; year <= 1460; year++) {
        final r = ramadanOfHijriYear(year);
        expect(r.length, anyOf(29, 30), reason: '$year');
        expect(r.days.length, r.length);

        final first = HijriCalendar.fromDate(r.start);
        expect([first.hYear, first.hMonth, first.hDay], [year, 9, 1]);

        final last = HijriCalendar.fromDate(r.end);
        expect([last.hYear, last.hMonth, last.hDay], [year, 9, r.length]);

        final after = HijriCalendar.fromDate(_plusDays(r.end, 1));
        expect([after.hMonth, after.hDay], [10, 1]);

        final before = HijriCalendar.fromDate(_plusDays(r.start, -1));
        expect(before.hMonth, 8);

        // Günler ardışık, gece yarısı ve tekrarsız
        for (var i = 0; i < r.days.length; i++) {
          final d = r.days[i];
          expect(d, DateTime(d.year, d.month, d.day));
          expect(RamadanCalendar.hijriOnly.dayOf(d), i + 1);
        }
      }
    });

    test(
      'içindeyken mevcut, öncesinde aynı yılın, sonrasında gelecek yılın Ramazanı',
      () {
        final r1447 = ramadanOfHijriYear(1447);
        final r1448 = ramadanOfHijriYear(1448);

        // Ramazan içinde (ilk, orta, son gün ve günün geç saati)
        expect(_hijri.currentOrNext(r1447.start).hijriYear, 1447);
        expect(
          _hijri
              .currentOrNext(
                _plusDays(r1447.start, 10).add(const Duration(hours: 23)),
              )
              .hijriYear,
          1447,
        );
        expect(_hijri.currentOrNext(r1447.end).hijriYear, 1447);

        // Ramazandan bir gün önce -> aynı Ramazan
        expect(
          _hijri.currentOrNext(_plusDays(r1447.start, -1)).hijriYear,
          1447,
        );

        // Bayram (Ramazan bitti) -> sonraki yıl
        expect(_hijri.currentOrNext(_plusDays(r1447.end, 1)).hijriYear, 1448);

        // Bugünkü bağlam: Ekim 2026 -> Ramazan 1448
        final next = _hijri.currentOrNext(DateTime(2026, 10, 6, 14, 30));
        expect(next.hijriYear, 1448);
        expect(next.start, r1448.start);
        expect(next.start.isAfter(DateTime(2026, 10, 6)), isTrue);
      },
    );
  });

  test('daysOfMonth: artık yıl ve ay uzunlukları', () {
    expect(daysOfMonth(2028, 2).length, 29);
    expect(daysOfMonth(2027, 2).length, 28);
    expect(daysOfMonth(2026, 10).length, 31);
    expect(daysOfMonth(2026, 11).length, 30);
    expect(daysOfMonth(2026, 12).last, DateTime(2026, 12, 31));
    expect(daysOfMonth(2026, 10).first, DateTime(2026, 10, 1));
  });

  test('timeOnDate: geçerli ve geçersiz girdiler', () {
    final day = DateTime(2027, 2, 10);
    expect(timeOnDate('05:07', day), DateTime(2027, 2, 10, 5, 7));
    expect(timeOnDate('5:07', day), DateTime(2027, 2, 10, 5, 7));
    expect(timeOnDate('19:45 (+03)', day), DateTime(2027, 2, 10, 19, 45));
    expect(timeOnDate(null, day), isNull);
    expect(timeOnDate('--:--', day), isNull);
    expect(timeOnDate('24:00', day), isNull);
    expect(timeOnDate('', day), isNull);
  });

  group('Ramazan sayacı', () {
    final r = ramadanOfHijriYear(1448);
    final day3 = r.days[2];
    DateTime at(DateTime d, int h, int m) =>
        DateTime(d.year, d.month, d.day, h, m);

    test('Ramazan dışında null', () {
      final outside = _plusDays(r.start, -5);
      expect(
        ramadanCountdown(now: at(outside, 12, 0), today: _times()),
        isNull,
      );
    });

    test('imsaktan önce sahur, imsak-akşam arası iftar', () {
      final sahur = ramadanCountdown(now: at(day3, 3, 0), today: _times())!;
      expect(sahur.phase, RamadanPhase.sahur);
      expect(sahur.target, at(day3, 5, 0));
      expect(sahur.fastDay, 3);

      final atImsak = ramadanCountdown(now: at(day3, 5, 0), today: _times())!;
      expect(atImsak.phase, RamadanPhase.iftar);
      expect(atImsak.target, at(day3, 19, 0));

      final iftar = ramadanCountdown(now: at(day3, 12, 0), today: _times())!;
      expect(iftar.phase, RamadanPhase.iftar);
      expect(iftar.target, at(day3, 19, 0));
      expect(iftar.fastDay, 3);
    });

    test('akşamdan sonra yarının imsakı (varsa yarının vakti kullanılır)', () {
      final day4 = r.days[3];
      final withTomorrow = ramadanCountdown(
        now: at(day3, 21, 0),
        today: _times(),
        tomorrow: _times(imsak: '04:58'),
      )!;
      expect(withTomorrow.phase, RamadanPhase.sahur);
      expect(withTomorrow.target, at(day4, 4, 58));
      expect(withTomorrow.fastDay, 4);

      final fallback = ramadanCountdown(now: at(day3, 19, 0), today: _times())!;
      expect(fallback.target, at(day4, 5, 0));
    });

    test('son gün akşamdan sonra (bayram arifesi) null', () {
      final lastDay = r.end;
      expect(
        ramadanCountdown(now: at(lastDay, 12, 0), today: _times())!.phase,
        RamadanPhase.iftar,
      );
      expect(
        ramadanCountdown(now: at(lastDay, 20, 0), today: _times()),
        isNull,
      );
    });

    test('Ramazan arifesi: akşamdan önce null, akşamdan sonra ilk sahur', () {
      final eve = _plusDays(r.start, -1);
      expect(ramadanCountdown(now: at(eve, 12, 0), today: _times()), isNull);
      final c = ramadanCountdown(now: at(eve, 21, 0), today: _times())!;
      expect(c.phase, RamadanPhase.sahur);
      expect(c.target, at(r.start, 5, 0));
      expect(c.fastDay, 1);
    });

    test('ilk gün imsaktan önce sahur', () {
      final c = ramadanCountdown(now: at(r.start, 0, 30), today: _times())!;
      expect(c.phase, RamadanPhase.sahur);
      expect(c.fastDay, 1);
    });

    test('bozuk vakit metni -> null', () {
      expect(
        ramadanCountdown(
          now: at(day3, 12, 0),
          today: _times(imsak: '--:--'),
        ),
        isNull,
      );
    });
  });

  test('cityLabel', () {
    expect(cityLabel('İstanbul', 'Kadıköy'), 'İstanbul / Kadıköy');
    expect(cityLabel('İstanbul', 'İstanbul Kadıköy'), 'İstanbul / Kadıköy');
    expect(cityLabel('İstanbul', 'İstanbul'), 'İstanbul');
    expect(cityLabel('Van', 'Vanköy'), 'Van / Vanköy');
    expect(cityLabel('Ankara', null), 'Ankara');
    expect(cityLabel(null, 'Çankaya'), 'Çankaya');
    expect(cityLabel(null, null), '');
  });

  group('Türkçe tarih ayrıştırma', () {
    test('geçerli biçimler', () {
      expect(parseTurkishDate('08 Şubat 2027'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('8 şubat 2027'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('19 ŞUBAT 2026'), DateTime(2026, 2, 19));
      expect(parseTurkishDate('  01   Mart 2025 '), DateTime(2025, 3, 1));
      expect(parseTurkishDate('26 Mayıs 2026'), DateTime(2026, 5, 26));
      expect(parseTurkishDate('15 Ağustos 2026'), DateTime(2026, 8, 15));
      expect(parseTurkishDate('31 Aralık 2027'), DateTime(2027, 12, 31));
      expect(parseTurkishDate('10 Eylül 2028'), DateTime(2028, 9, 10));
      expect(parseTurkishDate('05 Kasım 2025'), DateTime(2025, 11, 5));
      expect(parseTurkishDate('08 Subat 2027'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('08 Şub 2027'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('08.02.2027'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('2027-02-08'), DateTime(2027, 2, 8));
      expect(parseTurkishDate('08 Şubat 2027 Pazartesi'), DateTime(2027, 2, 8));
    });

    test('geçersizler null', () {
      expect(parseTurkishDate(null), isNull);
      expect(parseTurkishDate(''), isNull);
      expect(parseTurkishDate('abc'), isNull);
      expect(parseTurkishDate('31 Şubat 2027'), isNull);
      expect(parseTurkishDate('00 Mart 2027'), isNull);
      expect(parseTurkishDate('12 Foo 2027'), isNull);
      expect(parseTurkishDate('12.13.2027'), isNull);
      expect(parseTurkishDate('08 Şubat'), isNull);
    });
  });

  group('Diyanet Ramazan takvimi (religious_days.json)', () {
    final entries =
        jsonDecode(File('assets/data/religious_days.json').readAsStringSync())
            as List<dynamic>;
    final calendar = RamadanCalendar.fromReligiousDays(entries);

    test('2025-2028 aralıkları resmi tarihlerle', () {
      expect(calendar.official.keys.toSet(), {1446, 1447, 1448, 1449});
      final r2026 = calendar.rangeOf(1447);
      expect(r2026.start, DateTime(2026, 2, 19));
      expect(r2026.end, DateTime(2026, 3, 19));
      expect(r2026.length, 29);
      final r2027 = calendar.rangeOf(1448);
      expect(r2027.start, DateTime(2027, 2, 8));
      expect(r2027.end, DateTime(2027, 3, 8));
      final r2025 = calendar.rangeOf(1446);
      expect(r2025.start, DateTime(2025, 3, 1));
      expect(r2025.end, DateTime(2025, 3, 29));
      final r2028 = calendar.rangeOf(1449);
      expect(r2028.start, DateTime(2028, 1, 28));
      expect(r2028.end, DateTime(2028, 2, 25));
    });

    test(
      'gün numarası Diyanet tarihine göre (hijri 1 gün önce başlasa da)',
      () {
        // hijri paketi 1447 Ramazanını 18 Şubat'ta başlatıyor, Diyanet 19 Şubat
        expect(_hijri.dayOf(DateTime(2026, 2, 18)), 1);
        expect(calendar.dayOf(DateTime(2026, 2, 18)), isNull);
        expect(calendar.dayOf(DateTime(2026, 2, 19, 23, 59)), 1);
        expect(calendar.dayOf(DateTime(2026, 3, 19)), 29);
        expect(calendar.dayOf(DateTime(2026, 3, 20)), isNull); // bayram
        expect(calendar.dayOf(DateTime(2027, 2, 8)), 1);
        expect(calendar.dayOf(DateTime(2027, 3, 8)), 29);
        expect(calendar.dayOf(DateTime(2027, 3, 9)), isNull);
        expect(calendar.dayOf(DateTime(2026, 10, 6)), isNull);
      },
    );

    test('içinde bulunulan / sıradaki Ramazan', () {
      expect(
        calendar.currentOrNext(DateTime(2026, 2, 18)).start,
        DateTime(2026, 2, 19),
      );
      expect(calendar.currentOrNext(DateTime(2026, 3, 19)).hijriYear, 1447);
      expect(
        calendar.currentOrNext(DateTime(2026, 3, 20)).start,
        DateTime(2027, 2, 8),
      );
      expect(
        calendar.currentOrNext(DateTime(2026, 10, 6)).start,
        DateTime(2027, 2, 8),
      );
      expect(
        calendar.currentOrNext(DateTime(2027, 3, 9)).start,
        DateTime(2028, 1, 28),
      );
    });

    test('kayıt olmayan yıl hijri paketine düşer', () {
      // 2028 Ramazanından sonra JSON'da kayıt yok -> 1450 hijri hesabı
      final next = calendar.currentOrNext(DateTime(2028, 2, 26));
      expect(next.hijriYear, 1450);
      expect(next.start, ramadanOfHijriYear(1450).start);
      final r1450 = ramadanOfHijriYear(1450);
      expect(calendar.dayOf(r1450.start), 1);
      expect(calendar.dayOf(r1450.end), r1450.length);
    });

    test('sayaç Diyanet takvimini kullanır', () {
      final at = DateTime(2026, 2, 18, 12);
      expect(ramadanCountdown(now: at, today: _times()), isNotNull); // hijri
      expect(
        ramadanCountdown(now: at, today: _times(), calendar: calendar),
        isNull,
      );
      // 18 Şubat akşamı: yarın (19 Şubat) 1. gün -> sahur sayacı
      final eve = ramadanCountdown(
        now: DateTime(2026, 2, 18, 21),
        today: _times(),
        calendar: calendar,
      );
      expect(eve!.phase, RamadanPhase.sahur); // ilk sahur gecesi
      expect(eve.fastDay, 1);
      expect(eve.target, DateTime(2026, 2, 19, 5, 0));
      final first = ramadanCountdown(
        now: DateTime(2026, 2, 19, 3),
        today: _times(),
        calendar: calendar,
      )!;
      expect(first.phase, RamadanPhase.sahur);
      expect(first.fastDay, 1);
      // son gün (19 Mart) akşamdan sonra bayram -> gizli
      expect(
        ramadanCountdown(
          now: DateTime(2026, 3, 19, 21),
          today: _times(),
          calendar: calendar,
        ),
        isNull,
      );
    });

    test('bozuk / tutarsız kayıtlar atlanır', () {
      final broken = RamadanCalendar.fromReligiousDays([
        null,
        'x',
        {'name': 'Ramazan Başlangıcı'},
        {'name': 'Ramazan Başlangıcı', 'date': '31 Şubat 2027'},
        {'name': 'Ramazan Başlangıcı', 'date': 42},
        // 40 gün: tutarsız -> atlanır
        {'name': 'Ramazan Başlangıcı', 'date': '01 Ocak 2029'},
        {'name': 'Ramazan Bayramı 1. Gün', 'date': '10 Şubat 2029'},
        // Bayram kaydı olmayan başlangıç -> atlanır
        {'name': 'Ramazan Başlangıcı', 'date': '01 Ocak 2031'},
      ]);
      expect(broken.official, isEmpty);
      expect(RamadanCalendar.fromReligiousDays(const []).official, isEmpty);
    });

    test('büyük/küçük harf ve ASCII isimler', () {
      final c = RamadanCalendar.fromReligiousDays([
        {'name': 'RAMAZAN BAŞLANGICI', 'date': '08 ŞUBAT 2027'},
        {'name': 'Ramazan Bayrami 1. Gun', 'date': '09 Mart 2027'},
        {'name': 'Ramazan Bayramı 2. Gün', 'date': '10 Mart 2027'},
      ]);
      expect(c.official[1448]?.start, DateTime(2027, 2, 8));
      expect(c.official[1448]?.length, 29);
    });
  });
}
