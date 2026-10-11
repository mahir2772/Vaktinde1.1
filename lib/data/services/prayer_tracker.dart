/// Namaz takibi ve "vakit çıkıyor" hatırlatmalarının saf hesapları (test edilebilir).
/// Kayıt biçimi: yerel tarih "yyyy-MM-dd" → kılınan vakitlerin bit maskesi.
/// Özel günler (hayız/nifas; "yyyy-MM-dd" kümesi): o günlerin namazı kaza
/// edilmez → seri bu günleri atlar (bozmaz, saymaz), oran ve kaza adaylarına
/// katılmaz. O günlerde işaretlenmiş vakitler kayıtta kalır, sayılmaz.
class PrayerTracker {
  PrayerTracker._();

  /// Takip edilen farz vakitler (Güneş yok). "İmsak" = sabah namazı.
  static const List<String> prayerKeys = [
    "İmsak",
    "Öğle",
    "İkindi",
    "Akşam",
    "Yatsı",
  ];

  /// StorageService.loadMissedPrayers anahtarları
  static const Map<String, String> kazaKeys = {
    "İmsak": "Sabah",
    "Öğle": "Öğle",
    "İkindi": "İkindi",
    "Akşam": "Akşam",
    "Yatsı": "Yatsı",
  };

  static const int fullMask = 31;
  static const int keepDays = 400;
  static const int statsDays = 30; // oran penceresi (bugün dahil)
  static const int kazaDays = 30; // kazaya ekleme: dünden geriye

  // Bildirim aksiyonu
  static const String actionId = 'mark_prayed';
  static const String _payloadPrefix = 'prayed';

  // "Vakit çıkmadan hatırlat": ID 100-124 (5 gün x 5 vakit)
  static const int endReminderBaseId = 100;
  static const int endReminderDays = 5;
  static const List<int> endReminderMinuteOptions = [15, 30, 45];
  static const int defaultEndReminderMinutes = 30;

  static bool isEndReminderId(int id) =>
      id >= endReminderBaseId &&
      id < endReminderBaseId + endReminderDays * prayerKeys.length;

  static int bit(String key) {
    final i = prayerKeys.indexOf(key);
    if (i < 0) throw ArgumentError.value(key, 'key');
    return 1 << i;
  }

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  /// Takvim gününün sırası (1970'ten beri; yaz saatinden bağımsız)
  static int epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Takvim günü farkı (yaz saatinden bağımsız)
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDateKey(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final d = DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    return dateKey(d) == s ? d : null;
  }

  static int countOf(int mask) {
    int c = 0;
    for (int i = 0; i < prayerKeys.length; i++) {
      if ((mask & (1 << i)) != 0) c++;
    }
    return c;
  }

  static int maskOf(Map<String, int> log, DateTime date) =>
      (log[dateKey(date)] ?? 0) & fullMask;

  static bool isPrayed(Map<String, int> log, DateTime date, String key) =>
      (maskOf(log, date) & bit(key)) != 0;

  /// [date] günündeki [key] vaktini işaretler/kaldırır; eski kayıtlar budanır.
  static Map<String, int> withPrayed(
    Map<String, int> log,
    DateTime date,
    String key,
    bool prayed, {
    required DateTime today,
  }) {
    final result = Map<String, int>.from(log);
    final k = dateKey(date);
    int mask = (result[k] ?? 0) & fullMask;
    mask = prayed ? (mask | bit(key)) : (mask & ~bit(key));
    if (mask == 0) {
      result.remove(k);
    } else {
      result[k] = mask;
    }
    return prune(result, today);
  }

  /// [keepDays] günden eski ve boş kayıtları atar
  static Map<String, int> prune(Map<String, int> log, DateTime today) {
    final cutoff = dateKey(addDays(today, -keepDays));
    return {
      for (final e in log.entries)
        if (e.key.compareTo(cutoff) >= 0 && (e.value & fullMask) != 0)
          e.key: e.value & fullMask,
    };
  }

  /// [date] özel gün (hayız/nifas) olarak işaretli mi
  static bool isExcused(Set<String> excused, DateTime date) =>
      excused.contains(dateKey(date));

  /// [date] gününü özel gün yapar/kaldırır; geçersiz ve eski kayıtlar budanır.
  static Set<String> withExcused(
    Set<String> excused,
    DateTime date,
    bool value, {
    required DateTime today,
  }) {
    final result = {...excused};
    final k = dateKey(date);
    if (value) {
      result.add(k);
    } else {
      result.remove(k);
    }
    return pruneExcused(result, today);
  }

  /// Geçersiz ve [keepDays] günden eski özel gün kayıtlarını atar
  static Set<String> pruneExcused(Set<String> excused, DateTime today) {
    final cutoff = dateKey(addDays(today, -keepDays));
    return {
      for (final d in excused)
        if (parseDateKey(d) != null && d.compareTo(cutoff) >= 0) d,
    };
  }

  /// Beş vaktin tamamının kılındığı ardışık günler. Bugün sadece tamamsa sayılır;
  /// [yesterdayYatsiOngoing] (imsak girmedi) ise dünün yatsısı da henüz eksik sayılmaz.
  /// Özel günler ([excused]) atlanır: seriyi bozmaz, seriye de sayılmaz.
  static int streak(
    Map<String, int> log,
    DateTime today, {
    Set<String> excused = const {},
    bool yesterdayYatsiOngoing = false,
  }) {
    bool skipped(DateTime d) => isExcused(excused, d);
    int count = 0;
    if (!skipped(today) && maskOf(log, today) == fullMask) count++;
    DateTime d = addDays(today, -1);
    if (yesterdayYatsiOngoing) {
      if (!skipped(d)) {
        final mask = maskOf(log, d);
        if (mask == fullMask) {
          count++;
        } else if ((mask | bit("Yatsı")) != fullMask) {
          return count;
        }
      }
      d = addDays(d, -1);
    }
    // Kayıt ve özel gün kümesi sonlu: en geç ikisinin de öncesinde biter
    while (true) {
      if (!skipped(d)) {
        if (maskOf(log, d) != fullMask) return count;
        count++;
      }
      d = addDays(d, -1);
    }
  }

  /// Son [statsDays] günde (bugün dahil, takibe başlanan [since] gününden itibaren)
  /// kılınan / vakti girmiş farz oranı (0-1). [todayDue]: bugün vakti girmiş farz sayısı.
  /// [yesterdayYatsiOngoing]: dünün yatsısı kılınmadıysa henüz paydaya girmez.
  /// Özel günler ([excused]) ne paya ne paydaya girer.
  /// Değerlendirilecek vakit yoksa null.
  static double? completionRate(
    Map<String, int> log,
    DateTime today, {
    required int todayDue,
    DateTime? since,
    Set<String> excused = const {},
    bool yesterdayYatsiOngoing = false,
  }) {
    if (since == null) return null;
    int done = 0;
    int total = 0;
    for (int i = 0; i < statsDays; i++) {
      final d = addDays(today, -i);
      if (daysBetween(since, d) < 0) break;
      if (isExcused(excused, d)) continue;
      final c = countOf(maskOf(log, d));
      int due = prayerKeys.length;
      if (i == 0) due = todayDue;
      if (i == 1 && yesterdayYatsiOngoing) due = prayerKeys.length - 1;
      done += c;
      total += c > due ? c : due;
    }
    if (total == 0) return null;
    return done / total;
  }

  /// Kazaya eklenecek (tarih → vakit maskesi): dünden geriye [kazaDays] gün, [since]
  /// öncesi hariç; kılındı işaretli ya da daha önce eklenmiş ([added]) vakitler hariç.
  /// Özel günlerin ([excused]) namazı kaza edilmez, hiç aday olmaz.
  /// [yesterdayYatsiOngoing]: imsak girmediyse dünün yatsısı henüz kaza değildir.
  static Map<String, int> kazaCandidates(
    Map<String, int> log,
    Map<String, int> added,
    DateTime today, {
    DateTime? since,
    Set<String> excused = const {},
    bool yesterdayYatsiOngoing = false,
  }) {
    final result = <String, int>{};
    if (since == null) return result;
    for (int i = 1; i <= kazaDays; i++) {
      final d = addDays(today, -i);
      if (daysBetween(since, d) < 0) break;
      if (isExcused(excused, d)) continue;
      int missing = fullMask & ~maskOf(log, d) & ~maskOf(added, d);
      if (i == 1 && yesterdayYatsiOngoing) missing &= ~bit("Yatsı");
      if (missing != 0) result[dateKey(d)] = missing;
    }
    return result;
  }

  static int totalCount(Map<String, int> masks) =>
      masks.values.fold(0, (sum, m) => sum + countOf(m & fullMask));

  /// Maske haritasından kaza sayaçlarına eklenecek adetler (Sabah, Öğle, ...)
  static Map<String, int> kazaDeltas(Map<String, int> candidates) {
    final deltas = <String, int>{};
    for (final mask in candidates.values) {
      for (final key in prayerKeys) {
        if ((mask & bit(key)) != 0) {
          final kazaKey = kazaKeys[key]!;
          deltas[kazaKey] = (deltas[kazaKey] ?? 0) + 1;
        }
      }
    }
    return deltas;
  }

  /// İki maske haritasının birleşimi
  static Map<String, int> mergeMasks(Map<String, int> a, Map<String, int> b) {
    final result = Map<String, int>.from(a);
    b.forEach((k, v) => result[k] = (result[k] ?? 0) | v);
    return result;
  }

  // --- Bildirim aksiyonu yükü: "prayed|yyyy-MM-dd|Öğle" ---

  static String payload(DateTime date, String key) =>
      '$_payloadPrefix|${dateKey(date)}|$key';

  static ({DateTime date, String key})? parsePayload(String? payload) {
    if (payload == null) return null;
    final parts = payload.split('|');
    if (parts.length != 3 || parts[0] != _payloadPrefix) return null;
    final date = parseDateKey(parts[1]);
    if (date == null || !prayerKeys.contains(parts[2])) return null;
    return (date: date, key: parts[2]);
  }

  // --- Vakit çıkış hatırlatması ID'leri ---
  // Hatırlatma günü d: dünkü yatsı (d'nin imsakında biter) + d'nin sabah, öğle, ikindi,
  // akşamı; hepsi d günü çalar. ID takvim gününe bağlı olduğundan farklı günlerde kurulan
  // planlar aynı hatırlatmaya aynı ID'yi verir; ardışık 5 günde çakışma olmaz.

  /// [key] vaktinin ([prayerDate] günü) hatırlatmasının ait olduğu gün
  static DateTime reminderDay(DateTime prayerDate, String key) =>
      key == "Yatsı" ? addDays(prayerDate, 1) : day(prayerDate);

  static int endReminderId(DateTime reminderDay, String key) =>
      endReminderBaseId +
      (epochDay(reminderDay) % endReminderDays) * prayerKeys.length +
      prayerKeys.indexOf(key);

  /// Vakit kılındı işaretlenince iptal edilecek hatırlatma ID'si. Plan penceresi
  /// (bugün + 4 gün) dışındaysa null: aynı ID başka günün hatırlatması olabilir.
  static int? endReminderIdToCancel(
    DateTime prayerDate,
    String key,
    DateTime now,
  ) {
    final r = reminderDay(prayerDate, key);
    final diff = daysBetween(now, r);
    if (diff < 0 || diff >= endReminderDays) return null;
    return endReminderId(r, key);
  }
}
