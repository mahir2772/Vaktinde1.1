import 'package:ezan_saati/data/models/hadith_model.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Durum çubuğundaki alarm simgesi (alarmClock) sadece açık ezanda: kip kuralı,
// 1.1.0'ın alarmClock kayıtlarının bir kez yeni kiple yazılması (kip geçişi) ve
// "Günün ayeti ve hadisi" ayarı
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  // Eklentinin bekleyen listesi: ID → (başlık, metin, yük, kip)
  late Map<int, ({String title, String body, String payload, String mode})>
  pending;
  late List<MethodCall> calls;
  late bool canScheduleExact;
  late bool failPending;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    pending = {};
    calls = [];
    canScheduleExact = true;
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
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return canScheduleExact;
        case 'zonedSchedule':
          pending[call.arguments['id'] as int] = (
            title: call.arguments['title'] as String? ?? '',
            body: call.arguments['body'] as String? ?? '',
            payload: call.arguments['payload'] as String? ?? '',
            mode: call.arguments['platformSpecifics']['scheduleMode'] as String,
          );
          return null;
        case 'cancel':
          pending.remove(call.arguments['id']);
          return null;
        case 'pendingNotificationRequests':
          if (failPending) throw PlatformException(code: 'error');
          return [
            for (final e in pending.entries)
              {
                'id': e.key,
                'title': e.value.title,
                'body': e.value.body,
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
  const idCount = PrayerRefreshService.alarmIdCount;
  bool isEzan(int id) => id < idCount && id.isEven;
  Iterable<int> scheduledIds() => calls
      .where((c) => c.method == 'zonedSchedule')
      .map((c) => c.arguments['id'] as int);
  Iterable<int> cancelledIds() => calls
      .where((c) => c.method == 'cancel')
      .map((c) => c.arguments['id'] as int);
  // Alarm simgesini gösteren (alarmClock) bekleyen bildirimler
  Set<int> alarmClockIds() => {
    for (final e in pending.entries)
      if (e.value.mode == 'alarmClock') e.key,
  };

  group('Kip kuralı', () {
    AndroidScheduleMode mode(NotificationKind kind, bool? exact, bool? notif) =>
        NotificationService.scheduleModeFor(
          kind,
          exactAllowed: exact,
          notificationsEnabled: notif,
        );
    const alarmClock = AndroidScheduleMode.alarmClock;
    const exact = AndroidScheduleMode.exactAllowWhileIdle;
    const inexact = AndroidScheduleMode.inexactAllowWhileIdle;
    const unknownToo = <bool?>[true, false, null];

    test('ezan: izin varken (bilinmiyorsa önce denenir) alarmClock; '
        'bildirimler kapalıysa simgesiz, izin yoksa gecikmeli', () {
      for (final notif in [true, null]) {
        expect(mode(NotificationKind.prayer, true, notif), alarmClock);
        expect(mode(NotificationKind.prayer, null, notif), alarmClock);
      }
      expect(mode(NotificationKind.prayer, true, false), exact);
      expect(mode(NotificationKind.prayer, null, false), exact);
      for (final notif in unknownToo) {
        expect(mode(NotificationKind.prayer, false, notif), inexact);
      }
    });

    test('hatırlatma ve vakit çıkış: hiçbir durumda alarmClock değil', () {
      for (final kind in [
        NotificationKind.reminder,
        NotificationKind.endReminder,
      ]) {
        for (final notif in unknownToo) {
          expect(mode(kind, true, notif), exact, reason: '$kind $notif');
          expect(mode(kind, null, notif), exact, reason: '$kind $notif');
          expect(mode(kind, false, notif), inexact, reason: '$kind $notif');
        }
      }
    });

    test('günün ayeti/hadisi her zaman gecikmeli', () {
      for (final exactAllowed in unknownToo) {
        for (final notif in unknownToo) {
          expect(
            mode(NotificationKind.dailyContent, exactAllowed, notif),
            inexact,
          );
        }
      }
    });

    test('plan girdilerinin türü: ezan, hatırlatma, vakit çıkış', () {
      final day = PrayerTimesModel(
        imsak: '05:00',
        gunes: '06:30',
        ogle: '13:00',
        ikindi: '16:30',
        aksam: '19:00',
        yatsi: '20:30',
      );
      final now = DateTime(2026, 1, 10, 0, 1);
      final allOn = {for (final k in PrayerRefreshService.vakitKeys) k: true};
      final plan = PrayerRefreshService.buildAlarmPlan(
        days: [day, day],
        now: now,
        loc: tr,
        onTimeAlarms: allOn,
        reminderAlarms: allOn,
        selectedSounds: const {},
        selectedReminderSounds: const {},
        silentModeSettings: const {},
      );
      expect(plan, hasLength(24));
      for (final a in plan) {
        expect(
          a.kind,
          a.id.isEven ? NotificationKind.prayer : NotificationKind.reminder,
          reason: '${a.id}',
        );
      }
      final ends = PrayerRefreshService.buildEndReminderPlan(
        previous: day,
        days: [day],
        now: now,
        loc: tr,
        minutes: 15,
        prayerLog: const {},
      );
      expect(ends, isNotEmpty);
      expect(ends.map((a) => a.kind).toSet(), {NotificationKind.endReminder});
    });

    test('ezan kaydında kip/tür yok: 1.1.0 kaydıyla aynı biçim (güncellemede '
        'geç ezan korunur)', () {
      final a = PlannedAlarm(
        id: 16,
        kind: NotificationKind.prayer,
        title: 'Vakit',
        body: 'gövde kayda girmez',
        time: DateTime(2026, 10, 9, 13, 5),
        sound: 'ezan1',
        channelName: 'Ezan 1',
        payload: 'prayed|2026-10-09|Öğle',
      );
      expect(
        PrayerRefreshService.alarmFingerprint(a),
        '${a.time.millisecondsSinceEpoch}|Vakit|ezan1|Ezan 1|false|'
        'prayed|2026-10-09|Öğle',
      );
    });
  });

  group('Kip geçişi: 1.1.0 kayıtları bir kez yeni kiple yazılır', () {
    // Görev ve beklenen değerler aynı andan (gece yarısında gün ayrışmasın)
    final clockNow = DateTime.now();
    DateTime clock() => clockNow;
    final today = clockNow.toIso8601String().split('T')[0];
    final tomorrow = PrayerTracker.addDays(clockNow, 1);
    final aksamReminder = PrayerRefreshService.alarmId(
      tomorrow,
      4,
      reminder: true,
    );
    final ikindiReminder = PrayerRefreshService.alarmId(
      tomorrow,
      3,
      reminder: true,
    );
    final ogleEzan = PrayerRefreshService.alarmId(tomorrow, 2);
    final ogleEnd = PrayerTracker.endReminderId(tomorrow, 'Öğle');

    // 1.1.0 bugün her şeyi kurmuş (gün kaydı var), bayrak yok
    Map<String, Object> updatedFrom110([
      Map<String, Object> extra = const {},
    ]) => {
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'saved_city': 'İstanbul',
      'language_code': 'tr',
      'reminder_Akşam': true,
      'end_reminder_enabled': true,
      'alarms_scheduled_date': today,
      NotificationService.exactAlarmsAllowedKey: true,
      ...extra,
    };

    // 1.1.0'ın bekleyen bildirimleri: hepsi alarmClock (ikindi hatırlatması ve
    // öğle ezanı sonradan kapatılmış)
    void seed110() {
      for (final id in [aksamReminder, ikindiReminder, ogleEzan, ogleEnd]) {
        pending[id] = (
          title: 'eski',
          body: 'eski',
          payload: '',
          mode: 'alarmClock',
        );
      }
      pending[PrayerRefreshService.ayahNotificationId] = (
        title: 'Günün Ayeti',
        body: 'ayet metni',
        payload: '',
        mode: 'alarmClock',
      );
      pending[PrayerRefreshService.hadithNotificationId] = (
        title: 'Günün Hadisi',
        body: 'hadis metni',
        payload: '',
        mode: 'alarmClock',
      );
    }

    void expectDailyRewritten() {
      final ayah = pending[PrayerRefreshService.ayahNotificationId]!;
      final hadith = pending[PrayerRefreshService.hadithNotificationId]!;
      // Aynı metin (ağ gerekmez), gecikmeli kip
      expect(ayah, (
        title: 'Günün Ayeti',
        body: 'ayet metni',
        payload: '',
        mode: 'inexactAllowWhileIdle',
      ));
      expect(hadith.body, 'hadis metni');
      expect(hadith.mode, 'inexactAllowWhileIdle');
    }

    test('arka plan görevi: ezanlar kapalıyken hiçbir alarmClock kalmaz; '
        'ikinci koşu dokunmaz', () async {
      SharedPreferences.setMockInitialValues(updatedFrom110());
      seed110();

      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);

      // Gün kaydı bugün olsa da her şey yeniden yazıldı: alarm simgesi gider
      expect(alarmClockIds(), isEmpty);
      expect(pending[aksamReminder]!.mode, 'exactAllowWhileIdle');
      expect(pending[ogleEnd]!.mode, 'exactAllowWhileIdle');
      // Plandan çıkanlar iptal
      expect(pending.keys, isNot(contains(ikindiReminder)));
      expect(pending.keys, isNot(contains(ogleEzan)));
      expectDailyRewritten();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(PrayerRefreshService.scheduleModeMigratedKey),
        isTrue,
      );

      // Geçiş bitti: aynı gün ikinci koşu hiçbir şeye dokunmaz
      calls.clear();
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(scheduledIds(), isEmpty);
      expect(cancelledIds(), isEmpty);
    });

    test('açık ezan alarmClock kalır, geri kalanı simgesiz', () async {
      SharedPreferences.setMockInitialValues(
        updatedFrom110({'onTime_Öğle': true}),
      );
      seed110();
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(alarmClockIds(), isNotEmpty);
      expect(alarmClockIds().every(isEzan), isTrue);
      expect(pending[ogleEzan]!.mode, 'alarmClock');
      expectDailyRewritten();
    });

    test('uygulama açılışı (HomeViewModel) da geçişi yapar; ikinci kurulum '
        'günlük içeriğe dokunmaz', () async {
      SharedPreferences.setMockInitialValues(updatedFrom110());
      seed110();
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(tr);
      vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());
      vm.onTimeAlarms = {
        for (final k in PrayerRefreshService.vakitKeys) k: false,
      };
      vm.reminderAlarms = {
        for (final k in PrayerRefreshService.vakitKeys) k: k == 'Akşam',
      };

      await vm.rescheduleAlarms();
      expect(alarmClockIds(), isEmpty);
      expectDailyRewritten();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(PrayerRefreshService.scheduleModeMigratedKey),
        isTrue,
      );

      calls.clear();
      await vm.rescheduleAlarms();
      expect(scheduledIds(), isNotEmpty); // plan her kurulumda yazılır
      expect(
        scheduledIds(),
        isNot(contains(PrayerRefreshService.ayahNotificationId)),
      );
      expect(
        scheduledIds(),
        isNot(contains(PrayerRefreshService.hadithNotificationId)),
      );
    });

    test('günlük içerik kapalıysa kalmış olanlar iptal edilir', () async {
      SharedPreferences.setMockInitialValues(
        updatedFrom110({'daily_content_enabled': false}),
      );
      seed110();
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(alarmClockIds(), isEmpty);
      for (final id in PrayerRefreshService.dailyContentIds) {
        expect(pending.keys, isNot(contains(id)));
        expect(scheduledIds(), isNot(contains(id)));
      }
    });

    test('bekleyenler okunamazsa geçiş bitmiş sayılmaz, sonraki koşu '
        'yeniden dener', () async {
      SharedPreferences.setMockInitialValues(updatedFrom110());
      seed110();
      failPending = true;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(PrayerRefreshService.scheduleModeMigratedKey),
        isNull,
      );
      expect(
        pending[PrayerRefreshService.ayahNotificationId]!.mode,
        'alarmClock',
      );

      failPending = false;
      expect(await PrayerRefreshService.runHeadless(clock: clock), isTrue);
      expect(alarmClockIds(), isEmpty);
      expectDailyRewritten();
      expect(
        prefs.getBool(PrayerRefreshService.scheduleModeMigratedKey),
        isTrue,
      );
    });

    test(
      'güncelleme anında geç kalmış (henüz çalmamış) ezan korunur',
      () async {
        // Gerçek saatten bağımsız ileri bir gün; izin yok (gecikmeli kip)
        final day = DateTime(clockNow.year, clockNow.month, clockNow.day + 30);
        final times = PrayerTimeService().calculate(41.0, 29.0, date: day);
        final p = times.ogle!.split(':');
        final ogle = DateTime(
          day.year,
          day.month,
          day.day,
          int.parse(p[0]),
          int.parse(p[1]),
        );
        SharedPreferences.setMockInitialValues({
          'saved_lat': 41.0,
          'saved_lng': 29.0,
          'language_code': 'tr',
        });
        canScheduleExact = false;
        Future<void> runAt(DateTime at) async {
          final notifications = NotificationService();
          await notifications.init();
          await PrayerRefreshService(
            notifications,
            clock: () => at,
          ).rescheduleAlarms(
            todayTimes: PrayerTimeService().calculate(41.0, 29.0, date: at),
            loc: tr,
            onTimeAlarms: {
              for (final k in PrayerRefreshService.vakitKeys) k: true,
            },
            reminderAlarms: const {},
            selectedSounds: const {},
            selectedReminderSounds: const {},
            silentModeSettings: const {},
          );
        }

        await runAt(DateTime(day.year, day.month, day.day, 9));
        final lateId = PrayerRefreshService.alarmId(day, 2);
        expect(pending[lateId]!.payload, PrayerTracker.payload(day, 'Öğle'));
        // Bu sırada 1.1.1'e güncellendi: geçiş henüz yapılmamış
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(PrayerRefreshService.scheduleModeMigratedKey);

        calls.clear();
        await runAt(ogle.add(const Duration(minutes: 5)));
        expect(pending.keys, contains(lateId));
        expect(scheduledIds(), isNot(contains(lateId)));
        expect(cancelledIds(), isNot(contains(lateId)));
        expect(
          prefs.getBool(PrayerRefreshService.scheduleModeMigratedKey),
          isTrue,
        );
      },
    );
  });

  group('Günün ayeti ve hadisi ayarı', () {
    final ayah = AyahModel(
      number: 1,
      surahName: 'Fatiha',
      numberInSurah: 1,
      arabicText: 'x',
      translatedText: 'y',
    );
    final hadith = HadithModel(content: 'hadis', source: 'kaynak');

    for (final enabled in [true, false]) {
      test(
        'kurulum: ayar ${enabled ? 'açık → gecikmeli kipte kurulur' : 'kapalı → kurulmaz'}',
        () async {
          SharedPreferences.setMockInitialValues({
            if (!enabled) 'daily_content_enabled': false,
          });
          final notifications = NotificationService();
          await notifications.init();
          await PrayerRefreshService(
            notifications,
          ).scheduleDailyContent(localeName: 'tr', ayah: ayah, hadith: hadith);
          if (enabled) {
            expect(scheduledIds(), PrayerRefreshService.dailyContentIds);
            expect(pending.values.map((p) => p.mode).toSet(), {
              'inexactAllowWhileIdle',
            });
          } else {
            expect(scheduledIds(), isEmpty);
          }
        },
      );
    }

    test(
      'arka plan görevi: kapalıyken tamamlamaz, kalmış olanı iptal eder',
      () async {
        final now = DateTime.now();
        SharedPreferences.setMockInitialValues({
          'saved_lat': 41.0,
          'saved_lng': 29.0,
          'language_code': 'tr',
          'daily_content_enabled': false,
          'alarms_scheduled_date': now.toIso8601String().split('T')[0],
          PrayerRefreshService.scheduleModeMigratedKey: true,
        });
        pending[PrayerRefreshService.hadithNotificationId] = (
          title: 'Günün Hadisi',
          body: 'hadis',
          payload: '',
          mode: 'inexactAllowWhileIdle',
        );
        expect(
          await PrayerRefreshService.runHeadless(clock: () => now),
          isTrue,
        );
        expect(cancelledIds(), [PrayerRefreshService.hadithNotificationId]);
        expect(pending, isEmpty);
        expect(scheduledIds(), isEmpty);
      },
    );

    test('Ayarlar anahtarı (HomeViewModel): kapatınca hemen iptal, bir daha '
        'kurulmaz; açınca kurulur', () async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(tr);
      pending[PrayerRefreshService.ayahNotificationId] = (
        title: 'Günün Ayeti',
        body: 'ayet',
        payload: '',
        mode: 'alarmClock',
      );

      await vm.setDailyContentEnabled(false);
      expect(vm.dailyContentEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('daily_content_enabled'), isFalse);
      expect(
        cancelledIds().toSet(),
        PrayerRefreshService.dailyContentIds.toSet(),
      );
      expect(pending, isEmpty);
      // Yeni içerik gelse de kurulmaz (hadis: ağ yok → yerel yedek)
      await vm.getDailyHadith(const Locale('tr'));
      expect(vm.dailyHadith, isNotNull);
      expect(scheduledIds(), isEmpty);

      await vm.setDailyContentEnabled(true);
      expect(prefs.getBool('daily_content_enabled'), isTrue);
      expect(pending.keys, contains(PrayerRefreshService.hadithNotificationId));
      expect(
        pending[PrayerRefreshService.hadithNotificationId]!.mode,
        'inexactAllowWhileIdle',
      );
    });
  });
}
