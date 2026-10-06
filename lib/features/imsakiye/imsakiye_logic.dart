import 'package:hijri/hijri_calendar.dart';

import '../../data/models/prayer_times_model.dart';

// İmsakiye ve Ramazan sayacı için saf (UI'sız) hesaplamalar.
// Ramazan tarihleri: önce Diyanet listesi (assets/data/religious_days.json),
// o Ramazan için kayıt yoksa hijri paketi (Ümmü'l-Kurâ, düzeltmesiz).

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Miladi ayın tüm günleri (yerel gece yarısı).
List<DateTime> daysOfMonth(int year, int month) {
  final count = DateTime(year, month + 1, 0).day;
  return List.generate(count, (i) => DateTime(year, month, i + 1));
}

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Türkçe karakterleri sadeleştirip küçültür ("Şubat" -> "subat").
String _normalizeTr(String text) {
  const map = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
    '\u0307': '',
  };
  final buffer = StringBuffer();
  for (final ch in text.split('')) {
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const Map<String, int> _trMonths = {
  'ocak': 1,
  'subat': 2,
  'mart': 3,
  'nisan': 4,
  'mayis': 5,
  'haziran': 6,
  'temmuz': 7,
  'agustos': 8,
  'eylul': 9,
  'ekim': 10,
  'kasim': 11,
  'aralik': 12,
};

int? _monthFrom(String token) {
  final numeric = int.tryParse(token);
  if (numeric != null) return numeric;
  final exact = _trMonths[token];
  if (exact != null) return exact;
  // "Şub", "Ağu" gibi kısaltmalar (ilk 3 harf ayları ayırt eder)
  if (token.length < 3) return null;
  for (final e in _trMonths.entries) {
    if (e.key.startsWith(token)) return e.value;
  }
  return null;
}

/// "08 Şubat 2027", "8 subat 2027", "08.02.2027" veya "2027-02-08" -> tarih.
/// Geçersizse (ör. "31 Şubat") null.
DateTime? parseTurkishDate(String? text) {
  if (text == null) return null;
  final s = _normalizeTr(text);
  int day, month, year;
  final dmy = RegExp(
    r'^(\d{1,2})[\s./-]+([a-z]+|\d{1,2})[\s./,-]+(\d{4})\b',
  ).firstMatch(s);
  if (dmy != null) {
    final m = _monthFrom(dmy.group(2)!);
    if (m == null) return null;
    day = int.parse(dmy.group(1)!);
    month = m;
    year = int.parse(dmy.group(3)!);
  } else {
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(s);
    if (iso == null) return null;
    year = int.parse(iso.group(1)!);
    month = int.parse(iso.group(2)!);
    day = int.parse(iso.group(3)!);
  }
  if (month < 1 || month > 12 || day < 1) return null;
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  return date;
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

  /// Tarih aralıktaysa Ramazan'ın kaçıncı günü (1..length), değilse null.
  int? dayOf(DateTime date) {
    final i = _daysBetween(start, date);
    return (i >= 0 && i < length) ? i + 1 : null;
  }
}

RamadanRange ramadanOfHijriYear(int hijriYear) {
  final cal = HijriCalendar();
  return RamadanRange(
    hijriYear: hijriYear,
    start: cal.hijriToGregorian(hijriYear, 9, 1),
    length: cal.getDaysInMonth(hijriYear, 9),
  );
}

/// Ramazan takvimi: Diyanet tarihleri öncelikli, eksik yıllar için hijri paketi.
class RamadanCalendar {
  /// Resmi (Diyanet) aralıklar, hicri yıla göre.
  final Map<int, RamadanRange> official;

  const RamadanCalendar([this.official = const {}]);

  /// Resmi veri yok: tamamen hijri paketi.
  static const RamadanCalendar hijriOnly = RamadanCalendar();

  /// religious_days.json kayıtlarından: başlangıç = "Ramazan Başlangıcı",
  /// son oruç günü = "Ramazan Bayramı 1. Gün"ün bir önceki günü.
  /// Bozuk/tutarsız kayıtlar (29-30 gün dışı) atlanır.
  factory RamadanCalendar.fromReligiousDays(Iterable<Object?> entries) {
    final starts = <DateTime>[];
    final bayrams = <DateTime>[];
    final bayramName = RegExp(r'^ramazan bayrami\W*1\b');
    for (final e in entries) {
      if (e is! Map) continue;
      final name = e['name'];
      final date = e['date'];
      if (name is! String || date is! String) continue;
      final d = parseTurkishDate(date);
      if (d == null) continue;
      final n = _normalizeTr(name);
      if (n == 'ramazan baslangici') {
        starts.add(d);
      } else if (bayramName.hasMatch(n)) {
        bayrams.add(d);
      }
    }
    starts.sort();
    bayrams.sort();

    final official = <int, RamadanRange>{};
    for (final start in starts) {
      DateTime? bayram;
      for (final b in bayrams) {
        if (b.isAfter(start)) {
          bayram = b;
          break;
        }
      }
      if (bayram == null) continue;
      final length = _daysBetween(start, bayram);
      if (length < 29 || length > 30) continue;
      // Hicri yıl, ayın ortasından (1-2 günlük farklardan etkilenmez)
      final mid = HijriCalendar.fromDate(
        DateTime(start.year, start.month, start.day + 14),
      );
      if (mid.hMonth != 9) continue;
      official.putIfAbsent(
        mid.hYear,
        () => RamadanRange(hijriYear: mid.hYear, start: start, length: length),
      );
    }
    return RamadanCalendar(official);
  }

  RamadanRange rangeOf(int hijriYear) =>
      official[hijriYear] ?? ramadanOfHijriYear(hijriYear);

  /// Tarih Ramazan'daysa kaçıncı gün olduğu, değilse null.
  int? dayOf(DateTime date) {
    final d = dateOnly(date);
    for (final r in official.values) {
      final day = r.dayOf(d);
      if (day != null) return day;
    }
    final h = HijriCalendar.fromDate(d);
    if (h.hMonth != 9) return null;
    // O yılın resmi tarihi varsa ve içinde değilsek Ramazan değil
    if (official.containsKey(h.hYear)) return null;
    return h.hDay;
  }

  /// İçinde bulunulan Ramazan; değilse sıradaki Ramazan.
  RamadanRange currentOrNext(DateTime date) {
    final d = dateOnly(date);
    for (final r in official.values) {
      if (r.dayOf(d) != null) return r;
    }
    final h = HijriCalendar.fromDate(d);
    final range = rangeOf(h.hMonth <= 9 ? h.hYear : h.hYear + 1);
    return range.end.isBefore(d) ? rangeOf(range.hijriYear + 1) : range;
  }
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
  RamadanCalendar calendar = RamadanCalendar.hijriOnly,
}) {
  final day = dateOnly(now);
  final todayRamadan = calendar.dayOf(day);
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
  final nextRamadan = calendar.dayOf(nextDay);
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
