import '../../data/models/prayer_times_model.dart';
import '../../data/services/prayer_timezone.dart';

/// Diyanet: kerahat vakitleri yaklaşık 45 dakika
const int kerahatMinutes = 45;

/// Kerahat vakti ana ekranda bu kadar dakika önceden gösterilir
const int kerahatLookaheadMinutes = 60;

class KerahatInterval {
  final DateTime start;
  final DateTime end;

  const KerahatInterval(this.start, this.end);

  bool isActiveAt(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is KerahatInterval && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'KerahatInterval($start – $end)';
}

DateTime _at(String? zone, DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  return PrayerTimeZone.at(zone, day, int.parse(parts[0]), int.parse(parts[1]));
}

/// [day] gününün kerahat vakitleri (sıralı): güneş doğduktan sonra, istiva (öğleden
/// önce), güneş batmadan önce (akşamdan önce).
List<KerahatInterval> kerahatIntervals(PrayerTimesModel times, DateTime day) {
  const span = Duration(minutes: kerahatMinutes);
  final zone = times.timeZone;
  final cityDay = PrayerTimeZone.nowIn(zone, day);
  final gunes = _at(zone, cityDay, times.gunes!);
  final ogle = _at(zone, cityDay, times.ogle!);
  final aksam = _at(zone, cityDay, times.aksam!);
  return [
    KerahatInterval(gunes, gunes.add(span)),
    KerahatInterval(ogle.subtract(span), ogle),
    KerahatInterval(aksam.subtract(span), aksam),
  ];
}

/// Şu an süren ya da [kerahatLookaheadMinutes] dakika içinde başlayacak kerahat
/// vakti; yoksa (veya vakitler okunamazsa) null. [times] bugünün vakitleri.
KerahatInterval? relevantKerahat(PrayerTimesModel times, DateTime now) {
  try {
    final cityNow = PrayerTimeZone.nowIn(times.timeZone, now);
    final limit = cityNow.add(const Duration(minutes: kerahatLookaheadMinutes));
    for (final interval in kerahatIntervals(times, cityNow)) {
      if (!cityNow.isBefore(interval.end)) continue;
      if (interval.isActiveAt(cityNow) || !interval.start.isAfter(limit)) {
        return interval;
      }
    }
  } catch (e) {
    return null;
  }
  return null;
}
