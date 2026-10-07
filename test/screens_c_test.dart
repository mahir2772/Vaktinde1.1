// Kıble, Zikirmatik, Ayarlar, konum arama ve dil seçimi ekranları:
// tr/de/ar, açık/koyu, 320dp genişlik ve %130 yazıda hatasız çizilmeli;
// temel etkileşimler ve kıble açısı hesabı.
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/location_search_dialog/location_search_dialog.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/qibla/qibla_math.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/settings/view/time_adjust_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/dhikr_list_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/dhikr_stats_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_settings_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _istanbulLat = 41.0082;
const double _istanbulLng = 28.9784;

class _FakeHomeViewModel extends HomeViewModel {
  String? changedCity;
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
  Future<void> applyTimeOffsets() async {}

  @override
  Future<void> changeCityAndDistrict(
    String newCity,
    String? newDistrict, {
    double? lat,
    double? lng,
  }) async {
    changedCity = newDistrict == null ? newCity : '$newDistrict, $newCity';
  }
}

class _FakeGeocoding extends GeocodingPlatform {
  bool fail = false;

  @override
  Future<List<Location>> locationFromAddress(String address) async {
    if (fail) throw PlatformException(code: 'IO_ERROR');
    return [
      Location(latitude: 40.99, longitude: 29.03, timestamp: DateTime(2026)),
    ];
  }

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return const [
      Placemark(
        name: 'Kadıköy',
        isoCountryCode: 'TR',
        country: 'Türkiye',
        administrativeArea: 'İstanbul',
        subAdministrativeArea: 'Kadıköy',
        locality: 'Kadıköy',
      ),
    ];
  }
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var any = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    any = true;
  }
  if (any) await loader.load();
}

/// Gerçek yazı tipleri: taşma denetimi cihazdaki genişliklerle yapılır
Future<void> _loadFonts() async {
  await _loadFont('Poppins', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/google_fonts/Poppins-$w.ttf',
  ]);
  await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
}

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Konum servisi/izni ve pusula sahte yanıtları
bool _locationServiceEnabled = true;
int _locationPermission = 2; // whileInUse
double? _compassAccuracy = 5;
bool _compassEmits = true;
int _permissionRequests = 0;

void _mockPlatform() {
  _messenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/geolocator'),
    (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return _locationServiceEnabled;
        case 'checkPermission':
          return _locationPermission;
        case 'requestPermission':
          // Kullanıcı sistem penceresinde izin verir
          _permissionRequests++;
          _locationPermission = 2;
          return _locationPermission;
        case 'getLastKnownPosition':
        case 'getCurrentPosition':
          return {
            'latitude': _istanbulLat,
            'longitude': _istanbulLng,
            'timestamp': DateTime(2026).millisecondsSinceEpoch,
            'accuracy': 10.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
          };
        default:
          return null;
      }
    },
  );
  _messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async => {
      'appName': 'Vaktinde',
      'packageName': 'com.mmdigital.vaktinde',
      'version': '1.1.0',
      'buildNumber': '14',
    },
  );
  // Titreşim/ses gibi sistem çağrıları sessizce kabul edilir
  _messenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
  _messenger.setMockStreamHandler(
    const EventChannel('hemanthraj/flutter_compass'),
    MockStreamHandler.inline(
      onListen: (args, sink) {
        if (_compassEmits) {
          sink.success([120.0, 120.0, _compassAccuracy ?? -1.0]);
        }
      },
    ),
  );
  // Diğer eklenti kanalları (reklam, ses, ekran açık...) "başarılı, null"
  _messenger.allMessagesHandler = (channel, handler, message) {
    if (handler != null) return handler(message);
    if (channel.startsWith('flutter/')) {
      return _messenger.delegate.send(channel, message);
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
}

Map<String, Object> _prefs(
  String lang, {
  Map<String, Object> extra = const {},
  Set<String> without = const {},
}) {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return {
    'language_code': lang,
    'is_language_selected': true,
    'saved_city': 'İstanbul',
    'saved_district': 'Kadıköy',
    'saved_lat': _istanbulLat,
    'saved_lng': _istanbulLng,
    'time_offsets': '{"İmsak":-30,"Öğle":30}',
    'selected_dhikr': 'Hz. Yunus',
    'dhikr_count_Hz. Yunus': 1234567,
    'dhikr_target_Hz. Yunus': 1000,
    'custom_dhikrs_list': [
      'Ya Vedûd',
      'Çok uzun bir özel zikir adı: Sübhanallahi ve bihamdihi sübhanallahil azim',
    ],
    'dhikr_daily_stats': '{"$today": 123456}',
    ...extra,
  }..removeWhere((key, value) => without.contains(key));
}

Future<void> _settle(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Sahte eklenti olayları (pusula) gerçek olay döngüsüyle iletilir
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Ekranı gerçek sağlayıcılar ve temayla, açılmış bir sayfa olarak çizer
Future<_FakeHomeViewModel> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  String lang = 'tr',
  bool dark = false,
  double width = 320,
  double height = 640,
  double textScale = 1.3,
  Map<String, Object> prefs = const {},
  Set<String> without = const {},
}) async {
  SharedPreferences.setMockInitialValues(
    _prefs(lang, extra: prefs, without: without),
  );
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final homeVm = _FakeHomeViewModel()
    ..city = 'İstanbul'
    ..district = 'Kadıköy';
  await tester.pumpWidget(
    MultiProvider(
      key: UniqueKey(),
      providers: [
        // lazy: false → okunmasa da ağaçla birlikte kapatılır (zamanlayıcı)
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => homeVm,
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ZikirViewModel()),
      ],
      child: MaterialApp(
        locale: Locale(lang),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
  await tester.pump();
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
  await _settle(tester);
  return homeVm;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

AppLocalizations _loc(String lang) => lookupAppLocalizations(Locale(lang));

/// Sekmeli sayfada dikey listenin kaydırıcısı
Finder _listScrollable() => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    _locationServiceEnabled = true;
    _locationPermission = 2;
    _compassAccuracy = 5;
    _compassEmits = true;
    _permissionRequests = 0;
    _mockPlatform();
  });

  tearDown(() {
    _messenger.allMessagesHandler = null;
    _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('Kıble hesabı', () {
    test('İstanbul ≈ 151–152°', () {
      expect(
        qiblaBearing(_istanbulLat, _istanbulLng),
        inInclusiveRange(151, 152),
      );
    });

    test('Cakarta ≈ 295°, Berlin ≈ 136°', () {
      expect(qiblaBearing(-6.2088, 106.8456), inInclusiveRange(294, 296));
      expect(qiblaBearing(52.52, 13.405), inInclusiveRange(135, 137));
    });

    test('Açı farkı ve dönüş yönü', () {
      expect(normalizeDegrees(-170), 190);
      expect(signedDelta(350, 10), 20);
      expect(signedDelta(10, 350), -20);
      expect(qiblaTurnFor(150, 152), QiblaTurn.aligned);
      expect(qiblaTurnFor(140, 152), QiblaTurn.slightRight);
      expect(qiblaTurnFor(120, 152), QiblaTurn.right);
      expect(qiblaTurnFor(160, 152), QiblaTurn.slightLeft);
      expect(qiblaTurnFor(-170, 152), QiblaTurn.left);
    });
  });

  // Her ekran: 320x640 dp, %130 yazı, tr/de/ar, açık/koyu
  final screens = <String, Widget>{
    'kıble': const QiblaView(),
    'zikirmatik': const ZikirView(),
    'zikir listesi': const DhikrListView(),
    'istatistik': const DhikrStatsView(),
    'zikir ayarları': const ZikirSettingsView(),
    'ayarlar': const SettingsView(),
    'ince ayar': const TimeAdjustView(),
    'konum arama': const Scaffold(body: LocationSearchDialog()),
    'dil seçimi': const OnboardingLanguageView(),
  };
  for (final lang in ['tr', 'de', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$lang ${dark ? 'koyu' : 'açık'}: ekranlar 320dp %130 hatasız',
        (tester) async {
          for (final entry in screens.entries) {
            await _pumpScreen(tester, entry.value, lang: lang, dark: dark);
            expect(tester.takeException(), isNull, reason: entry.key);
          }
          // İkinci sekmeler ve klasik tesbih
          await _pumpScreen(
            tester,
            const DhikrListView(),
            lang: lang,
            dark: dark,
          );
          await tester.tap(find.text(_loc(lang).esmaulHusnaTab));
          await _settle(tester);
          expect(tester.takeException(), isNull, reason: 'esma');
          await _pumpScreen(
            tester,
            const DhikrStatsView(),
            lang: lang,
            dark: dark,
          );
          await tester.tap(find.text(_loc(lang).yearly));
          await _settle(tester);
          expect(tester.takeException(), isNull, reason: 'yıllık');
          // Hedefe ulaşıldı (modern ve klasik)
          await _pumpScreen(
            tester,
            const ZikirView(),
            lang: lang,
            dark: dark,
            prefs: {'dhikr_count_Hz. Yunus': 2000},
          );
          expect(tester.takeException(), isNull, reason: 'hedef');
          await _pumpScreen(
            tester,
            const ZikirView(),
            lang: lang,
            dark: dark,
            prefs: {'zikir_view_mode': 1, 'dhikr_count_Hz. Yunus': 2000},
          );
          expect(tester.takeException(), isNull, reason: 'klasik tesbih');
          await _finish(tester);
        },
      );
    }
  }

  group('Kıble', () {
    testWidgets('GPS: kıble açısı ve telefon yönü ayrı', (tester) async {
      await _pumpScreen(tester, const QiblaView(), textScale: 1);
      final loc = _loc('tr');
      expect(find.textContaining('152°'), findsWidgets);
      expect(find.textContaining('120°'), findsOneWidget);
      expect(find.text(loc.qiblaTurnRight), findsOneWidget);
      expect(find.text(loc.usingSavedLocation), findsNothing);
      await _finish(tester);
    });

    testWidgets('GPS kapalı: kayıtlı konum kullanılır', (tester) async {
      _locationServiceEnabled = false;
      await _pumpScreen(tester, const QiblaView(), lang: 'de');
      final loc = _loc('de');
      expect(find.text(loc.usingSavedLocation), findsOneWidget);
      expect(find.textContaining('152°'), findsWidgets);
      await _finish(tester);
    });

    testWidgets('Konum yok: hata ve tekrar dene', (tester) async {
      _locationPermission = 0; // denied
      await _pumpScreen(
        tester,
        const QiblaView(),
        without: {'saved_lat', 'saved_lng'},
      );
      final loc = _loc('tr');
      expect(find.text(loc.locationPermissionDenied), findsOneWidget);
      expect(find.text(loc.retry), findsOneWidget);
      // İzin verilince tekrar dene ile açı gelir
      _locationPermission = 2;
      await tester.tap(find.text(loc.retry));
      await _settle(tester);
      expect(find.textContaining('152°'), findsWidgets);
      await _finish(tester);
    });

    testWidgets('Pusula yoksa noCompass, açı yine görünür', (tester) async {
      _compassEmits = false;
      await _pumpScreen(tester, const QiblaView(), lang: 'ar');
      await tester.pump(const Duration(seconds: 5));
      final loc = _loc('ar');
      expect(find.text(loc.noCompass), findsOneWidget);
      expect(find.textContaining('152°'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('Zayıf kalibrasyon: pencere sadece ilk sefer', (tester) async {
      _compassAccuracy = null;
      await _pumpScreen(tester, const QiblaView());
      final loc = _loc('tr');
      expect(find.text(loc.calibrationRequired), findsOneWidget);
      await tester.tap(find.text(loc.okUnderstood));
      await _settle(tester);
      expect(find.text(loc.calibrationRequired), findsNothing);
      // Tek uyarı: ipucu kartının yerine geçer
      expect(find.text(loc.lowAccuracyWarning), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('qibla_calibration_dialog_seen'), isTrue);
      await _finish(tester);
    });
  });

  group('Zikirmatik', () {
    testWidgets('Dokun, düzenle, hedef, sıfırla (onaylı)', (tester) async {
      await _pumpScreen(
        tester,
        const ZikirView(),
        textScale: 1,
        prefs: {
          'selected_dhikr': 'Sübhanallah',
          'dhikr_count_Sübhanallah': 27,
          'dhikr_target_Sübhanallah': 33,
        },
      );
      final loc = _loc('tr');
      ZikirViewModel vm() =>
          tester.element(find.byType(ZikirView)).read<ZikirViewModel>();
      expect(vm().count, 27);
      expect(find.text(loc.targetCount(33)), findsOneWidget);

      await tester.tap(find.byType(TabularText));
      await _settle(tester, steps: 3);
      expect(vm().count, 28);

      // Görünür düzenle düğmesi
      await tester.tap(find.text(loc.editCounterTitle));
      await _settle(tester, steps: 4);
      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.text(loc.save));
      await _settle(tester, steps: 4);
      expect(vm().count, 500);

      // Hedef
      await tester.tap(find.text(loc.targetCount(33)));
      await _settle(tester, steps: 4);
      expect(find.text(loc.setTarget), findsOneWidget);
      await tester.enterText(find.byType(TextField), '99');
      await tester.tap(find.text(loc.save));
      await _settle(tester, steps: 4);
      expect(vm().target, 99);

      // Sıfırla: vazgeçince sayı kalır, onaylayınca sıfırlanır
      await tester.tap(find.text(loc.resetCounter));
      await _settle(tester, steps: 4);
      expect(find.text(loc.resetCounterConfirm), findsOneWidget);
      await tester.tap(find.text(loc.cancel));
      await _settle(tester, steps: 4);
      expect(vm().count, 500);
      await tester.tap(find.text(loc.resetCounter));
      await _settle(tester, steps: 4);
      await tester.tap(find.text(loc.resetCounter).last);
      await _settle(tester, steps: 4);
      expect(vm().count, 0);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('Uzun basınca sayaç düzenleme açılır', (tester) async {
      await _pumpScreen(tester, const ZikirView(), textScale: 1);
      final loc = _loc('tr');
      await tester.longPress(find.byType(TabularText));
      await _settle(tester, steps: 4);
      expect(find.text(loc.editCounterTitle), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('Liste: uzun Arapça düzgün, özel zikir boş/sil', (
      tester,
    ) async {
      await _pumpScreen(tester, const DhikrListView(), lang: 'ar');
      expect(tester.takeException(), isNull);
      // Uzun Arapça (Hz. Yunus) ekranda, kartın içinde satır kırarak
      final yunus = find.textContaining('سُبْحَانَكَ');
      await tester.scrollUntilVisible(
        yunus,
        200,
        scrollable: _listScrollable(),
      );
      expect(yunus, findsOneWidget);
      expect(tester.getSize(yunus).width, lessThanOrEqualTo(320));
      await _finish(tester);

      await _pumpScreen(
        tester,
        const DhikrListView(),
        prefs: {
          'custom_dhikrs_list': <String>['Ya Vedûd'],
        },
      );
      final loc = _loc('tr');
      // Listenin sonuna (alt boşluk sayesinde son kart FAB'ın üstünde kalır)
      await tester.drag(_listScrollable(), const Offset(0, -3000));
      await _settle(tester, steps: 4);
      expect(find.text('Ya Vedûd'), findsOneWidget);
      await tester.tap(find.byTooltip(loc.deleteDhikr));
      await _settle(tester, steps: 4);
      await tester.tap(find.text(loc.deleteDhikr).last);
      await _settle(tester, steps: 4);
      expect(find.text('Ya Vedûd'), findsNothing);
      expect(find.text(loc.noCustomDhikr), findsOneWidget);
      expect(find.text(loc.statsEmpty), findsNothing);
      await _finish(tester);
    });
  });

  group('Ayarlar', () {
    testWidgets('Gerçek sürüm, dil seçimi, görünüm', (tester) async {
      await _pumpScreen(tester, const SettingsView(), textScale: 1);
      final loc = _loc('tr');
      await tester.scrollUntilVisible(
        find.text(loc.versionLabel('1.1.0 (14)')),
        200,
      );
      expect(find.text(loc.versionLabel('1.1.0 (14)')), findsOneWidget);
      expect(find.text(loc.madeBy), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await _settle(tester, steps: 4);
      expect(find.text('Türkçe'), findsOneWidget); // geçerli dil alt yazıda
      await tester.tap(find.text(loc.changeLanguage));
      await _settle(tester, steps: 6);
      await tester.tap(find.text('Deutsch'));
      await _settle(tester, steps: 6);
      final language = tester
          .element(find.byType(SettingsView))
          .read<LanguageProvider>();
      expect(language.locale.languageCode, 'de');

      // Uygulama dili testte sabit (MaterialApp.locale); görünüm penceresi
      await tester.tap(find.text(loc.appearanceSettings));
      await _settle(tester, steps: 6);
      await tester.tap(find.text(loc.themeDark));
      await _settle(tester, steps: 4);
      final theme = tester
          .element(find.byType(SettingsView))
          .read<ThemeProvider>();
      expect(theme.themeMode, ThemeMode.dark);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  });

  group('Konum arama', () {
    testWidgets('Sonuç seçilir; hata ekranında tekrar dene', (tester) async {
      final geocoding = _FakeGeocoding();
      GeocodingPlatform.instance = geocoding;
      final homeVm = await _pumpScreen(
        tester,
        const Scaffold(body: LocationSearchDialog()),
        textScale: 1,
      );
      final loc = _loc('tr');
      expect(find.text(loc.searchInitial), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Kadıköy');
      await tester.pump(const Duration(milliseconds: 900));
      await _settle(tester, steps: 3);
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Kadıköy, İstanbul'),
                    matching: find.byType(InkWell),
                  )
                  .first,
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Kadıköy, İstanbul'));
      await _settle(tester, steps: 4);
      expect(homeVm.changedCity, 'Kadıköy, İstanbul');
      await _finish(tester);

      geocoding.fail = true;
      await _pumpScreen(
        tester,
        const Scaffold(body: LocationSearchDialog()),
        lang: 'de',
      );
      final de = _loc('de');
      await tester.enterText(find.byType(TextField), 'Berlin');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester, steps: 3);
      expect(find.text(de.searchError), findsOneWidget);
      geocoding.fail = false;
      await tester.tap(find.text(de.retry));
      await _settle(tester, steps: 3);
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  });

  group('İlk açılış', () {
    testWidgets('Diller yazıyla; izinlerden önce açıklama', (tester) async {
      final homeVm = await _pumpScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Expanded(child: OnboardingLanguageView()),
                TextButton(
                  onPressed: () => requestPermissionsWithPriming(context),
                  child: const Text('izinler'),
                ),
              ],
            ),
          ),
        ),
        textScale: 1,
        height: 900,
        prefs: {'is_language_selected': false},
      );
      final loc = _loc('tr');
      for (final name in [
        'Türkçe',
        'English',
        'Deutsch',
        'Français',
        'العربية',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text(loc.onboardingWelcome), findsOneWidget);

      _locationPermission = 0; // henüz sorulmadı
      await tester.tap(find.text('izinler'));
      await _settle(tester, steps: 4);
      expect(find.text(loc.permissionPrimingTitle), findsOneWidget);
      expect(_permissionRequests, 0); // sistem penceresi açıklamadan sonra
      await tester.tap(find.text(loc.continueAction));
      await _settle(tester, steps: 4);
      expect(_permissionRequests, 1);
      expect(homeVm.refreshedLocation, isTrue);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  });
}
