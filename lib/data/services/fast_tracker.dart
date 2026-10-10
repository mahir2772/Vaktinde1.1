import '../../features/imsakiye/imsakiye_logic.dart';
import 'prayer_tracker.dart';

/// Ramazan orucu takibinin saf hesapları (test edilebilir). Kayıt: tutulan ve
/// kaza orucuna eklenmiş günlerin "yyyy-MM-dd" kümeleri.
class FastTracker {
  FastTracker._();

  /// Ramazan bittikten sonra kartın görünmeye devam ettiği gün sayısı
  /// (tutulmayanları kazaya eklemek için)
  static const int daysAfterRamadan = 30;

  /// StorageService.loadMissedPrayers anahtarı (Kaza Takibi)
  static const String kazaKey = 'Oruç';

  /// Kartta gösterilecek Ramazan: içindeyken ve bitişinden sonraki
  /// [daysAfterRamadan] gün; diğer günlerde null
  static RamadanRange? visibleRamadan(RamadanCalendar calendar, DateTime today) {
    final range = calendar.currentOrNext(
      PrayerTracker.addDays(today, -daysAfterRamadan),
    );
    if (PrayerTracker.daysBetween(range.start, today) < 0) return null;
    if (PrayerTracker.daysBetween(range.end, today) > daysAfterRamadan) {
      return null;
    }
    return range;
  }

  static bool isFuture(DateTime date, DateTime today) =>
      PrayerTracker.daysBetween(today, date) > 0;

  /// Ramazan'da tutulan gün sayısı
  static int fastedCount(RamadanRange range, Set<String> fasted) => range.days
      .where((d) => fasted.contains(PrayerTracker.dateKey(d)))
      .length;

  /// Kaza orucuna eklenecek günler: bugünden önceki (bugünün orucu sürüyor
  /// olabilir), tutulmamış ve daha önce eklenmemiş Ramazan günleri
  static List<DateTime> kazaCandidates(
    RamadanRange range,
    Set<String> fasted,
    Set<String> added,
    DateTime today,
  ) => [
    for (final d in range.days)
      if (PrayerTracker.daysBetween(today, d) < 0 &&
          !fasted.contains(PrayerTracker.dateKey(d)) &&
          !added.contains(PrayerTracker.dateKey(d)))
        d,
  ];

  /// [date] gününü kümeye ekler/çıkarır; eski kayıtlar budanır
  static Set<String> withDay(
    Set<String> days,
    DateTime date,
    bool present, {
    required DateTime today,
  }) {
    final result = {...days};
    final key = PrayerTracker.dateKey(date);
    if (present) {
      result.add(key);
    } else {
      result.remove(key);
    }
    return prune(result, today);
  }

  /// Geçersiz ve [PrayerTracker.keepDays] günden eski kayıtları atar
  static Set<String> prune(Set<String> days, DateTime today) {
    final cutoff = PrayerTracker.dateKey(
      PrayerTracker.addDays(today, -PrayerTracker.keepDays),
    );
    return {
      for (final d in days)
        if (PrayerTracker.parseDateKey(d) != null && d.compareTo(cutoff) >= 0)
          d,
    };
  }
}
