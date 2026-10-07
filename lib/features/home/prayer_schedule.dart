import '../../core/ui/prayer_time_row.dart';
import '../../data/models/prayer_times_model.dart';
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

DateTime? _at(DateTime day, String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0].trim());
  final m = int.tryParse(parts[1].trim());
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}

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

  /// Yatsıdan sonra: yarının imsakı (bugünün imsak saatiyle)
  final bool isTomorrow;

  const UpcomingPrayer(this.key, this.time, {this.isTomorrow = false});
}

/// Şu andan sonraki ilk vakit (sayaç ve vurgu için); okunamazsa null
UpcomingPrayer? upcomingPrayer(PrayerTimesModel times, DateTime now) {
  for (final key in homePrayerKeys) {
    final t = _at(now, _value(times, key));
    if (t != null && t.isAfter(now)) return UpcomingPrayer(key, t);
  }
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final imsak = _at(tomorrow, times.imsak);
  return imsak == null
      ? null
      : UpcomingPrayer('İmsak', imsak, isTomorrow: true);
}

/// Vakit ızgarası için durumlar: sıradaki, şu an içinde bulunulan (Güneş'ten
/// sonra öğleye kadar yok), geçmiş ve gelecek vakitler
Map<String, PrayerRowState> prayerRowStates(
  PrayerTimesModel times,
  DateTime now,
) {
  final next = upcomingPrayer(times, now);
  String? lastStarted;
  final started = <String>{};
  for (final key in homePrayerKeys) {
    final t = _at(now, _value(times, key));
    if (t != null && !t.isAfter(now)) {
      lastStarted = key;
      started.add(key);
    }
  }
  final current = lastStarted == 'Güneş' ? null : lastStarted;
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
