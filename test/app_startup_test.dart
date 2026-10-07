import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

// Uygulama düzeyi: açılış sırası (tur / izin / pil), reklam rızası (UMP),
// Ayarlar'daki reklam gizlilik satırı, fotoğraf üstünde bölüm başlığı,
// alt menü etiketleri.

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
  });

  group('Ayarlar: reklam gizlilik satırı', () {
    for (final required in [true, false]) {
      testWidgets('UMP gerekli=$required', (tester) async {
        AdConsent.privacyOptionsRequired.value = required;
        await pumpApp(tester, const SettingsView());
        final loc = lookupAppLocalizations(const Locale('tr'));
        await tester.scrollUntilVisible(
          find.text(required ? loc.adPrivacySettings : loc.contactUs),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 300));
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

  group('Alt menü etiketleri tek satır', () {
    for (final lang in ['tr', 'de', 'fr', 'ar']) {
      testWidgets('$lang 320dp %130', (tester) async {
        final loc = lookupAppLocalizations(Locale(lang));
        final labels = [
          loc.navPrayer,
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
