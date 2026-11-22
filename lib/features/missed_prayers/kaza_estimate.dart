/// "Kaza hesapla" tahmini (saf, test edilebilir): yıl 365, ay 30 gün sayılır.
/// Hayız günlerinde kılınmayan namazın kazası gerekmez: toplam ay × aylık özel
/// gün namazdan düşülür. Oruçtan düşülmez (hayızda tutulamayan oruç da kaza
/// edilir); oruç kazası doğrudan gün gün ([fastDays]) ya da Ramazan ([ramadans]
/// × 30) olarak verilebilir.
class KazaEstimate {
  static const int maxYears = 80;
  static const int maxMonths = 11;
  static const int maxExcusedDays = 10;
  static const int maxRamadans = 80;
  static const int maxFastDays = maxRamadans * 30;

  /// 5 vaktin ve vitrin her birine eklenecek kaza
  final int prayers;

  /// Kaza orucu (gün)
  final int fasts;

  const KazaEstimate._(this.prayers, this.fasts);

  factory KazaEstimate({
    int years = 0,
    int months = 0,
    int excusedDays = 0,
    int fastDays = 0,
    int ramadans = 0,
  }) {
    final safeYears = years.clamp(0, maxYears);
    final safeMonths = months.clamp(0, maxMonths);
    final days = safeYears * 365 + safeMonths * 30;
    final excused =
        (safeYears * 12 + safeMonths) * excusedDays.clamp(0, maxExcusedDays);
    final prayers = (days - excused).clamp(0, days);
    final fasts = (fastDays + ramadans * 30).clamp(0, maxFastDays);
    return KazaEstimate._(prayers, fasts);
  }

  /// Eklenecek kaza yok (süre ve oruç 0): ekleme düğmesi kapalı
  bool get isEmpty => prayers == 0 && fasts == 0;

  /// Günde 1 günlük kaza (her vakitten 1 kaza) kılınırsa namaz kazalarının
  /// tahmini bitiş süresi. [maxPrayerCount] ≤ 0 ise null.
  /// 1 yıl = 365 gün, 1 ay = 30 gün (KazaEstimate ile aynı kural).
  static ({int years, int months, int days})? completionDuration(
    int maxPrayerCount,
  ) {
    if (maxPrayerCount <= 0) return null;
    final years = maxPrayerCount ~/ 365;
    final remAfterYears = maxPrayerCount % 365;
    final months = remAfterYears ~/ 30;
    final days = remAfterYears % 30;
    return (years: years, months: months, days: days);
  }
}
