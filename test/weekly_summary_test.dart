// Haftalık namaz özeti (ID 2500): geçen haftanın (Pzt–Paz) sayımı (takip
// başlangıcı ve özel günler hariç), Pazartesi–Salı 09:00–21:00 penceresi,
// haftada bir kez, ayar, bildirim yükü (NotificationRoutes.tracker)
import 'package:ezan_saati/core/notification_routes.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final tr = lookupAppLocalizations(const Locale('tr'));
  // 19-25 Ekim 2026 (Pzt–Paz); özet 26 Ekim Pazartesi
  final weekStart = DateTime(2026, 10, 19);

  group('Sayım', () {
    test('7 gün × 5 vakit; takip başlamadan önceki ve özel günler sayılmaz; '
        'hiç işaret yoksa null', () {
      final log = {'2026-10-19': 31, '2026-10-20': 5, '2026-10-26': 31};
      expect(
        PrayerTracker.weekSummary(log, weekStart, since: DateTime(2026, 9, 1)),
        (done: 7, total: 35),
      );
      expect(
        PrayerTracker.weekSummary(
          log,
          weekStart,
          since: DateTime(2026, 10, 20),
          excused: {'2026-10-21', '2026-10-22'},
        ),
        (done: 2, total: 20),
      );
      expect(
        PrayerTracker.weekSummary(const {}, weekStart, since: weekStart),
        isNull,
      );
      expect(PrayerTracker.weekSummary(log, weekStart, since: null), isNull);
    });
  });

  group('Bildirim', () {
    final shows = <MethodCall>[];
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      shows.clear();
      messenger.setMockMethodCallHandler(notifChannel, (call) async {
        if (call.method == 'show') shows.add(call);
        return null;
      });
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(notifChannel, null);
    });

    Future<void> runAt(DateTime now) => PrayerRefreshService(
      NotificationService(),
      clock: () => now,
    ).showWeeklySummaryIfDue(tr);

    Map<String, Object> prefs(Map<String, int> log) => {
      'prayer_log':
          '{${log.entries.map((e) => '"${e.key}":${e.value}').join(',')}}',
      'prayer_log_since': '2026-09-01',
    };

    test('Pazartesi 09:00 sonrası bir kez: ID 2500, sayı metni, takip '
        'ekranına yük; aynı hafta tekrar yok', () async {
      SharedPreferences.setMockInitialValues(
        prefs({'2026-10-19': 31, '2026-10-20': 7}),
      );
      await runAt(DateTime(2026, 10, 26, 8, 59));
      expect(shows, isEmpty);
      await runAt(DateTime(2026, 10, 26, 9));
      expect(shows, hasLength(1));
      final args = shows.single.arguments as Map;
      expect(args['id'], PrayerRefreshService.weeklySummaryId);
      expect(args['title'], tr.weeklySummaryTitle);
      expect(args['body'], tr.weeklySummaryBody(8, 35));
      expect(
        args['payload'],
        NotificationRoutes.route(NotificationRoutes.tracker),
      );
      await runAt(DateTime(2026, 10, 27, 12));
      expect(shows, hasLength(1));
    });

    test('hepsi kılındıysa tebrik; Salı da gösterilir', () async {
      SharedPreferences.setMockInitialValues(
        prefs({for (var d = 19; d <= 25; d++) '2026-10-$d': 31}),
      );
      await runAt(DateTime(2026, 10, 27, 20, 59));
      expect(shows.single.arguments['body'], tr.weeklySummaryFull(35));
    });

    test('pencere dışı (Çarşamba–Pazar, 21:00 sonrası), ayar kapalı ya da '
        'takip kullanılmadıysa yok', () async {
      SharedPreferences.setMockInitialValues(prefs({'2026-10-19': 31}));
      await runAt(DateTime(2026, 10, 26, 21));
      await runAt(DateTime(2026, 10, 28, 12));
      await runAt(DateTime(2026, 11, 1, 12));
      expect(shows, isEmpty);

      SharedPreferences.setMockInitialValues({
        ...prefs({'2026-10-19': 31}),
        StorageService.weeklySummaryEnabledKey: false,
      });
      await runAt(DateTime(2026, 10, 26, 12));
      expect(shows, isEmpty);

      SharedPreferences.setMockInitialValues(prefs({'2026-10-26': 31}));
      await runAt(DateTime(2026, 10, 26, 12));
      expect(shows, isEmpty);
    });
  });
}
