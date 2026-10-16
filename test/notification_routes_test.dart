// Bildirimden uygulama içi yönlendirme: 'open|<hedef>' gövdenin yükünde ya da
// uygulamayı açan düğmenin kimliğinde; "Kıldım" yükü, "Kıldım" ve "Durdur"
// eylemleri yönlendirme değildir. Uygulamayı açan bildirim süreç başına bir
// kez okunur, açık uygulamadaki dokunuş initialize işleyicisine gelir.
// MainWrapper hedefi açılış akışından sonra (tur ve Yenilikler kapanınca)
// açar: Cuma mesajları, Kur'an okuyucusunda sure; geçiş reklamı yok.
import 'package:ezan_saati/core/notification_routes.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/app_guide/whats_new.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class _FakeHomeViewModel extends HomeViewModel {
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
  Future<void> rescheduleAlarms() async {}

  @override
  Future<void> requestBatteryOptimizationOnce() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final tr = lookupAppLocalizations(const Locale('tr'));
  final prayed = PrayerTracker.payload(DateTime(2026, 10, 16), 'Öğle');

  NotificationResponse tap({String? payload, String? actionId}) =>
      NotificationResponse(
        notificationResponseType: actionId == null
            ? NotificationResponseType.selectedNotification
            : NotificationResponseType.selectedNotificationAction,
        id: 2400,
        actionId: actionId,
        payload: payload,
      );

  setUp(() => NotificationRoutes.pending.value = null);

  group('Hedef', () {
    test('gövde: yükten; uygulamayı açan düğme: eylem kimliğinden', () {
      expect(
        NotificationRoutes.route(NotificationRoutes.friday),
        'open|friday',
      );
      expect(
        NotificationRoutes.targetOf(tap(payload: 'open|friday')),
        'friday',
      );
      expect(
        NotificationRoutes.targetOf(
          tap(payload: 'open|friday', actionId: 'open|surah:18'),
        ),
        'surah:18',
      );
      // Cuma bildiriminin kendisi
      final friday = PrayerRefreshService.buildFridayPlan(
        now: DateTime(2026, 10, 14, 12),
        loc: tr,
      ).first;
      expect(
        NotificationRoutes.targetOf(tap(payload: friday.payload)),
        NotificationRoutes.friday,
      );
      expect(
        NotificationRoutes.targetOf(
          tap(
            payload: friday.payload,
            actionId: PrayerRefreshService.fridayKehfRoute,
          ),
        ),
        '${NotificationRoutes.surah}:18',
      );
    });

    test('"Kıldım" yükü, "Kıldım" ve "Durdur" eylemleri yönlendirme değil; '
        'başka eylem yükteki hedefe düşmez', () {
      for (final response in [
        tap(payload: prayed),
        tap(payload: prayed, actionId: PrayerTracker.actionId),
        tap(
          payload: prayed,
          actionId: '${NotificationService.stopActionId}|["Öğle","x"]',
        ),
        tap(payload: 'open|friday', actionId: PrayerTracker.actionId),
        tap(),
        tap(payload: ''),
        tap(payload: 'open|'),
        tap(payload: 'friday'),
      ]) {
        final reason = '${response.actionId} ${response.payload}';
        expect(NotificationRoutes.targetOf(response), isNull, reason: reason);
        NotificationRoutes.handle(response);
        expect(NotificationRoutes.pending.value, isNull, reason: reason);
      }
      NotificationRoutes.handle(tap(payload: 'open|friday'));
      expect(NotificationRoutes.pending.value, 'friday');
    });
  });

  group('NotificationService', () {
    late int launchReads;
    late Map<String, Object?>? launch;
    late List<MethodCall> calls;

    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      launchReads = 0;
      launch = null;
      calls = [];
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/Istanbul',
      );
      messenger.setMockMethodCallHandler(notifChannel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'getNotificationAppLaunchDetails':
            launchReads++;
            return launch;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(notifChannel, null);
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        null,
      );
    });

    // Süreç başına bir kez okunur: bu dosyada init'i ilk çağıran test
    test('uygulamayı bildirim açtıysa hedef bir kez okunur', () async {
      launch = {
        'notificationLaunchedApp': true,
        'notificationResponse': {
          'notificationId': 2400,
          'actionId': null,
          'input': null,
          'payload': 'open|friday',
          'notificationResponseType': 0,
        },
      };
      await NotificationService().init();
      expect(launchReads, 1);
      expect(NotificationRoutes.pending.value, 'friday');

      // Sonraki init (başka hizmet nesnesi) aynı bildirimi yeniden açmaz
      NotificationRoutes.pending.value = null;
      await NotificationService().init();
      expect(launchReads, 1);
      expect(NotificationRoutes.pending.value, isNull);
    });

    test('açık uygulamada dokunuş: gövde ve düğme hedefe yazılır, "Kıldım" '
        'yükü yazılmaz; arka plan işleyicisi yerinde', () async {
      await NotificationService().init();
      final init = calls.firstWhere((c) => c.method == 'initialize');
      expect(init.arguments['dispatcher_handle'], isNotNull);
      expect(init.arguments['callback_handle'], isNotNull);

      Future<void> platformTap(String? actionId, String? payload) =>
          messenger.handlePlatformMessage(
            notifChannel.name,
            notifChannel.codec.encodeMethodCall(
              MethodCall('didReceiveNotificationResponse', {
                'notificationId': 2400,
                'actionId': actionId,
                'input': null,
                'payload': payload,
                'notificationResponseType': actionId == null ? 0 : 1,
              }),
            ),
            (_) {},
          );
      await platformTap(null, prayed);
      expect(NotificationRoutes.pending.value, isNull);
      await platformTap(null, 'open|friday');
      expect(NotificationRoutes.pending.value, 'friday');
      await platformTap(PrayerRefreshService.fridayKehfRoute, 'open|friday');
      expect(NotificationRoutes.pending.value, 'surah:18');
    });
  });

  group('MainWrapper', () {
    // Uygulama boyu önbelleklenen Future'lar gerçek zaman bölgesinde dolsun
    // (sahte zamanda oluşanlar sonraki testlerde tamamlanmaz)
    setUpAll(() async {
      await rootBundle.loadString(QuranService.surahsAsset);
      await DiniGunlerService.loadResmiGunler();
      await rootBundle.loadString('assets/data/friday_messages_tr.json');
    });

    setUp(() {
      FeatureTip.debugReset();
      AdConsent.debugReset();
      debugResetPermissionPriming();
      // Eklentiler (reklam, bildirim, cihaz kanalı): "başarılı, null"
      messenger.allMessagesHandler = (channel, handler, message) {
        if (handler != null) return handler(message);
        if (channel.startsWith('flutter/')) {
          return messenger.delegate.send(channel, message);
        }
        if (channel.startsWith('dev.flutter.pigeon.')) {
          return Future.value(
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
        }
        return Future.value(
          const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      };
    });

    tearDown(() => messenger.allMessagesHandler = null);

    // Açılış akışı beklemeden biter (tur görülmüş, izinler tamam, Yenilikler
    // görülmüş)
    const returning = <String, Object>{
      tourSeenKey: false,
      permissionsPrimedKey: true,
      WhatsNew.seenKey: WhatsNew.version,
    };

    Future<void> settle(WidgetTester tester) async {
      for (var round = 0; round < 2; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    Future<void> pumpApp(
      WidgetTester tester, {
      Map<String, Object> prefs = returning,
    }) async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'tr',
        'is_language_selected': true,
        ...prefs,
      });
      tester.view.physicalSize = const Size(411 * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final vm = _FakeHomeViewModel()
        ..city = 'Ankara'
        ..isLoading = false
        ..prayerTimes = PrayerTimesModel(
          imsak: '05:35',
          gunes: '07:00',
          ogle: '12:57',
          ikindi: '16:08',
          aksam: '18:43',
          yatsi: '20:02',
        );
      await tester.pumpWidget(
        MultiProvider(
          key: UniqueKey(),
          providers: [
            ChangeNotifierProvider<HomeViewModel>(
              create: (_) => vm,
              lazy: false,
            ),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ZikirViewModel()),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShowCaseWidget(
              onFinish: () {},
              builder: (context) => const MainWrapper(),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('uygulamayı açan Cuma bildirimi: açılış akışı bitince Cuma '
        'mesajları açılır; geçiş reklamı ya da reklam açıklaması yok', (
      tester,
    ) async {
      final ads = AdHelper.instance.debugShowRequests;
      NotificationRoutes.pending.value = 'friday';
      await pumpApp(tester);
      expect(find.byType(FridayMessagesView), findsOneWidget);
      expect(NotificationRoutes.pending.value, isNull);
      expect(AdHelper.instance.debugShowRequests, ads);
      expect(find.text(tr.adInfoTitle), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('Yenilikler açıkken beklenir, kapanınca açılır', (
      tester,
    ) async {
      NotificationRoutes.pending.value = 'friday';
      await pumpApp(tester, prefs: {...returning, WhatsNew.seenKey: '1.2.0'});
      expect(find.text(tr.whatsNewTitle), findsOneWidget);
      expect(find.byType(FridayMessagesView), findsNothing);
      expect(NotificationRoutes.pending.value, 'friday');

      await tester.tap(find.text(tr.tipGotIt));
      await settle(tester);
      expect(find.text(tr.whatsNewTitle), findsNothing);
      expect(find.byType(FridayMessagesView), findsOneWidget);
      await finish(tester);
    });

    testWidgets('tanıtım turu sürerken beklenir, tur bitince açılır', (
      tester,
    ) async {
      await pumpApp(tester, prefs: const {});
      final tour = ShowcaseView.get();
      expect(tour.isShowcaseRunning, isTrue);
      NotificationRoutes.pending.value = 'friday';
      await settle(tester);
      expect(find.byType(FridayMessagesView), findsNothing);

      for (var i = 0; i < 10 && tour.isShowcaseRunning; i++) {
        tour.next();
        await settle(tester);
      }
      expect(tour.isShowcaseRunning, isFalse);
      await settle(tester); // saniyede bir yeniden denenir
      expect(find.byType(FridayMessagesView), findsOneWidget);
      await finish(tester);
    });

    testWidgets('açık uygulamada dokunuş hemen açar: Kehf okuyucuda (kaldığın '
        'yer saklanmaz); bilinmeyen hedef yok sayılır', (tester) async {
      await pumpApp(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      NotificationRoutes.pending.value = 'surah:18';
      await settle(tester);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect(reader.surah.number, 18);
      expect(reader.trackLastRead, isFalse);
      expect(NotificationRoutes.pending.value, isNull);

      navigator.pop();
      await settle(tester);
      expect(find.byType(SurahReaderView), findsNothing);
      NotificationRoutes.pending.value = 'bilinmeyen';
      await settle(tester);
      expect(NotificationRoutes.pending.value, isNull);
      expect(navigator.canPop(), isFalse);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });
}
