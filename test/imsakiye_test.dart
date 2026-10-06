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
          expect(ramadanDayOf(d), i + 1);
        }
      }
    });

    test(
      'içindeyken mevcut, öncesinde aynı yılın, sonrasında gelecek yılın Ramazanı',
      () {
        final r1447 = ramadanOfHijriYear(1447);
        final r1448 = ramadanOfHijriYear(1448);

        // Ramazan içinde (ilk, orta, son gün ve günün geç saati)
        expect(currentOrNextRamadan(r1447.start).hijriYear, 1447);
        expect(
          currentOrNextRamadan(
            _plusDays(r1447.start, 10).add(const Duration(hours: 23)),
          ).hijriYear,
          1447,
        );
        expect(currentOrNextRamadan(r1447.end).hijriYear, 1447);

        // Ramazandan bir gün önce -> aynı Ramazan
        expect(
          currentOrNextRamadan(_plusDays(r1447.start, -1)).hijriYear,
          1447,
        );

        // Bayram (Ramazan bitti) -> sonraki yıl
        expect(currentOrNextRamadan(_plusDays(r1447.end, 1)).hijriYear, 1448);

        // Bugünkü bağlam: Ekim 2026 -> Ramazan 1448
        final next = currentOrNextRamadan(DateTime(2026, 10, 6, 14, 30));
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
}
