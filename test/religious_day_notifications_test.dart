// Dini gün ve kandil bildirimleri (ID 2000-2399): religious_days.json'dan plan
// (o gün 10:00, Ramazan bir gün önce, aynı gün tek bildirim), kip/kanal, ayar,
// uygulama içi ve arka plan (WorkManager) kurulumu
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  final days = DiniGunlerService.parseBildirimGunleri(
    jsonDecode(File('assets/data/religious_days.json').readAsStringSync())
        as List,
  );

  List<PlannedAlarm> planAt(DateTime now, [AppLocalizations? loc]) =>
      PrayerRefreshService.buildReligiousDayPlan(
        days: days,
        now: now,
        loc: loc ?? tr,
      );

  group('Plan', () {
    // Yılın bütün bildirimleri (aylık kayan 60 günlük pencereler)
    List<PlannedAlarm> yearPlan(int year, [AppLocalizations? loc]) {
      final all = <int, PlannedAlarm>{};
      for (var month = 1; month <= 12; month++) {
        for (final a in planAt(DateTime(year, month, 1, 0, 0, 1), loc)) {
          if (a.time.year == year) all[a.id] = a;
        }
      }
      return all.values.toList()..sort((a, b) => a.time.compareTo(b.time));
    }

    // (bildirim günü, tür; null: Üç Aylar + Regaib ortak metni)
    void expectYear(int year, List<(DateTime, DiniGunTuru?)> expected) {
      final plan = yearPlan(year);
      expect(
        [for (final a in plan) a.time],
        [
          for (final (day, _) in expected)
            DateTime(day.year, day.month, day.day, 10),
        ],
      );
      for (final (i, (day, tur)) in expected.indexed) {
        final a = plan[i];
        expect(a.id, PrayerRefreshService.religiousDayId(day), reason: '$day');
        expect(a.kind, NotificationKind.religiousDay);
        expect(a.channelName, tr.religiousDaysChannel);
        expect(a.payload, isNull);
        expect(
          (a.title, a.body),
          tur == null
              ? (tr.ucAylarRegaipTitle, tr.ucAylarRegaipNotifBody)
              : (
                  DiniGunlerService.isimOf(tur, tr),
                  DiniGunlerService.bildirimMetniOf(tur, tr),
                ),
          reason: '$day',
        );
      }
    }

    test('2026: kandiller, Ramazan (bir gün önce), arefe ve bayramın 1. günü; '
        '10 Aralık Üç Aylar + Regaib tek bildirim', () {
      expectYear(2026, [
        (DateTime(2026, 1, 15), DiniGunTuru.miracKandili),
        (DateTime(2026, 2, 2), DiniGunTuru.beratKandili),
        (DateTime(2026, 2, 18), DiniGunTuru.ramazanBaslangici),
        (DateTime(2026, 3, 16), DiniGunTuru.kadirGecesi),
        (DateTime(2026, 3, 19), DiniGunTuru.ramazanArefesi),
        (DateTime(2026, 3, 20), DiniGunTuru.ramazanBayrami),
        (DateTime(2026, 5, 26), DiniGunTuru.kurbanArefesi),
        (DateTime(2026, 5, 27), DiniGunTuru.kurbanBayrami),
        (DateTime(2026, 6, 16), DiniGunTuru.hicriYilbasi),
        (DateTime(2026, 6, 25), DiniGunTuru.asureGunu),
        (DateTime(2026, 8, 24), DiniGunTuru.mevlidKandili),
        (DateTime(2026, 12, 10), null),
      ]);
    });

    test(
      '2027: Ramazan 08.02 → 07.02 10:00; Üç Aylar ve Regaib ayrı günlerde',
      () {
        expectYear(2027, [
          (DateTime(2027, 1, 4), DiniGunTuru.miracKandili),
          (DateTime(2027, 1, 22), DiniGunTuru.beratKandili),
          (DateTime(2027, 2, 7), DiniGunTuru.ramazanBaslangici),
          (DateTime(2027, 3, 5), DiniGunTuru.kadirGecesi),
          (DateTime(2027, 3, 8), DiniGunTuru.ramazanArefesi),
          (DateTime(2027, 3, 9), DiniGunTuru.ramazanBayrami),
          (DateTime(2027, 5, 15), DiniGunTuru.kurbanArefesi),
          (DateTime(2027, 5, 16), DiniGunTuru.kurbanBayrami),
          (DateTime(2027, 6, 6), DiniGunTuru.hicriYilbasi),
          (DateTime(2027, 6, 15), DiniGunTuru.asureGunu),
          (DateTime(2027, 8, 13), DiniGunTuru.mevlidKandili),
          (DateTime(2027, 11, 29), DiniGunTuru.ucAylar),
          (DateTime(2027, 12, 2), DiniGunTuru.regaipKandili),
          (DateTime(2027, 12, 24), DiniGunTuru.miracKandili),
        ]);
      },
    );

    test(
      'metinler: "bu gece", Ramazan "yarın başlıyor, ilk sahur bu gece"',
      () {
        final plan = planAt(DateTime(2026, 12, 9, 12));
        expect(
          [for (final a in plan) a.time],
          [
            DateTime(2026, 12, 10, 10),
            DateTime(2027, 1, 4, 10),
            DateTime(2027, 1, 22, 10),
            DateTime(2027, 2, 7, 10), // 60. gün
          ],
        );
        expect(plan[0].title, 'Üç Aylar ve Regaib Kandili');
        expect(
          plan[0].body,
          'Üç aylar bugün başladı, bu gece de Regaib Kandili. Üç aylarınız ve '
          'kandiliniz mübarek olsun.',
        );
        expect(plan[1].title, 'Miraç Kandili');
        expect(
          plan[1].body,
          'Bu gece Miraç Kandili. Kandiliniz mübarek olsun.',
        );
        expect(plan[3].title, 'Ramazan Başlangıcı');
        expect(
          plan[3].body,
          'Ramazan yarın başlıyor; ilk teravih ve sahur bu gece. '
          'Hayırlı Ramazanlar!',
        );
      },
    );

    test('vakti geçen gün ve 60 günden ötesi yok', () {
      final regaib = DateTime(2026, 12, 10, 10);
      expect(planAt(DateTime(2026, 12, 10, 9, 59)).first.time, regaib);
      expect(planAt(DateTime(2026, 12, 10, 10)).first.time, isNot(regaib));
      expect(planAt(DateTime(2026, 12, 10, 18)).first.time, isNot(regaib));
      expect(planAt(DateTime(2026, 10, 11, 23)).single.time, regaib);
      expect(planAt(DateTime(2026, 10, 10, 23)), isEmpty); // 61 gün
      // Listedeki son tarihten sonra bildirim yok (hicri tahmin kullanılmaz)
      expect(planAt(DateTime(2028, 12, 31)), isEmpty);
    });

    test(
      'ID 2000-2399: diğer bildirimlerle çakışmaz, 61 günde tekrar etmez',
      () {
        final others = {
          for (var id = 0; id < PrayerRefreshService.alarmIdCount; id++) id,
          for (var id = 100; id <= 124; id++) id,
          888,
          ...PrayerRefreshService.dailyContentIds,
          1999,
        };
        for (final id in others) {
          expect(PrayerRefreshService.isReligiousDayId(id), isFalse);
        }
        expect(PrayerRefreshService.isReligiousDayId(2000), isTrue);
        expect(PrayerRefreshService.isReligiousDayId(2399), isTrue);
        expect(PrayerRefreshService.isReligiousDayId(2400), isFalse);
        final ids = [
          for (var i = 0; i < 4 * 366; i++)
            PrayerRefreshService.religiousDayId(
              PrayerTracker.addDays(DateTime(2025, 1, 1), i),
            ),
        ];
        for (final id in ids) {
          expect(id, inInclusiveRange(2000, 2399));
          expect(PrayerTracker.isEndReminderId(id), isFalse);
        }
        const window = PrayerRefreshService.religiousDayDays + 1;
        for (var i = 0; i + window <= ids.length; i++) {
          expect(ids.sublist(i, i + window).toSet(), hasLength(window));
        }
      },
    );

    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      test('$lang: her gün için ad ve metin çevrili', () {
        final loc = lookupAppLocalizations(Locale(lang));
        final texts = [
          for (final tur in DiniGunTuru.values) ...[
            DiniGunlerService.isimOf(tur, loc),
            DiniGunlerService.bildirimMetniOf(tur, loc),
          ],
          loc.ucAylarRegaipTitle,
          loc.ucAylarRegaipNotifBody,
          loc.religiousDaysChannel,
          loc.religiousDaysNotifTitle,
          loc.religiousDaysNotifSub,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty);
          expect(t, isNot(contains('{')));
        }
        expect(texts.toSet(), hasLength(texts.length));
        if (lang != 'tr') {
          final trTexts = [
            for (final tur in DiniGunTuru.values)
              DiniGunlerService.bildirimMetniOf(tur, tr),
          ];
          for (final tur in DiniGunTuru.values) {
            expect(
              trTexts,
              isNot(contains(DiniGunlerService.bildirimMetniOf(tur, loc))),
            );
          }
        }
        final plan = yearPlan(2026, loc);
        expect(plan.last.title, loc.ucAylarRegaipTitle);
        expect(plan.last.channelName, loc.religiousDaysChannel);
      });
    }

    test(
      'kip: ayar ve izinden bağımsız her zaman gecikmeli (alarm simgesi yok)',
      () {
        for (final exact in <bool?>[true, false, null]) {
          for (final notif in <bool?>[true, false, null]) {
            expect(
              NotificationService.scheduleModeFor(
                NotificationKind.religiousDay,
                exactAllowed: exact,
                notificationsEnabled: notif,
              ),
              AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      },
    );
  });

  group('Kurulum', () {
    // Eklentinin bekleyen listesi: ID → (başlık, metin, kip, kanal, saat)
    late Map<
      int,
      ({String title, String body, String mode, String channel, String at})
    >
    pending;
    late List<MethodCall> calls;

    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      pending = {};
      calls = [];
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
            final specifics = call.arguments['platformSpecifics'];
            pending[call.arguments['id'] as int] = (
              title: call.arguments['title'] as String? ?? '',
              body: call.arguments['body'] as String? ?? '',
              mode: specifics['scheduleMode'] as String,
              channel: specifics['channelId'] as String,
              at: call.arguments['scheduledDateTime'] as String,
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
                  'title': e.value.title,
                  'body': e.value.body,
                  'payload': '',
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
    Iterable<int> religiousIds(Iterable<int> ids) =>
        ids.where(PrayerRefreshService.isReligiousDayId);
    void seed(int id, {String mode = 'inexactAllowWhileIdle'}) =>
        pending[id] = (
          title: 'eski',
          body: 'eski',
          mode: mode,
          channel: 'religious_days_channel',
          at: '',
        );

    // Eklenti geçmiş saati reddeder: gerçek saate göre en az iki gün sonraki ilk
    // bildirim günü (listedeki son tarihten sonra bu testler atlanır)
    DateTime? firstUpcomingDay() {
      final today = PrayerTracker.day(DateTime.now());
      var from = DateTime(today.year, today.month, today.day + 1, 23);
      for (var i = 0; i < 60; i++) {
        final plan = planAt(from);
        if (plan.isNotEmpty) return PrayerTracker.day(plan.first.time);
        from = DateTime(from.year, from.month, from.day + 60, 23);
      }
      return null;
    }

    final eventDay = firstUpcomingDay();
    final skip = eventDay == null
        ? 'religious_days.json\'da ileri tarih yok'
        : null;
    // Bildirim gününden bir gün önce sabah (gerçek saate göre ileride)
    DateTime dayBefore() =>
        DateTime(eventDay!.year, eventDay.month, eventDay.day - 1, 9);

    Future<PrayerRefreshService> serviceAt(DateTime at) async {
      final notifications = NotificationService();
      await notifications.init();
      return PrayerRefreshService(notifications, clock: () => at);
    }

    test('ayar açık (varsayılan): plan gecikmeli kipte, kendi kanalında ve '
        '10:00\'a kurulur; plandan çıkan bekleyen iptal, diğer ID\'lere '
        'dokunulmaz', () async {
      SharedPreferences.setMockInitialValues({});
      final at = dayBefore();
      final expected = planAt(at);
      expect(expected, isNotEmpty);
      final stale = [
        for (var id = 2000; id < 2400; id++)
          if (!expected.any((a) => a.id == id) &&
              id != PrayerRefreshService.religiousDayId(at))
            id,
      ].first;
      seed(stale);
      seed(PrayerRefreshService.ayahNotificationId);
      seed(PrayerRefreshService.alarmId(eventDay!, 2), mode: 'alarmClock');

      final service = await serviceAt(at);
      expect(await service.syncReligiousDays(tr), isTrue);

      expect(scheduledIds(), [for (final a in expected) a.id]);
      expect(cancelledIds(), [stale]);
      for (final a in expected) {
        expect(pending[a.id], (
          title: a.title,
          body: a.body,
          mode: 'inexactAllowWhileIdle',
          channel: 'religious_days_channel',
          at: '${PrayerTracker.dateKey(a.time)}T10:00:00',
        ));
      }
      expect(pending.keys, contains(PrayerRefreshService.ayahNotificationId));
      expect(pending.keys, contains(PrayerRefreshService.alarmId(eventDay, 2)));
      final channelName = calls
          .firstWhere((c) => c.method == 'zonedSchedule')
          .arguments['platformSpecifics']['channelName'];
      expect(channelName, tr.religiousDaysChannel);
    }, skip: skip);

    test(
      'vakti geçmiş bugünün bildirimi (gecikmeli kipte henüz gelmemiş '
      'olabilir) iptal edilmez, yeniden de kurulmaz; ayar kapalıysa iptal',
      () async {
        SharedPreferences.setMockInitialValues({});
        final todayId = PrayerRefreshService.religiousDayId(eventDay!);
        final at = DateTime(
          eventDay.year,
          eventDay.month,
          eventDay.day,
          10,
          30,
        );
        seed(todayId);

        await (await serviceAt(at)).syncReligiousDays(tr);
        expect(pending.keys, contains(todayId));
        expect(scheduledIds(), isNot(contains(todayId)));
        expect(cancelledIds(), isEmpty);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageService.religiousDaysEnabledKey, false);
        final later = scheduledIds();
        await (await serviceAt(at)).syncReligiousDays(tr);
        expect(cancelledIds().toSet(), {todayId, ...later});
        expect(religiousIds(pending.keys), isEmpty);
      },
      skip: skip,
    );

    test('ayar kapalıyken kurulum turu (rescheduleAlarms) kurmaz, kalmış '
        'olanları iptal eder; ezan alarmları etkilenmez', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        StorageService.religiousDaysEnabledKey: false,
      });
      final at = dayBefore();
      final leftover = PrayerRefreshService.religiousDayId(eventDay!);
      seed(leftover);

      await (await serviceAt(at)).rescheduleAlarms(
        todayTimes: PrayerTimeService().calculate(41.0, 29.0, date: at),
        loc: tr,
        onTimeAlarms: const {'Öğle': true},
        reminderAlarms: const {},
        selectedSounds: const {},
        selectedReminderSounds: const {},
        silentModeSettings: const {},
      );
      expect(religiousIds(scheduledIds()), isEmpty);
      expect(cancelledIds(), [leftover]);
      expect(scheduledIds(), contains(PrayerRefreshService.alarmId(at, 2)));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('alarms_scheduled_date'),
        PrayerTracker.dateKey(at),
      );
    }, skip: skip);

    test('arka plan görevi (WorkManager) seçili dilde kurar; aynı gün ikinci '
        'koşu dokunmaz', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'saved_city': 'İstanbul',
        'language_code': 'de',
        PrayerRefreshService.scheduleModeMigratedKey: true,
      });
      // Günlük içerik zaten kurulu (ağ gerekmesin)
      seed(PrayerRefreshService.ayahNotificationId);
      seed(PrayerRefreshService.hadithNotificationId);
      final at = dayBefore();
      final de = lookupAppLocalizations(const Locale('de'));
      final expected = planAt(at, de);

      expect(await PrayerRefreshService.runHeadless(clock: () => at), isTrue);
      expect(religiousIds(scheduledIds()), [for (final a in expected) a.id]);
      for (final a in expected) {
        expect(pending[a.id]!.title, a.title);
        expect(pending[a.id]!.body, a.body);
        expect(pending[a.id]!.mode, 'inexactAllowWhileIdle');
      }
      expect(expected.first.body, isNot(planAt(at).first.body)); // Almanca

      calls.clear();
      expect(await PrayerRefreshService.runHeadless(clock: () => at), isTrue);
      expect(scheduledIds(), isEmpty);
      expect(cancelledIds(), isEmpty);
    }, skip: skip);

    test('Ayarlar anahtarı (HomeViewModel): kapatınca aralıktaki bekleyenler '
        'hemen iptal, açınca önümüzdeki günler kurulur', () async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(tr);
      final religious = [2000, 2123, 2399];
      for (final id in religious) {
        seed(id);
      }
      seed(PrayerRefreshService.hadithNotificationId);

      await vm.setReligiousDaysEnabled(false);
      expect(vm.religiousDaysEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageService.religiousDaysEnabledKey), isFalse);
      expect(cancelledIds().toSet(), religious.toSet());
      expect(pending.keys, [PrayerRefreshService.hadithNotificationId]);
      expect(scheduledIds(), isEmpty);

      calls.clear();
      final expected = planAt(DateTime.now());
      await vm.setReligiousDaysEnabled(true);
      expect(prefs.getBool(StorageService.religiousDaysEnabledKey), isTrue);
      expect(scheduledIds(), [for (final a in expected) a.id]);
      expect(cancelledIds(), isEmpty);
    });
  });
}
