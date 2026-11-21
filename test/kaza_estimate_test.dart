// "Kaza hesapla": yıl 365 / ay 30 gün, hayız günleri namazdan düşülür,
// oruçtan düşülmez; oruç gün gün veya Ramazan (+30) olarak eklenir;
// eklenecek bir şey yoksa ekleme kapalı.
import 'package:ezan_saati/features/missed_prayers/kaza_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('süre 0 → eklenecek kaza yok', () {
    final e = KazaEstimate();
    expect((e.prayers, e.fasts, e.isEmpty), (0, 0, true));
    // Süre yokken özel gün tek başına bir şey değiştirmez
    expect(KazaEstimate(excusedDays: 7).isEmpty, isTrue);
  });

  test('gün = yıl × 365 + ay × 30', () {
    expect(KazaEstimate(years: 1).prayers, 365);
    expect(KazaEstimate(months: 1).prayers, 30);
    expect(KazaEstimate(years: 2, months: 3).prayers, 820);
    expect(KazaEstimate(years: 2, months: 3).fasts, 0);
  });

  test('özel gün: toplam ay × aylık gün namazdan düşülür', () {
    expect(KazaEstimate(years: 1, excusedDays: 7).prayers, 365 - 12 * 7);
    expect(
      KazaEstimate(years: 2, months: 3, excusedDays: 5).prayers,
      820 - 135,
    );
    // En çok 10 gün; en uç durumda da eksiye inmez
    expect(KazaEstimate(months: 1, excusedDays: 15).prayers, 20);
    expect(
      KazaEstimate(
        years: KazaEstimate.maxYears,
        months: KazaEstimate.maxMonths,
        excusedDays: KazaEstimate.maxExcusedDays,
      ).prayers,
      greaterThan(0),
    );
  });

  test('oruç: gün gün veya Ramazan × 30, özel gün düşülmez', () {
    final byDays = KazaEstimate(years: 1, excusedDays: 7, fastDays: 14);
    expect(byDays.fasts, 14);
    expect(byDays.prayers, 365 - 12 * 7);

    // Sadece gün gün oruç kazası eklenebilir
    final onlyDays = KazaEstimate(fastDays: 7);
    expect((onlyDays.prayers, onlyDays.fasts), (0, 7));
    expect(onlyDays.isEmpty, isFalse);

    // Ramazan kısayolu + tekil günler tutarlı toplanır ve sınıra kırpılır
    expect(KazaEstimate(ramadans: 2).fasts, 60);
    expect(KazaEstimate(fastDays: 5, ramadans: 1).fasts, 35);
    expect(
      KazaEstimate(fastDays: KazaEstimate.maxFastDays + 50).fasts,
      KazaEstimate.maxFastDays,
    );
  });
}
