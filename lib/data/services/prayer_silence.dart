import 'dart:io';

import 'package:flutter/services.dart';

import '../models/prayer_times_model.dart';
import 'prayer_timezone.dart';
import 'prayer_tracker.dart';

/// Tek bir otomatik sessiz penceresi (gerçek UTC/epoch anları)
class SilenceWindow {
  final DateTime start;
  final DateTime end;

  const SilenceWindow({required this.start, required this.end});

  Map<String, int> toChannelMap() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) =>
      other is SilenceWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SilenceWindow($start → $end)';
}

/// "Namazdayım" otomatik sessiz modu ayarları
class PrayerSilenceSettings {
  final bool enabled;

  /// Normal vakitlerde sessiz kalma süresi (dk)
  final int durationMinutes;

  /// Sessize alınacak farz vakitler (İmsak/Öğle/İkindi/Akşam/Yatsı alt kümesi)
  final Set<String> prayers;

  /// Cuma namazı penceresi: Cuma günü Öğle'den 15 dk önce başlar, 45 dk sonra biter
  final bool fridayEnabled;

  const PrayerSilenceSettings({
    this.enabled = false,
    this.durationMinutes = PrayerSilence.defaultDurationMinutes,
    this.prayers = PrayerSilence.defaultPrayers,
    this.fridayEnabled = true,
  });

  PrayerSilenceSettings copyWith({
    bool? enabled,
    int? durationMinutes,
    Set<String>? prayers,
    bool? fridayEnabled,
  }) => PrayerSilenceSettings(
    enabled: enabled ?? this.enabled,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    prayers: prayers ?? this.prayers,
    fridayEnabled: fridayEnabled ?? this.fridayEnabled,
  );
}

/// "Namazdayım" otomatik sessiz modu: saf planlayıcı + Android DND köprüsü.
abstract final class PrayerSilence {
  static const List<int> durationOptions = [15, 20, 30, 45];
  static const int defaultDurationMinutes = 20;
  static const int fridayBeforeMinutes = 15;
  static const int fridayAfterMinutes = 45;

  /// 5 farz vakit (Güneş dahil değil)
  static const Set<String> defaultPrayers = {
    'İmsak',
    'Öğle',
    'İkindi',
    'Akşam',
    'Yatsı',
  };

  static const MethodChannel _device = MethodChannel('vaktinde/device');

  /// Verilen günler ([days][0] = bugün) için otomatik sessiz pencerelerini
  /// hesaplar.
  /// - [audibleEzans] içinde olan vakitlerde ezan bildirimi kesilmesin diye
  ///   sessiz mod vakitten 1 dk sonra başlar.
  /// - Cuma günü [settings.fridayEnabled] açıksa Öğle'den 15 dk önce → 45 dk
  ///   sonra penceresi eklenir.
  /// - Çakışan pencereler birleştirilir, [now] anında bitmiş olanlar elenir.
  static List<SilenceWindow> buildPlan({
    required List<PrayerTimesModel> days,
    required DateTime now,
    required PrayerSilenceSettings settings,
    Set<String> audibleEzans = const {},
  }) {
    if (!settings.enabled || days.isEmpty) return const [];
    final duration = Duration(
      minutes: durationOptions.contains(settings.durationMinutes)
          ? settings.durationMinutes
          : defaultDurationMinutes,
    );
    final baseZone = days.first.timeZone;
    final cityNow = PrayerTimeZone.nowIn(baseZone, now);
    final raw = <SilenceWindow>[];

    void addWindow(DateTime start, DateTime end) {
      if (!end.isAfter(start)) return;
      if (!end.isAfter(cityNow)) return;
      raw.add(SilenceWindow(start: start, end: end));
    }

    for (var day = 0; day < days.length; day++) {
      final model = days[day];
      final zone = model.timeZone;
      final dayDate = DateTime(cityNow.year, cityNow.month, cityNow.day + day);
      final afterMidnightYatsi = PrayerTimeZone.isYatsiAfterMidnight(model);
      final map = {
        'İmsak': model.imsak,
        'Öğle': model.ogle,
        'İkindi': model.ikindi,
        'Akşam': model.aksam,
        'Yatsı': model.yatsi,
      };

      for (final key in PrayerTracker.prayerKeys) {
        if (!settings.prayers.contains(key)) continue;
        final hhmm = map[key];
        if (hhmm == null) continue;
        final offset = audibleEzans.contains(key)
            ? const Duration(minutes: 1)
            : Duration.zero;

        if (key == 'Yatsı' && afterMidnightYatsi) {
          // Gece yarısı hemen sonrası dünün Yatsı penceresi (henüz bitmediyse)
          if (day == 0) {
            final early = PrayerTimeZone.parseAt(zone, dayDate, hhmm);
            if (early != null) {
              final start = early.add(offset);
              addWindow(start, start.add(duration));
            }
          }
          final nextCal = DateTime(
            dayDate.year,
            dayDate.month,
            dayDate.day + 1,
          );
          final shifted = PrayerTimeZone.parseAt(zone, nextCal, hhmm);
          if (shifted != null) {
            final start = shifted.add(offset);
            addWindow(start, start.add(duration));
          }
          continue;
        }

        final vakitTime = PrayerTimeZone.parseAt(zone, dayDate, hhmm);
        if (vakitTime == null) continue;
        final start = vakitTime.add(offset);
        addWindow(start, start.add(duration));
      }

      // Cuma namazı penceresi: Cuma günü Öğle - 15 dk → Öğle + 45 dk
      if (settings.fridayEnabled && dayDate.weekday == DateTime.friday) {
        final ogle = PrayerTimeZone.parseAt(zone, dayDate, model.ogle);
        if (ogle != null) {
          addWindow(
            ogle.subtract(const Duration(minutes: fridayBeforeMinutes)),
            ogle.add(const Duration(minutes: fridayAfterMinutes)),
          );
        }
      }
    }

    return mergeWindows(raw);
  }

  /// Çakışan veya bitişik pencereleri birleştirir (sıralı)
  static List<SilenceWindow> mergeWindows(List<SilenceWindow> windows) {
    if (windows.length <= 1) return List<SilenceWindow>.from(windows);
    final sorted = List<SilenceWindow>.from(windows)
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <SilenceWindow>[sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final last = merged.last;
      if (!current.start.isAfter(last.end)) {
        final newEnd = current.end.isAfter(last.end) ? current.end : last.end;
        merged[merged.length - 1] = SilenceWindow(
          start: last.start,
          end: newEnd,
        );
      } else {
        merged.add(current);
      }
    }
    return merged;
  }

  /// Android Rahatsız Etmeyin (DND) erişim izni verilmiş mi
  static Future<bool> hasPolicyAccess() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _device.invokeMethod<bool>('hasDndAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sistemin "Rahatsız Etmeyin erişimi" ekranını açar
  static Future<bool> openPolicyAccessSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _device.invokeMethod<bool>('openDndAccessSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Planı Android native zamanlayıcısına gönderir (hata fırlatmaz)
  static Future<bool> syncToPlatform({
    required bool enabled,
    required List<SilenceWindow> windows,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _device.invokeMethod<bool>('syncPrayerSilence', {
            'enabled': enabled,
            'windows': [for (final w in windows) w.toChannelMap()],
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
