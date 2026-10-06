import 'dart:async';

import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
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
  late Completer<void> firstCancel;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    pending = {};
    firstCancel = Completer<void>();
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
            pending.add(call.arguments['id']);
            return null;
          case 'cancel':
            pending.remove(call.arguments['id']);
            if (!firstCancel.isCompleted) firstCancel.complete();
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

    vm.changeSound('Öğle', 'ezan2'); // 1. kurulum: öğle açık, iptal aşamasında
    await firstCancel.future;
    vm.onTimeAlarms['Öğle'] = false;
    vm.toggleSilentMode('Öğle', false); // 1. sürerken 2. istek
    await vm.alarmsSettled;

    expect(pending.where((id) => id < 60), isEmpty);
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

    // Öğle ezanı her gün 4 + 12*gün; yarından itibaren 4 gün kesin gelecekte
    expect(pending, containsAll([16, 28, 40, 52]));
    expect(pending.where((id) => id < 60 && id % 12 != 4), isEmpty);
  });
}
