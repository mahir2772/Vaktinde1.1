import 'dart:convert';

import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// WorkManager görevinin yaptığı işler, platform kanalları taklit edilerek doğrulanır
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> widgetCalls;
  late List<MethodCall> notifCalls;
  late List<int> pending;
  late bool failSchedule;
  late Future<void> Function(MethodCall call)? onSchedule;

  setUp(() {
    failSchedule = false;
    onSchedule = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    widgetCalls = [];
    notifCalls = [];
    pending = [];
    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (
      call,
    ) async {
      widgetCalls.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        notifCalls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
            if (failSchedule) throw PlatformException(code: 'error');
            await onSchedule?.call(call);
            return null;
          case 'pendingNotificationRequests':
            return [
              for (final id in pending)
                {'id': id, 'title': '', 'body': '', 'payload': ''},
            ];
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Koordinat yoksa hiçbir şeye dokunmaz', () async {
    SharedPreferences.setMockInitialValues({'saved_city': 'İstanbul'});
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    expect(widgetCalls, isEmpty);
    expect(notifCalls, isEmpty);
  });

  test('Widget, kalıcı bildirim, cache ve 5 günlük alarmlar güncellenir', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
      'saved_district': 'Fatih',
      'language_code': 'de',
      'onTime_Öğle': true,
      'reminder_Akşam': true,
    });
    // 7 (İkindi hatırlatma) ve 30 (3. gün İkindi) artık planda yok; 1000/1900 günlük içerik
    pending = [7, 30, 1000, 1900];
    final de = lookupAppLocalizations(const Locale('de'));

    expect(await PrayerRefreshService.runHeadless(), isTrue);

    final saved = {
      for (final c in widgetCalls.where((c) => c.method == 'saveWidgetData'))
        c.arguments['id']: c.arguments['data'],
    };
    expect(saved['location_text'], 'İstanbul, Fatih');
    expect(saved['label_ogle'], de.ogle);
    expect(saved['ogle_time'], matches(RegExp(r'^\d\d:\d\d$')));
    expect(saved['hijri_date_text'], isNotEmpty); // de: hijri paketinde yok
    expect(saved['target_time_ms'], greaterThan(0));
    expect(
      widgetCalls
          .where((c) => c.method == 'updateWidget')
          .map((c) => c.arguments['android'])
          .toSet(),
      {
        'VaktindeWidgetSmallProvider',
        'VaktindeWidgetLargeProvider',
        'VaktindeWidgetSmall2Provider',
        'NotificationUpdater',
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    expect(prefs.getString('cached_prayer_date'), today);
    expect(prefs.getString('alarms_scheduled_date'), today);
    expect(jsonDecode(prefs.getString('bg_display')!)['next'], de.nextPrayer);

    // Toplu iptal yok: sadece plandan çıkan bekleyen alarmlar iptal edilir
    expect(
      notifCalls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments['id'])
          .toSet(),
      {7, 30},
    );
    final scheduled = notifCalls
        .where((c) => c.method == 'zonedSchedule')
        .map((c) => c.arguments['id'] as int)
        .toList();
    // Öğle ezanı: 4 + 12*gün, Akşam hatırlatması: 9 + 12*gün (bugünküler geçmişse yok)
    expect(
      scheduled.toSet().difference({4, 16, 28, 40, 52, 9, 21, 33, 45, 57}),
      isEmpty,
    );
    expect(scheduled, containsAll([16, 28, 40, 52, 21, 33, 45, 57]));
    final ogle = notifCalls.firstWhere(
      (c) => c.method == 'zonedSchedule' && c.arguments['id'] == 16,
    );
    expect(ogle.arguments['body'], de.notifBodyTime(de.ogle));
    // "Kıldım" butonu ve yükü (yarının öğlesi)
    final tomorrow = PrayerTracker.addDays(DateTime.now(), 1);
    expect(ogle.arguments['payload'], PrayerTracker.payload(tomorrow, 'Öğle'));
    final action = ogle.arguments['platformSpecifics']['actions'][0];
    expect(action['id'], PrayerTracker.actionId);
    expect(action['title'], de.trackerPrayedAction);
    expect(action['showsUserInterface'], isFalse);
    // Bildirim aksiyonu için arka plan işleyicisi kaydedilir
    final init = notifCalls.firstWhere((c) => c.method == 'initialize');
    expect(init.arguments['dispatcher_handle'], isNotNull);
    expect(init.arguments['callback_handle'], isNotNull);
    // Ayar kapalı: vakit çıkış hatırlatması kurulmaz
    expect(scheduled.where(PrayerTracker.isEndReminderId), isEmpty);

    // Aynı gün tekrar çalışınca alarmlara dokunmaz
    notifCalls.clear();
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    expect(notifCalls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    expect(notifCalls.where((c) => c.method == 'cancel'), isEmpty);
  });

  test('Vakit çıkış hatırlatmaları arka planda da kurulur; kılınan iptal', () async {
    final tomorrow = PrayerTracker.addDays(DateTime.now(), 1);
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
      'language_code': 'tr',
      'end_reminder_enabled': true,
      'end_reminder_minutes': 30,
      'prayer_log': jsonEncode({
        PrayerTracker.dateKey(tomorrow): PrayerTracker.bit('Öğle'),
      }),
    });
    final skipped = PrayerTracker.endReminderId(tomorrow, 'Öğle');
    pending = [skipped, 1000, 1900];
    final tr = lookupAppLocalizations(const Locale('tr'));

    expect(await PrayerRefreshService.runHeadless(), isTrue);

    expect(
      notifCalls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments['id'])
          .toList(),
      [skipped],
    );
    final reminders = notifCalls
        .where(
          (c) =>
              c.method == 'zonedSchedule' &&
              PrayerTracker.isEndReminderId(c.arguments['id']),
        )
        .toList();
    // Yarından itibaren 4 gün x 5 vakit, kılınan yarın öğle hariç
    expect(reminders.length, greaterThanOrEqualTo(19));
    expect(reminders.map((c) => c.arguments['id']), isNot(contains(skipped)));
    final first = reminders.first;
    expect(
      first.arguments['platformSpecifics']['channelId'],
      'channel_end_reminder',
    );
    expect(
      first.arguments['platformSpecifics']['channelName'],
      tr.endReminderChannel,
    );
    expect(first.arguments['title'], tr.endReminderNotifTitle);
    expect(
      first.arguments['platformSpecifics']['actions'][0]['id'],
      PrayerTracker.actionId,
    );
    expect(
      PrayerTracker.parsePayload(first.arguments['payload']),
      isNotNull,
    );
  });

  test('Hiç alarm kurulamazsa gün kaydedilmez, aynı gün yeniden denenir', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
      'onTime_Öğle': true,
    });
    failSchedule = true;
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('alarms_scheduled_date'), isNull);

    failSchedule = false;
    notifCalls.clear();
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    expect(notifCalls.where((c) => c.method == 'zonedSchedule'), isNotEmpty);
    expect(
      prefs.getString('alarms_scheduled_date'),
      DateTime.now().toIso8601String().split('T')[0],
    );
  });

  test('Plan boşsa (tüm alarmlar kapalı) gün kaydedilir', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
    });
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('alarms_scheduled_date'), isNotNull);
  });

  test('Koordinat varsa bugünün vakitleri yeniden hesaplanır (eski gün verilse de)', () async {
    SharedPreferences.setMockInitialValues({'saved_lat': 41.0, 'saved_lng': 29.0});
    final notifications = NotificationService();
    await notifications.init();
    // Gece yarısından kalmış gibi uydurma vakitler
    final stale = PrayerTimesModel(
      imsak: '23:59',
      gunes: '23:59',
      ogle: '23:59',
      ikindi: '23:59',
      aksam: '23:59',
      yatsi: '23:59',
    );
    final loc = lookupAppLocalizations(const Locale('tr'));
    await PrayerRefreshService(notifications).rescheduleAlarms(
      todayTimes: stale,
      loc: loc,
      onTimeAlarms: {for (final k in PrayerRefreshService.vakitKeys) k: true},
      reminderAlarms: const {},
      selectedSounds: const {},
      selectedReminderSounds: const {},
      silentModeSettings: const {},
    );
    final scheduled = notifCalls.where((c) => c.method == 'zonedSchedule');
    expect(scheduled, isNotEmpty);
    for (final call in scheduled) {
      expect(
        call.arguments['scheduledDateTime'] as String,
        isNot(endsWith('T23:59:00')),
      );
    }
  });

  test('Ramazan takvimi (Diyanet tarihleri) widget olmadan da okunur', () async {
    final calendar = await loadRamadanCalendar();
    expect(calendar.official, isNotEmpty);
    expect(calendar.dayOf(DateTime(2026, 3, 19)), 29);
    expect(calendar.dayOf(DateTime(2026, 3, 20)), isNull);
  });

  test('Kurulurken başka yerden "Kıldım" denen vaktin hatırlatması iptal edilir', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
      'end_reminder_enabled': true,
    });
    int? markedId;
    onSchedule = (call) async {
      final id = call.arguments['id'] as int;
      if (markedId != null || !PrayerTracker.isEndReminderId(id)) return;
      // Bildirim aksiyonu isolate'i bu sırada işaretliyor
      final target = PrayerTracker.parsePayload(call.arguments['payload'])!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'prayer_log',
        jsonEncode({
          PrayerTracker.dateKey(target.date): PrayerTracker.bit(target.key),
        }),
      );
      markedId = id;
    };

    expect(await PrayerRefreshService.runHeadless(), isTrue);
    expect(markedId, isNotNull);
    final scheduleIndex = notifCalls.indexWhere(
      (c) => c.method == 'zonedSchedule' && c.arguments['id'] == markedId,
    );
    final cancelIndex = notifCalls.lastIndexWhere(
      (c) => c.method == 'cancel' && c.arguments['id'] == markedId,
    );
    expect(cancelIndex, greaterThan(scheduleIndex));
    // Diğer hatırlatmalar iptal edilmez
    expect(
      notifCalls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments['id'])
          .toSet(),
      {markedId},
    );
  });
}
