import 'package:hijri/hijri_calendar.dart';

import '../../data/models/prayer_times_model.dart';

// İmsakiye ve Ramazan sayacı için saf (UI'sız) hesaplamalar.
// Hicri takvim: hijri paketi (Ümmü'l-Kurâ), uygulamanın geri kalanı gibi düzeltmesiz.

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Miladi ayın tüm günleri (yerel gece yarısı).
List<DateTime> daysOfMonth(int year, int month) {
  final count = DateTime(year, month + 1, 0).day;
  return List.generate(count, (i) => DateTime(year, month, i + 1));
}

/// Tarih Ramazan'daysa kaçıncı gün olduğu, değilse null.
int? ramadanDayOf(DateTime date) {
  final h = HijriCalendar.fromDate(date);
  return h.hMonth == 9 ? h.hDay : null;
}

class RamadanRange {
  final int hijriYear;
  final DateTime start;
  final int length;

  const RamadanRange({
    required this.hijriYear,
    required this.start,
    required this.length,
  });

  DateTime get end => DateTime(start.year, start.month, start.day + length - 1);

  List<DateTime> get days => List.generate(
    length,
    (i) => DateTime(start.year, start.month, start.day + i),
  );
}

RamadanRange ramadanOfHijriYear(int hijriYear) {
  final cal = HijriCalendar();
  return RamadanRange(
    hijriYear: hijriYear,
    start: cal.hijriToGregorian(hijriYear, 9, 1),
    length: cal.getDaysInMonth(hijriYear, 9),
  );
}

/// İçinde bulunulan Ramazan; değilse sıradaki Ramazan.
RamadanRange currentOrNextRamadan(DateTime date) {
  final h = HijriCalendar.fromDate(dateOnly(date));
  return ramadanOfHijriYear(h.hMonth <= 9 ? h.hYear : h.hYear + 1);
}

final RegExp _hhmm = RegExp(r'^\s*(\d{1,2}):(\d{2})');

/// "HH:mm" metnini verilen güne uygular; geçersizse null.
DateTime? timeOnDate(String? hhmm, DateTime day) {
  if (hhmm == null) return null;
  final m = _hhmm.firstMatch(hhmm);
  if (m == null) return null;
  final hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

enum RamadanPhase { sahur, iftar }

class RamadanCountdown {
  final RamadanPhase phase;
  final DateTime target;

  /// Hedef vaktin ait olduğu Ramazan günü (1..30).
  final int fastDay;

  const RamadanCountdown({
    required this.phase,
    required this.target,
    required this.fastDay,
  });
}

/// Bugün Ramazan değilse null. İmsak öncesi sahur, imsak-akşam arası iftar,
/// akşamdan sonra (yarın da Ramazan ise) yarının imsakına sahur sayacı.
/// [tomorrow] yoksa bugünün imsak saati yarına uygulanır.
RamadanCountdown? ramadanCountdown({
  required DateTime now,
  required PrayerTimesModel today,
  PrayerTimesModel? tomorrow,
}) {
  final day = dateOnly(now);
  final todayRamadan = ramadanDayOf(day);
  if (todayRamadan == null) return null;

  final imsak = timeOnDate(today.imsak, day);
  final aksam = timeOnDate(today.aksam, day);
  if (imsak == null || aksam == null) return null;

  if (now.isBefore(imsak)) {
    return RamadanCountdown(
      phase: RamadanPhase.sahur,
      target: imsak,
      fastDay: todayRamadan,
    );
  }
  if (now.isBefore(aksam)) {
    return RamadanCountdown(
      phase: RamadanPhase.iftar,
      target: aksam,
      fastDay: todayRamadan,
    );
  }

  final nextDay = DateTime(day.year, day.month, day.day + 1);
  final nextRamadan = ramadanDayOf(nextDay);
  if (nextRamadan == null) return null; // Ramazan bitti, bayram

  final nextImsak =
      timeOnDate(tomorrow?.imsak, nextDay) ??
      DateTime(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        imsak.hour,
        imsak.minute,
      );
  return RamadanCountdown(
    phase: RamadanPhase.sahur,
    target: nextImsak,
    fastDay: nextRamadan,
  );
}

/// "İl / İlçe" etiketi (ilçe il adıyla başlıyorsa tekrar edilmez).
String cityLabel(String? city, String? district) {
  final c = city?.trim() ?? '';
  var d = district?.trim() ?? '';
  if (c.isEmpty) return d;
  if (d.length >= c.length &&
      d.substring(0, c.length).toLowerCase() == c.toLowerCase()) {
    final rest = d.substring(c.length);
    // Sadece kelime sınırındaysa kırp ("Van" / "Vanköy" gibi durumlar bozulmasın)
    if (rest.isEmpty || RegExp(r'^[\s/,\-]').hasMatch(rest)) {
      d = rest.replaceFirst(RegExp(r'^[\s/,\-]+'), '').trim();
    }
  }
  return d.isEmpty ? c : '$c / $d';
}
