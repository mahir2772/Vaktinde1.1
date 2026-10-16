import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/app_guide/whats_new.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/app_analytics.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/common/widgets/ad_banner_widget.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/features/settings/view/notification_settings_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

// Uygulama düzeyi: açılış sırası (tur / izin / pil) ve ilk açılış hunisi
// olayları, reklam rızası (UMP),
// Ayarlar > Gizlilik ve Reklamlar'daki reklam gizlilik satırı, Ayarlar >
// Bildirim Ayarları'ndan Alarmlar sekmesi, fotoğraf üstünde bölüm başlığı,
// alt menü (5 sekme, Kur'an sekmesi, tanıtım turu) ve etiketleri.

class _FakeHomeViewModel extends HomeViewModel {
  int batteryRequests = 0;
  bool refreshedLocation = false;

  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshLocationAndTimes(BuildContext context) async {
    refreshedLocation = true;
  }

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> requestBatteryOptimizationOnce() async {
    batteryRequests++;
  }
}

const _umpChannel = 'plugins.flutter.io/google_mobile_ads/ump';
const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Ana ekranın "Bugün için" kartı uygulama boyu önbelleklenen dosyaları okur:
  // gerçek zaman bölgesinde dolsunlar (sahte zamanda oluşan Future sonraki
  // testlerde hiç tamamlanmaz)
  setUpAll(() async {
    await rootBundle.loadString(QuranService.surahsAsset);
    await DiniGunlerService.loadResmiGunler();
  });

  // UMP sahte yanıtları
  var umpCanRequestAds = true;
  var umpPrivacyStatus = 1; // 1 = gerekli
  final umpCalls = <String>[];
  var umpFails = false;
  // Konum izni: 0 = reddedildi, 2 = kullanırken
  var locationPermission = 0;
  var locationRequests = 0;

  setUp(() {
    umpCanRequestAds = true;
    umpPrivacyStatus = 1;
    umpCalls.clear();
    locationPermission = 0;
    locationRequests = 0;
    AdConsent.debugReset();
    debugResetPermissionPriming();
    umpFails = false;
    // UMP kanalı özel codec kullanır (istek parametreleri); sadece yöntem adı
    // okunur, yanıtlar (bool/int/null) standart codec ile aynı kodlanır
    messenger.setMockMessageHandler(_umpChannel, (message) async {
      final method =
          const StandardMessageCodec().readValue(ReadBuffer(message!))
              as String;
      umpCalls.add(method);
      const codec = StandardMethodCodec();
      if (umpFails) return codec.encodeErrorEnvelope(code: 'x');
      return codec.encodeSuccessEnvelope(switch (method) {
        'ConsentInformation#canRequestAds' => umpCanRequestAds,
        'ConsentInformation#getPrivacyOptionsRequirementStatus' =>
          umpPrivacyStatus,
        _ => null,
      });
    });
    messenger.setMockMethodCallHandler(_geolocator, (call) async {
      switch (call.method) {
        case 'checkPermission':
          return locationPermission;
        case 'requestPermission':
          locationRequests++;
          return locationPermission;
        case 'isLocationServiceEnabled':
          return true;
        default:
          return null;
      }
    });
    // Reklam SDK'sı ve diğer eklentiler: "başarılı, null"
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => {
        'appName': 'Vaktinde',
        'packageName': 'com.mmdigital.vaktinde',
        'version': '1.1.0',
        'buildNumber': '14',
      },
    );
  });

  tearDown(() {
    AdConsent.isSupported = () => false;
    messenger.setMockMessageHandler(_umpChannel, null);
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      null,
    );
    for (final channel in [
      _geolocator,
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  group('Reklam rızası (UMP)', () {
    test('gizlilik girişi gerekliyse saklanır, reklamlar başlar', () async {
      AdConsent.isSupported = () => true;
      await AdConsent.gatherAndStartAds();
      expect(AdConsent.privacyOptionsRequired.value, isTrue);
      expect(AdConsent.canRequestAds.value, isTrue);
      expect(umpCalls, contains('ConsentInformation#requestConsentInfoUpdate'));
    });

    test('gerekli değilse Ayarlar satırı için false', () async {
      AdConsent.isSupported = () => true;
      umpPrivacyStatus = 0;
      await AdConsent.gatherAndStartAds();
      expect(AdConsent.privacyOptionsRequired.value, isFalse);
    });

    test('platform hatası çökertmez', () async {
      AdConsent.isSupported = () => true;
      umpFails = true;
      await AdConsent.gatherAndStartAds();
      expect(AdConsent.canRequestAds.value, isFalse);
      expect(AdConsent.privacyOptionsRequired.value, isFalse);
      await AdConsent.showPrivacyOptions();
    });

    test(
      'rıza geri çekilince yeni reklam istenmez, verilince bekleyen çalışır',
      () async {
        AdConsent.isSupported = () => true;
        await AdConsent.gatherAndStartAds();
        expect(AdConsent.canRequestAds.value, isTrue);

        umpCanRequestAds = false;
        await AdConsent.showPrivacyOptions();
        expect(
          umpCalls,
          contains('UserMessagingPlatform#showPrivacyOptionsForm'),
        );
        expect(AdConsent.canRequestAds.value, isFalse);

        var calls = 0;
        AdConsent.whenAdsStarted(() => calls++);
        expect(calls, 0); // sonsuz döngü yok, bekler

        umpCanRequestAds = true;
        await AdConsent.showPrivacyOptions();
        expect(AdConsent.canRequestAds.value, isTrue);
        expect(calls, 1);
      },
    );
  });

  Future<_FakeHomeViewModel> pumpApp(
    WidgetTester tester,
    Widget home, {
    String lang = 'tr',
    Map<String, Object> prefs = const {},
    bool backgroundImage = false,
    double width = 411,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      'language_code': lang,
      'is_language_selected': true,
      'theme_mode': 1,
      ...prefs,
    });
    tester.view.physicalSize = Size(width * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final vm = _FakeHomeViewModel()
      ..city = 'Ankara'
      ..district = 'Çankaya'
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
          ChangeNotifierProvider<HomeViewModel>(create: (_) => vm, lazy: false),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ZikirViewModel()),
        ],
        child: MaterialApp(
          locale: Locale(lang),
          theme: AppTheme.light(hasBackgroundImage: backgroundImage),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return vm;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Widget mainWrapper() => ShowCaseWidget(
    onFinish: () {},
    builder: (context) => const MainWrapper(),
  );

  group('Açılış sırası', () {
    final loc = lookupAppLocalizations(const Locale('tr'));

    testWidgets('ilk açılış: tur başlar, izin penceresi turla çakışmaz', (
      tester,
    ) async {
      final vm = await pumpApp(tester, mainWrapper());
      expect(find.text(loc.showcaseLanguage), findsOneWidget);
      expect(find.text(loc.permissionPrimingTitle), findsNothing);
      expect(vm.batteryRequests, 0);
      // Takip satırı kaydı yeniden okur (reload): değer depodan okunur
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool(tourSeenKey), isFalse);
      expect(prefs.getBool(permissionsPrimedKey), isNull);
      await finish(tester);
    });

    testWidgets(
      'tur yarıda kaldıysa sonraki açılışta izinler bir kez sorulur, sonra pil',
      (tester) async {
        final vm = await pumpApp(
          tester,
          mainWrapper(),
          prefs: {tourSeenKey: false},
        );
        expect(find.text(loc.showcaseLanguage), findsNothing);
        expect(find.text(loc.permissionPrimingTitle), findsOneWidget);
        expect(locationRequests, 0); // sistem penceresi açıklamadan sonra
        expect(vm.batteryRequests, 0); // pencereler üst üste binmez

        await tester.tap(find.text(loc.continueAction));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(loc.permissionPrimingTitle), findsNothing);
        expect(locationRequests, 1);
        expect(vm.batteryRequests, 1);
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        expect(prefs.getBool(permissionsPrimedKey), isTrue);

        // Aynı oturumda ikinci kez gösterilmez
        final context = tester.element(find.byType(MainWrapper));
        await primePermissionsIfNeeded(context);
        await tester.pump();
        expect(find.text(loc.permissionPrimingTitle), findsNothing);
        await finish(tester);
      },
    );

    testWidgets('izinler zaten verilmişse pencere yok, tamamlandı sayılır', (
      tester,
    ) async {
      locationPermission = 2;
      final vm = await pumpApp(
        tester,
        mainWrapper(),
        prefs: {tourSeenKey: false},
      );
      expect(find.text(loc.permissionPrimingTitle), findsNothing);
      expect(vm.batteryRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool(permissionsPrimedKey), isTrue);
      await finish(tester);
    });

    testWidgets('izin akışı tamamlanmışsa tekrar sorulmaz', (tester) async {
      final vm = await pumpApp(
        tester,
        mainWrapper(),
        prefs: {tourSeenKey: false, permissionsPrimedKey: true},
      );
      expect(find.text(loc.permissionPrimingTitle), findsNothing);
      expect(locationRequests, 0);
      expect(vm.batteryRequests, 1);
      await finish(tester);
    });

    testWidgets('sonraki açılışta elle seçilen şehir GPS ile ezilmez', (
      tester,
    ) async {
      final vm = await pumpApp(
        tester,
        mainWrapper(),
        prefs: {tourSeenKey: false},
      );
      locationPermission = 2; // pencerede izin verildi
      await tester.tap(find.text(loc.continueAction));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(vm.refreshedLocation, isFalse); // şehir: Ankara (elle)
      await finish(tester);
    });

    testWidgets('ilk açılış hunisi: dil → tur başladı/bitti → izin sonucu; her '
        'olay bir kez, konum/vakit yok', (tester) async {
      final events = <(String, Map<String, Object>?)>[];
      final originalSink = AppAnalytics.sink;
      AppAnalytics.sink = (name, parameters) async =>
          events.add((name, parameters));
      addTearDown(() => AppAnalytics.sink = originalSink);
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await pumpApp(tester, const OnboardingLanguageView());
      await tester.tap(find.text('Türkçe'));
      await settle();
      expect(events.map((e) => e.$1), ['dil_secildi', 'tur_basladi']);

      final view = ShowcaseView.get();
      for (var i = 0; i < 10 && view.isShowcaseRunning; i++) {
        view.next();
        await settle();
      }
      // Tur bitince izin akışı (bildirim sonucu sadece Android'de)
      await tester.tap(find.text(loc.continueAction));
      await settle();
      expect(events.map((e) => e.$1), [
        'dil_secildi',
        'tur_basladi',
        'tur_bitti',
        'konum_izni',
      ]);
      expect(events.last.$2, {'sonuc': 'reddedildi'});
      for (final (_, parameters) in events.take(3)) {
        expect(parameters, isNull);
      }

      // İzin akışı tamamlandı: sonuç yeniden gönderilmez
      await primePermissionsIfNeeded(tester.element(find.byType(MainWrapper)));
      await settle();
      expect(events, hasLength(4));
      await finish(tester);
    });
  });

  group('Ayarlar > Gizlilik ve Reklamlar: reklam gizlilik satırı', () {
    for (final required in [true, false]) {
      testWidgets('UMP gerekli=$required', (tester) async {
        AdConsent.privacyOptionsRequired.value = required;
        await pumpApp(tester, const SettingsView());
        final loc = lookupAppLocalizations(const Locale('tr'));
        await tester.scrollUntilVisible(
          find.text(loc.privacyAdsTitle),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 300));
        // Satırın alt yazısı ayarın orada olduğunu söyler
        expect(
          find.text(required ? loc.privacyAdsConsentSub : loc.privacyAdsSub),
          findsOneWidget,
        );
        await tester.tap(find.text(loc.privacyAdsTitle));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.text(loc.adPrivacySettings),
          required ? findsOneWidget : findsNothing,
        );
        if (required) {
          await tester.tap(find.text(loc.adPrivacySettings));
          await tester.pump();
          expect(
            umpCalls,
            contains('UserMessagingPlatform#showPrivacyOptionsForm'),
          );
        }
        expect(tester.takeException(), isNull);
        await finish(tester);
      });
    }
  });

  testWidgets('Alarmlar sekmesi isteği (Bildirim Kontrolü): başka sekmedeyken '
      'ana sayfa açılır, Alarmlar sekmesine geçilir', (tester) async {
    final loc = lookupAppLocalizations(const Locale('tr'));
    await pumpApp(
      tester,
      mainWrapper(),
      prefs: {
        tourSeenKey: false,
        permissionsPrimedKey: true,
        WhatsNew.seenKey: WhatsNew.version,
      },
    );
    int selected() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
    await tester.tap(find.text(loc.navTools));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(selected(), MainTab.tools.index);

    HomeView.openAlarmsTab();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(selected(), MainTab.home.index);
    expect(find.text(loc.ezanAlarmStreamTitle).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Ayarlar > Bildirim Ayarları > Ezan Alarmları: sayfalar kapanır, '
      'ana sayfanın Alarmlar sekmesi açılır', (tester) async {
    final loc = lookupAppLocalizations(const Locale('tr'));
    await pumpApp(
      tester,
      mainWrapper(),
      prefs: {
        tourSeenKey: false,
        permissionsPrimedKey: true,
        WhatsNew.seenKey: WhatsNew.version,
      },
    );
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text(loc.navTools));
    await settle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
    await settle();
    await tester.scrollUntilVisible(
      find.text(loc.notificationSettingsTitle),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    await tester.tap(find.text(loc.notificationSettingsTitle));
    await settle();
    await tester.tap(find.text(loc.ezanAlarmsTitle));
    await settle();

    expect(find.byType(NotificationSettingsView), findsNothing);
    expect(find.byType(SettingsView), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      MainTab.home.index,
    );
    expect(find.text(loc.ezanAlarmStreamTitle).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Fotoğraf üstünde bölüm başlığı koyu kapsülde', (tester) async {
    for (final image in [false, true]) {
      await pumpApp(
        tester,
        const Scaffold(body: SectionHeader('Destek')),
        backgroundImage: image,
      );
      final pill = find.ancestor(
        of: find.text('Destek'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  PrayerColors.light.heroImageScrim,
        ),
      );
      expect(pill, image ? findsOneWidget : findsNothing);
      final text = tester.widget<Text>(find.text('Destek'));
      expect(
        text.style!.color,
        image ? PrayerColors.light.onHero : AppColors.lightPrimary,
      );
    }
    await finish(tester);
  });

  group('Alt menü: 5 sekme', () {
    setUpAll(() async {
      // Kur'an sekmesi listeyi rootBundle'dan okur: önbellek gerçek zaman
      // bölgesinde dolsun (sahte zamanda bekleyen Future kalmasın)
      await rootBundle.loadString(QuranService.surahsAsset);
    });

    // Sekmelerin diğer eklentileri (zikir sesi, ekran açık, titreşim):
    // "başarılı, null"
    setUp(() {
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

    Future<void> settle(WidgetTester tester) async {
      for (var round = 0; round < 2; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    int selected(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    testWidgets("Ana Sayfa · Kur'an · Kıble · Zikir · Araçlar; sekmeler ilk "
        "ziyarette kurulur, Kur'an listesi açılır, sekme geçişinde reklam yok", (
      tester,
    ) async {
      final loc = lookupAppLocalizations(const Locale('tr'));
      await pumpApp(
        tester,
        mainWrapper(),
        prefs: {
          tourSeenKey: false,
          permissionsPrimedKey: true,
          WhatsNew.seenKey: WhatsNew.version,
        },
      );
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(MainTab.values.length));
      expect(MainTab.values.length, 5);
      final labels = [
        loc.navPrayer,
        loc.navQuran,
        loc.navQibla,
        loc.navZikir,
        loc.navTools,
      ];
      final xs = [for (final l in labels) tester.getCenter(find.text(l)).dx];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(selected(tester), MainTab.home.index);
      // Açılışta sadece ana sayfa kurulur (pusula/konum ve Kur'an listesi yok)
      for (final type in [QuranView, QiblaView, ZikirView, ToolsView]) {
        expect(find.byType(type, skipOffstage: false), findsNothing);
      }
      final banners = find
          .byType(AdBannerWidget, skipOffstage: false)
          .evaluate()
          .length;
      final ads = AdHelper.instance.debugShowRequests;

      await tester.tap(find.text(loc.navQuran));
      await settle(tester);
      expect(selected(tester), MainTab.quran.index);
      expect(find.byType(QuranView), findsOneWidget);
      expect(find.text(loc.quranTitle), findsOneWidget);
      expect(find.text('Fâtiha'), findsOneWidget);
      // Tek banner (alt menünün): Kur'an sekmesi kendi banner'ını eklemez
      expect(
        find.descendant(
          of: find.byType(QuranView),
          matching: find.byType(AdBannerWidget, skipOffstage: false),
        ),
        findsNothing,
      );
      expect(
        find.byType(AdBannerWidget, skipOffstage: false).evaluate().length,
        banners,
      );
      expect(
        tester
            .widgetList<AdBannerWidget>(
              find.byType(AdBannerWidget, skipOffstage: false),
            )
            .map((b) => b.adUnitId),
        contains(AdIds.mainBanner),
      );

      // Sekmeler arasında gezinmek reklam göstermez; durum korunur
      for (final (label, tab) in [
        (loc.navQibla, MainTab.qibla),
        (loc.navZikir, MainTab.zikir),
        (loc.navTools, MainTab.tools),
        (loc.navPrayer, MainTab.home),
        (loc.navQuran, MainTab.quran),
      ]) {
        await tester.tap(find.text(label));
        await settle(tester);
        expect(selected(tester), tab.index);
      }
      expect(AdHelper.instance.debugShowRequests, ads);
      expect(find.byType(QuranView, skipOffstage: false), findsOneWidget);

      // Sure okuyucu alt menünün üstüne açılır (reklamsız)
      await tester.tap(find.text('Fâtiha'));
      await settle(tester);
      expect(find.byType(SurahReaderView), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(AdHelper.instance.debugShowRequests, ads);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets("tanıtım turu: dil, \"Bugün\" takibi, alarmlar; alt menüde "
        "Kur'an, Kıble, Zikir, Araçlar sırasıyla (en çok 8 adım)", (
      tester,
    ) async {
      final loc = lookupAppLocalizations(const Locale('tr'));
      await pumpApp(tester, mainWrapper());
      final view = ShowcaseView.get();
      expect(view.isShowcaseRunning, isTrue);
      final seen = <GlobalKey>[];
      for (var i = 0; i < 10 && view.isShowcaseRunning; i++) {
        final key = view.getActiveShowcaseKey!;
        seen.add(key);
        final text = {
          homeTrackerKey: loc.showcaseTracker,
          toolsKey: loc.showcaseTools,
        }[key];
        if (text != null) {
          // Hedefe kaydırma ve baloncuk animasyonu
          for (var j = 0; j < 10; j++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.text(text), findsOneWidget);
        }
        view.next();
        for (var j = 0; j < 5; j++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      expect(seen.first, homeLangKey);
      // Günün ayeti yüklenmediyse o adım atlanır, tur bitmez
      expect(seen, isNot(contains(homeStoryKey)));
      expect(
        seen,
        containsAllInOrder([
          homeLangKey,
          homeTrackerKey,
          homeAlarmsKey,
          quranKey,
          qiblaKey,
          zikirmatikKey,
          toolsKey,
        ]),
      );
      expect(seen.last, toolsKey);
      expect(seen.length, lessThanOrEqualTo(8));
      await finish(tester);
    });
  });

  group('Alt menü etiketleri tek satır', () {
    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      testWidgets('$lang 320dp %130', (tester) async {
        final loc = lookupAppLocalizations(Locale(lang));
        // 5 sekme: Ana Sayfa · Kur'an · Kıble · Zikir · Araçlar
        final labels = [
          loc.navPrayer,
          loc.navQuran,
          loc.navQibla,
          loc.navZikir,
          loc.navTools,
        ];
        await pumpApp(
          tester,
          Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: [
                for (final label in labels)
                  NavigationDestination(
                    icon: const Icon(Icons.home),
                    label: label,
                  ),
              ],
            ),
          ),
          lang: lang,
          width: 320,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        final heights = {
          for (final label in labels) tester.getSize(find.text(label)).height,
        };
        // Hepsi aynı (tek satır) yükseklikte: ikonlar hizalı
        expect(heights, hasLength(1));
        expect(heights.single, lessThan(13 * 1.3 * 1.6));
        await finish(tester);
      });
    }
  });
}
