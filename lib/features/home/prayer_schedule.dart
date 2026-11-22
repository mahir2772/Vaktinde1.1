import '../../core/ui/prayer_time_row.dart';
import '../../data/models/prayer_times_model.dart';
import '../../data/services/prayer_timezone.dart';
import '../../l10n/app_localizations.dart';

/// Ana ekrandaki 6 vakit (Güneş namaz vakti değil ama sayaçta yer alır)
const List<String> homePrayerKeys = [
  'İmsak',
  'Güneş',
  'Öğle',
  'İkindi',
  'Akşam',
  'Yatsı',
];

String? _value(PrayerTimesModel times, String key) => switch (key) {
  'İmsak' => times.imsak,
  'Güneş' => times.gunes,
  'Öğle' => times.ogle,
  'İkindi' => times.ikindi,
  'Akşam' => times.aksam,
  'Yatsı' => times.yatsi,
  _ => null,
};

/// [key] vaktinin "HH:mm" değeri ("" okunamazsa)
String prayerTimeOf(PrayerTimesModel times, String key) =>
    _value(times, key) ?? '';

DateTime? _at(String? zone, DateTime day, String? hhmm) =>
    PrayerTimeZone.parseAt(zone, day, hhmm);

String localizedPrayerName(String key, AppLocalizations loc) => switch (key) {
  'İmsak' => loc.imsak,
  'Güneş' => loc.gunes,
  'Öğle' => loc.ogle,
  'İkindi' => loc.ikindi,
  'Akşam' => loc.aksam,
  'Yatsı' => loc.yatsi,
  _ => key,
};

class UpcomingPrayer {
  final String key;
  final DateTime time;

  /// Ertesi güne sarkan vakit (yatsıdan sonra yarının imsakı veya yüksek
  /// enlem yazında gece yarısını geçen yatsı)
  final bool isTomorrow;

  const UpcomingPrayer(this.key, this.time, {this.isTomorrow = false});
}

/// Şu andan sonraki ilk vakit (sayaç ve vurgu için); okunamazsa null.
/// [times.timeZone] varsa vakitler o şehrin saat diliminde çözülür; yüksek
/// enlem yazında gece yarısını geçen Yatsı (örn. Akşam 22:05, Yatsı 00:15)
/// atlanmadan sayaca girer.
UpcomingPrayer? upcomingPrayer(PrayerTimesModel times, DateTime now) {
  final zone = times.timeZone;
  final cityNow = PrayerTimeZone.nowIn(zone, now);
  final afterMidnightYatsi = PrayerTimeZone.isYatsiAfterMidnight(times);
  final tomorrow = DateTime(cityNow.year, cityNow.month, cityNow.day + 1);

  UpcomingPrayer? best;
  void consider(String key, DateTime? t, {bool isTomorrow = false}) {
    if (t == null || !t.isAfter(cityNow)) return;
    if (best == null || t.isBefore(best!.time)) {
      best = UpcomingPrayer(key, t, isTomorrow: isTomorrow);
    }
  }

  for (final key in homePrayerKeys) {
    if (key == 'Yatsı' && afterMidnightYatsi) {
      consider(key, _at(zone, cityNow, times.yatsi));
      consider(key, _at(zone, tomorrow, times.yatsi), isTomorrow: true);
    } else {
      consider(key, _at(zone, cityNow, _value(times, key)));
    }
  }
  if (best != null) return best;

  final imsak = _at(zone, tomorrow, times.imsak);
  return imsak == null
      ? null
      : UpcomingPrayer('İmsak', imsak, isTomorrow: true);
}

/// Vakit ızgarası için durumlar: sıradaki, şu an içinde bulunulan (Güneş'ten
/// sonra öğleye kadar yok), geçmiş ve gelecek vakitler. Gece yarısını geçen
/// Yatsı ve seçilen şehrin saat dilimini destekler.
Map<String, PrayerRowState> prayerRowStates(
  PrayerTimesModel times,
  DateTime now,
) {
  final zone = times.timeZone;
  final cityNow = PrayerTimeZone.nowIn(zone, now);
  final afterMidnightYatsi = PrayerTimeZone.isYatsiAfterMidnight(times);
  final next = upcomingPrayer(times, now);

  final imsakToday = _at(zone, cityNow, times.imsak);
  final yatsiToday = _at(zone, cityNow, times.yatsi);

  String? current;
  final started = <String>{};

  if (afterMidnightYatsi &&
      imsakToday != null &&
      cityNow.isBefore(imsakToday)) {
    // Gece yarısı ile imsak arasında: yatsı henüz girmediyse akşam, girdiyse
    // yatsı sürüyor; günün diğer vakitleri gelecek.
    if (yatsiToday != null && cityNow.isBefore(yatsiToday)) {
      current = 'Akşam';
    } else {
      current = 'Yatsı';
    }
  } else {
    final tomorrow = DateTime(cityNow.year, cityNow.month, cityNow.day + 1);
    String? lastStarted;
    for (final key in homePrayerKeys) {
      final t = (key == 'Yatsı' && afterMidnightYatsi)
          ? _at(zone, tomorrow, times.yatsi)
          : _at(zone, cityNow, _value(times, key));
      if (t != null && !t.isAfter(cityNow)) {
        lastStarted = key;
        started.add(key);
      }
    }
    current = lastStarted == 'Güneş' ? null : lastStarted;
  }

  return {
    for (final key in homePrayerKeys)
      key: key == current
          ? PrayerRowState.current
          : (next != null && key == next.key)
          ? PrayerRowState.next
          : started.contains(key)
          ? PrayerRowState.past
          : PrayerRowState.upcoming,
  };
}
