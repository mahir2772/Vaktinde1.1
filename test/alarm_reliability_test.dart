import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/error_reporter.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ezan güvenilirliği: tam zamanlı alarm izni yoksa gecikmeli kip, hataların
// yutulmaması/bildirilmesi, "sessiz modda da çal" kanalları
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  late List<MethodCall> notifCalls;
  late List<int> pending;
  // Eklentinin yanıtı: bool, null ya da fırlatılacak hata
  late Object? canScheduleExact;
  late Object? notificationsOn;
  late Set<int> failIds;
  // İzin yokken eklentinin tam zamanlı kip (alarmClock, exactAllowWhileIdle) reddi
  late bool rejectExact;
  late bool failPending;

  Object? answer(Object? value) {
    if (value is Exception) throw value;
    return value;
  }

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    notifCalls = [];
    pending = [];
    canScheduleExact = true;
    notificationsOn = null;
    failIds = {};
    rejectExact = false;
    failPending = false;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async => true,
    );
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      notifCalls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return answer(canScheduleExact);
        case 'areNotificationsEnabled':
          return answer(notificationsOn);
        case 'zonedSchedule':
          final id = call.arguments['id'] as int;
          final mode = call.arguments['platformSpecifics']['scheduleMode'];
          if (failIds.contains(id)) {
            throw PlatformException(code: 'error', message: 'kurulamadı');
          }
          if (rejectExact &&
              (mode == 'alarmClock' || mode == 'exactAllowWhileIdle')) {
            throw PlatformException(
              code: 'exact_alarms_not_permitted',
              message: 'Exact alarms are not permitted',
            );
          }
          pending.add(id);
          return null;
        case 'cancel':
          pending.remove(call.arguments['id']);
          return null;
        case 'pendingNotificationRequests':
          if (failPending) throw PlatformException(code: 'error');
          return [
            for (final id in pending)
              {'id': id, 'title': '', 'body': '', 'payload': ''},
          ];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(notifChannel, null);
  });

  final tr = lookupAppLocalizations(const Locale('tr'));
  // Görev ve beklenen değerler aynı andan (gece yarısında gün ayrışmasın)
  final clockNow = DateTime.now();
  DateTime clock() => clockNow;
  final today = clockNow.toIso8601String().split('T')[0];
  const idCount = PrayerRefreshService.alarmIdCount;
  // [day] gün sonraki vaktin ID'si (vakit sırası: Öğle 2, Akşam 4, Yatsı 5)
  int idOf(int day, int vakit, {bool reminder = false}) =>
      PrayerRefreshService.alarmId(
        PrayerTracker.addDays(clockNow, day),
        vakit,
        reminder: reminder,
      );

  Iterable<MethodCall> scheduleCalls() =>
      notifCalls.where((c) => c.method == 'zonedSchedule');
  String modeOf(MethodCall c) =>
      c.arguments['platformSpecifics']['scheduleMode'] as String;
  // Kurulan bildirimlerin kipleri (sadece [where] ID'leri)
  Set<String> modes([bool Function(int id)? where]) => {
    for (final c in scheduleCalls())
      if (where == null || where(c.arguments['id'] as int)) modeOf(c),
  };
  bool isEzan(int id) => id < idCount && id.isEven;
  bool isPreReminder(int id) => id < idCount && id.isOdd;
  bool isDaily(int id) => PrayerRefreshService.dailyContentIds.contains(id);
  Map<String, Object> basePrefs([Map<String, Object> extra = const {}]) => {
    'saved_lat': 41.0,
    'saved_lng': 29.0,
    'saved_city': 'İstanbul',
    'language_code': 'tr',
    'onTime_Öğle': true,
    'reminder_Akşam': true,
    'end_reminder_enabled': true,
    ...extra,
  };

  group('Zamanlama kipi', () {
    test(
      'ezan: izin var/yok/bilinmiyor → alarmClock / gecikmeli / alarmClock',
      () {
        AndroidScheduleMode ezan(bool? exact) =>
            NotificationService.scheduleModeFor(
              NotificationKind.prayer,
              exactAllowed: exact,
              notificationsEnabled: null,
            );
        expect(ezan(true), AndroidScheduleMode.alarmClock);
        expect(ezan(false), AndroidScheduleMode.inexactAllowWhileIdle);
        expect(ezan(null), AndroidScheduleMode.alarmClock);
      },
    );

    for (final allowed in [true, false]) {
      // İzin varken alarmClock (alarm simgesi) sadece ezanda; günlük içerik hep gecikmeli
      test('arka plan görevi: izin ${allowed ? 'var' : 'yok'} → kipler (ezan, '
          'hatırlatma, vakit çıkış, günlük içerik)', () async {
        SharedPreferences.setMockInitialValues(basePrefs());
        canScheduleExact = allowed;
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);

        final ids = scheduleCalls().map((c) => c.arguments['id'] as int);
        expect(ids.where(isEzan), isNotEmpty);
        expect(ids.where(isPreReminder), isNotEmpty);
        expect(ids.where(PrayerTracker.isEndReminderId), isNotEmpty);
        expect(ids.where(isDaily), isNotEmpty); // hadis (yerel yedek)
        expect(modes(isEzan), {
          allowed ? 'alarmClock' : 'inexactAllowWhileIdle',
        });
        expect(modes(isPreReminder), {
          allowed ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle',
        });
        expect(modes(PrayerTracker.isEndReminderId), {
          allowed ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle',
        });
        expect(modes(isDaily), {'inexactAllowWhileIdle'});
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(NotificationService.exactAlarmsAllowedKey),
          allowed,
        );
        expect(prefs.getString('alarms_scheduled_date'), today);
      });
    }

    test('uygulama içi kurulum da izni kurulumdan önce okur', () async {
      SharedPreferences.setMockInitialValues(basePrefs());
      canScheduleExact = false;
      final notifications = NotificationService();
      await notifications.init();
      final times = await PrayerTimeService().forDate(clockNow);
      await PrayerRefreshService(notifications, clock: clock).rescheduleAlarms(
        todayTimes: times!,
        loc: tr,
        onTimeAlarms: {for (final k in PrayerRefreshService.vakitKeys) k: true},
        reminderAlarms: const {},
        selectedSounds: const {},
        selectedReminderSounds: const {},
        silentModeSettings: const {},
      );
      final checkIndex = notifCalls.indexWhere(
        (c) => c.method == 'canScheduleExactNotifications',
      );
      final firstSchedule = notifCalls.indexWhere(
        (c) => c.method == 'zonedSchedule',
      );
      expect(checkIndex, isNonNegative);
      expect(firstSchedule, greaterThan(checkIndex));
      expect(modes(), {'inexactAllowWhileIdle'});
    });

    for (final unknown in <Object?>[
      null,
      PlatformException(code: 'error'),
      MissingPluginException(),
    ]) {
      test('izin okunamazsa (${unknown.runtimeType}) önce tam zamanlı, kayıt '
          'değişmez', () async {
        SharedPreferences.setMockInitialValues(basePrefs());
        canScheduleExact = unknown;
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
        expect(scheduleCalls(), isNotEmpty);
        expect(modes(isEzan), {'alarmClock'});
        expect(
          modes((id) => isPreReminder(id) || PrayerTracker.isEndReminderId(id)),
          {'exactAllowWhileIdle'},
        );
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(NotificationService.exactAlarmsAllowedKey),
          isNull,
        );
      });
    }

    // Eklenti alarmClock'u da exactAllowWhileIdle'ı da izinsiz reddeder
    for (final (name, extra) in <(String, Map<String, Object>)>[
      ('ezan (alarmClock)', const {}),
      (
        'sadece hatırlatma (exactAllowWhileIdle)',
        const {'onTime_Öğle': false, 'end_reminder_enabled': false},
      ),
    ]) {
      test('tam zamanlı kip reddedilirse aynı bildirim gecikmeli kurulur, '
          'sonrakiler doğrudan gecikmeli: $name', () async {
        SharedPreferences.setMockInitialValues(basePrefs(extra));
        canScheduleExact = null; // sorgu sonuç vermedi
        rejectExact = true; // ama izin yok
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);

        final calls = scheduleCalls().toList();
        final rejected = calls
            .where((c) => modeOf(c) != 'inexactAllowWhileIdle')
            .toList();
        expect(rejected, hasLength(1));
        if (extra.isNotEmpty) {
          expect(isPreReminder(rejected.single.arguments['id'] as int), isTrue);
          expect(modeOf(rejected.single), 'exactAllowWhileIdle');
        }
        // Reddedilen bildirim hemen aynı ID ile gecikmeli kuruldu
        final retry = calls[calls.indexOf(rejected.single) + 1];
        expect(retry.arguments['id'], rejected.single.arguments['id']);
        expect(modeOf(retry), 'inexactAllowWhileIdle');
        expect(pending, contains(retry.arguments['id']));
        // Ezan / hatırlatma ve (açıksa) vakit çıkış hatırlatmaları kuruldu
        expect(pending.where((id) => id < idCount), isNotEmpty);
        if (extra.isEmpty) {
          expect(pending.where(PrayerTracker.isEndReminderId), isNotEmpty);
        }
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(NotificationService.exactAlarmsAllowedKey),
          isFalse,
        );
        expect(prefs.getString('alarms_scheduled_date'), today);
      });
    }
  });

  group('Arka plan: izin değişimi', () {
    // Bugün kurulmuş, kip geçişi bitmiş: yeniden kurulumu sadece izin değişimi tetikler
    Map<String, Object> scheduledToday(Map<String, Object> extra) => basePrefs({
      'alarms_scheduled_date': today,
      PrayerRefreshService.scheduleModeMigratedKey: true,
      ...extra,
    });

    test(
      'izin kapatılınca aynı gün de gecikmeli kiple yeniden kurulur',
      () async {
        SharedPreferences.setMockInitialValues(
          scheduledToday({NotificationService.exactAlarmsAllowedKey: true}),
        );
        canScheduleExact = false;
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
        expect(scheduleCalls(), isNotEmpty);
        expect(modes(), {'inexactAllowWhileIdle'});
      },
    );

    test('izin açılınca aynı gün de tam vaktine kurulur', () async {
      SharedPreferences.setMockInitialValues(
        scheduledToday({NotificationService.exactAlarmsAllowedKey: false}),
      );
      canScheduleExact = true;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(modes(isEzan), {'alarmClock'});
      expect(modes(isPreReminder), {'exactAllowWhileIdle'});
    });

    test('bildirimler kapatılınca aynı gün de alarm simgesiz kurulur; '
        'açılınca ezan yine alarmClock', () async {
      SharedPreferences.setMockInitialValues(
        scheduledToday({
          NotificationService.exactAlarmsAllowedKey: true,
          NotificationService.notificationsEnabledKey: true,
        }),
      );
      pending = [1000, 1900]; // günlük içerik zaten kurulu
      notificationsOn = false;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(
        scheduleCalls().where((c) => isEzan(c.arguments['id'])),
        isNotEmpty,
      );
      expect(modes(), {'exactAllowWhileIdle'});
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(NotificationService.notificationsEnabledKey),
        isFalse,
      );

      notifCalls.clear();
      notificationsOn = true;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(modes(isEzan), {'alarmClock'});
      expect(modes(isPreReminder), {'exactAllowWhileIdle'});
    });

    test('izin değişmediyse aynı gün alarmlara dokunulmaz', () async {
      SharedPreferences.setMockInitialValues(
        scheduledToday({
          NotificationService.exactAlarmsAllowedKey: true,
          NotificationService.notificationsEnabledKey: true,
        }),
      );
      notificationsOn = true;
      // Günlük içerik zaten kurulu: sadece alarm kurulumu ölçülür
      pending = [1000, 1900];
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(scheduleCalls(), isEmpty);
      expect(notifCalls.where((c) => c.method == 'cancel'), isEmpty);
    });
  });

  group('Kurulum hataları yutulmaz', () {
    test(
      'bir alarm kurulamazsa diğerleri yine kurulur, gün kaydedilir',
      () async {
        SharedPreferences.setMockInitialValues(
          basePrefs({'end_reminder_enabled': false, 'reminder_Akşam': false}),
        );
        failIds = {idOf(1, 2), idOf(2, 2)}; // yarın ve sonraki gün öğle
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
        expect(pending, containsAll([idOf(3, 2), idOf(4, 2)]));
        expect(pending, isNot(contains(idOf(1, 2))));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('alarms_scheduled_date'), today);
      },
    );

    test(
      'bekleyenler okunamasa da kurulur; gün kaydedilmez (yeniden denenir)',
      () async {
        SharedPreferences.setMockInitialValues(basePrefs());
        failPending = true;
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
        expect(pending, containsAll([for (var d = 1; d <= 4; d++) idOf(d, 2)]));
        expect(pending.where(PrayerTracker.isEndReminderId), isNotEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('alarms_scheduled_date'), isNull);
      },
    );

    test(
      'Firebase yokken (arka plan isolate) bildirim hata fırlatmaz',
      () async {
        await expectLater(
          reportNonFatal(
            Exception('deneme'),
            StackTrace.current,
            reason: 'test',
          ),
          completes,
        );
      },
    );
  });

  group('Gecikmeli kipte göreli metin yok', () {
    // Gecikmeli alarm Android 12'de bir saate kadar geç gelebilir: "X dakika
    // kaldı" vakit geçince okunabilir. Hatırlatmalar saatli, nötr başlıkla gelir.
    Map<String, Object> reminderPrefs() => basePrefs({
      for (final k in PrayerRefreshService.vakitKeys) 'reminder_$k': true,
      'end_reminder_minutes': 15,
    });
    bool isReminder(int id) =>
        (id < idCount && id.isOdd) || PrayerTracker.isEndReminderId(id);

    test('izin yok: hatırlatma ve vakit çıkış metinleri saatli', () async {
      SharedPreferences.setMockInitialValues(reminderPrefs());
      canScheduleExact = false;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      final reminders = scheduleCalls()
          .where((c) => isReminder(c.arguments['id'] as int))
          .toList();
      final ids = reminders.map((c) => c.arguments['id'] as int);
      expect(ids.where((id) => id < idCount), isNotEmpty);
      expect(ids.where(PrayerTracker.isEndReminderId), isNotEmpty);
      for (final c in reminders) {
        final title = c.arguments['title'] as String;
        final body = c.arguments['body'] as String;
        expect(title, isNot(tr.notifTitleUpcoming), reason: body);
        expect(title, isNot(tr.endReminderNotifTitle), reason: body);
        expect(body, isNot(contains('kaldı')), reason: body);
        expect(body, matches(RegExp(r'\d\d:\d\d')), reason: body);
      }
    });

    test('izin var: göreli metinler aynen kalır', () async {
      SharedPreferences.setMockInitialValues(reminderPrefs());
      canScheduleExact = true;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      final reminders = scheduleCalls()
          .where((c) => isReminder(c.arguments['id'] as int))
          .toList();
      expect(reminders, isNotEmpty);
      for (final c in reminders) {
        expect(
          c.arguments['title'],
          anyOf(tr.notifTitleUpcoming, tr.endReminderNotifTitle),
        );
        expect(c.arguments['body'] as String, contains('kaldı'));
      }
    });
  });

  group('Sessiz modda da çal', () {
    test('kanal ve ses türü', () {
      final silent = NotificationService.prayerChannel(null, alarmStream: true);
      expect(silent.id, 'channel_silent_prayer');
      expect(silent.usage, AudioAttributesUsage.notification);
      final normal = NotificationService.prayerChannel('ezan1');
      expect(normal.id, 'channel_ezan1');
      expect(normal.usage, AudioAttributesUsage.notification);
      final alarm = NotificationService.prayerChannel(
        'ezan1',
        alarmStream: true,
      );
      expect(alarm.id, 'alarm_channel_ezan1');
      expect(alarm.usage, AudioAttributesUsage.alarm);
    });

    List<PlannedAlarm> plan({bool? alarmStream}) {
      final day = PrayerTimesModel(
        imsak: '05:00',
        gunes: '06:30',
        ogle: '13:00',
        ikindi: '16:30',
        aksam: '19:00',
        yatsi: '20:30',
      );
      final args = (
        days: [day, day],
        now: DateTime(2026, 1, 10, 0, 1),
        onTime: {for (final k in PrayerRefreshService.vakitKeys) k: true},
        reminder: {for (final k in PrayerRefreshService.vakitKeys) k: true},
        sounds: {'Öğle': 'ezan2', 'İkindi': 'bildirim2'},
        silent: {'Yatsı': true},
      );
      return alarmStream == null
          ? PrayerRefreshService.buildAlarmPlan(
              days: args.days,
              now: args.now,
              loc: tr,
              onTimeAlarms: args.onTime,
              reminderAlarms: args.reminder,
              selectedSounds: args.sounds,
              selectedReminderSounds: const {},
              silentModeSettings: args.silent,
            )
          : PrayerRefreshService.buildAlarmPlan(
              days: args.days,
              now: args.now,
              loc: tr,
              onTimeAlarms: args.onTime,
              reminderAlarms: args.reminder,
              selectedSounds: args.sounds,
              selectedReminderSounds: const {},
              silentModeSettings: args.silent,
              alarmStream: alarmStream,
            );
    }

    String describe(PlannedAlarm a) =>
        '${a.id}|${a.title}|${a.body}|${a.time}|${a.sound}|${a.channelName}|'
        '${a.payload}|${a.actionLabel}|${a.alarmStream}';

    test('kapalıyken plan eskisiyle aynı', () {
      final before = plan().map(describe).toList();
      expect(before, hasLength(24));
      expect(plan(alarmStream: false).map(describe), before);
      expect(plan().where((a) => a.alarmStream), isEmpty);
    });

    test('açıkken sadece sesli ezan alarm kanalına geçer', () {
      final off = plan(alarmStream: false);
      final on = plan(alarmStream: true);
      expect(on.map((a) => a.id), off.map((a) => a.id));
      for (var i = 0; i < on.length; i++) {
        final a = on[i];
        final isEzan = a.id % 2 == 0;
        final hasSound = a.sound != null;
        expect(a.alarmStream, isEzan && hasSound, reason: describe(a));
        if (a.alarmStream) {
          expect(a.channelName, tr.channelAlarmSound(a.sound!));
          // Metin, ses, zaman ve "Kıldım" aynı
          expect(
            describe(a).replaceAll(a.channelName, ''),
            describe(
              off[i],
            ).replaceAll(off[i].channelName, '').replaceAll('|false', '|true'),
          );
        } else {
          expect(describe(a), describe(off[i]));
        }
      }
      // Sessiz (yazılı) ezan ve hatırlatmalar değişmez
      expect(on.where((a) => a.sound == null), isNotEmpty);
      expect(on.where((a) => a.id.isOdd && !a.alarmStream), hasLength(12));
    });

    Map<String, Object?> specifics(int id) => Map<String, Object?>.from(
      scheduleCalls()
          .lastWhere((c) => c.arguments['id'] == id)
          .arguments['platformSpecifics'],
    );

    for (final on in [false, true]) {
      test('arka plan kurulumu: ayar ${on ? 'açık' : 'kapalı'}', () async {
        SharedPreferences.setMockInitialValues(
          basePrefs({
            'sound_Öğle': 'ezan2',
            'onTime_Yatsı': true,
            'silent_Yatsı': true,
            'end_reminder_enabled': false,
            'ezan_alarm_stream': on,
          }),
        );
        expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
        // Öğle ezanı (yarın)
        final ogle = specifics(idOf(1, 2));
        expect(ogle['channelId'], on ? 'alarm_channel_ezan2' : 'channel_ezan2');
        expect(
          ogle['channelName'],
          on ? tr.channelAlarmSound('ezan2') : tr.channelSoundPrefix('ezan2'),
        );
        expect(
          ogle['audioAttributesUsage'],
          on
              ? AudioAttributesUsage.alarm.value
              : AudioAttributesUsage.notification.value,
        );
        expect(ogle['sound'], 'ezan2');
        // Akşam hatırlatması (yarın) — bildirim akışında kalır
        final reminder = specifics(idOf(1, 4, reminder: true));
        expect(reminder['channelId'], 'channel_bildirim1');
        expect(
          reminder['audioAttributesUsage'],
          AudioAttributesUsage.notification.value,
        );
        // Sessiz (yazılı) yatsı ezanı (yarın)
        final yatsi = specifics(idOf(1, 5));
        expect(yatsi['channelId'], 'channel_silent_prayer');
        expect(yatsi['playSound'], isFalse);
      });
    }
  });
}
