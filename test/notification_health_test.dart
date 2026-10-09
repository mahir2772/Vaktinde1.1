// Bildirim Kontrolü: cihaz durumundan satır durumları (sahte "vaktinde/device"
// kanalı), üreticiye göre rehber, test ezanı (ID 1999; gerçek ezanın sesi, kanalı
// ve kipi; plan temizliği dokunmaz), sıradaki kurulu ezan, arka plan görevinin son
// koşusu ve 24 saat uyarısı; 320 dp + %130 yazıda taşma yok
import 'dart:convert';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/notification_health/notification_health.dart';
import 'package:ezan_saati/features/notification_health/view/notification_health_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _FakeHomeViewModel extends HomeViewModel {
  int reschedules = 0;

  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> rescheduleAlarms() async => reschedules++;
}

const Map<String, Object?> _healthyDevice = {
  'manufacturer': 'samsung',
  'brand': 'samsung',
  'sdkInt': 35,
  'batteryOptimized': false,
  'interruptionFilter': 1,
  'notificationVolume': 5,
  'alarmVolume': 5,
  'ringerMode': 2,
};

const Map<String, Object?> _problemDevice = {
  'manufacturer': 'Xiaomi',
  'brand': 'Redmi',
  'sdkInt': 34,
  'batteryOptimized': true,
  'interruptionFilter': 2,
  'notificationVolume': 5,
  'alarmVolume': 5,
  'ringerMode': 1,
};

Map<String, Object> _pendingRequest(int id) => {
  'id': id,
  'title': '',
  'body': '',
  'payload': '',
};

// Kurulum kaydı (ilk alan vaktin zamanı)
String _fingerprint(DateTime time) => PrayerRefreshService.alarmFingerprint(
  PlannedAlarm(
    id: 0,
    kind: NotificationKind.prayer,
    title: 'Ezan Vakti',
    body: '',
    time: time,
    sound: 'ezan1',
    channelName: 'Ses: ezan1',
    payload: 'prayed',
  ),
);

DateTime _at(DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const deviceChannel = MethodChannel('vaktinde/device');
  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
  const otherChannels = [
    MethodChannel('flutter_timezone'),
    MethodChannel('home_widget'),
  ];
  final tr = lookupAppLocalizations(const Locale('tr'));

  // null: kanal yok (Android dışı / eski sürüm)
  late Map<String, Object?>? device;
  late List<String> opened;
  late bool exactAllowed;
  late bool notificationsEnabled;
  late List<Map<String, Object>> pending;
  late List<MethodCall> notifCalls;
  late bool failSchedule;
  late bool failPending;
  late bool failInitialize;
  late int exactRequests;
  late int notificationRequests;
  late List<MethodCall> launches;

  setUpAll(tz.initializeTimeZones);

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    device = {..._healthyDevice};
    opened = [];
    exactAllowed = true;
    notificationsEnabled = true;
    pending = [];
    notifCalls = [];
    failSchedule = false;
    failPending = false;
    failInitialize = false;
    exactRequests = 0;
    notificationRequests = 0;
    launches = [];
    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      switch (call.method) {
        case 'deviceInfo':
          if (device == null) throw MissingPluginException();
          return device;
        case 'openSettings':
          opened.add((call.arguments as Map)['target'] as String);
          return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      notifCalls.add(call);
      switch (call.method) {
        case 'initialize':
          if (failInitialize) throw PlatformException(code: 'error');
          return true;
        case 'canScheduleExactNotifications':
          return exactAllowed;
        case 'areNotificationsEnabled':
          return notificationsEnabled;
        case 'requestExactAlarmsPermission':
          exactRequests++;
          return exactAllowed;
        case 'requestNotificationsPermission':
          notificationRequests++;
          return notificationsEnabled;
        case 'zonedSchedule':
          if (failSchedule) throw PlatformException(code: 'error');
          final id = call.arguments['id'] as int;
          pending
            ..removeWhere((p) => p['id'] == id)
            ..add(_pendingRequest(id));
          return null;
        case 'cancel':
          pending.removeWhere((p) => p['id'] == call.arguments['id']);
          return null;
        case 'pendingNotificationRequests':
          if (failPending) throw PlatformException(code: 'error');
          return pending;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(permissionChannel, (call) async => true);
    messenger.setMockMethodCallHandler(urlLauncher, (call) async {
      launches.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(
      otherChannels[0],
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(otherChannels[1], (call) async => true);
    final now = DateTime.now();
    PackageInfo.setMockInitialValues(
      appName: 'Vaktinde',
      packageName: 'com.mmdigital.vaktinde',
      version: '1.2.0',
      buildNumber: '17',
      buildSignature: '',
      installTime: now.subtract(const Duration(days: 30)),
      updateTime: now.subtract(const Duration(days: 3)),
    );
  });

  tearDown(() {
    for (final channel in [
      deviceChannel,
      notifChannel,
      permissionChannel,
      urlLauncher,
      ...otherChannels,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  group('saf kararlar', () {
    test('üretici ailesi Build.MANUFACTURER / BRAND kelimelerinden', () {
      const cases = {
        ('Xiaomi', 'Redmi'): PhoneVendor.xiaomi,
        ('Xiaomi', 'POCO'): PhoneVendor.xiaomi,
        ('Xiaomi', 'Xiaomi'): PhoneVendor.xiaomi,
        ('HUAWEI', 'HUAWEI'): PhoneVendor.huawei,
        ('HONOR', 'HONOR'): PhoneVendor.huawei,
        ('OPPO', 'OPPO'): PhoneVendor.oppo,
        ('realme', 'realme'): PhoneVendor.oppo,
        ('OnePlus', 'OnePlus'): PhoneVendor.oppo,
        ('vivo', 'vivo'): PhoneVendor.vivo,
        ('vivo', 'iQOO'): PhoneVendor.vivo,
        ('samsung', 'samsung'): PhoneVendor.samsung,
        ('TECNO MOBILE LIMITED', 'TECNO'): PhoneVendor.transsion,
        ('INFINIX MOBILITY LIMITED', 'Infinix'): PhoneVendor.transsion,
        ('itel', 'itel'): PhoneVendor.transsion,
        ('Google', 'google'): PhoneVendor.generic,
        ('motorola', 'motorola'): PhoneVendor.generic,
        ('HMD Global', 'Nokia'): PhoneVendor.generic,
        ('General Mobile', 'GM'): PhoneVendor.generic,
        // Kelime içinde geçen ad sayılmaz ("Satellite" ≠ itel)
        ('Satellite', 'Vivobook'): PhoneVendor.generic,
        ('', ''): PhoneVendor.generic,
      };
      for (final MapEntry(key: (manufacturer, brand), :value)
          in cases.entries) {
        expect(
          NotificationHealth.vendorOf(manufacturer, brand),
          value,
          reason: '$manufacturer / $brand',
        );
      }
    });

    test('rehber: her üreticiye 2-4 adım, her dilde dolu', () {
      expect(
        NotificationHealth.vendorNames.keys.toSet(),
        PhoneVendor.values.toSet()..remove(PhoneVendor.generic),
      );
      for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
        final loc = lookupAppLocalizations(Locale(lang));
        for (final vendor in PhoneVendor.values) {
          final steps = NotificationHealth.guideSteps(vendor, loc);
          expect(steps.length, inInclusiveRange(2, 4), reason: '$lang $vendor');
          expect(steps.toSet(), hasLength(steps.length));
          expect(steps.every((s) => s.trim().length > 20), isTrue);
          // Son uygulamalarda kilit (Samsung'da böyle bir seçenek yok)
          expect(
            steps.contains(loc.healthStepLockRecents),
            vendor != PhoneVendor.samsung,
            reason: '$lang $vendor',
          );
        }
        List<String> steps(PhoneVendor v) =>
            NotificationHealth.guideSteps(v, loc);
        expect(steps(PhoneVendor.xiaomi).take(2), [
          loc.healthStepXiaomiAutostart,
          loc.healthStepXiaomiBattery,
        ]);
        expect(steps(PhoneVendor.huawei).first, loc.healthStepHuaweiLaunch);
        expect(steps(PhoneVendor.oppo).first, loc.healthStepOppoBackground);
        expect(
          steps(PhoneVendor.vivo),
          contains(loc.healthStepAutostartIn('i Manager')),
        );
        expect(steps(PhoneVendor.samsung), [
          loc.healthStepAppBattery,
          loc.healthStepSamsungSleeping,
        ]);
        expect(
          steps(PhoneVendor.transsion).first,
          loc.healthStepAutostartIn('Phone Master'),
        );
        expect(steps(PhoneVendor.generic).first, loc.healthStepAppBattery);
      }
    });

    test('ses: alarm akışında sadece alarm sesi; bildirim akışında sessiz/'
        'titreşim modu ve bildirim sesi', () {
      VolumeIssue? issue({
        int? ringer,
        int? notification,
        int? alarm,
        bool alarmStream = false,
      }) => NotificationHealth.volumeIssue(
        DeviceStatus(
          ringerMode: ringer,
          notificationVolume: notification,
          alarmVolume: alarm,
        ),
        alarmStream: alarmStream,
      );
      expect(issue(ringer: 2, notification: 4, alarm: 4), isNull);
      expect(issue(ringer: 1, notification: 4), VolumeIssue.silentMode);
      expect(issue(ringer: 0, notification: 0), VolumeIssue.silentMode);
      expect(issue(ringer: 2, notification: 0), VolumeIssue.notificationMuted);
      expect(issue(notification: 0), VolumeIssue.notificationMuted);
      expect(issue(), isNull);
      // "Sessiz modda da çal": zil modu ve bildirim sesi ezanı etkilemez
      expect(
        issue(ringer: 0, notification: 0, alarm: 3, alarmStream: true),
        isNull,
      );
      expect(
        issue(ringer: 2, notification: 4, alarm: 0, alarmStream: true),
        VolumeIssue.alarmMuted,
      );
    });

    test('Rahatsız Etmeyin: kapalı ok; alarm akışında alarmlara izin veren '
        'süzgeçte bilgi; tam sessizlikte ve bildirim akışında uyarı', () {
      HealthStatus? status(int? filter, bool alarmStream) =>
          NotificationHealth.dndStatus(filter, alarmStream: alarmStream);
      expect(status(null, false), isNull);
      expect(status(0, true), isNull);
      expect(status(1, false), HealthStatus.ok);
      expect(status(1, true), HealthStatus.ok);
      for (final filter in [2, 4]) {
        expect(status(filter, false), HealthStatus.warning);
        expect(status(filter, true), HealthStatus.info);
      }
      expect(status(3, false), HealthStatus.warning);
      expect(status(3, true), HealthStatus.warning);
    });

    test('arka planda çalışma: son koşu 48 saatten eskiyse uyarı; kayıt '
        'yoksa sürüm 48 saatten eskiyse uyarı, değilse bilinmiyor', () {
      final now = DateTime(2026, 10, 9, 12);
      DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));
      HealthStatus? status(DateTime? lastRun, DateTime? installedAt) =>
          NotificationHealth.backgroundStatus(
            lastRun: lastRun,
            installedAt: installedAt,
            now: now,
          );
      expect(status(hoursAgo(2), hoursAgo(900)), HealthStatus.ok);
      expect(status(hoursAgo(30), hoursAgo(900)), HealthStatus.ok);
      expect(status(hoursAgo(48), hoursAgo(900)), HealthStatus.ok);
      expect(status(hoursAgo(49), hoursAgo(900)), HealthStatus.warning);
      // Güncellemeden önceki son koşu da eskidir
      expect(status(hoursAgo(49), hoursAgo(1)), HealthStatus.warning);
      // 1.2.0 öncesinde kayıt yoktu: yeni sürüm 48 saati doldurmadan uyarı yok
      expect(status(null, hoursAgo(3)), isNull);
      expect(status(null, hoursAgo(48)), isNull);
      expect(status(null, hoursAgo(49)), HealthStatus.warning);
      expect(status(null, null), isNull);
    });

    test('cihaz durumu: eksik alanlar null', () {
      final full = DeviceStatus.fromMap(_problemDevice);
      expect(full.manufacturer, 'Xiaomi');
      expect(full.brand, 'Redmi');
      expect(full.sdkInt, 34);
      expect(full.batteryOptimized, isTrue);
      expect(full.interruptionFilter, 2);
      expect(full.ringerMode, 1);
      final empty = DeviceStatus.fromMap(const {'batteryOptimized': null});
      expect(empty.manufacturer, '');
      expect(empty.batteryOptimized, isNull);
      expect(empty.alarmVolume, isNull);
    });
  });

  group('servis', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Map<Object?, Object?> specifics(MethodCall call) =>
        call.arguments['platformSpecifics'] as Map<Object?, Object?>;

    Future<MethodCall> scheduleTest({
      Map<String, bool> onTime = const {},
      Map<String, String> sounds = const {},
      Map<String, bool> silent = const {},
      bool alarmStream = false,
    }) async {
      await PrayerRefreshService(NotificationService()).scheduleTestEzan(
        loc: tr,
        onTimeAlarms: onTime,
        selectedSounds: sounds,
        silentModeSettings: silent,
        alarmStream: alarmStream,
      );
      return notifCalls.lastWhere((c) => c.method == 'zonedSchedule');
    }

    test('test ezanı: ID 1999, 1 dk sonra, ilk açık vaktin sesi ve kanalı, '
        'alarmClock; "Kıldım" yok', () async {
      SharedPreferences.setMockInitialValues({});
      final before = DateTime.now();
      var call = await scheduleTest(
        onTime: const {'İmsak': false, 'Öğle': true, 'Akşam': true},
        sounds: const {'Öğle': 'ezan3', 'Akşam': 'ezan5'},
      );
      expect(call.arguments['id'], PrayerRefreshService.testEzanId);
      expect(call.arguments['title'], tr.healthTestTitle);
      expect(call.arguments['body'], tr.healthTestNotifBody);
      expect(call.arguments['payload'], isEmpty);
      expect(specifics(call)['channelId'], 'channel_ezan3');
      expect(specifics(call)['channelName'], tr.channelSoundPrefix('ezan3'));
      expect(specifics(call)['sound'], 'ezan3');
      expect(specifics(call)['scheduleMode'], 'alarmClock');
      expect(specifics(call)['actions'], isNull);
      final naive = DateTime.parse(call.arguments['scheduledDateTime']);
      final at = tz.TZDateTime(
        tz.getLocation(call.arguments['timeZoneName']),
        naive.year,
        naive.month,
        naive.day,
        naive.hour,
        naive.minute,
        naive.second,
      );
      expect(at.difference(before).inSeconds, inInclusiveRange(58, 62));

      // İlk açık vakit "sadece yazılı": sessiz kanal
      call = await scheduleTest(
        onTime: const {'Öğle': true},
        silent: const {'Öğle': true},
      );
      expect(specifics(call)['channelId'], 'channel_silent_prayer');
      expect(specifics(call)['playSound'], isFalse);
      // Hiç açık vakit yok: ezan1
      call = await scheduleTest();
      expect(specifics(call)['channelId'], 'channel_ezan1');
      // "Sessiz modda da çal": alarm kanalı ve alarm ses türü
      call = await scheduleTest(
        onTime: const {'Yatsı': true},
        sounds: const {'Yatsı': 'ezan2'},
        alarmStream: true,
      );
      expect(specifics(call)['channelId'], 'alarm_channel_ezan2');
      expect(specifics(call)['channelName'], tr.channelAlarmSound('ezan2'));
      expect(
        specifics(call)['audioAttributesUsage'],
        AudioAttributesUsage.alarm.value,
      );
      // Hep aynı ID: tekrar basınca üzerine yazılır
      expect(
        notifCalls
            .where((c) => c.method == 'zonedSchedule')
            .map((c) => c.arguments['id'])
            .toSet(),
        {PrayerRefreshService.testEzanId},
      );
    });

    test(
      'test ezanının kipi gerçek ezanınkiyle aynı (izinlere göre)',
      () async {
        SharedPreferences.setMockInitialValues({});
        exactAllowed = false;
        expect(
          specifics(await scheduleTest())['scheduleMode'],
          'inexactAllowWhileIdle',
        );
        exactAllowed = true;
        notificationsEnabled = false;
        expect(
          specifics(await scheduleTest())['scheduleMode'],
          'exactAllowWhileIdle',
        );
      },
    );

    test('plan temizliği test ezanına dokunmaz; vakit sayılmaz', () async {
      expect(
        PrayerRefreshService.testEzanId,
        greaterThanOrEqualTo(PrayerRefreshService.alarmIdCount),
      );
      expect(
        PrayerTracker.isEndReminderId(PrayerRefreshService.testEzanId),
        isFalse,
      );
      expect(
        PrayerRefreshService.dailyContentIds,
        isNot(contains(PrayerRefreshService.testEzanId)),
      );
      // Kip geçişi bitmemiş: bekleyen günlük içerik de yeniden yazılır
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'end_reminder_enabled': true,
      });
      final notifications = NotificationService();
      await notifications.init();
      final service = PrayerRefreshService(notifications);
      await service.scheduleTestEzan(
        loc: tr,
        onTimeAlarms: const {},
        selectedSounds: const {},
        silentModeSettings: const {},
      );
      // Plandan çıkmış eski hatırlatma (tek ID): temizliğin çalıştığı görülsün
      pending.add(_pendingRequest(71));
      final times = PrayerTimeService().calculate(41.0, 29.0);
      await service.rescheduleAlarms(
        todayTimes: times,
        loc: tr,
        onTimeAlarms: const {'Öğle': true},
        reminderAlarms: const {},
        selectedSounds: const {},
        selectedReminderSounds: const {},
        silentModeSettings: const {},
      );
      await service.syncEndReminders(todayTimes: times, loc: tr);
      await service.cancelDailyContent();
      final cancelled = notifCalls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments['id'])
          .toSet();
      expect(cancelled, contains(71));
      expect(cancelled, isNot(contains(PrayerRefreshService.testEzanId)));
      expect(
        pending.map((p) => p['id']),
        contains(PrayerRefreshService.testEzanId),
      );
      // Sıradaki ezan hesabında yok
      final next = await service.nextScheduledEzan();
      expect(next, isNotNull);
      expect(next!.key, 'Öğle');
    });

    test('sıradaki kurulu ezan: en yakın gelecek ezan; saat kurulum '
        'kaydından, yoksa hesaptan; ezan olmayan ID sayılmaz', () async {
      final now = DateTime.now();
      final tomorrow = PrayerTracker.addDays(now, 1);
      final ogle = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 13, 5);
      final ogleId = PrayerRefreshService.alarmId(tomorrow, 2);
      final pastId = PrayerRefreshService.alarmId(
        PrayerTracker.addDays(now, -1),
        4,
      );
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        PrayerRefreshService.planMetaKey: jsonEncode({
          '$ogleId': _fingerprint(ogle),
          '$pastId': _fingerprint(now.subtract(const Duration(hours: 20))),
        }),
      });
      pending = [
        for (final id in [
          ogleId,
          pastId,
          ogleId + 1, // hatırlatma
          PrayerRefreshService.testEzanId,
          PrayerRefreshService.ayahNotificationId,
          PrayerTracker.endReminderBaseId,
        ])
          _pendingRequest(id),
      ];
      final service = PrayerRefreshService(NotificationService());
      expect(await service.nextScheduledEzan(), (key: 'Öğle', time: ogle));

      // Kaydı olmayan ezan (yarın imsak): kayıtlı konumla hesaplanır
      pending.add(_pendingRequest(PrayerRefreshService.alarmId(tomorrow, 0)));
      final imsak = (await PrayerTimeService().forDate(tomorrow))!.imsak!;
      expect(await service.nextScheduledEzan(), (
        key: 'İmsak',
        time: _at(tomorrow, imsak),
      ));

      // Bekleyen ezan yok: null; okunamazsa hata (ekran satırı gizler)
      pending = [
        _pendingRequest(PrayerRefreshService.testEzanId),
        _pendingRequest(PrayerRefreshService.hadithNotificationId),
      ];
      expect(await service.nextScheduledEzan(), isNull);
      failPending = true;
      await expectLater(
        service.nextScheduledEzan(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('arka plan görevi başarıyla bitince son koşu yazılır; başarısızsa '
        'yazılmaz', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      );
      DateTime clock() => now;
      // Koordinat yok: erken biter ama başarılıdır
      SharedPreferences.setMockInitialValues({'saved_city': 'İstanbul'});
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(await PrayerRefreshService.lastHeadlessRun(), now);

      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        PrayerRefreshService.scheduleModeMigratedKey: true,
      });
      expect(await PrayerRefreshService.lastHeadlessRun(), isNull);
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(PrayerRefreshService.lastHeadlessRunKey),
        now.millisecondsSinceEpoch,
      );

      // Bildirim eklentisi başlatılamadı: görev başarısız, kayıt yazılmaz
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      failInitialize = true;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isFalse);
      expect(await PrayerRefreshService.lastHeadlessRun(), isNull);
    });
  });

  group('ekran', () {
    final android = TargetPlatformVariant.only(TargetPlatform.android);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<_FakeHomeViewModel> pumpHealth(
      WidgetTester tester, {
      String lang = 'tr',
      double width = 411,
      double height = 891,
      double textScale = 1,
      Map<String, Object> prefs = const {},
      Map<String, bool> onTime = const {'Öğle': true, 'Akşam': true},
      Map<String, String> sounds = const {},
      bool alarmStream = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        ...prefs,
      });
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      if (textScale != 1) {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      final vm = _FakeHomeViewModel()
        ..onTimeAlarms = {...onTime}
        ..selectedSounds = {...sounds}
        ..ezanAlarmStream = alarmStream;
      await tester.pumpWidget(
        ChangeNotifierProvider<HomeViewModel>(
          // lazy: false → ağaçla birlikte kapatılır (gece yarısı zamanlayıcısı)
          create: (_) => vm,
          lazy: false,
          child: MaterialApp(
            locale: Locale(lang),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const NotificationHealthView(),
          ),
        ),
      );
      await settle(tester);
      return vm;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    // Satırın (durum simgesi + metin) tek butonu
    Finder actionOf(String message) => find.descendant(
      of: find
          .ancestor(of: find.text(message), matching: find.byType(Row))
          .first,
      matching: find.byType(TextButton),
    );

    Future<void> tapAction(WidgetTester tester, String message) async {
      final button = actionOf(message);
      expect(button, findsOneWidget, reason: message);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);
    }

    Future<void> lifecycle(AppLifecycleState state) =>
        messenger.handlePlatformMessage(
          SystemChannels.lifecycle.name,
          SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
          (_) {},
        );

    final staleRun = {
      PrayerRefreshService.lastHeadlessRunKey: DateTime.now()
          .subtract(const Duration(hours: 50))
          .millisecondsSinceEpoch,
    };

    testWidgets(
      'tr: her sorun uyarı ve tek düzeltme butonuyla; butonlar '
      'doğru ekranı açar; Xiaomi rehberi uyarıyla testten önce',
      variant: android,
      (tester) async {
        device = {..._problemDevice};
        exactAllowed = false;
        notificationsEnabled = false;
        await pumpHealth(tester, onTime: const {}, prefs: staleRun);
        final tip = ' ${tr.healthAlarmStreamTip(tr.ezanAlarmStreamTitle)}';
        expect(find.text(tr.healthEzansNone), findsOneWidget);
        // Açık ezan yokken sıradaki ezan satırı yok
        expect(find.text(tr.healthNextTitle), findsNothing);
        expect(find.text(tr.alarmHealthNotificationsOff), findsOneWidget);
        expect(find.text(tr.alarmHealthExactOff), findsOneWidget);
        expect(find.text(tr.healthVolumeSilent + tip), findsOneWidget);
        expect(find.text(tr.healthDndOn + tip), findsOneWidget);
        expect(find.text(tr.healthBatteryOptimized), findsOneWidget);
        expect(find.text(tr.healthBackgroundStale), findsOneWidget);
        // 6 uyarı satırı + rehberin başındaki uyarı; açık ezan yok: bilgi
        expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(7));
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        final guideTitle = find.text(
          tr.healthGuideTitle('Xiaomi / Redmi / POCO'),
        );
        expect(guideTitle, findsOneWidget);
        expect(find.text(tr.healthGuideStale), findsOneWidget);
        for (final step in NotificationHealth.guideSteps(
          PhoneVendor.xiaomi,
          tr,
        )) {
          expect(find.text(step), findsOneWidget);
        }
        expect(
          tester.getTopLeft(guideTitle).dy,
          lessThan(tester.getTopLeft(find.text(tr.healthTestTitle)).dy),
        );

        // "Adımları göster": rehbere kaydırır
        await tester.ensureVisible(find.text(tr.healthBackgroundTitle));
        await tester.pump();
        final before = tester.getTopLeft(guideTitle).dy;
        await tapAction(tester, tr.healthBackgroundStale);
        expect(tester.getTopLeft(guideTitle).dy, lessThan(before));
        expect(guideTitle.hitTestable(), findsOneWidget);

        await tapAction(tester, tr.healthBatteryOptimized);
        await tapAction(tester, tr.healthDndOn + tip);
        await tapAction(tester, tr.healthVolumeSilent + tip);
        expect(opened, ['battery', 'dnd', 'sound']);
        await tapAction(tester, tr.alarmHealthNotificationsOff);
        expect(notificationRequests, 1);
        await tapAction(tester, tr.alarmHealthExactOff);
        expect(exactRequests, 1);

        // "Alarmlar": ana sayfanın Alarmlar sekmesi istenir
        final requests = HomeView.alarmsTabRequests.value;
        await tapAction(tester, tr.healthEzansNone);
        expect(HomeView.alarmsTabRequests.value, requests + 1);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );

    testWidgets(
      'en: sorunsuz durum; "sessiz modda da çal" açıkken Rahatsız '
      'Etmeyin bilgi, ses alarm sesinden; Samsung rehberi testten sonra',
      variant: android,
      (tester) async {
        device = {
          ..._healthyDevice,
          'interruptionFilter': 2,
          'notificationVolume': 0,
          'ringerMode': 1,
          'alarmVolume': 7,
        };
        final en = lookupAppLocalizations(const Locale('en'));
        final now = DateTime.now();
        final tomorrow = PrayerTracker.addDays(now, 1);
        final ogle = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          13,
          5,
        );
        final ogleId = PrayerRefreshService.alarmId(tomorrow, 2);
        pending = [_pendingRequest(ogleId)];
        final lastRun = now.subtract(const Duration(hours: 2));
        await pumpHealth(
          tester,
          lang: 'en',
          alarmStream: true,
          prefs: {
            PrayerRefreshService.planMetaKey: jsonEncode({
              '$ogleId': _fingerprint(ogle),
            }),
            PrayerRefreshService.lastHeadlessRunKey:
                lastRun.millisecondsSinceEpoch,
          },
        );
        expect(
          find.text(en.healthEzansOn('${en.ogle}, ${en.aksam}')),
          findsOneWidget,
        );
        expect(
          find.text('${en.ogle} ${formatClockTime(ogle, 'en')} ${en.tomorrow}'),
          findsOneWidget,
        );
        expect(find.text(en.healthNotificationsOk), findsOneWidget);
        expect(find.text(en.healthExactOk), findsOneWidget);
        expect(find.text(en.healthVolumeAlarmOk), findsOneWidget);
        expect(
          find.text(en.healthDndAlarm(en.ezanAlarmStreamTitle)),
          findsOneWidget,
        );
        expect(find.text(en.healthBatteryOk), findsOneWidget);
        final time = formatClockTime(lastRun, 'en');
        expect(
          find.text(
            DateUtils.isSameDay(lastRun, now)
                ? en.healthBackgroundToday(time)
                : en.healthBackgroundYesterday(time),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
        final guideTitle = find.text(en.healthGuideTitle('Samsung'));
        expect(guideTitle, findsOneWidget);
        expect(find.text(en.healthGuideStale), findsNothing);
        expect(
          tester.getTopLeft(find.text(en.healthTestTitle)).dy,
          lessThan(tester.getTopLeft(guideTitle).dy),
        );

        // Sorunsuz bildirimlerde bile sistem bildirim ayarlarına geçilebilir
        await tapAction(tester, en.healthNotificationsOk);
        // Rehber: uygulama ayarları ve dış tarayıcıda dontkillmyapp.com
        final guideSettings = find.descendant(
          of: find
              .ancestor(of: guideTitle, matching: find.byType(Column))
              .first,
          matching: find.widgetWithText(TextButton, en.healthOpenSettings),
        );
        await tester.ensureVisible(guideSettings);
        await tester.pump();
        await tester.tap(guideSettings);
        await settle(tester);
        expect(opened, ['notifications', 'app']);
        await tester.ensureVisible(find.text('dontkillmyapp.com'));
        await tester.pump();
        await tester.tap(find.text('dontkillmyapp.com'));
        await settle(tester);
        expect(launches.single.arguments['url'], NotificationHealth.guideUrl);
        expect(launches.single.arguments['useWebView'], isFalse);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );

    testWidgets(
      'test ezanı: 1 dk sonra ID 1999 kurulur ve SnackBar; '
      'kurulamazsa hata mesajı',
      variant: android,
      (tester) async {
        await pumpHealth(
          tester,
          onTime: const {'Akşam': true},
          sounds: const {'Akşam': 'ezan4'},
        );
        final button = find.text(tr.healthTestButton);
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await settle(tester);
        final call = notifCalls.lastWhere((c) => c.method == 'zonedSchedule');
        expect(call.arguments['id'], PrayerRefreshService.testEzanId);
        expect(
          call.arguments['platformSpecifics']['channelId'],
          'channel_ezan4',
        );
        expect(
          call.arguments['platformSpecifics']['scheduleMode'],
          'alarmClock',
        );
        expect(find.text(tr.healthTestScheduled), findsOneWidget);

        // SnackBar kapanınca (butonun üstünde yüzer) yeniden denenir
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);
        failSchedule = true;
        await tester.tap(button);
        await settle(tester);
        expect(find.text(tr.shareFailed), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Crashlytics bildirimi arka planda (testte Firebase yok: 5 sn zaman aşımı)
        await tester.pump(const Duration(seconds: 6));
        await finish(tester);
      },
    );

    testWidgets('ayarlardan dönünce yeniden okunur', variant: android, (
      tester,
    ) async {
      device = {..._healthyDevice, 'batteryOptimized': true};
      await pumpHealth(tester);
      expect(find.text(tr.healthBatteryOptimized), findsOneWidget);

      // Kullanıcı pil ayarını değiştirip döndü
      device = {..._healthyDevice};
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        await lifecycle(state);
      }
      await settle(tester);
      expect(find.text(tr.healthBatteryOptimized), findsNothing);
      expect(find.text(tr.healthBatteryOk), findsOneWidget);
      await finish(tester);
    });

    testWidgets(
      'cihaz kanalı yoksa cihaz satırları gizli, genel rehber; '
      'Android 11 ve altında alarm izni satırı yok',
      variant: android,
      (tester) async {
        device = null;
        await pumpHealth(tester);
        for (final title in [
          tr.healthBatteryTitle,
          tr.healthDndTitle,
          tr.healthVolumeTitle,
        ]) {
          expect(find.text(title), findsNothing);
        }
        expect(find.text(tr.healthGuideTitleGeneric), findsOneWidget);
        expect(find.text(tr.healthNotificationsTitle), findsOneWidget);
        expect(find.text(tr.healthExactTitle), findsOneWidget);
        // Sürüm kaydı 3 gündür var, görev hiç çalışmadı
        expect(find.text(tr.healthBackgroundStale), findsOneWidget);
        expect(tester.takeException(), isNull);
        await finish(tester);

        device = {..._healthyDevice, 'sdkInt': 30};
        await pumpHealth(tester);
        expect(find.text(tr.healthExactTitle), findsNothing);
        expect(find.text(tr.healthBatteryTitle), findsOneWidget);
        await finish(tester);
      },
    );

    testWidgets(
      'açık ezan varken kurulu ezan yoksa uyarı, "Yeniden kur" '
      'alarmları kurar; bekleyenler okunamazsa satır yok',
      variant: android,
      (tester) async {
        final vm = await pumpHealth(tester, onTime: const {'Öğle': true});
        expect(find.text(tr.healthNextNone), findsOneWidget);
        await tapAction(tester, tr.healthNextNone);
        expect(vm.reschedules, 1);
        await finish(tester);

        failPending = true;
        await pumpHealth(tester, onTime: const {'Öğle': true});
        expect(find.text(tr.healthNextTitle), findsNothing);
        await finish(tester);
      },
    );

    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      testWidgets(
        '$lang: 320 dp, %130 yazı, tüm uyarılar: taşma yok',
        variant: android,
        (tester) async {
          device = {
            ..._problemDevice,
            'manufacturer': 'HUAWEI',
            'brand': 'HUAWEI',
          };
          exactAllowed = false;
          notificationsEnabled = false;
          await pumpHealth(
            tester,
            lang: lang,
            width: 320,
            height: 640,
            textScale: 1.3,
            onTime: const {},
            prefs: staleRun,
          );
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -10000),
          );
          await settle(tester);
          // En altta test ezanı butonu
          expect(
            find.byIcon(Icons.notifications_active_outlined).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await finish(tester);
        },
      );
    }
  });
}
