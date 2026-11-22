// Seçilen şehrin IANA saat dilimi ("Memleket vakitleri") ve yüksek enlemde
// gece yarısını geçen Avrupa yaz Yatsı alarmları / vakit çıkış hatırlatmaları
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_timezone.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tr = lookupAppLocalizations(const Locale('tr'));

  group('Avrupa yazı: gece yarısını geçen Yatsı alarmları', () {
    // Örn. Amsterdam 21–22 Haziran: Akşam 22:05, Yatsı 00:15 (ertesi gün), İmsak 03:00
    final summerDay = PrayerTimesModel(
      imsak: '03:00',
      gunes: '05:18',
      ogle: '13:45',
      ikindi: '18:05',
      aksam: '22:05',
      yatsi: '00:15',
      timeZone: 'Europe/Amsterdam',
    );

    test(
      '22:30: bugünün Yatsı alarmı ertesi gün 00:15 için kurulur, payload bugüne ait',
      () {
        // Amsterdam yaz = UTC+2 → 20:30 UTC = 22:30 CEST
        final nowUtc = DateTime.utc(2026, 6, 21, 20, 30);
        final plan = PrayerRefreshService.buildAlarmPlan(
          days: [summerDay, summerDay],
          now: nowUtc,
          loc: tr,
          onTimeAlarms: const {'Yatsı': true},
          reminderAlarms: const {},
          selectedSounds: const {'Yatsı': 'ezan1'},
          selectedReminderSounds: const {},
          silentModeSettings: const {},
        );
        expect(plan, hasLength(2));
        // 2026-06-22 00:15 CEST = 2026-06-21 22:15 UTC
        expect(plan.first.time.toUtc(), DateTime.utc(2026, 6, 21, 22, 15));
        expect(plan.first.payload, 'prayed|2026-06-21|Yatsı');
        // 2026-06-23 00:15 CEST = 2026-06-22 22:15 UTC
        expect(plan[1].time.toUtc(), DateTime.utc(2026, 6, 22, 22, 15));
        expect(plan[1].payload, 'prayed|2026-06-22|Yatsı');
      },
    );

    test('00:05: dünün gece yarısına sarkan 00:15 Yatsı alarmı atlanmaz', () {
      // 2026-06-22 00:05 CEST = 2026-06-21 22:05 UTC
      final nowUtc = DateTime.utc(2026, 6, 21, 22, 5);
      final plan = PrayerRefreshService.buildAlarmPlan(
        days: [summerDay],
        now: nowUtc,
        loc: tr,
        onTimeAlarms: const {'Yatsı': true},
        reminderAlarms: const {},
        selectedSounds: const {'Yatsı': 'ezan1'},
        selectedReminderSounds: const {},
        silentModeSettings: const {},
      );
      expect(plan, hasLength(2));
      expect(plan.first.time.toUtc(), DateTime.utc(2026, 6, 21, 22, 15));
      expect(plan.first.payload, 'prayed|2026-06-21|Yatsı');
      expect(plan[1].time.toUtc(), DateTime.utc(2026, 6, 22, 22, 15));
      expect(plan[1].payload, 'prayed|2026-06-22|Yatsı');
    });

    test(
      'vakit çıkış hatırlatması: Akşam (22:05→00:15) ve Yatsı (00:15→03:00) doğru kurulur',
      () {
        // 2026-06-21 22:30 CEST = 20:30 UTC
        final nowUtc = DateTime.utc(2026, 6, 21, 20, 30);
        final plan = PrayerRefreshService.buildEndReminderPlan(
          previous: summerDay,
          days: [summerDay, summerDay],
          now: nowUtc,
          loc: tr,
          minutes: 30,
          prayerLog: const {},
        );
        // 21 Haziran Akşamı 00:15'te biter → 23:45 CEST (21:45 UTC) hatırlatma
        final aksam = plan.firstWhere(
          (a) => a.payload == 'prayed|2026-06-21|Akşam',
        );
        expect(aksam.time.toUtc(), DateTime.utc(2026, 6, 21, 21, 45));
        // 21 Haziran Yatsısı 03:00'te biter → 02:30 CEST (00:30 UTC) hatırlatma
        final yatsi = plan.firstWhere(
          (a) => a.payload == 'prayed|2026-06-21|Yatsı',
        );
        expect(yatsi.time.toUtc(), DateTime.utc(2026, 6, 22, 0, 30));
      },
    );
  });

  group('Farklı saat dilimi (Memleket vakitleri)', () {
    test(
      'İstanbul alarmı cihaz diliminden bağımsız gerçek UTC anında kurulur',
      () {
        // Kış: Europe/Istanbul = UTC+3 → 12:30 TRT = 09:30 UTC
        final istanbul = PrayerTimesModel(
          imsak: '06:30',
          gunes: '08:00',
          ogle: '12:30',
          ikindi: '15:15',
          aksam: '17:45',
          yatsi: '19:15',
          timeZone: 'Europe/Istanbul',
        );
        final nowUtc = DateTime.utc(2026, 1, 15, 9, 0); // 12:00 TRT
        final plan = PrayerRefreshService.buildAlarmPlan(
          days: [istanbul],
          now: nowUtc,
          loc: tr,
          onTimeAlarms: const {'Öğle': true},
          reminderAlarms: const {'Öğle': true},
          selectedSounds: const {'Öğle': 'ezan1'},
          selectedReminderSounds: const {'Öğle': 'bildirim1'},
          silentModeSettings: const {},
        );
        expect(plan, hasLength(2));
        expect(plan.first.time.toUtc(), DateTime.utc(2026, 1, 15, 9, 30));
        expect(plan[1].time.toUtc(), DateTime.utc(2026, 1, 15, 9, 15));
      },
    );

    test(
      'StorageService: saat dilimi kaydedilir, okunur ve temizlenir',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        expect(await storage.loadTimeZone(), isNull);
        await storage.saveTimeZone('Europe/Berlin');
        expect(await storage.loadTimeZone(), 'Europe/Berlin');
        await storage.saveTimeZone(null);
        expect(await storage.loadTimeZone(), isNull);
      },
    );

    test('PrayerTimeZone: geçersiz dilim güvenle null döner', () {
      expect(PrayerTimeZone.resolve('Invalid/Zone'), isNull);
      expect(PrayerTimeZone.resolve(''), isNull);
      expect(PrayerTimeZone.resolve('Europe/Istanbul'), isNotNull);
    });
  });
}
