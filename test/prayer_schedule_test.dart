import 'package:ezan_saati/core/ui/prayer_time_row.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/home/prayer_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

// Ana ekran sayacı ve 2x3 ızgara: sıradaki / şu anki / geçmiş vakit
void main() {
  final times = PrayerTimesModel(
    imsak: '05:35',
    gunes: '07:00',
    ogle: '12:57',
    ikindi: '16:08',
    aksam: '18:43',
    yatsi: '20:02',
  );
  DateTime at(int h, int m, [int s = 0]) => DateTime(2026, 10, 7, h, m, s);

  group('upcomingPrayer', () {
    test('gün içinde sıradaki vakit', () {
      final next = upcomingPrayer(times, at(14, 0))!;
      expect(next.key, 'İkindi');
      expect(next.time, at(16, 8));
      expect(next.isTomorrow, isFalse);
    });

    test('Güneş de sayaçta yer alır', () {
      expect(upcomingPrayer(times, at(6, 0))!.key, 'Güneş');
    });

    test('vakit tam girdiği dakikada bir sonrakine geçer', () {
      expect(upcomingPrayer(times, at(12, 56, 59))!.key, 'Öğle');
      expect(upcomingPrayer(times, at(12, 57))!.key, 'İkindi');
    });

    test('gece yarısından sonra imsaktan önce: bugünün imsakı', () {
      final next = upcomingPrayer(times, at(0, 30))!;
      expect(next.key, 'İmsak');
      expect(next.time, at(5, 35));
      expect(next.isTomorrow, isFalse);
    });

    test('yatsıdan sonra: yarının imsakı (ay/yıl geçişi dahil)', () {
      final next = upcomingPrayer(times, at(22, 0))!;
      expect(next.key, 'İmsak');
      expect(next.isTomorrow, isTrue);
      expect(next.time, DateTime(2026, 10, 8, 5, 35));

      final newYear = upcomingPrayer(times, DateTime(2026, 12, 31, 23, 0))!;
      expect(newYear.isTomorrow, isTrue);
      expect(newYear.time, DateTime(2027, 1, 1, 5, 35));
    });

    test('okunamayan vakitler atlanır, hiçbiri yoksa null', () {
      final broken = PrayerTimesModel(
        imsak: 'x',
        gunes: '',
        ogle: '12:57',
        ikindi: null,
        aksam: '18:43',
        yatsi: '20:02',
      );
      expect(upcomingPrayer(broken, at(13, 0))!.key, 'Akşam');
      expect(upcomingPrayer(broken, at(21, 0)), isNull);
    });
  });

  group('prayerRowStates', () {
    test('öğleden sonra: öğle şu an, ikindi sıradaki, öncekiler geçmiş', () {
      final s = prayerRowStates(times, at(14, 0));
      expect(s['İmsak'], PrayerRowState.past);
      expect(s['Güneş'], PrayerRowState.past);
      expect(s['Öğle'], PrayerRowState.current);
      expect(s['İkindi'], PrayerRowState.next);
      expect(s['Akşam'], PrayerRowState.upcoming);
      expect(s['Yatsı'], PrayerRowState.upcoming);
    });

    test('güneş doğduktan sonra öğleye kadar "şu an" vakit yok', () {
      final s = prayerRowStates(times, at(9, 0));
      expect(s.values, isNot(contains(PrayerRowState.current)));
      expect(s['İmsak'], PrayerRowState.past);
      expect(s['Güneş'], PrayerRowState.past);
      expect(s['Öğle'], PrayerRowState.next);
    });

    test('imsak ile güneş arası: imsak şu an, güneş sıradaki', () {
      final s = prayerRowStates(times, at(6, 0));
      expect(s['İmsak'], PrayerRowState.current);
      expect(s['Güneş'], PrayerRowState.next);
    });

    test('gece yarısından sonra: hepsi gelecek, imsak sıradaki', () {
      final s = prayerRowStates(times, at(1, 0));
      expect(s['İmsak'], PrayerRowState.next);
      for (final key in ['Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı']) {
        expect(s[key], PrayerRowState.upcoming, reason: key);
      }
    });

    test('yatsıdan sonra: yatsı şu an, imsak (yarın) sıradaki', () {
      final s = prayerRowStates(times, at(23, 0));
      expect(s['Yatsı'], PrayerRowState.current);
      expect(s['İmsak'], PrayerRowState.next);
      for (final key in ['Güneş', 'Öğle', 'İkindi', 'Akşam']) {
        expect(s[key], PrayerRowState.past, reason: key);
      }
    });

    test('her an tek bir sıradaki vakit vardır', () {
      for (var minute = 0; minute < 24 * 60; minute += 7) {
        final s = prayerRowStates(times, at(minute ~/ 60, minute % 60));
        expect(
          s.values.where((v) => v == PrayerRowState.next),
          hasLength(1),
          reason: '$minute',
        );
        expect(
          s.values.where((v) => v == PrayerRowState.current).length,
          lessThanOrEqualTo(1),
        );
      }
    });
  });

  test('prayerTimeOf', () {
    expect(prayerTimeOf(times, 'Akşam'), '18:43');
    expect(prayerTimeOf(times, 'Bilinmeyen'), '');
  });
}
