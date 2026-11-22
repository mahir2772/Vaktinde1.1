// Uygulama içi yazı boyutu (Ayarlar > Görünüm Ayarları): seçim kaydedilir,
// açılışta ve yedekten dönünce okunur (seçenek dışı kayıt → Normal);
// MaterialApp.builder Normal'de sistem ölçeğine dokunmaz (Android 14 doğrusal
// olmayan ölçek), diğerlerinde sistem × seçim, toplam en çok %200; paylaşılan
// resim ölçeksiz kalır; Görünüm penceresinde seçim hemen uygulanır.
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:ezan_saati/main.dart' show MyApp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeViewModel extends HomeViewModel {
  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> refreshEndReminders() async {}
}

// Sayfa geçişi, alt sayfa ve kayıt okuması
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final loc = lookupAppLocalizations(const Locale('tr'));

  group('kayıt', () {
    test('varsayılan Normal; seçim yazılır, yeniden açılışta okunur', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await pumpEventQueue();
      expect(provider.textScale, 1.0);

      await provider.setTextScale(1.3);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble(ThemeProvider.textScaleKey), 1.3);
      final reopened = ThemeProvider();
      await pumpEventQueue();
      expect(reopened.textScale, 1.3);
    });

    test('seçenek dışı kayıt Normal; yedekten dönüşte kayıttan okunur', () async {
      SharedPreferences.setMockInitialValues({ThemeProvider.textScaleKey: 1.7});
      final provider = ThemeProvider();
      await pumpEventQueue();
      expect(provider.textScale, 1.0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(ThemeProvider.textScaleKey, 1.15);
      await provider.reload();
      expect(provider.textScale, 1.15);
      // Yedekte yoksa geri yükleme kaydı siler: Normal
      await prefs.remove(ThemeProvider.textScaleKey);
      await provider.reload();
      expect(provider.textScale, 1.0);
    });
  });

  late ThemeProvider theme;

  // Dil seçilmemiş: ilk sayfa dil seçimi (MainWrapper'sız hafif ağaç)
  Future<void> pumpApp(
    WidgetTester tester, {
    required double system,
    double choice = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({
      ThemeProvider.textScaleKey: choice,
    });
    tester.platformDispatcher.textScaleFactorTestValue = system;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    theme = ThemeProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) => _FakeHomeViewModel(),
            lazy: false,
          ),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => theme),
        ],
        child: const MyApp(),
      ),
    );
    await _settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  TextScaler scalerOf(WidgetTester tester, Finder finder) =>
      MediaQuery.textScalerOf(tester.element(finder));

  group('MaterialApp.builder', () {
    final page = find.byType(OnboardingLanguageView);

    // (sistem, seçim, beklenen); null: sistem ölçeği aynen kalır
    const cases = <(double, double, double?)>[
      (1.0, 1.0, null),
      (1.3, 1.0, null),
      (1.0, 1.15, 1.15),
      (1.0, 1.3, 1.3),
      (1.3, 1.3, 1.69),
      (1.8, 1.3, 2.0), // en çok %200
      (2.0, 1.15, null), // sistem zaten en büyükte
    ];
    for (final (system, choice, expected) in cases) {
      testWidgets('sistem ×$system, seçim ×$choice → '
          '${expected == null ? 'sistem ölçeği' : 'doğrusal ×$expected'}', (
        tester,
      ) async {
        await pumpApp(tester, system: system, choice: choice);
        final scaler = scalerOf(tester, page);
        if (expected == null) {
          expect(scaler, isA<SystemTextScaler>());
          expect(scaler.scale(10), closeTo(10 * system, 1e-9));
        } else {
          for (final size in [10.0, 44.0]) {
            expect(scaler.scale(size), closeTo(size * expected, 1e-9));
          }
        }
        await finish(tester);
      });
    }

    testWidgets('paylaşılan resim ölçeksiz', (tester) async {
      final temp = Directory.systemTemp.createTempSync('vaktinde_scale');
      addTearDown(() => temp.deleteSync(recursive: true));
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      const share = MethodChannel('dev.fluttercommunity.plus/share');
      messenger.setMockMethodCallHandler(pathProvider, (_) async => temp.path);
      messenger.setMockMethodCallHandler(
        share,
        (_) async => 'dev.fluttercommunity.plus/share/success',
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(pathProvider, null);
        messenger.setMockMethodCallHandler(share, null);
      });
      await pumpApp(tester, system: 1.3, choice: 1.3);
      expect(scalerOf(tester, page).scale(10), closeTo(16.9, 1e-9));

      TextScaler? card;
      var done = false;
      shareAsImage(
        tester.element(page),
        title: 'Başlık',
        message: 'Mesaj',
        campaign: 'friday',
      ).then((_) => done = true);
      // Kart çizimi ve PNG gerçek zaman ister
      for (var i = 0; i < 100 && !done; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        final shown = find.byType(ShareCard);
        if (shown.evaluate().isNotEmpty) card ??= scalerOf(tester, shown);
      }
      expect(done, isTrue);
      expect(card, TextScaler.noScaling);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });

  testWidgets('Görünüm Ayarları: Yazı Boyutu seçimi kaydedilir ve hemen '
      'uygulanır (pencere de büyür); Normal sistem ölçeğine döner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, system: 1.0);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
    await _settle(tester);
    await tester.tap(find.text(loc.appearanceSettings));
    await _settle(tester);

    final title = find.text(loc.textSizeTitle);
    bool selected(String label) => find
        .descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(AppListTile),
          ),
          matching: find.byIcon(Icons.radio_button_checked),
        )
        .evaluate()
        .isNotEmpty;
    Future<void> choose(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(title, findsOneWidget);
    expect(selected(loc.textSizeNormal), isTrue);

    await choose(loc.textSizeExtraLarge);
    expect(theme.textScale, 1.3);
    expect(selected(loc.textSizeExtraLarge), isTrue);
    expect(selected(loc.textSizeNormal), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(ThemeProvider.textScaleKey), 1.3);
    // Pencere ve arkadaki sayfa yeni ölçekle çizilir
    expect(scalerOf(tester, title).scale(10), closeTo(13, 1e-9));
    expect(
      scalerOf(tester, find.byType(SettingsView)).scale(10),
      closeTo(13, 1e-9),
    );

    await choose(loc.textSizeLarge);
    expect(theme.textScale, 1.15);
    expect(scalerOf(tester, title).scale(10), closeTo(11.5, 1e-9));

    await choose(loc.textSizeNormal);
    expect(theme.textScale, 1.0);
    expect(scalerOf(tester, title), isA<SystemTextScaler>());
    expect(prefs.getDouble(ThemeProvider.textScaleKey), 1.0);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
