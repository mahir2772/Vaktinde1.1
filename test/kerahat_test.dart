import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/home/kerahat_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = PrayerTimesModel(
    imsak: '05:00',
    gunes: '06:30',
    ogle: '13:00',
    ikindi: '16:30',
    aksam: '19:00',
    yatsi: '20:30',
  );
  DateTime at(int h, int m) => DateTime(2026, 3, 10, h, m);
  final sunrise = KerahatInterval(at(6, 30), at(7, 15));
  final istiva = KerahatInterval(at(12, 15), at(13, 0));
  final sunset = KerahatInterval(at(18, 15), at(19, 0));

  test('Üç kerahat aralığı, 45 dakika', () {
    expect(kerahatMinutes, 45);
    expect(kerahatIntervals(times, at(0, 0)), [sunrise, istiva, sunset]);
  });

  test('Sadece sürerken ya da 60 dk içinde başlayacaksa gösterilir', () {
    expect(relevantKerahat(times, at(5, 29)), isNull); // 61 dk önce
    expect(relevantKerahat(times, at(5, 30)), sunrise); // tam 60 dk önce
    expect(relevantKerahat(times, at(6, 30)), sunrise);
    expect(sunrise.isActiveAt(at(6, 30)), isTrue);
    expect(sunrise.isActiveAt(at(6, 29)), isFalse);
    expect(relevantKerahat(times, at(7, 14)), sunrise);
    expect(relevantKerahat(times, at(7, 15)), isNull); // bitti
    expect(relevantKerahat(times, at(11, 14)), isNull);
    expect(relevantKerahat(times, at(11, 15)), istiva);
    expect(relevantKerahat(times, at(12, 59)), istiva);
    expect(relevantKerahat(times, at(13, 0)), isNull);
    expect(relevantKerahat(times, at(17, 30)), sunset);
    expect(relevantKerahat(times, at(18, 59)), sunset);
    expect(relevantKerahat(times, at(19, 0)), isNull);
    expect(relevantKerahat(times, at(23, 30)), isNull);
  });

  test('Okunamayan vakitte hata vermez', () {
    final broken = PrayerTimesModel(
      imsak: '05:00',
      gunes: '--:--',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: '19:00',
      yatsi: '20:30',
    );
    expect(relevantKerahat(broken, at(6, 40)), isNull);
  });
}
