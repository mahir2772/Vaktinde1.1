/// "Kaza hesapla" tahmini (saf, test edilebilir): yıl 365, ay 30 gün sayılır.
/// Hayız günlerinde kılınmayan namazın kazası gerekmez: toplam ay × aylık özel
/// gün namazdan düşülür. Oruçtan düşülmez (hayızda tutulamayan Ramazan orucu
/// da kaza edilir); her Ramazan 30 gün.
class KazaEstimate {
  static const int maxYears = 80;
  static const int maxMonths = 11;
  static const int maxExcusedDays = 10;
  static const int maxRamadans = 80;

  /// 5 vaktin ve vitrin her birine eklenecek kaza
  final int prayers;

  /// Kaza orucu (gün)
  final int fasts;

  const KazaEstimate._(this.prayers, this.fasts);

  factory KazaEstimate({
    int years = 0,
    int months = 0,
    int excusedDays = 0,
    int ramadans = 0,
  }) {
    final days = years * 365 + months * 30;
    final excused =
        (years * 12 + months) * excusedDays.clamp(0, maxExcusedDays);
    return KazaEstimate._(days - excused, ramadans * 30);
  }

  /// Eklenecek kaza yok (süre ve Ramazan 0): ekleme düğmesi kapalı
  bool get isEmpty => prayers == 0 && fasts == 0;
}
