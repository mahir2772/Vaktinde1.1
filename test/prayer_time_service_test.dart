import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

void main() {
  // Kaynak: namazvakitleri.diyanet.gov.tr, İstanbul, 16.04.2020
  // Cihaz saat dilimi Türkiye olmalı: TZ=Europe/Istanbul flutter test
  final isTurkeyTz =
      DateTime(2020, 4, 16).timeZoneOffset == const Duration(hours: 3);

  test(
    'İstanbul vakitleri Diyanet ile en fazla 1 dk farklı',
    () {
      final times = PrayerTimeService().calculate(
        41.005616,
        28.97638,
        date: DateTime(2020, 4, 16),
      );
      final expected = {
        times.imsak: '04:44',
        times.gunes: '06:16',
        times.ogle: '13:09',
        times.ikindi: '16:53',
        times.aksam: '19:52',
        times.yatsi: '21:19',
      };
      expected.forEach((actual, diyanet) {
        expect(
          (_minutes(actual!) - _minutes(diyanet)).abs(),
          lessThanOrEqualTo(1),
          reason: 'hesaplanan $actual, Diyanet $diyanet',
        );
      });
    },
    skip: isTurkeyTz ? false : 'TZ=Europe/Istanbul ile çalıştırın',
  );

  test(
    'IANA saat dilimi verilince cihaz diliminden bağımsız şehrin saati döner',
    () {
      final service = PrayerTimeService();
      // İstanbul (Europe/Istanbul) her cihaz diliminde Diyanet ±1 dk
      final ist = service.calculate(
        41.005616,
        28.97638,
        date: DateTime(2020, 4, 16),
        timeZone: 'Europe/Istanbul',
      );
      expect(ist.timeZone, 'Europe/Istanbul');
      expect(
        (_minutes(ist.ogle!) - _minutes('13:09')).abs(),
        lessThanOrEqualTo(1),
      );

      // Aynı gün Berlin (Europe/Berlin, UTC+2) ve İstanbul (UTC+3) arasında
      // saat farkı + boylam farkı tutarlı olmalı; Berlin öğlesi ~13:05 civarı
      final berlin = service.calculate(
        52.52,
        13.405,
        date: DateTime(2026, 1, 15),
        timeZone: 'Europe/Berlin',
      );
      expect(berlin.timeZone, 'Europe/Berlin');
      expect(
        _minutes(berlin.ogle!),
        inInclusiveRange(_minutes('12:00'), _minutes('12:40')),
      );
    },
  );

  test('Yüksek enlemde (Berlin, 21 Haziran) İmsak ile Yatsı birleşmez', () {
    final t = PrayerTimeService().calculate(
      52.52,
      13.405,
      date: DateTime(2026, 6, 21),
    );
    // Saat diliminden bağımsız: Yatsı'dan İmsak'a en az 2 saat olmalı
    final gap = (_minutes(t.imsak!) - _minutes(t.yatsi!)) % 1440;
    expect(gap, greaterThan(120), reason: 'İmsak ${t.imsak}, Yatsı ${t.yatsi}');
  });

  test('İnce ayar dakikaları vakte eklenir', () {
    final service = PrayerTimeService();
    final base = service.calculate(41.0, 29.0, date: DateTime(2026, 1, 15));
    final adjusted = service.calculate(
      41.0,
      29.0,
      date: DateTime(2026, 1, 15),
      offsets: {'Öğle': 2, 'Yatsı': -3},
    );
    expect(_minutes(adjusted.ogle!) - _minutes(base.ogle!), 2);
    expect(_minutes(adjusted.yatsi!) - _minutes(base.yatsi!), -3);
    expect(adjusted.imsak, base.imsak);
  });
}
