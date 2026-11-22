// Reklamlar hakkında: ilk geçiş reklamı fırsatında reklam yerine bir kez
// açıklama (fırsat reklam molası sayılır: açıklama reklamla aynı dokunuşa
// bağlanmaz), sonraki fırsatta (soğumadan sonra) reklam; zekat reklamı da aynı
// kurala uyar; açılış penceresi açıkken ne açıklama ne reklam; Ayarlar >
// Destek > Gizlilik ve Reklamlar satırı reklamsız açar; metinlerde reklama
// tıklama/izleme/destek çağrısı yok; 320dp + büyük yazıda taşma yok, RTL, alt
// boşluk.
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/common/widgets/ad_info_sheet.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/zakat/view/zakat_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adsChannel = 'plugins.flutter.io/google_mobile_ads';

/// Yüklenmiş sayılan geçiş reklamı: gösterimler sayılır
class _FakeAd extends Fake implements InterstitialAd {
  int shows = 0;

  @override
  Future<void> show() async => shows++;

  @override
  Future<void> dispose() async {}
}

final _loc = lookupAppLocalizations(const Locale('tr'));

Future<void> _pumpApp(
  WidgetTester tester,
  Widget home, {
  String lang = 'tr',
  double width = 411,
  double height = 891,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

// Sayfa geçişi + alt sayfa animasyonu
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

// Soğuma geçmiş gibi: son reklam molası 4 dk önce
void _cooldownPassed() => AdHelper.instance.markInterstitialShown(
  DateTime.now().subtract(AdHelper.cooldown),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _FakeAd ad;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'language_code': 'tr',
      'is_language_selected': true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Vaktinde',
      packageName: 'com.mmdigital.vaktinde',
      version: '1.1.0',
      buildNumber: '15',
      buildSignature: '',
    );
    AdHelper.instance.debugReset();
    ad = _FakeAd();
  });

  tearDown(AdHelper.instance.debugReset);

  // Araçlar'dan geçiş reklamlı bir araç (Namaz Takibi) açılır
  Future<void> openTool(WidgetTester tester) async {
    final row = find.text(_loc.trackerTitle);
    await tester.scrollUntilVisible(row, 200);
    await tester.pump();
    await tester.tap(row);
    await _settle(tester);
    expect(find.byType(PrayerTrackerView), findsOneWidget);
  }

  Future<void> closeTool(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(PrayerTrackerView))).pop();
    await _settle(tester);
  }

  group('Geçiş reklamı fırsatı', () {
    testWidgets('ilk fırsatta reklam yerine açıklama (açılan ekranın üstünde); '
        'soğuma bitmeden hiçbir şey, sonra reklam; açıklama bir daha çıkmaz', (
      tester,
    ) async {
      final ads = AdHelper.instance..debugLoadedAd = ad;
      await _pumpApp(tester, const ToolsView());

      await openTool(tester);
      expect(find.text(_loc.adInfoTitle), findsOneWidget);
      expect(find.text(_loc.adInfoBody), findsOneWidget);
      expect(ad.shows, 0);
      // Fırsat reklam molası sayıldı; görüldü bilgisi kalıcı
      expect(ads.canShowInterstitial(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AdHelper.infoSeenKey), isTrue);

      // "Anladım" sadece kapatır: ardından reklam gelmez
      await tester.tap(find.text(_loc.adInfoGotIt));
      await _settle(tester);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      expect(find.byType(PrayerTrackerView), findsOneWidget);
      expect(ad.shows, 0);
      await closeTool(tester);

      // Soğuma sürerken: ne açıklama ne reklam
      await openTool(tester);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      expect(ad.shows, 0);
      await closeTool(tester);

      // Soğumadan sonraki fırsat: reklam, açıklama yok
      _cooldownPassed();
      await openTool(tester);
      expect(ad.shows, 1);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('açıklama önceki oturumda görüldüyse ilk fırsatta reklam', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'tr',
        'is_language_selected': true,
        AdHelper.infoSeenKey: true,
      });
      final ads = AdHelper.instance..debugLoadedAd = ad;
      await ads.restoreLog();
      await _pumpApp(tester, const ToolsView());

      await openTool(tester);
      expect(ad.shows, 1);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      await _finish(tester);
    });

    testWidgets('açılış penceresi (tur, izin, rıza formu) açıkken ne açıklama '
        'ne reklam; fırsat sonrakine kalır', (tester) async {
      final ads = AdHelper.instance..debugLoadedAd = ad;
      var windowOpen = true;
      ads.startupWindowOpen = () => windowOpen;
      await _pumpApp(tester, const ToolsView());

      await openTool(tester);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      expect(ad.shows, 0);
      expect(ads.canShowInterstitial(), isTrue); // mola başlamadı
      await closeTool(tester);

      windowOpen = false;
      await openTool(tester);
      expect(find.text(_loc.adInfoTitle), findsOneWidget);
      expect(ad.shows, 0);
      await _finish(tester);
    });

    testWidgets('zekat reklamı: ilk fırsatta açıklama, sonraki ziyarette '
        'soğumadan sonra reklam', (tester) async {
      // Banner da yüklenmeye çalışır: kanal sessizce kabul eder
      messenger.setMockMessageHandler(
        _adsChannel,
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
      AdConsent.canRequestAds.value = true;
      ZakatView.debugLoadedAd = ad;
      addTearDown(() {
        messenger.setMockMessageHandler(_adsChannel, null);
        AdConsent.debugReset();
        ZakatView.debugLoadedAd = null;
      });

      Future<void> calculate() async {
        final button = find.text(_loc.calculateButton);
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await _settle(tester);
      }

      await _pumpApp(tester, const ZakatView());
      await calculate();
      expect(find.text(_loc.adInfoTitle), findsOneWidget);
      expect(ad.shows, 0);
      await tester.tap(find.text(_loc.adInfoGotIt));
      await _settle(tester);
      expect(ad.shows, 0);
      // Aynı ziyarette yeniden hesap: reklam yok
      await calculate();
      expect(ad.shows, 0);
      expect(find.text(_loc.adInfoTitle), findsNothing);

      // Yeni ziyaret, soğuma bitti: reklam
      await _finish(tester);
      _cooldownPassed();
      await _pumpApp(tester, const ZakatView());
      await calculate();
      expect(ad.shows, 1);
      expect(find.text(_loc.adInfoTitle), findsNothing);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  });

  testWidgets('Ayarlar > Destek > Gizlilik ve Reklamlar: "Reklamlar Hakkında" '
      'açıklamayı reklamsız açar ve görüldü sayar', (tester) async {
    final ads = AdHelper.instance..debugLoadedAd = ad;
    final requests = ads.debugShowRequests;
    await _pumpApp(tester, const SettingsView());
    final page = find.text(_loc.privacyAdsTitle);
    await tester.scrollUntilVisible(
      page,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(page);
    await _settle(tester);
    expect(ads.debugShowRequests, requests);
    await tester.tap(find.text(_loc.aboutAds));
    await _settle(tester);
    expect(find.text(_loc.adInfoTitle), findsOneWidget);
    expect(ad.shows, 0);
    expect(ads.debugShowRequests, requests);
    expect(ads.canShowInterstitial(), isTrue); // reklam molası değil
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AdHelper.infoSeenKey), isTrue);
    await tester.tap(find.text(_loc.adInfoGotIt));
    await _settle(tester);
    expect(find.text(_loc.adInfoTitle), findsNothing);
    await _finish(tester);
  });

  test('metinler: reklama tıklama/izleme/destek çağrısı ya da vaat yok; '
      '"reklam yok" değil "tam ekran reklam yok"', () {
    // Dil başına yasak kökler (küçük harfle aranır)
    const banned = {
      'tr': ['tıkla', 'izle', 'destek', 'dokun', 'reklamlara bak', 'ödül'],
      'en': ['click', 'tap', 'watch', 'view', 'support', 'reward'],
      'de': ['klick', 'tipp', 'anseh', 'schau', 'unterstütz', 'belohn'],
      'fr': ['cliqu', 'appuy', 'regard', 'visionn', 'souten', 'soutien'],
      'ar': ['انقر', 'اضغط', 'شاهد', 'مشاهدة', 'دعم', 'مكافأة'],
    };
    const fullScreen = {
      'tr': 'tam ekran',
      'en': 'full-screen',
      'de': 'vollbild',
      'fr': 'plein écran',
      'ar': 'بملء الشاشة',
    };
    for (final MapEntry(key: lang, value: roots) in banned.entries) {
      final loc = lookupAppLocalizations(Locale(lang));
      final texts = [
        loc.aboutAds,
        loc.adInfoTitle,
        loc.adInfoBody,
        loc.adInfoGotIt,
        loc.privacyAdsTitle,
        loc.privacyAdsSub,
        loc.privacyAdsConsentSub,
      ];
      for (final text in texts) {
        expect(text.trim(), isNotEmpty, reason: lang);
        for (final root in roots) {
          expect(
            text.toLowerCase(),
            isNot(contains(root)),
            reason: '$lang: "$root"',
          );
        }
      }
      expect(
        loc.adInfoBody.toLowerCase(),
        contains(fullScreen[lang]),
        reason: lang,
      );
    }
  });

  group('Alt sayfa yerleşimi', () {
    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      for (final scale in [1.3, 2.0]) {
        testWidgets('$lang, %${(scale * 100).round()} yazı, 320dp: taşma yok, '
            'düğme gezinme çubuğunun üstünde', (tester) async {
          // Uçtan uca: alt 48dp gezinme çubuğu
          tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
          await _pumpApp(
            tester,
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showAdInfoSheet(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
            lang: lang,
            width: 320,
            height: 640,
            textScale: scale,
          );
          await tester.tap(find.text('open'));
          await _settle(tester);
          final loc = lookupAppLocalizations(Locale(lang));
          final title = find.text(loc.adInfoTitle);
          expect(title, findsOneWidget);
          expect(
            Directionality.of(tester.element(title)),
            lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          final button = find.widgetWithText(FilledButton, loc.adInfoGotIt);
          await tester.dragUntilVisible(
            button,
            find.byType(SingleChildScrollView),
            const Offset(0, -200),
          );
          await tester.pump();
          expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(640 - 48));
          expect(tester.takeException(), isNull);
          await tester.tap(button);
          await _settle(tester);
          expect(title, findsNothing);
          await _finish(tester);
        });
      }
    }
  });
}
