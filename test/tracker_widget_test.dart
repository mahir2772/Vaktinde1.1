import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/data/services/tracker_widget_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Namaz takibi widget'ı: Dart'ın yazdığı veri ve uygulama açılmadan gelen dokunuş.
// Anahtarlar ve adres Kotlin'le sözleşme (VaktindeWidgetTrackerProvider.kt).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 3, 10, 14, 0);
  String dk(DateTime d) => PrayerTracker.dateKey(d);
  int bit(String key) => PrayerTracker.bit(key);

  group('Veri (saf)', () {
    test('bugünün maskesi, adlar, durum sözleri ve ekran okuyucu metni', () {
      final data = TrackerWidgetService.data(
        log: {
          dk(now): bit('İmsak') | bit('İkindi'),
          dk(PrayerTracker.addDays(now, -1)): PrayerTracker.fullMask,
        },
        excused: const {},
        open: null,
        now: now,
        loc: tr,
      );
      expect(data, {
        'tracker_date': '2026-03-10',
        'tracker_mask': 5,
        'tracker_excused_days': '',
        'tracker_title': 'Bugün',
        'tracker_labels': 'Sabah\nÖğle\nİkindi\nAkşam\nYatsı',
        'tracker_states': 'Kılındı\nKılınmadı\nVakti girmedi\nÖzel gün',
        'tracker_cell_text': r'Bugün, %1$s: %2$s',
      });

      final english = TrackerWidgetService.data(
        log: const {},
        excused: const {},
        open: null,
        now: now,
        loc: en,
      );
      expect(english['tracker_mask'], 0);
      expect(english['tracker_title'], en.trackerToday);
      expect((english['tracker_labels'] as String).split('\n'), [
        en.sabah,
        en.ogle,
        en.ikindi,
        en.aksam,
        en.yatsi,
      ]);
      expect((english['tracker_states'] as String).split('\n'), hasLength(4));
    });

    test('özel gün: açık dönemin sonraki günleri de yazılır (gün dönümünde '
        'widget uygulamayı beklemez)', () {
      // Dönem iki gün önce başladı, kayıt dünde kaldı (uygulama bugün açılmadı)
      final start = PrayerTracker.addDays(now, -2);
      final days = TrackerWidgetService.data(
        log: const {},
        excused: {dk(start), dk(PrayerTracker.addDays(now, -1))},
        open: dk(start),
        now: now,
        loc: tr,
      )['tracker_excused_days'];
      expect(
        days,
        [
          for (var i = 0; i < 8; i++) dk(PrayerTracker.addDays(now, i)),
        ].join(','),
      );

      // Sadece bugün (dönem kapalı) ve süresi dolmuş dönem
      expect(
        TrackerWidgetService.data(
          log: const {},
          excused: {dk(now), dk(PrayerTracker.addDays(now, -3))},
          open: null,
          now: now,
          loc: tr,
        )['tracker_excused_days'],
        dk(now),
      );
      final old = PrayerTracker.addDays(now, -10);
      expect(
        TrackerWidgetService.data(
          log: const {},
          excused: {dk(old)},
          open: dk(old),
          now: now,
          loc: tr,
        )['tracker_excused_days'],
        '',
      );
    });

    test('dokunuş adresi', () {
      final parsed = TrackerWidgetService.parseTap(
        Uri.parse('vaktinde://tracker/toggle?date=2026-03-10&prayer=1'),
      )!;
      expect(parsed.date, DateTime(2026, 3, 10));
      expect(parsed.key, 'Öğle');
      expect(
        TrackerWidgetService.parseTap(
          Uri.parse('vaktinde://tracker/toggle?date=2026-03-10&prayer=0'),
        )!.key,
        'İmsak',
      );
      for (final bad in [
        'vaktinde://tracker/toggle?date=2026-03-10&prayer=5',
        'vaktinde://tracker/toggle?date=2026-03-10&prayer=-1',
        'vaktinde://tracker/toggle?date=2026-02-30&prayer=1',
        'vaktinde://tracker/toggle?prayer=1',
        'vaktinde://tracker/other?date=2026-03-10&prayer=1',
        'vaktinde://widget/toggle?date=2026-03-10&prayer=1',
        'baska://tracker/toggle?date=2026-03-10&prayer=1',
      ]) {
        expect(TrackerWidgetService.parseTap(Uri.parse(bad)), isNull);
      }
      expect(TrackerWidgetService.parseTap(null), isNull);
    });
  });

  group('Dokunuş ve yenileme (arka plan geri çağrısı)', () {
    late List<MethodCall> widgetCalls;
    late List<MethodCall> notifCalls;
    DateTime today() => PrayerTracker.day(DateTime.now());
    Uri tap(DateTime date, int prayer) =>
        Uri.parse('vaktinde://tracker/toggle?date=${dk(date)}&prayer=$prayer');

    // Son yazılan değerler
    Map<String, Object?> saved() => {
      for (final c in widgetCalls.where((c) => c.method == 'saveWidgetData'))
        c.arguments['id'] as String: c.arguments['data'],
    };
    List<String?> updated() => [
      for (final c in widgetCalls.where((c) => c.method == 'updateWidget'))
        c.arguments['android'] as String?,
    ];
    Future<Map<String, int>> log() => PrayerTrackerService().loadLog();

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      widgetCalls = [];
      notifCalls = [];
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
              return <Object>[];
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        null,
      );
    });

    test('dokunuş bugünün vaktini işaretler / geri alır, widget yeniden '
        'çizilir; geri alınınca hatırlatmalar yeniden kurulur', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      expect(await TrackerWidgetService.handleTap(tap(today(), 1)), isTrue);
      expect(await log(), {dk(today()): bit('Öğle')});
      expect(saved()['tracker_date'], dk(today()));
      expect(saved()['tracker_mask'], bit('Öğle'));
      expect(saved()['tracker_title'], tr.trackerToday);
      expect(updated(), ['VaktindeWidgetTrackerProvider']);
      // Kılınan vaktin "vakit çıkıyor" hatırlatması iptal ("Kıldım" ile aynı kural)
      expect(
        notifCalls
            .where((c) => c.method == 'cancel')
            .map((c) => c.arguments['id']),
        [PrayerTracker.endReminderId(today(), 'Öğle')],
      );
      expect(notifCalls.where((c) => c.method == 'initialize'), isEmpty);

      widgetCalls.clear();
      expect(await TrackerWidgetService.handleTap(tap(today(), 1)), isTrue);
      expect(await log(), isEmpty);
      expect(saved()['tracker_mask'], 0);
      expect(updated(), ['VaktindeWidgetTrackerProvider']);
      // Uygulamadaki refreshEndReminders gibi: hatırlatmalar eşitlenir
      expect(notifCalls.where((c) => c.method == 'initialize'), isNotEmpty);
      expect(
        notifCalls.where((c) => c.method == 'pendingNotificationRequests'),
        isNotEmpty,
      );
    });

    test('art arda iki dokunuş sırayla işlenir (ikincisi geri alır)', () async {
      SharedPreferences.setMockInitialValues({});
      final results = await Future.wait([
        TrackerWidgetService.handleTap(tap(today(), 3)),
        TrackerWidgetService.handleTap(tap(today(), 3)),
      ]);
      expect(results, [isTrue, isTrue]);
      expect(await log(), isEmpty);
      expect(saved()['tracker_mask'], 0);
    });

    test(
      'dünün hücresi (gece yarısından önce çizilmiş), özel gün, kazaya '
      'eklenmiş vakit ve bozuk adres işaretlemez; widget yine çizilir',
      () async {
        final yesterday = PrayerTracker.addDays(today(), -1);
        SharedPreferences.setMockInitialValues({
          'prayer_kaza_added': '{"${dk(today())}":${bit('Akşam')}}',
        });
        expect(
          await TrackerWidgetService.handleTap(tap(yesterday, 1)),
          isFalse,
        );
        expect(await TrackerWidgetService.handleTap(tap(today(), 3)), isFalse);
        expect(
          await TrackerWidgetService.handleTap(Uri.parse('vaktinde://x')),
          isFalse,
        );
        expect(await TrackerWidgetService.handleTap(null), isFalse);
        expect(await log(), isEmpty);
        expect(updated(), List.filled(4, 'VaktindeWidgetTrackerProvider'));
        expect(saved()['tracker_date'], dk(today()));

        // Bugün özel gün: hücreler sayılmaz
        SharedPreferences.setMockInitialValues({
          'tracker_excused': [dk(today())],
        });
        widgetCalls.clear();
        expect(await TrackerWidgetService.handleTap(tap(today(), 0)), isFalse);
        expect(await log(), isEmpty);
        expect(saved()['tracker_excused_days'], dk(today()));
      },
    );

    test('kayıtlı dil ve başka isolate\'in işareti okunur', () async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'en',
        'prayer_log': '{"${dk(today())}":${bit('Yatsı')}}',
      });
      await TrackerWidgetService.update();
      expect(saved()['tracker_title'], en.trackerToday);
      expect(saved()['tracker_mask'], bit('Yatsı'));
      expect(saved()['tracker_labels'], startsWith(en.sabah));
      expect(updated(), ['VaktindeWidgetTrackerProvider']);
    });

    test('"Kıldım" bildirimi takip widget\'ını da yeniler', () async {
      SharedPreferences.setMockInitialValues({});
      onNotificationActionBackground(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 4,
          actionId: PrayerTracker.actionId,
          payload: PrayerTracker.payload(today(), 'İkindi'),
        ),
      );
      for (var i = 0; i < 50 && updated().isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(await log(), {dk(today()): bit('İkindi')});
      expect(saved()['tracker_mask'], bit('İkindi'));
      expect(updated(), ['VaktindeWidgetTrackerProvider']);
    });

    test('uygulama içi değişiklik (PrayerTrackerService.changes) takip '
        'widget\'ını uygulama dilinde yeniler', () async {
      SharedPreferences.setMockInitialValues({});
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(en);
      await PrayerTrackerService().setPrayed(today(), 'Akşam', true);
      for (var i = 0; i < 50 && updated().isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(saved()['tracker_mask'], bit('Akşam'));
      expect(saved()['tracker_title'], en.trackerToday);
      expect(updated(), ['VaktindeWidgetTrackerProvider']);

      // Özel gün de (bugün işaretlenince dönem başlar)
      widgetCalls.clear();
      await PrayerTrackerService().setExcused(today(), true);
      for (var i = 0; i < 50 && updated().isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final days = (saved()['tracker_excused_days'] as String).split(',');
      expect(days.first, dk(today()));
      expect(days, hasLength(PrayerTracker.excusedPeriodDays));
    });

    test('eklenti yoksa (test, eski platform) fırlatmaz', () async {
      SharedPreferences.setMockInitialValues({});
      messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        null,
      );
      await TrackerWidgetService.update();
      await TrackerWidgetService.registerCallback();
      expect(await TrackerWidgetService.handleTap(tap(today(), 2)), isTrue);
    });
  });
}
