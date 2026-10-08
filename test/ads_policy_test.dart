// Reklam: içerik sınırı (PG) reklam SDK'sı başlamadan verilir, hata açılışı
// bozmaz; Araçlar'dan Ayarlar geçiş reklamsız açılır.
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _umpChannel = 'plugins.flutter.io/google_mobile_ads/ump';
const _adsChannel = 'plugins.flutter.io/google_mobile_ads';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var canRequestAds = true;
  var failConfig = false;
  final adCalls = <MethodCall>[];

  setUp(() {
    canRequestAds = true;
    failConfig = false;
    adCalls.clear();
    AdConsent.debugReset();
    AdConsent.isSupported = () => true;
    // UMP kanalı özel codec kullanır: sadece yöntem adı okunur
    messenger.setMockMessageHandler(_umpChannel, (message) async {
      final method =
          const StandardMessageCodec().readValue(ReadBuffer(message!))
              as String;
      return const StandardMethodCodec().encodeSuccessEnvelope(switch (method) {
        'ConsentInformation#canRequestAds' => canRequestAds,
        'ConsentInformation#getPrivacyOptionsRequirementStatus' => 0,
        _ => null,
      });
    });
    messenger.setMockMessageHandler(_adsChannel, (message) async {
      const codec = StandardMethodCodec();
      final call = codec.decodeMethodCall(message);
      adCalls.add(call);
      if (failConfig && call.method == 'MobileAds#updateRequestConfiguration') {
        return codec.encodeErrorEnvelope(code: 'error');
      }
      return codec.encodeSuccessEnvelope(null);
    });
  });

  tearDown(() {
    AdConsent.isSupported = () => false;
    messenger.setMockMessageHandler(_umpChannel, null);
    messenger.setMockMessageHandler(_adsChannel, null);
  });

  List<String> methods() => [for (final c in adCalls) c.method];

  test('içerik sınırı PG, reklam SDK\'sı başlamadan önce verilir', () async {
    final run = AdConsent.gatherAndStartAds();
    expect(AdConsent.isGatheringConsent, isTrue);
    await run;
    expect(AdConsent.isGatheringConsent, isFalse);
    expect(AdConsent.canRequestAds.value, isTrue);

    final config = methods().indexOf('MobileAds#updateRequestConfiguration');
    expect(config, isNonNegative);
    expect(config, lessThan(methods().indexOf('MobileAds#initialize')));
    expect((adCalls[config].arguments as Map)['maxAdContentRating'], 'PG');
    // Bir kez: rıza güncellemesinden sonraki ikinci deneme yinelemez
    expect(
      methods().where((m) => m == 'MobileAds#updateRequestConfiguration'),
      hasLength(1),
    );
  });

  test('içerik sınırı ayarlanamazsa reklamlar yine başlar', () async {
    failConfig = true;
    await AdConsent.gatherAndStartAds();
    expect(methods(), contains('MobileAds#initialize'));
    expect(AdConsent.canRequestAds.value, isTrue);
  });

  test('rıza yoksa reklam SDK\'sına dokunulmaz', () async {
    canRequestAds = false;
    await AdConsent.gatherAndStartAds();
    expect(methods().where((m) => m.startsWith('MobileAds#')), isEmpty);
    expect(AdConsent.canRequestAds.value, isFalse);
  });

  testWidgets('Araçlar: Ayarlar reklamsız, araçlar geçiş reklamıyla açılır', (
    tester,
  ) async {
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
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ToolsView(),
        ),
      ),
    );
    await tester.pump();
    final loc = lookupAppLocalizations(const Locale('tr'));
    final ads = AdHelper.instance;
    final before = ads.debugShowRequests;

    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text(loc.menuTitle));
    await settle();
    expect(find.byType(SettingsView), findsOneWidget);
    expect(ads.debugShowRequests, before);

    Navigator.of(tester.element(find.byType(SettingsView))).pop();
    await settle();
    await tester.tap(find.text(loc.missedPrayersTitle));
    await tester.pump();
    expect(ads.debugShowRequests, before + 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
