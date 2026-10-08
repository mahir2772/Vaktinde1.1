import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

// Ana ekran ve "Alarmlar" sekmesindeki izin uyarıları + "sessiz modda da çal":
// 320 dp, %130 yazı, tr/de/ar (ar koyu tema, sağdan sola)

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
  Future<void> refreshLocationAndTimes(BuildContext context) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> rescheduleAlarms() async => reschedules++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  late bool? canScheduleExact;
  late bool? notificationsEnabled;
  late bool grantOnRequest; // sistem ekranında/penceresinde izin verilir
  late int exactRequests;
  late int notificationRequests;
  late int settingsOpened;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    canScheduleExact = true;
    notificationsEnabled = true;
    grantOnRequest = false;
    exactRequests = 0;
    notificationRequests = 0;
    settingsOpened = 0;
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      switch (call.method) {
        case 'canScheduleExactNotifications':
          return canScheduleExact;
        case 'areNotificationsEnabled':
          return notificationsEnabled;
        case 'requestExactAlarmsPermission':
          exactRequests++;
          if (grantOnRequest) canScheduleExact = true;
          return canScheduleExact;
        case 'requestNotificationsPermission':
          notificationRequests++;
          if (grantOnRequest) notificationsEnabled = true;
          return notificationsEnabled;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(permissionChannel, (call) async {
      if (call.method == 'openAppSettings') settingsOpened++;
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(notifChannel, null);
    messenger.setMockMethodCallHandler(permissionChannel, null);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<_FakeHomeViewModel> pumpHome(
    WidgetTester tester,
    String lang, {
    bool dark = false,
    Map<String, bool> onTime = const {'Öğle': true},
  }) async {
    SharedPreferences.setMockInitialValues({
      'language_code': lang,
      'is_language_selected': true,
    });
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final vm = _FakeHomeViewModel()
      ..city = 'İstanbul'
      ..district = 'Kadıköy'
      ..isLoading = false
      ..prayerTimes = PrayerTimesModel(
        imsak: '05:35',
        gunes: '07:00',
        ogle: '12:57',
        ikindi: '16:08',
        aksam: '18:43',
        yatsi: '20:02',
      )
      ..onTimeAlarms = {...onTime};
    await tester.pumpWidget(
      MultiProvider(
        key: UniqueKey(),
        providers: [
          ChangeNotifierProvider<HomeViewModel>(create: (_) => vm, lazy: false),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          locale: Locale(lang),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShowCaseWidget(builder: (context) => const HomeView()),
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

  Future<void> lifecycle(AppLifecycleState state) =>
      messenger.handlePlatformMessage(
        SystemChannels.lifecycle.name,
        SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
        (_) {},
      );

  Future<void> openAlarmsTab(WidgetTester tester, AppLocalizations loc) async {
    await tester.tap(find.text(loc.tabAlarms));
    await settle(tester);
  }

  for (final lang in ['tr', 'de', 'ar']) {
    final loc = lookupAppLocalizations(Locale(lang));
    final dark = lang == 'ar';

    testWidgets('$lang: alarm izni yoksa uyarı (ana ekran + Alarmlar); izin '
        'verilince kalkar, alarmlar yeniden kurulur', (tester) async {
      canScheduleExact = false;
      final vm = await pumpHome(tester, lang, dark: dark);
      expect(
        find.text(loc.alarmHealthExactOff),
        findsNothing,
      ); // henüz okunmadı
      await vm.alarmHealth.refresh();
      await settle(tester);
      expect(find.text(loc.alarmHealthExactOff), findsOneWidget);
      expect(find.text(loc.alarmHealthNotificationsOff), findsNothing);
      expect(vm.reschedules, 0); // ilk okuma kurmaz

      await openAlarmsTab(tester, loc);
      expect(find.text(loc.alarmHealthExactOff).hitTestable(), findsOneWidget);
      expect(find.text(loc.ezanAlarmStreamTitle), findsOneWidget);
      expect(find.text(loc.ezanAlarmStreamSub), findsOneWidget);

      grantOnRequest = true;
      await tester.tap(find.text(loc.alarmHealthExactAction).hitTestable());
      await settle(tester);
      expect(exactRequests, 1);
      expect(settingsOpened, 0);
      expect(find.text(loc.alarmHealthExactOff), findsNothing);
      expect(vm.reschedules, 1);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('$lang: bildirimler kapalıysa önce o uyarı; izin verilince '
        'kalkar, sıradaki sorun görünür', (tester) async {
      notificationsEnabled = false;
      canScheduleExact = false;
      final vm = await pumpHome(tester, lang, dark: dark);
      await vm.alarmHealth.refresh();
      await settle(tester);
      expect(find.text(loc.alarmHealthNotificationsOff), findsOneWidget);
      expect(find.text(loc.alarmHealthExactOff), findsNothing);

      grantOnRequest = true;
      await tester.tap(find.text(loc.alarmHealthNotificationsAction));
      await settle(tester);
      expect(notificationRequests, 1);
      expect(settingsOpened, 0);
      expect(find.text(loc.alarmHealthNotificationsOff), findsNothing);
      // Bildirimler açıldı: alarmlar kurulur; tam zamanlı izin hâlâ yok
      expect(vm.reschedules, 1);
      expect(find.text(loc.alarmHealthExactOff), findsOneWidget);

      await openAlarmsTab(tester, loc);
      expect(find.text(loc.alarmHealthExactOff).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }

  testWidgets('hiç alarm açık değilse izinler kapalı olsa da uyarı yok', (
    tester,
  ) async {
    notificationsEnabled = false;
    canScheduleExact = false;
    final vm = await pumpHome(tester, 'tr', onTime: const {});
    await vm.alarmHealth.refresh();
    await settle(tester);
    final loc = lookupAppLocalizations(const Locale('tr'));
    expect(find.text(loc.alarmHealthNotificationsOff), findsNothing);
    expect(find.text(loc.alarmHealthExactOff), findsNothing);

    // Alarm açılınca uyarı hemen görünür (pencere açılmaz)
    vm.onTimeAlarms['Öğle'] = true;
    vm.notifyListeners();
    await settle(tester);
    expect(find.text(loc.alarmHealthNotificationsOff), findsOneWidget);
    expect(notificationRequests, 0);
    await finish(tester);
  });

  testWidgets('pencere çıkmadan ret (kalıcı) → uygulama ayarları; ayarlardan '
      'dönünce uyarı kalkar', (tester) async {
    notificationsEnabled = false;
    final vm = await pumpHome(tester, 'tr');
    final loc = lookupAppLocalizations(const Locale('tr'));
    await vm.alarmHealth.refresh();
    await settle(tester);

    await tester.tap(find.text(loc.alarmHealthNotificationsAction));
    await settle(tester);
    expect(notificationRequests, 1);
    expect(settingsOpened, 1);
    expect(find.text(loc.alarmHealthNotificationsOff), findsOneWidget);

    // Kullanıcı ayarlardan açıp uygulamaya döndü
    notificationsEnabled = true;
    await lifecycle(AppLifecycleState.inactive);
    await lifecycle(AppLifecycleState.hidden);
    await lifecycle(AppLifecycleState.paused);
    await lifecycle(AppLifecycleState.hidden);
    await lifecycle(AppLifecycleState.inactive);
    await lifecycle(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.text(loc.alarmHealthNotificationsOff), findsNothing);
    expect(vm.reschedules, 1);
    await finish(tester);
  });

  testWidgets('"Sessiz modda da çal" kaydedilir ve alarmları yeniden kurar', (
    tester,
  ) async {
    final vm = await pumpHome(tester, 'tr');
    final loc = lookupAppLocalizations(const Locale('tr'));
    await openAlarmsTab(tester, loc);
    expect(vm.ezanAlarmStream, isFalse);

    await tester.tap(find.text(loc.ezanAlarmStreamTitle));
    await settle(tester);
    expect(vm.ezanAlarmStream, isTrue);
    expect(vm.reschedules, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ezan_alarm_stream'), isTrue);
    final toggle = tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(loc.ezanAlarmStreamTitle),
          matching: find.byType(AppListTile),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle.value, isTrue);

    await tester.tap(find.byWidget(toggle));
    await settle(tester);
    expect(vm.ezanAlarmStream, isFalse);
    expect(prefs.getBool('ezan_alarm_stream'), isFalse);
    expect(vm.reschedules, 2);
    await finish(tester);
  });
}
