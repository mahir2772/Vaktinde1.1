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

  test('İstanbul vakitleri Diyanet ile en fazla 1 dk farklı', () {
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
  }, skip: isTurkeyTz ? false : 'TZ=Europe/Istanbul ile çalıştırın');

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
