// Cuma bildirimi (ID 2400-2403): her Cuma 09:00 plan (bugünden itibaren 4
// hafta, vakti geçen yok, dini gün bildirimi olan Cuma atlanır), kip/kanal,
// gövde ve "Kehf Suresi" düğmesi (NotificationRoutes), ayar (HomeViewModel,
// Ayarlar satırı, yedekten dönüş), uygulama içi ve arka plan (WorkManager)
// kurulumu
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/friday_notification_setting.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final tr = lookupAppLocalizations(const Locale('tr'));
  final days = DiniGunlerService.parseBildirimGunleri(
    jsonDecode(File('assets/data/religious_days.json').readAsStringSync())
        as List,
  );
  const fridayIds = [2400, 2401, 2402, 2403];

  List<PlannedAlarm> planAt(
    DateTime now, {
    AppLocalizations? loc,
    Set<DateTime> religious = const {},
  }) => PrayerRefreshService.buildFridayPlan(
    now: now,
    loc: loc ?? tr,
    religiousDays: religious,
  );

  // Dini gün bildirimi olan günler (o ayar açıkken Cuma bu günlerde atlanır)
  Set<DateTime> religiousAt(DateTime now) => {
    for (final a in PrayerRefreshService.buildReligiousDayPlan(
      days: days,
      now: now,
      loc: tr,
    ))
      PrayerTracker.day(a.time),
  };

  group('Plan', () {
    List<DateTime> times(DateTime now) => [for (final a in planAt(now)) a.time];

    test('bugünden itibaren 4 haftanın Cumaları 09:00; bugün Cuma ise vakti '
        'geçmediyse dahil, geçtiyse 4 hafta sonrası da yok', () {
      final fourFrom16 = [
        DateTime(2026, 10, 16, 9),
        DateTime(2026, 10, 23, 9),
        DateTime(2026, 10, 30, 9),
        DateTime(2026, 11, 6, 9),
      ];
      expect(times(DateTime(2026, 10, 14, 12)), fourFrom16); // Çarşamba
      expect(times(DateTime(2026, 10, 15, 23, 59)), fourFrom16); // Perşembe
      expect(times(DateTime(2026, 10, 16, 8, 59)), fourFrom16); // Cuma
      // Bugünün vakti geçti: geciken bildirimin ID'si 4 hafta sonrasınınkiyle
      // ezilmesin diye pencere bugünden 4 hafta
      expect(times(DateTime(2026, 10, 16, 9)), fourFrom16.skip(1));
      expect(times(DateTime(2026, 10, 16, 21)), fourFrom16.skip(1));
      // Hafta sınırı: Cumartesi
      expect(times(DateTime(2026, 10, 17, 0, 0, 1)), [
        ...fourFrom16.skip(1),
        DateTime(2026, 11, 13, 9),
      ]);
    });

    test('yıl dönümünde ve yaz saati geçişlerinde de 09:00, tam 7 takvim günü '
        'arayla', () {
      // Takvim günüyle hesaplanır (7×24 saat değil): yaz saatli bir bölgede
      // (ör. TZ=Europe/Berlin, 29 Mart ve 25 Ekim 2026) de saat kaymaz
      for (final now in [
        DateTime(2026, 12, 30, 12),
        DateTime(2026, 3, 25, 12),
        DateTime(2026, 10, 21, 12),
      ]) {
        final plan = planAt(now);
        expect(plan, hasLength(4), reason: '$now');
        for (final (i, a) in plan.indexed) {
          expect(a.time.weekday, DateTime.friday, reason: '${a.time}');
          expect((a.time.hour, a.time.minute), (9, 0), reason: '${a.time}');
          if (i > 0) {
            expect(PrayerTracker.daysBetween(plan[i - 1].time, a.time), 7);
          }
        }
      }
      expect(times(DateTime(2026, 12, 30, 12)), [
        DateTime(2027, 1, 1, 9),
        DateTime(2027, 1, 8, 9),
        DateTime(2027, 1, 15, 9),
        DateTime(2027, 1, 22, 9),
      ]);
    });

    test('dini gün bildirimi olan Cuma atlanır (günde tek bildirim)', () {
      expect(
        [
          for (final a in planAt(
            DateTime(2026, 10, 14, 12),
            religious: {DateTime(2026, 10, 23), DateTime(2026, 10, 24)},
          ))
            a.time,
        ],
        [
          DateTime(2026, 10, 16, 9),
          DateTime(2026, 10, 30, 9),
          DateTime(2026, 11, 6, 9),
        ],
      );
      // religious_days.json: Ramazan Bayramı 20 Mart 2026 Cuma
      final march = DateTime(2026, 3, 1, 12);
      expect(religiousAt(march), contains(DateTime(2026, 3, 20)));
      expect(
        [for (final a in planAt(march, religious: religiousAt(march))) a.time],
        [
          DateTime(2026, 3, 6, 9),
          DateTime(2026, 3, 13, 9),
          DateTime(2026, 3, 27, 9),
        ],
      );
      // Dini gün bildirimleri kapalıyken o Cuma da kurulur
      expect(times(march), contains(DateTime(2026, 3, 20, 9)));
    });

    test('metin, kanal, kip (her zaman gecikmeli), gövde yükü ve "Kehf '
        'Suresi" düğmesi', () {
      final a = planAt(DateTime(2026, 10, 14, 12)).first;
      expect(a.title, 'Hayırlı Cumalar');
      expect(
        a.body,
        "Kehf Suresi'ni okumayı ve sevdiklerinize Cuma mesajı göndermeyi "
        'unutmayın.',
      );
      expect(a.channelName, tr.religiousDaysChannel);
      expect(a.sound, isNull);
      expect(a.payload, 'open|friday');
      expect(a.actionLabel, 'Kehf Suresi');
      expect(PrayerRefreshService.fridayKehfRoute, 'open|surah:18');
      for (final exact in <bool?>[true, false, null]) {
        for (final notif in <bool?>[true, false, null]) {
          expect(
            NotificationService.scheduleModeFor(
              a.kind,
              exactAllowed: exact,
              notificationsEnabled: notif,
            ),
            AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    });

    test('ID 2400-2403: Cuma\'nın haftasına bağlı, 4 haftada tekrar etmez, '
        'diğer bildirimlerle çakışmaz', () {
      final others = {
        for (var id = 0; id < PrayerRefreshService.alarmIdCount; id++) id,
        for (var id = 100; id <= 124; id++) id,
        888,
        ...PrayerRefreshService.dailyContentIds,
        PrayerRefreshService.testEzanId,
        for (var id = 2000; id < 2400; id++) id,
      };
      for (final id in others) {
        expect(PrayerRefreshService.isFridayId(id), isFalse, reason: '$id');
      }
      for (final id in fridayIds) {
        expect(PrayerRefreshService.isFridayId(id), isTrue);
        expect(PrayerRefreshService.isReligiousDayId(id), isFalse);
      }
      expect(PrayerRefreshService.isFridayId(2404), isFalse);

      final ids = [
        for (
          var friday = DateTime(2025, 1, 3);
          friday.year < 2029;
          friday = PrayerTracker.addDays(friday, 7)
        )
          PrayerRefreshService.fridayId(friday),
      ];
      for (var i = 0; i + 4 <= ids.length; i++) {
        expect(ids.sublist(i, i + 4).toSet(), hasLength(4));
      }
      // Her gün kurulan plan aynı Cuma'ya aynı ID'yi verir
      for (var d = 0; d < 21; d++) {
        final day = PrayerTracker.addDays(DateTime(2026, 12, 20), d);
        final plan = planAt(DateTime(day.year, day.month, day.day, 12));
        for (final a in plan) {
          expect(a.id, PrayerRefreshService.fridayId(a.time));
        }
        expect(plan.map((a) => a.id).toSet(), hasLength(plan.length));
      }
    });

    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      test('$lang: başlık, metin, düğme ve ayar satırı çevrili', () {
        final loc = lookupAppLocalizations(Locale(lang));
        final texts = [
          loc.fridayGreeting,
          loc.fridayNotifBody,
          loc.fridayKehfAction,
          loc.fridayNotifTitle,
          loc.fridayNotifSub,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty);
          expect(t, isNot(contains('{')));
        }
        expect(texts.toSet(), hasLength(texts.length));
        if (lang != 'tr') {
          expect(loc.fridayNotifBody, isNot(tr.fridayNotifBody));
          expect(loc.fridayNotifSub, isNot(tr.fridayNotifSub));
        }
        final a = planAt(DateTime(2026, 10, 14, 12), loc: loc).first;
        expect(
          (a.title, a.body, a.actionLabel, a.channelName),
          (
            loc.fridayGreeting,
            loc.fridayNotifBody,
            loc.fridayKehfAction,
            loc.religiousDaysChannel,
          ),
        );
      });
    }
  });

  group('Kurulum', () {
    // Eklentinin bekleyen listesi: ID → zonedSchedule bağımsız değişkenleri
    late Map<int, Map<Object?, Object?>> pending;
    late List<MethodCall> calls;
    late Set<int> failIds;

    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      pending = {};
      calls = [];
      failIds = {};
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/Istanbul',
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async => true,
      );
      messenger.setMockMethodCallHandler(notifChannel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
            final id = call.arguments['id'] as int;
            if (failIds.contains(id)) {
              throw PlatformException(code: 'error', message: 'kurulamadı');
            }
            pending[id] = call.arguments as Map<Object?, Object?>;
            return null;
          case 'cancel':
            pending.remove(call.arguments['id']);
            return null;
          case 'pendingNotificationRequests':
            return [
              for (final e in pending.entries)
                {
                  'id': e.key,
                  'title': e.value['title'],
                  'body': e.value['body'],
                  'payload': e.value['payload'],
                },
            ];
          default:
            return null;
        }
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(notifChannel, null);
    });

    List<int> scheduledIds() => [
      for (final c in calls)
        if (c.method == 'zonedSchedule') c.arguments['id'] as int,
    ];
    List<int> cancelledIds() => [
      for (final c in calls)
        if (c.method == 'cancel') c.arguments['id'] as int,
    ];
    Iterable<int> pendingFridays() =>
        pending.keys.where(PrayerRefreshService.isFridayId);
    void seed(int id) =>
        pending[id] = {'title': 'eski', 'body': 'eski', 'payload': null};

    // Eklenti geçmiş saati reddeder: gerçek saate göre en az iki gün sonraki
    // ilk [weekday], [hour]:[minute]
    DateTime upcoming(int weekday, int hour, [int minute = 0]) {
      final from = PrayerTracker.addDays(DateTime.now(), 2);
      final day = PrayerTracker.addDays(from, (weekday - from.weekday) % 7);
      return DateTime(day.year, day.month, day.day, hour, minute);
    }

    Future<PrayerRefreshService> serviceAt(DateTime at) async {
      final notifications = NotificationService();
      await notifications.init();
      return PrayerRefreshService(notifications, clock: () => at);
    }

    Future<void> rescheduleAt(DateTime at) async =>
        (await serviceAt(at)).rescheduleAlarms(
          todayTimes: PrayerTimeService().calculate(41.0, 29.0, date: at),
          loc: tr,
          onTimeAlarms: const {'Öğle': true},
          reminderAlarms: const {},
          selectedSounds: const {},
          selectedReminderSounds: const {},
          silentModeSettings: const {},
        );

    test('ayar açık (varsayılan): 4 Cuma gecikmeli kipte, dini gün kanalında '
        '09:00\'a kurulur; gövde Cuma mesajlarını, "Kehf Suresi" uygulamayı '
        'açıp Kehf\'i açar; diğer ID\'lere dokunulmaz', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.religiousDaysEnabledKey: false,
      });
      final at = upcoming(DateTime.wednesday, 12);
      final expected = planAt(at);
      expect(expected, hasLength(4));
      final others = [
        2000,
        PrayerRefreshService.ayahNotificationId,
        PrayerRefreshService.alarmId(at, 2),
      ];
      others.forEach(seed);

      expect(await (await serviceAt(at)).syncFridayNotifications(tr), isTrue);

      expect(scheduledIds(), [for (final a in expected) a.id]);
      expect(cancelledIds(), isEmpty);
      for (final a in expected) {
        final args = pending[a.id]!;
        final specifics = args['platformSpecifics'] as Map;
        expect(args['title'], 'Hayırlı Cumalar');
        expect(args['body'], tr.fridayNotifBody);
        expect(
          args['scheduledDateTime'],
          '${PrayerTracker.dateKey(a.time)}T09:00:00',
        );
        expect(args['payload'], 'open|friday');
        expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
        expect(specifics['channelId'], 'religious_days_channel');
        expect(specifics['channelName'], tr.religiousDaysChannel);
        final action = (specifics['actions'] as List).single as Map;
        expect(action['id'], 'open|surah:18');
        expect(action['title'], 'Kehf Suresi');
        expect(action['showsUserInterface'], isTrue);
        expect(action['cancelNotification'], isTrue);
      }
      expect(pending.keys, containsAll(others));
    });

    // Gerçek saate göre en az üç gün sonraki, dini gün bildirimi olan ilk Cuma
    DateTime? religiousFriday() {
      var from = PrayerTracker.addDays(DateTime.now(), 3);
      for (var i = 0; i < 30; i++) {
        final fridays = [
          for (final day in religiousAt(from))
            if (day.weekday == DateTime.friday) day,
        ]..sort();
        if (fridays.isNotEmpty) return fridays.first;
        from = PrayerTracker.addDays(
          from,
          PrayerRefreshService.religiousDayDays,
        );
      }
      return null;
    }

    final religiousFridayDay = religiousFriday();
    test(
      'dini gün bildirimi olan Cuma kurulmaz, bekleyeni iptal edilir; dini '
      'gün bildirimleri kapalıyken kurulur',
      () async {
        SharedPreferences.setMockInitialValues({});
        final friday = religiousFridayDay!;
        final at = DateTime(friday.year, friday.month, friday.day - 2, 12);
        final skipped = PrayerRefreshService.fridayId(friday);
        fridayIds.forEach(seed);

        expect(await (await serviceAt(at)).syncFridayNotifications(tr), isTrue);
        final expected = planAt(at, religious: religiousAt(at));
        final expectedIds = {for (final a in expected) a.id};
        expect(scheduledIds(), [for (final a in expected) a.id]);
        expect(expectedIds, isNot(contains(skipped)));
        expect(cancelledIds(), contains(skipped));
        expect(
          cancelledIds().toSet(),
          fridayIds.toSet().difference(expectedIds),
        );
        expect(pendingFridays().toSet(), expectedIds);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageService.religiousDaysEnabledKey, false);
        calls.clear();
        expect(await (await serviceAt(at)).syncFridayNotifications(tr), isTrue);
        expect(scheduledIds(), [for (final a in planAt(at)) a.id]);
        expect(scheduledIds(), contains(skipped));
      },
      skip: religiousFridayDay == null
          ? 'religious_days.json\'da ileri tarihli Cuma yok'
          : null,
    );

    test('vakti geçmiş bugünün bildirimi (gecikmeli kipte henüz gelmemiş '
        'olabilir) iptal edilmez, yeniden de kurulmaz; ayar kapalıysa hepsi '
        'iptal', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.religiousDaysEnabledKey: false,
      });
      final at = upcoming(DateTime.friday, 10, 30);
      final todayId = PrayerRefreshService.fridayId(at);
      seed(todayId);

      await (await serviceAt(at)).syncFridayNotifications(tr);
      expect(pending.keys, contains(todayId));
      expect(scheduledIds(), isNot(contains(todayId)));
      expect(scheduledIds(), hasLength(3));
      expect(cancelledIds(), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageService.fridayNotifEnabledKey, false);
      final later = scheduledIds();
      await (await serviceAt(at)).syncFridayNotifications(tr);
      expect(cancelledIds().toSet(), {todayId, ...later});
      expect(pendingFridays(), isEmpty);
    });

    test('ayar kapalıyken kurulum turu (rescheduleAlarms) kurmaz, kalmış '
        'olanları iptal eder; ezan alarmları etkilenmez', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        StorageService.religiousDaysEnabledKey: false,
        StorageService.fridayNotifEnabledKey: false,
      });
      final at = upcoming(DateTime.wednesday, 12);
      final leftover = PrayerRefreshService.fridayId(
        PrayerTracker.addDays(at, 2),
      );
      seed(leftover);

      await rescheduleAt(at);
      expect(scheduledIds().where(PrayerRefreshService.isFridayId), isEmpty);
      expect(cancelledIds(), [leftover]);
      expect(scheduledIds(), contains(PrayerRefreshService.alarmId(at, 2)));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('alarms_scheduled_date'),
        PrayerTracker.dateKey(at),
      );
    });

    test('Cuma bildirimi kurulamazsa gün kaydedilmez (arka plan görevi aynı '
        'gün yeniden dener)', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        StorageService.religiousDaysEnabledKey: false,
      });
      final at = upcoming(DateTime.wednesday, 12);
      failIds = {for (final a in planAt(at)) a.id};

      await rescheduleAt(at);
      expect(pending.keys, contains(PrayerRefreshService.alarmId(at, 2)));
      expect(pendingFridays(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('alarms_scheduled_date'), isNull);

      failIds = {};
      await rescheduleAt(at);
      expect(pendingFridays(), hasLength(4));
      expect(
        prefs.getString('alarms_scheduled_date'),
        PrayerTracker.dateKey(at),
      );
    });

    test('arka plan görevi (WorkManager) seçili dilde kurar; aynı gün ikinci '
        'koşu dokunmaz', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'saved_city': 'İstanbul',
        'language_code': 'de',
        PrayerRefreshService.scheduleModeMigratedKey: true,
        StorageService.religiousDaysEnabledKey: false,
      });
      // Günlük içerik zaten kurulu (ağ gerekmesin)
      seed(PrayerRefreshService.ayahNotificationId);
      seed(PrayerRefreshService.hadithNotificationId);
      final at = upcoming(DateTime.wednesday, 12);
      final de = lookupAppLocalizations(const Locale('de'));
      final expected = planAt(at, loc: de);

      expect(await PrayerRefreshService.runHeadless(clock: () => at), isTrue);
      expect(scheduledIds().where(PrayerRefreshService.isFridayId), [
        for (final a in expected) a.id,
      ]);
      for (final a in expected) {
        final args = pending[a.id]!;
        expect(args['title'], de.fridayGreeting);
        expect(args['body'], de.fridayNotifBody);
        final specifics = args['platformSpecifics'] as Map;
        expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
        expect(
          ((specifics['actions'] as List).single as Map)['title'],
          de.fridayKehfAction,
        );
      }
      expect(de.fridayNotifBody, isNot(tr.fridayNotifBody));

      calls.clear();
      expect(await PrayerRefreshService.runHeadless(clock: () => at), isTrue);
      expect(scheduledIds(), isEmpty);
      expect(cancelledIds(), isEmpty);
    });

    test('Ayarlar anahtarı (HomeViewModel): kapatınca bekleyenler hemen '
        'iptal, açınca önümüzdeki Cumalar kurulur; dini gün anahtarı da '
        'eşitler', () async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(tr);
      expect(vm.fridayNotifEnabled, isTrue);
      fridayIds.forEach(seed);
      seed(PrayerRefreshService.hadithNotificationId);

      await vm.setFridayNotifEnabled(false);
      expect(vm.fridayNotifEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageService.fridayNotifEnabledKey), isFalse);
      expect(cancelledIds().toSet(), fridayIds.toSet());
      expect(pending.keys, [PrayerRefreshService.hadithNotificationId]);
      expect(scheduledIds(), isEmpty);

      calls.clear();
      final now = DateTime.now();
      final expected = planAt(now, religious: religiousAt(now));
      await vm.setFridayNotifEnabled(true);
      expect(prefs.getBool(StorageService.fridayNotifEnabledKey), isTrue);
      expect(scheduledIds(), [for (final a in expected) a.id]);
      expect(cancelledIds(), isEmpty);

      // Dini gün bildirimleri kapanınca onlara denk gelen Cuma da kurulur,
      // açılınca yine atlanır
      calls.clear();
      await vm.setReligiousDaysEnabled(false);
      expect(scheduledIds().where(PrayerRefreshService.isFridayId), [
        for (final a in planAt(now)) a.id,
      ]);
      await vm.setReligiousDaysEnabled(true);
      expect(pendingFridays().toSet(), {for (final a in expected) a.id});
    });

    test('yedekten dönüş (reloadFromStorage): ayar kayıttan okunur, Cuma '
        'bildirimleri ona göre iptal edilir ya da kurulur', () async {
      SharedPreferences.setMockInitialValues({
        'saved_city': 'Ankara',
        'saved_lat': 39.93,
        'saved_lng': 32.85,
        'daily_content_enabled': false,
        StorageService.persistentNotificationKey: false,
      });
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(tr);
      fridayIds.forEach(seed);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageService.fridayNotifEnabledKey, false);
      await vm.reloadFromStorage();
      expect(vm.fridayNotifEnabled, isFalse);
      expect(pendingFridays(), isEmpty);

      // Yedekte yok: varsayılan (açık)
      await prefs.remove(StorageService.fridayNotifEnabledKey);
      await vm.reloadFromStorage();
      expect(vm.fridayNotifEnabled, isTrue);
      expect(pendingFridays(), isNotEmpty);
    });
  });

  group('Ayarlar satırı', () {
    Future<HomeViewModel> pump(
      WidgetTester tester, {
      String lang = 'tr',
      double width = 411,
      double textScale = 1,
    }) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final vm = HomeViewModel();
      await tester.pumpWidget(
        // lazy: false → ağaçla birlikte kapatılır (gece yarısı zamanlayıcısı)
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => vm,
          lazy: false,
          child: MaterialApp(
            locale: Locale(lang),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListView(children: const [FridayNotificationSetting()]),
            ),
          ),
        ),
      );
      await tester.pump();
      return vm;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('varsayılan açık; anahtar da satır da değiştirir ve kaydeder', (
      tester,
    ) async {
      final vm = await pump(tester);
      expect(find.text('Cuma Bildirimi'), findsOneWidget);
      expect(find.text(tr.fridayNotifSub), findsOneWidget);
      Switch toggle() => tester.widget<Switch>(find.byType(Switch));
      expect(toggle().value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(toggle().value, isFalse);
      expect(vm.fridayNotifEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageService.fridayNotifEnabledKey), isFalse);

      await tester.tap(find.text(tr.fridayNotifTitle));
      await tester.pump();
      expect(toggle().value, isTrue);
      expect(prefs.getBool(StorageService.fridayNotifEnabledKey), isTrue);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    for (final lang in ['tr', 'de', 'ar']) {
      testWidgets('$lang: 320dp %130 yazıda taşmaz', (tester) async {
        await pump(tester, lang: lang, width: 320, textScale: 1.3);
        final loc = lookupAppLocalizations(Locale(lang));
        expect(find.text(loc.fridayNotifTitle), findsOneWidget);
        expect(find.text(loc.fridayNotifSub), findsOneWidget);
        expect(tester.takeException(), isNull);
        await finish(tester);
      });
    }
  });
}
