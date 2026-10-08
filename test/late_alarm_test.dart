import 'package:ezan_saati/data/models/prayer_times_model.dart';
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

// Tam zamanlı izin yokken (Android 12) gecikmeli kurulan ezan vaktinden sonra da bir
// süre bekler (çalmamıştır). Bu sırada yapılan yeniden kurulum onu iptal etmemeli,
// başka bir alarmla üzerine yazmamalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  // Eklentinin bekleyen listesi: ID → (yük, zaman); çalmayan alarm listede kalır
  late Map<int, ({String payload, String time})> pending;
  late List<MethodCall> calls;
  late bool canScheduleExact;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    pending = {};
    calls = [];
    canScheduleExact = false;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return canScheduleExact;
        case 'zonedSchedule':
          pending[call.arguments['id'] as int] = (
            payload: call.arguments['payload'] as String? ?? '',
            time: call.arguments['scheduledDateTime'] as String,
          );
          return null;
        case 'cancel':
          pending.remove(call.arguments['id']);
          return null;
        case 'pendingNotificationRequests':
          return [
            for (final e in pending.entries)
              {
                'id': e.key,
                'title': '',
                'body': '',
                'payload': e.value.payload,
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

  final tr = lookupAppLocalizations(const Locale('tr'));
  // Gerçek saatten bağımsız olsun diye ileri bir gün (kurulum geçmiş zamanı atlar)
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day + 30);
  final allOn = {for (final k in PrayerRefreshService.vakitKeys) k: true};

  PrayerTimesModel timesOf(DateTime date) =>
      PrayerTimeService().calculate(41.0, 29.0, date: date);

  DateTime at(DateTime date, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
  }

  // Kurulumu verilen anda çalıştırır; o çalışmanın eklenti çağrılarını döner
  Future<List<MethodCall>> runAt(
    DateTime clock, {
    Map<String, bool>? onTime,
    Map<String, bool> reminders = const {},
    PrayerTimesModel? todayTimes,
  }) async {
    calls.clear();
    final notifications = NotificationService();
    await notifications.init();
    await PrayerRefreshService(
      notifications,
      clock: () => clock,
    ).rescheduleAlarms(
      todayTimes: todayTimes ?? timesOf(clock),
      loc: tr,
      onTimeAlarms: onTime ?? allOn,
      reminderAlarms: reminders,
      selectedSounds: const {},
      selectedReminderSounds: const {},
      silentModeSettings: const {},
    );
    return List.of(calls);
  }

  // Yükü verilen vakte ait bekleyen ezanın ID'si (yoksa null)
  int? pendingIdOf(DateTime date, String key) {
    final payload = PrayerTracker.payload(date, key);
    for (final e in pending.entries) {
      if (e.value.payload == payload) return e.key;
    }
    return null;
  }

  Set<int> touched(List<MethodCall> runCalls) => {
    for (final c in runCalls)
      if (c.method == 'cancel' || c.method == 'zonedSchedule')
        c.arguments['id'] as int,
  };

  void expectUntouched(
    List<MethodCall> runCalls,
    DateTime date,
    String key,
    int idBefore,
  ) {
    expect(pendingIdOf(date, key), idBefore, reason: '$key bekliyor olmalı');
    expect(touched(runCalls), isNot(contains(idBefore)));
  }

  group('Geç kalan ezan yeniden kurulumda korunur', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'language_code': 'tr',
      });
    });

    test('aynı gün: vakitten 5 dk sonra kurulum, bekleyen öğle ezanına '
        'dokunmaz', () async {
      final ogle = at(day, timesOf(day).ogle!);
      await runAt(DateTime(day.year, day.month, day.day, 9));
      final id = pendingIdOf(day, 'Öğle');
      expect(id, isNotNull);

      final second = await runAt(ogle.add(const Duration(minutes: 5)));
      expectUntouched(second, day, 'Öğle', id!);
      // Yarının öğlesi yine kurulur
      expect(pendingIdOf(PrayerTracker.addDays(day, 1), 'Öğle'), isNotNull);
    });

    test('günün ilk kurulumu (dünkü planın imsakı gecikmiş): üzerine '
        'yarının imsakı yazılmaz', () async {
      final yesterday = PrayerTracker.addDays(day, -1);
      final imsak = at(day, timesOf(day).imsak!);
      await runAt(DateTime(yesterday.year, yesterday.month, yesterday.day, 21));
      final id = pendingIdOf(day, 'İmsak');
      expect(id, isNotNull);

      final second = await runAt(imsak.add(const Duration(minutes: 10)));
      expectUntouched(second, day, 'İmsak', id!);
      expect(pendingIdOf(PrayerTracker.addDays(day, 1), 'İmsak'), isNotNull);
    });

    test('izin az önce verildi (artık tam zamanlı): gecikmeli kurulmuş ezan '
        'yine korunur', () async {
      final ogle = at(day, timesOf(day).ogle!);
      await runAt(DateTime(day.year, day.month, day.day, 9));
      final id = pendingIdOf(day, 'Öğle')!;

      canScheduleExact = true;
      final second = await runAt(ogle.add(const Duration(minutes: 20)));
      expectUntouched(second, day, 'Öğle', id);
    });

    test('vakit kapatıldıysa geç kalan ezan iptal edilir', () async {
      final ogle = at(day, timesOf(day).ogle!);
      await runAt(DateTime(day.year, day.month, day.day, 9));
      expect(pendingIdOf(day, 'Öğle'), isNotNull);

      await runAt(
        ogle.add(const Duration(minutes: 5)),
        onTime: {...allOn, 'Öğle': false},
      );
      expect(pendingIdOf(day, 'Öğle'), isNull);
    });

    test('pencereden (90 dk) eskiyse iptal edilir', () async {
      final ogle = at(day, timesOf(day).ogle!);
      await runAt(DateTime(day.year, day.month, day.day, 9));
      expect(pendingIdOf(day, 'Öğle'), isNotNull);

      await runAt(ogle.add(const Duration(minutes: 91)));
      expect(pendingIdOf(day, 'Öğle'), isNull);
    });

    test('aynı ID\'de başka günün ezanı bekliyorsa (eski numaralama) korunmaz, '
        'o gün çift çalmaz', () async {
      final ogle = at(day, timesOf(day).ogle!);
      final lateId = PrayerRefreshService.alarmId(day, 2);
      final tomorrow = PrayerTracker.addDays(day, 1);
      pending[lateId] = (
        payload: PrayerTracker.payload(tomorrow, 'Öğle'),
        time: at(tomorrow, timesOf(tomorrow).ogle!).toIso8601String(),
      );
      await runAt(ogle.add(const Duration(minutes: 5)));
      expect(pending.containsKey(lateId), isFalse);
      expect(pendingIdOf(tomorrow, 'Öğle'), isNot(lateId));
    });

    test('geç kalan "vakit yaklaşıyor" hatırlatması korunmaz', () async {
      final ogle = at(day, timesOf(day).ogle!);
      await runAt(
        DateTime(day.year, day.month, day.day, 9),
        reminders: const {'Öğle': true},
      );
      final reminderTime = ogle
          .subtract(const Duration(minutes: 15))
          .toIso8601String()
          .split('.')
          .first;
      int? reminderId() {
        for (final e in pending.entries) {
          if (e.value.time.startsWith(reminderTime)) return e.key;
        }
        return null;
      }

      expect(reminderId(), isNotNull);
      await runAt(
        ogle.add(const Duration(minutes: 5)),
        reminders: const {'Öğle': true},
      );
      expect(reminderId(), isNull);
      expect(pendingIdOf(day, 'Öğle'), isNotNull);
    });
  });

  test('koordinatsız tek gün: geçmiş vakit yarına kayarken geç kalan ezanın '
      'üzerine yazılmaz', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'tr'});
    final times = PrayerTimesModel(
      imsak: '05:00',
      gunes: '06:30',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: '19:00',
      yatsi: '20:30',
    );
    await runAt(
      DateTime(day.year, day.month, day.day, 12, 50),
      todayTimes: times,
    );
    final id = pendingIdOf(day, 'Öğle');
    expect(id, isNotNull);

    final second = await runAt(
      DateTime(day.year, day.month, day.day, 13, 5),
      todayTimes: times,
    );
    expectUntouched(second, day, 'Öğle', id!);
    // Yarının öğlesi başka ID ile kurulu
    final tomorrowId = pendingIdOf(PrayerTracker.addDays(day, 1), 'Öğle');
    expect(tomorrowId, isNotNull);
    expect(tomorrowId, isNot(id));
  });
}
