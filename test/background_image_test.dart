// Arka plan görseli: eski sürümlerin kayıtları (1.0 .jpg adları, kaldırılan
// bg_quran) açılışta düzeltilir; görsel yüklenemezse hata bildirilmez
// (Crashlytics "Unable to load asset"), ekran arka plansız çizilir.
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:ezan_saati/main.dart' show MyApp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Görsel istekleri cihazdaki eksik varlık gibi düşer, diğerleri gerçek
class _MissingImagesBundle extends CachingAssetBundle {
  final List<String> failed = [];

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/images/')) {
      failed.add(key);
      throw FlutterError('Unable to load asset: "$key".');
    }
    return rootBundle.load(key);
  }
}

/// MaterialApp.builder'daki arka plan görseli
final _background = find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName.startsWith(
        'assets/images/backgrounds/',
      ),
);

class _FakeHomeViewModel extends HomeViewModel {
  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> refreshEndReminders() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Varlık yüklemesi gerçek zamanda tamamlanır
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Kayıtlı arka plan', () {
    test('eski .jpg → .webp, kaldırılan ve bozuk adlar → arka plansız', () {
      expect(ThemeProvider.validBackground('bg_kaaba1.jpg'), 'bg_kaaba1.webp');
      expect(
        ThemeProvider.validBackground('bg_mosque6.jpg'),
        'bg_mosque6.webp',
      );
      expect(
        ThemeProvider.validBackground('bg_mosque3.webp'),
        'bg_mosque3.webp',
      );
      for (final name in [
        'bg_quran.jpg', // 1.0
        'bg_quran.webp', // 1.1.0'da seçilebiliyordu, dosyası hiç olmadı
        'bg_mosque7.webp',
        'bg_kaaba1.png',
        'BG_KAABA1.WEBP',
        '../bg_kaaba1.webp',
        'bg_kaaba1.jpg.jpg',
        '.jpg',
        '',
        'çöp',
      ]) {
        expect(ThemeProvider.validBackground(name), isNull, reason: name);
      }
      expect(ThemeProvider.validBackground(null), isNull);
    });

    test('Ayarlar\'daki her seçenek pakette var', () {
      for (final name in [
        ...ThemeProvider.mosqueBackgrounds,
        ...ThemeProvider.kaabaBackgrounds,
      ]) {
        expect(
          File('assets/images/backgrounds/$name').existsSync(),
          isTrue,
          reason: name,
        );
      }
    });

    const cases = <String?, String?>{
      'bg_kaaba1.jpg': 'bg_kaaba1.webp',
      'bg_mosque4.jpg': 'bg_mosque4.webp',
      'bg_quran.jpg': null,
      'bg_quran.webp': null,
      'bg_mosque2.webp': 'bg_mosque2.webp',
      'çöp': null,
      null: null,
    };
    for (final MapEntry(key: saved, value: expected) in cases.entries) {
      test('açılış: $saved → $expected (kayıtta da)', () async {
        SharedPreferences.setMockInitialValues({'background_image': ?saved});
        final provider = ThemeProvider();
        await pumpEventQueue();
        expect(provider.backgroundImage, expected);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('background_image'), expected);
        expect(prefs.containsKey('background_image'), expected != null);
      });
    }
  });

  testWidgets('görsel yüklenemezse hata bildirilmez, arka plansız çizilir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'background_image': 'bg_quran.jpg',
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await settle(tester);
    final themeProvider = tester
        .element(find.byType(MaterialApp))
        .read<ThemeProvider>();
    expect(themeProvider.backgroundImage, isNull);
    expect(_background, findsNothing);

    // Doğrulamadan geçmeyen ad çizilse bile: hata yok, yüzey rengi
    await themeProvider.setBackgroundImage('bg_yok.webp');
    await settle(tester);
    expect(_background, findsOneWidget);
    expect(tester.takeException(), isNull);
    final fallback = find.descendant(
      of: _background,
      matching: find.byType(ColoredBox),
    );
    expect(fallback, findsOneWidget);
    final scheme = Theme.of(tester.element(fallback)).colorScheme;
    expect(tester.widget<ColoredBox>(fallback).color, scheme.surface);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ayarlar küçük resimleri yüklenemezse hata bildirilmez', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bundle = _MissingImagesBundle();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeViewModel>(
              create: (_) => _FakeHomeViewModel(),
              lazy: false,
            ),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsView(),
          ),
        ),
      ),
    );
    await settle(tester);
    final loc = lookupAppLocalizations(const Locale('tr'));
    await tester.tap(find.text(loc.appearanceSettings));
    await settle(tester);
    expect(find.text(loc.bgImage), findsOneWidget);
    expect(
      bundle.failed,
      contains('assets/images/backgrounds/bg_mosque1.webp'),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
