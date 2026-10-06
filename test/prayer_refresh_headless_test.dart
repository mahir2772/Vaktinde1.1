import 'dart:convert';

import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
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

  setUp(() {
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

    // Aynı gün tekrar çalışınca alarmlara dokunmaz
    notifCalls.clear();
    expect(await PrayerRefreshService.runHeadless(), isTrue);
    expect(notifCalls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    expect(notifCalls.where((c) => c.method == 'cancel'), isEmpty);
  });
}
