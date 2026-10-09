// Ayarlar: "Günün ayeti ve hadisi bildirimi" anahtarı ve gizlilik politikası
// satırı (adres boşken gizli; doluyken dış tarayıcıda açılır)
import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/notification_health/view/notification_health_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeViewModel extends HomeViewModel {
  final List<bool> dailyToggles = [];

  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> setDailyContentEnabled(bool value) async {
    dailyToggles.add(value);
    dailyContentEnabled = value;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
  final loc = lookupAppLocalizations(const Locale('tr'));
  late List<MethodCall> launches;

  setUp(() {
    launches = [];
    messenger.setMockMethodCallHandler(urlLauncher, (call) async {
      launches.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(urlLauncher, null);
    SettingsView.privacyPolicyUrl = AppLinks.privacyPolicy;
  });

  Future<_FakeHomeViewModel> pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'language_code': 'tr',
      'is_language_selected': true,
    });
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final vm = _FakeHomeViewModel();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // lazy: false → ağaçla birlikte kapatılır (gece yarısı zamanlayıcısı)
          ChangeNotifierProvider<HomeViewModel>(create: (_) => vm, lazy: false),
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
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return vm;
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Günün ayeti ve hadisi: anahtar ayarı gösterir ve değiştirir', (
    tester,
  ) async {
    final vm = await pumpSettings(tester);
    await scrollTo(tester, loc.dailyContentNotifTitle);
    expect(find.text(loc.dailyContentNotifSub), findsOneWidget);
    Switch toggle() => tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(loc.dailyContentNotifTitle),
          matching: find.byType(AppListTile),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle().value, isTrue); // varsayılan açık

    await tester.tap(find.byWidget(toggle()));
    await tester.pump();
    expect(vm.dailyToggles, [false]);
    expect(toggle().value, isFalse);

    // Satırın kendisine dokunmak da değiştirir
    await tester.tap(find.text(loc.dailyContentNotifTitle));
    await tester.pump();
    expect(vm.dailyToggles, [false, true]);
    expect(toggle().value, isTrue);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Bildirim Kontrolü: tek satır ekranı açar; eski "Bildirim '
      'İzinleri" ve "Bildirim Gelmiyor mu?" satırları yok', (tester) async {
    await pumpSettings(tester);
    await scrollTo(tester, loc.healthTitle);
    expect(find.text(loc.healthSub), findsOneWidget);
    // Eski satırların metinleri ARB'den silindi; adlarıyla aranır
    expect(find.text('Bildirim İzinleri'), findsNothing);
    expect(find.text('Bildirim Gelmiyor mu?'), findsNothing);
    await tester.tap(find.text(loc.healthTitle));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NotificationHealthView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Gizlilik politikası: adres boşken satır yok', (tester) async {
    expect(SettingsView.privacyPolicyUrl, AppLinks.privacyPolicy);
    SettingsView.privacyPolicyUrl = '';
    await pumpSettings(tester);
    await scrollTo(tester, loc.contactUs);
    expect(find.text(loc.rateApp), findsOneWidget);
    expect(find.text(loc.privacyPolicy), findsNothing);
    expect(find.byIcon(Icons.policy_outlined), findsNothing);
    await finish(tester);
  });

  testWidgets('Gizlilik politikası: adres verilince satır görünür, dış '
      'tarayıcıda açılır', (tester) async {
    const url = 'https://example.com/gizlilik';
    SettingsView.privacyPolicyUrl = url;
    await pumpSettings(tester);
    await scrollTo(tester, loc.privacyPolicy);
    await tester.tap(find.text(loc.privacyPolicy));
    await tester.pump();
    expect(launches, hasLength(1));
    expect(launches.single.method, 'launch');
    expect(launches.single.arguments['url'], url);
    expect(launches.single.arguments['useWebView'], isFalse);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  test('Gizlilik politikası adresi boş ya da https', () {
    const url = AppLinks.privacyPolicy;
    expect(url.isEmpty || Uri.parse(url).scheme == 'https', isTrue);
  });
}
