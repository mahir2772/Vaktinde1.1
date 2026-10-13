import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesli ezandaki "Durdur": sadece sesli ezanda; sistem bildirimi hemen kapatır,
// arka plan isolate'i aynı başlık/metin/yükle sessiz kopyasını gösterir
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final tr = lookupAppLocalizations(const Locale('tr'));
  final de = lookupAppLocalizations(const Locale('de'));
  late List<MethodCall> calls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Map<Object?, Object?> specifics(MethodCall call) =>
      call.arguments['platformSpecifics'] as Map<Object?, Object?>;
  List<Map<Object?, Object?>> actionsOf(MethodCall call) => [
    for (final a in (specifics(call)['actions'] as List?) ?? const [])
      a as Map<Object?, Object?>,
  ];

  group('Plan', () {
    final day = PrayerTimesModel(
      imsak: '05:00',
      gunes: '06:30',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: '19:00',
      yatsi: '20:30',
    );
    Map<String, bool> all(bool value) => {
      for (final key in PrayerRefreshService.vakitKeys) key: value,
    };
    List<PlannedAlarm> plan({bool silent = false, bool alarmStream = false}) =>
        PrayerRefreshService.buildAlarmPlan(
          days: [day, day],
          now: DateTime(2026, 3, 10, 0, 1),
          loc: tr,
          onTimeAlarms: all(true),
          reminderAlarms: all(true),
          selectedSounds: const {'Öğle': 'ezan3'},
          selectedReminderSounds: const {},
          silentModeSettings: silent ? all(true) : {'Akşam': true},
          alarmStream: alarmStream,
        );

    test('sesli ezanda (Güneş dahil, alarm akışında da) "Durdur"; yazılı '
        'ezanda ve hatırlatmada yok', () {
      for (final alarmStream in [false, true]) {
        final alarms = plan(alarmStream: alarmStream);
        final ezans = alarms.where((a) => a.kind == NotificationKind.prayer);
        expect(ezans.length, 12);
        for (final a in ezans) {
          // Akşam "sadece yazılı" (sessiz)
          expect(a.stopLabel, a.sound == null ? isNull : tr.notifStopAction);
          expect(a.sound == null, a.id % 12 == 8);
        }
        final reminders = alarms.where(
          (a) => a.kind == NotificationKind.reminder,
        );
        expect(reminders, isNotEmpty);
        expect(reminders.every((a) => a.stopLabel == null), isTrue);
      }
      expect(plan(silent: true).every((a) => a.stopLabel == null), isTrue);
    });

    test('"Durdur" ezan kaydını (alarmFingerprint) değiştirmez: geç ezan '
        'koruması ve kurulu plan etkilenmez', () {
      for (final a in plan().where((a) => a.stopLabel != null)) {
        final withoutStop = PlannedAlarm(
          id: a.id,
          kind: a.kind,
          title: a.title,
          body: a.body,
          time: a.time,
          sound: a.sound,
          channelName: a.channelName,
          payload: a.payload,
          actionLabel: a.actionLabel,
          alarmStream: a.alarmStream,
        );
        expect(
          PrayerRefreshService.alarmFingerprint(a),
          PrayerRefreshService.alarmFingerprint(withoutStop),
        );
      }
    });
  });

  group('Bildirim ve "Durdur" sonrası sessiz kopya', () {
    final day = DateTime.now().add(const Duration(days: 1));
    final payload = PrayerTracker.payload(day, 'Öğle');

    Future<MethodCall> schedule({
      String? sound = 'ezan3',
      String? stopLabel,
      String? actionLabel,
      String? payload,
    }) async {
      final service = NotificationService();
      await service.init();
      await service.schedulePrayerNotification(
        id: 14,
        title: 'Vakit girdi',
        body: 'Öğle "vakti" | girdi',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        soundName: sound,
        localizedChannelName: tr.channelSoundPrefix('ezan3'),
        localizedTicker: tr.tickerEzan,
        kind: NotificationKind.prayer,
        payload: payload,
        actionLabel: actionLabel,
        stopLabel: stopLabel,
      );
      return calls.lastWhere((c) => c.method == 'zonedSchedule');
    }

    NotificationResponse responseTo(
      Map<Object?, Object?> action,
      String? payload,
    ) => NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      id: 14,
      actionId: action['id'] as String,
      payload: payload ?? '',
    );

    test('"Kıldım" + "Durdur": Durdur bildirimi hemen kapatır (sistem), '
        'uygulamayı açmaz; verilmezse yok', () async {
      var call = await schedule(
        stopLabel: tr.notifStopAction,
        actionLabel: tr.trackerPrayedAction,
        payload: payload,
      );
      final actions = actionsOf(call);
      expect(actions.length, 2);
      expect(actions[0]['id'], PrayerTracker.actionId); // yeri değişmez
      expect(
        actions[1]['id'],
        startsWith('${NotificationService.stopActionId}|'),
      );
      expect(actions[1]['title'], tr.notifStopAction);
      expect(actions[1]['cancelNotification'], isTrue);
      expect(actions[1]['showsUserInterface'], isFalse);

      call = await schedule(
        actionLabel: tr.trackerPrayedAction,
        payload: payload,
      );
      expect(actionsOf(call).map((a) => a['id']), [PrayerTracker.actionId]);
    });

    test('aynı ID, başlık, metin ve yükle sessiz kanalda yeniden gösterilir; '
        '"Kıldım" kalır (güncel dilde), "Durdur" kalkar', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'de'});
      final stop = actionsOf(
        await schedule(
          stopLabel: tr.notifStopAction,
          actionLabel: tr.trackerPrayedAction,
          payload: payload,
        ),
      )[1];
      calls.clear();

      expect(
        await NotificationService.showSilentCopy(responseTo(stop, payload)),
        isTrue,
      );
      final show = calls.singleWhere((c) => c.method == 'show');
      expect(show.arguments['id'], 14);
      expect(show.arguments['title'], 'Vakit girdi');
      expect(show.arguments['body'], 'Öğle "vakti" | girdi');
      expect(show.arguments['payload'], payload);
      expect(specifics(show)['channelId'], 'channel_silent_prayer');
      expect(specifics(show)['channelName'], de.channelSilentPrayers);
      expect(specifics(show)['silent'], isTrue);
      expect(specifics(show)['playSound'], isFalse);
      final actions = actionsOf(show);
      expect(actions.map((a) => a['id']), [PrayerTracker.actionId]);
      expect(actions.single['title'], de.trackerPrayedAction);
      expect(actions.single['cancelNotification'], isTrue);

      // "Durdur" vakti işaretlemez
      expect(
        await PrayerTrackerService.handleNotificationAction(
          responseTo(stop, payload),
        ),
        isFalse,
      );
      expect(await PrayerTrackerService().loadLog(), isEmpty);
    });

    test(
      'yükü olmayan ezan (Güneş, test ezanı): sessiz kopyada buton yok',
      () async {
        SharedPreferences.setMockInitialValues({});
        final stop = actionsOf(
          await schedule(stopLabel: tr.notifStopAction),
        ).single;
        calls.clear();
        expect(
          await NotificationService.showSilentCopy(responseTo(stop, null)),
          isTrue,
        );
        final show = calls.singleWhere((c) => c.method == 'show');
        expect(show.arguments['title'], 'Vakit girdi');
        expect(specifics(show)['channelName'], tr.channelSilentPrayers);
        expect(specifics(show)['actions'], isNull);
      },
    );

    test('"Kıldım", bozuk ya da ID\'siz yanıt: kopya gösterilmez', () async {
      SharedPreferences.setMockInitialValues({});
      NotificationResponse response(int? id, String? actionId) =>
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: id,
            actionId: actionId,
            payload: payload,
          );
      for (final r in [
        response(14, PrayerTracker.actionId),
        response(14, null),
        response(14, '${NotificationService.stopActionId}|bozuk'),
        response(null, '${NotificationService.stopActionId}|["a","b"]'),
      ]) {
        expect(await NotificationService.showSilentCopy(r), isFalse);
      }
      expect(calls.where((c) => c.method == 'show'), isEmpty);
    });
  });
}
