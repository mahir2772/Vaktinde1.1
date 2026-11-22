import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_times_model.dart';

/// Seçilen şehrin IANA saat dilimi ("Memleket vakitleri") ve yüksek enlemde
/// gece yarısını geçen Yatsı vakitleri için ortak saat yardımcısı.
///
/// [zoneId] null ya da geçersizse cihazın yerel saat dilimi kullanılır (eski
/// kayıtlar, GPS konumu ve mevcut birim testleriyle tam uyumlu).
abstract final class PrayerTimeZone {
  static void _ensureInitialized() {
    if (!tz.timeZoneDatabase.isInitialized) {
      tzdata.initializeTimeZones();
    }
  }

  /// Geçerli IANA saat dilimi adıysa [tz.Location], değilse null.
  static tz.Location? resolve(String? zoneId) {
    final trimmed = zoneId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    try {
      _ensureInitialized();
      return tz.getLocation(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// [now] anının [zoneId] saat dilimindeki karşılığı (aynı UTC anı, şehrin
  /// duvar saati). [zoneId] yoksa/geçersizse [now] (veya [DateTime.now]) döner.
  static DateTime nowIn(String? zoneId, [DateTime? now]) {
    final base = now ?? DateTime.now();
    final loc = resolve(zoneId);
    if (loc == null) return base;
    return tz.TZDateTime.from(base.toUtc(), loc);
  }

  /// [day] takvim gününün [hour]:[minute] duvar saatini [zoneId] diliminde
  /// gerçek bir [DateTime] anına çevirir.
  static DateTime at(String? zoneId, DateTime day, int hour, int minute) {
    final loc = resolve(zoneId);
    if (loc == null) {
      return DateTime(day.year, day.month, day.day, hour, minute);
    }
    return tz.TZDateTime(loc, day.year, day.month, day.day, hour, minute);
  }

  /// "HH:mm" metnini [day] günü için [zoneId] diliminde [DateTime] yapar.
  static DateTime? parseAt(String? zoneId, DateTime day, String? hhmm) {
    final minutes = parseMinutes(hhmm);
    if (minutes == null) return null;
    return at(zoneId, day, minutes ~/ 60, minutes % 60);
  }

  /// "HH:mm" → günün dakikası (0..1439); okunamazsa null.
  static int? parseMinutes(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  /// Yüksek enlem yazında (NL/BE/FR/DE vb.) Yatsı 00:00'ı geçip ertesi güne
  /// sarktıysa true (örn. Akşam 22:05, Yatsı 00:15).
  static bool isYatsiAfterMidnight(PrayerTimesModel times) {
    final aksam = parseMinutes(times.aksam);
    final yatsi = parseMinutes(times.yatsi);
    return aksam != null && yatsi != null && yatsi < aksam;
  }

  /// "yyyy-MM-dd" takvim anahtarı (yerel saat veya TZDateTime duvar tarihinden)
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// [zoneId] saat diliminin [now] anındaki UTC farkı telefonunkinden farklı mı
  static bool differsFromLocal(String? zoneId, {DateTime? now}) {
    final loc = resolve(zoneId);
    if (loc == null) return false;
    final local = (now ?? DateTime.now()).toLocal();
    final there = tz.TZDateTime.from(local.toUtc(), loc);
    return there.timeZoneOffset != local.timeZoneOffset;
  }
}
