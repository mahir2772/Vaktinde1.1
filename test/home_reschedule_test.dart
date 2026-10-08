import 'dart:async';

import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Uygulama içi alarm kurma işleri üst üste binmemeli
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Set<int> pending;
  late Completer<void> firstSchedule;
  late List<int> scheduled;
  late List<int> cancelledNotPending;
  late Duration scheduleDelay;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    pending = {};
    firstSchedule = Completer<void>();
    scheduled = [];
    cancelledNotPending = [];
    scheduleDelay = Duration.zero;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
            await Future<void>.delayed(scheduleDelay);
            pending.add(call.arguments['id']);
            scheduled.add(call.arguments['id']);
            if (!firstSchedule.isCompleted) firstSchedule.complete();
            return null;
          case 'cancel':
            // Bekleyen değilse çekmecede gösterilen bildirim silinmiş olur
            if (!pending.remove(call.arguments['id'])) {
              cancelledNotPending.add(call.arguments['id']);
            }
            return null;
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

  const idCount = PrayerRefreshService.alarmIdCount;
  // Yarından itibaren 4 günün öğle ezanı (kesin gelecekte)
  List<int> ogleIds() => [
    for (var d = 1; d <= 4; d++)
      PrayerRefreshService.alarmId(
        PrayerTracker.addDays(DateTime.now(), d),
        2,
      ),
  ];

  test('Kurulum sürerken kapatılan alarm kurulu kalmaz', () async {
    SharedPreferences.setMockInitialValues({'saved_lat': 41.0, 'saved_lng': 29.0});
    await NotificationService().init();
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.updateLocalization(lookupAppLocalizations(const Locale('tr')));
    vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());
    vm.onTimeAlarms = {
      for (final k in PrayerRefreshService.vakitKeys) k: k == 'Öğle',
    };

    scheduleDelay = const Duration(milliseconds: 30); // yavaş kurulum
    vm.changeSound('Öğle', 'ezan2'); // 1. kurulum: öğle açık, kurma aşamasında
    await firstSchedule.future;
    vm.onTimeAlarms['Öğle'] = false;
    vm.toggleSilentMode('Öğle', false); // 1. sürerken 2. istek
    await vm.alarmsSettled;
    // Geride kalmış bir kurulum olmadığından emin ol
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(pending.where((id) => id < idCount), isEmpty);
  });

  test('Ardışık istekler sonunda son ayar kurulu olur', () async {
    SharedPreferences.setMockInitialValues({'saved_lat': 41.0, 'saved_lng': 29.0});
    await NotificationService().init();
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.updateLocalization(lookupAppLocalizations(const Locale('tr')));
    vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());
    vm.onTimeAlarms = {for (final k in PrayerRefreshService.vakitKeys) k: false};

    vm.changeSound('Öğle', 'ezan2');
    vm.onTimeAlarms['Öğle'] = true;
    vm.toggleSilentMode('Öğle', false);
    vm.toggleSilentMode('Öğle', true);
    await vm.alarmsSettled;

    // Öğle ezanı (her günde ID % 12 == 4)
    expect(pending, containsAll(ogleIds()));
    expect(pending.where((id) => id < idCount && id % 12 != 4), isEmpty);
  });

  Future<HomeViewModel> loadedViewModel() async {
    SharedPreferences.setMockInitialValues({'saved_lat': 41.0, 'saved_lng': 29.0});
    await NotificationService().init();
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.updateLocalization(lookupAppLocalizations(const Locale('tr')));
    vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());
    vm.onTimeAlarms = {for (final k in PrayerRefreshService.vakitKeys) k: false};
    return vm;
  }

  test('Kapatılan alarmın bekleyenleri iptal edilir, çekmecedekilere dokunulmaz', () async {
    final vm = await loadedViewModel();
    vm.onTimeAlarms['Öğle'] = true;
    vm.toggleSilentMode('Öğle', false);
    await vm.alarmsSettled;
    expect(pending, containsAll(ogleIds()));

    vm.onTimeAlarms['Öğle'] = false;
    vm.toggleSilentMode('Öğle', false);
    await vm.alarmsSettled;
    expect(pending.where((id) => id < idCount), isEmpty);
    // Toplu iptal yok: sadece bekleyen alarmlar iptal edildi
    expect(cancelledNotPending, isEmpty);
  });

  test('Eski güne ait ayet/hadis bildirimi yeniden kurulmaz', () async {
    final vm = await loadedViewModel();
    // Tarihi olmayan (dünden kalmış gibi) içerik
    vm.dailyAyah = AyahModel(
      number: 1,
      surahName: 'Fatiha',
      numberInSurah: 1,
      arabicText: 'x',
      translatedText: 'y',
    );
    vm.onTimeAlarms['Öğle'] = true;
    vm.toggleSilentMode('Öğle', false);
    await vm.alarmsSettled;
    expect(scheduled, isNotEmpty);
    expect(scheduled, isNot(contains(1000)));
    expect(scheduled, isNot(contains(1900)));
  });
}
