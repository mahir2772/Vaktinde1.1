import '../../data/models/prayer_times_model.dart';

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

DateTime _at(DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// [day] gününün kerahat vakitleri (sıralı): güneş doğduktan sonra, istiva (öğleden
/// önce), güneş batmadan önce (akşamdan önce).
List<KerahatInterval> kerahatIntervals(PrayerTimesModel times, DateTime day) {
  const span = Duration(minutes: kerahatMinutes);
  final gunes = _at(day, times.gunes!);
  final ogle = _at(day, times.ogle!);
  final aksam = _at(day, times.aksam!);
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
    final limit = now.add(const Duration(minutes: kerahatLookaheadMinutes));
    for (final interval in kerahatIntervals(times, now)) {
      if (!now.isBefore(interval.end)) continue;
      if (interval.isActiveAt(now) || !interval.start.isAfter(limit)) {
        return interval;
      }
    }
  } catch (e) {
    return null;
  }
  return null;
}
