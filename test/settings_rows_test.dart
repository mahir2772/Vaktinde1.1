// Ayarlar: kısa üst liste (anahtar yok); Bildirim Ayarları sayfası ("Ezan
// Alarmları" ana ekranın Alarmlar sekmesini açar; "Günün ayeti ve hadisi
// bildirimi", "Dini gün ve kandil", "Kalıcı bildirim" ve "Özel günde ezanı
// sessiz bildir" anahtarları); Gizlilik ve Reklamlar sayfası (gizlilik
// politikası satırı adres boşken gizli, doluyken dış tarayıcıda açılır; reklam
// gizlilik satırı UMP zorunlu kılınca, Ayarlar'daki alt yazı da bunu söyler);
// "Ana ekrana widget ekle" (başlatıcı destekliyorsa), "Uygulamayı paylaş"
// (kaynaklı link); 320dp'de %130 ve %200 yazıda taşma yok
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/common/widgets/ad_banner_widget.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/notification_health/view/notification_health_view.dart';
import 'package:ezan_saati/features/settings/view/add_widget_sheet.dart';
import 'package:ezan_saati/features/settings/view/notification_settings_view.dart';
import 'package:ezan_saati/features/settings/view/privacy_ads_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeViewModel extends HomeViewModel {
  final List<bool> dailyToggles = [];
  final List<bool> persistentToggles = [];
  int reschedules = 0;

  @override
  Future<void> rescheduleAlarms() async {
    reschedules++;
  }

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

  @override
  Future<void> setPersistentNotificationEnabled(bool value) async {
    persistentToggles.add(value);
    persistentNotificationEnabled = value;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
  const homeWidget = MethodChannel('home_widget');
  const share = MethodChannel('dev.fluttercommunity.plus/share');
  final loc = lookupAppLocalizations(const Locale('tr'));
  late List<MethodCall> launches;
  late List<MethodCall> pinRequests;
  late List<MethodCall> shares;

  setUp(() {
    launches = [];
    pinRequests = [];
    shares = [];
    messenger.setMockMethodCallHandler(urlLauncher, (call) async {
      launches.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(share, (call) async {
      shares.add(call);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(urlLauncher, null);
    messenger.setMockMethodCallHandler(homeWidget, null);
    messenger.setMockMethodCallHandler(share, null);
    SettingsView.privacyPolicyUrl = AppLinks.privacyPolicy;
    AdConsent.privacyOptionsRequired.value = false;
  });

  // Başlatıcının widget ekleme desteği (Android 8+ ve başlatıcıya bağlı)
  void mockPinSupport(bool supported) {
    messenger.setMockMethodCallHandler(homeWidget, (call) async {
      switch (call.method) {
        case 'isRequestPinWidgetSupported':
          return supported;
        case 'requestPinWidget':
          pinRequests.add(call);
          return null;
        default:
          return null;
      }
    });
  }

  Future<_FakeHomeViewModel> pumpSettings(
    WidgetTester tester, {
    Widget home = const SettingsView(),
    String lang = 'tr',
    double width = 411,
    double height = 891,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      'language_code': lang,
      'is_language_selected': true,
    });
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
          locale: Locale(lang),
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
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

  // Alt sayfa açılış/kapanış animasyonu
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Satırın açtığı sayfaya geçer (Bildirim Ayarları, Gizlilik ve Reklamlar)
  Future<void> open(WidgetTester tester, String title) async {
    await scrollTo(tester, title);
    await tester.tap(find.text(title));
    await settle(tester);
  }

  // Ekrandaki sıra (üstten alta)
  List<double> topsOf(WidgetTester tester, List<String> texts) => [
    for (final text in texts) tester.getTopLeft(find.text(text)).dy,
  ];

  testWidgets('Ayarlar: kısa liste, anahtar yok; bildirim anahtarları ve '
      'gizlilik/reklam satırları alt sayfalarda', (tester) async {
    mockPinSupport(true);
    // Uzun ekran: listenin tamamı çizilir
    await pumpSettings(tester, height: 2400);
    final tops = topsOf(tester, [
      loc.sectionAppearance,
      loc.changeLanguage,
      loc.appearanceSettings,
      loc.addWidgetTitle,
      loc.sectionLocation,
      loc.changeLocation,
      loc.timeAdjustTitle,
      loc.sectionNotifications,
      loc.notificationSettingsTitle,
      loc.healthTitle,
      loc.sectionBackup,
      loc.sectionSupport,
      loc.appGuideTitle,
      loc.shareApp,
      loc.rateApp,
      loc.contactUs,
      loc.privacyAdsTitle,
    ]);
    expect(tops, [...tops]..sort());
    expect(find.text(loc.appearanceSub), findsOneWidget);
    expect(find.text(loc.notificationSettingsSub), findsOneWidget);
    expect(find.text(loc.privacyAdsSub), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    for (final moved in [
      loc.endReminderTitle,
      loc.dailyContentNotifTitle,
      loc.religiousDaysNotifTitle,
      loc.excusedSilentEzanTitle,
      loc.persistentNotifTitle,
      loc.privacyPolicy,
      loc.aboutAds,
      loc.adPrivacySettings,
    ]) {
      expect(find.text(moved), findsNothing, reason: moved);
    }
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Bildirim Ayarları: Ezan Alarmları başta, anahtarlar sırayla, '
      'reklamsız; Ezan Alarmları ana ekranın Alarmlar sekmesini açar', (
    tester,
  ) async {
    await pumpSettings(tester, height: 1600);
    await open(tester, loc.notificationSettingsTitle);
    expect(find.byType(NotificationSettingsView), findsOneWidget);
    expect(find.text(loc.ezanAlarmsSub), findsOneWidget);
    final tops = topsOf(tester, [
      loc.ezanAlarmsTitle,
      loc.endReminderTitle,
      loc.dailyContentNotifTitle,
      loc.religiousDaysNotifTitle,
      loc.fridayNotifTitle,
      loc.excusedSilentEzanTitle,
      loc.persistentNotifTitle,
    ]);
    expect(tops, [...tops]..sort());
    expect(find.byType(Switch), findsNWidgets(6));
    expect(find.byType(AdBannerWidget), findsNothing);

    // Dini gün ve kandil: varsayılan açık, satıra dokununca kapanır
    await tester.tap(find.text(loc.religiousDaysNotifTitle));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(StorageService.religiousDaysEnabledKey), isFalse);

    // Sayfalar kapanır (ilk sayfaya dönülür), HomeView Alarmlar'a geçer
    final requests = HomeView.alarmsTabRequests.value;
    await tester.tap(find.text(loc.ezanAlarmsTitle));
    await settle(tester);
    expect(HomeView.alarmsTabRequests.value, requests + 1);
    expect(find.byType(NotificationSettingsView), findsNothing);
    expect(find.byType(SettingsView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Bildirim Ayarları: %200 yazıda liste sonu gezinme çubuğunun '
      'üstünde (uçtan uca, banner yok)', (tester) async {
    // Uçtan uca: 48 dp gezinme çubuğu
    tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
    await pumpSettings(
      tester,
      home: const NotificationSettingsView(),
      textScale: 2,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await settle(tester);
    expect(
      tester.getRect(find.text(loc.persistentNotifSub)).bottom,
      lessThanOrEqualTo(891 - 48),
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Günün ayeti ve hadisi: anahtar ayarı gösterir ve değiştirir', (
    tester,
  ) async {
    final vm = await pumpSettings(tester);
    await open(tester, loc.notificationSettingsTitle);
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

  testWidgets('Kalıcı bildirim: anahtar ayarı gösterir ve değiştirir', (
    tester,
  ) async {
    final vm = await pumpSettings(tester);
    await open(tester, loc.notificationSettingsTitle);
    await scrollTo(tester, loc.persistentNotifTitle);
    expect(find.text(loc.persistentNotifSub), findsOneWidget);
    Switch toggle() => tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(loc.persistentNotifTitle),
          matching: find.byType(AppListTile),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(toggle().value, isFalse);

    await tester.tap(find.byWidget(toggle()));
    await tester.pump();
    expect(vm.persistentToggles, [true]);
    expect(toggle().value, isTrue);

    await tester.tap(find.text(loc.persistentNotifTitle));
    await tester.pump();
    expect(vm.persistentToggles, [true, false]);
    expect(toggle().value, isFalse);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Özel günde ezanı sessiz bildir: varsayılan açık; değişince '
      'kaydedilir ve alarmlar yeniden kurulur', (tester) async {
    final vm = await pumpSettings(tester);
    await open(tester, loc.notificationSettingsTitle);
    await scrollTo(tester, loc.excusedSilentEzanTitle);
    expect(find.text(loc.excusedSilentEzanSub), findsOneWidget);
    Switch toggle() => tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(loc.excusedSilentEzanTitle),
          matching: find.byType(AppListTile),
        ),
        matching: find.byType(Switch),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(toggle().value, isTrue);

    await tester.tap(find.byWidget(toggle()));
    await tester.pump();
    expect(toggle().value, isFalse);
    expect(prefs.getBool(StorageService.excusedSilentEzanKey), isFalse);
    expect(vm.reschedules, 1);

    await tester.tap(find.text(loc.excusedSilentEzanTitle));
    await tester.pump();
    expect(toggle().value, isTrue);
    expect(prefs.getBool(StorageService.excusedSilentEzanKey), isTrue);
    expect(vm.reschedules, 2);
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
    await open(tester, loc.privacyAdsTitle);
    expect(find.byType(PrivacyAdsView), findsOneWidget);
    expect(find.text(loc.aboutAds), findsOneWidget);
    expect(find.text(loc.privacyPolicy), findsNothing);
    expect(find.byIcon(Icons.policy_outlined), findsNothing);
    await finish(tester);
  });

  testWidgets('Gizlilik politikası: adres verilince satır görünür, dış '
      'tarayıcıda açılır', (tester) async {
    const url = 'https://example.com/gizlilik';
    SettingsView.privacyPolicyUrl = url;
    await pumpSettings(tester);
    await open(tester, loc.privacyAdsTitle);
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

  for (final required in [false, true]) {
    testWidgets('Gizlilik ve Reklamlar: UMP gerekli=$required → Ayarlar alt '
        'yazısı ve reklam gizlilik satırı; sayfa reklamsız', (tester) async {
      AdConsent.privacyOptionsRequired.value = required;
      await pumpSettings(tester);
      await scrollTo(tester, loc.privacyAdsTitle);
      expect(
        find.text(loc.privacyAdsConsentSub),
        required ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(loc.privacyAdsSub),
        required ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.text(loc.privacyAdsTitle));
      await settle(tester);
      final rows = [
        loc.privacyPolicy,
        loc.aboutAds,
        if (required) loc.adPrivacySettings,
      ];
      final tops = topsOf(tester, rows);
      expect(tops, [...tops]..sort());
      expect(
        find.text(loc.adPrivacySettings),
        required ? findsOneWidget : findsNothing,
      );
      expect(find.byType(AdBannerWidget), findsNothing);

      // Rıza durumu sonradan değişirse satır da değişir
      AdConsent.privacyOptionsRequired.value = !required;
      await tester.pump();
      expect(
        find.text(loc.adPrivacySettings),
        required ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }

  // Yaşlı kullanıcı: küçük telefon + büyük sistem yazısı. Sayfalar uzun ekranda
  // tamamen çizilir (her satırın yerleşimi denetlenir); Görünüm penceresi gerçek
  // boyda
  for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
    testWidgets('$lang 320dp: Ayarlar, alt sayfalar ve Görünüm penceresi %130 '
        've %200 yazıda taşmaz', (tester) async {
      mockPinSupport(true);
      AdConsent.privacyOptionsRequired.value = true;
      final l = lookupAppLocalizations(Locale(lang));
      for (final scale in [1.3, 2.0]) {
        for (final page in const [
          SettingsView(),
          NotificationSettingsView(),
          PrivacyAdsView(),
        ]) {
          await pumpSettings(
            tester,
            home: page,
            lang: lang,
            width: 320,
            height: 4000,
            textScale: scale,
          );
          expect(tester.takeException(), isNull, reason: '$page %$scale');
          await finish(tester);
        }
        await pumpSettings(
          tester,
          lang: lang,
          width: 320,
          height: 640,
          textScale: scale,
        );
        await tester.tap(find.text(l.appearanceSettings));
        await settle(tester);
        expect(find.text(l.textSizeTitle), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'görünüm %$scale');
        await finish(tester);
      }
    });
  }

  testWidgets('Ana ekrana widget ekle: destekleniyorsa satır görünür; seçilen '
      'widget başlatıcıdan istenir, sayfa gezinme çubuğunun üstünde', (
    tester,
  ) async {
    mockPinSupport(true);
    // Uçtan uca: 48 dp gezinme çubuğu
    tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
    await pumpSettings(tester);
    expect(find.text(loc.addWidgetSub), findsOneWidget);
    await tester.tap(find.text(loc.addWidgetTitle));
    await settle(tester);

    expect(find.text(loc.addWidgetHint), findsOneWidget);
    for (final item in HomeScreenWidget.values) {
      expect(find.text(item.title(loc)), findsOneWidget);
      expect(find.text(item.description(loc)), findsOneWidget);
    }
    // Liste ekrandan uzun olabilir: sona kaydırınca son satır çubuğun üstünde
    final last = HomeScreenWidget.values.last.description(loc);
    await tester.drag(find.text(loc.addWidgetHint), const Offset(0, -600));
    await settle(tester);
    expect(tester.getRect(find.text(last)).bottom, lessThanOrEqualTo(891 - 48));

    await tester.tap(find.text(loc.widgetLargeName));
    await settle(tester);
    expect(find.text(loc.addWidgetHint), findsNothing);
    expect(pinRequests, hasLength(1));
    expect(
      pinRequests.single.arguments['qualifiedAndroidName'],
      'com.mmdigital.vaktinde.VaktindeWidgetLargeProvider',
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Ana ekrana widget ekle: başlatıcı desteklemiyorsa ya da '
      'eklenti yoksa satır yok', (tester) async {
    mockPinSupport(false);
    await pumpSettings(tester);
    expect(find.text(loc.changeLanguage), findsOneWidget);
    expect(find.text(loc.addWidgetTitle), findsNothing);
    await finish(tester);

    messenger.setMockMethodCallHandler(homeWidget, null);
    await pumpSettings(tester);
    expect(find.text(loc.changeLanguage), findsOneWidget);
    expect(find.text(loc.addWidgetTitle), findsNothing);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  test('Widget sağlayıcıları manifest\'tekilerle aynı (ad değişirse '
      'ekleme sessizce olmaz)', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final providers = <String>{
      for (final receiver in manifest.split('<receiver').skip(1))
        if (receiver.contains('android.appwidget.provider'))
          RegExp(r'android:name="([\w.]+)"').firstMatch(receiver)![1]!,
    }.map((n) => n.startsWith('.') ? 'com.mmdigital.vaktinde$n' : n).toSet();
    expect(providers, hasLength(6));
    expect(
      HomeScreenWidget.values.map((w) => w.qualifiedAndroidName).toSet(),
      providers,
    );
  });

  testWidgets('Uygulamayı paylaş: davet metni kaynak takipli Play linkiyle', (
    tester,
  ) async {
    await pumpSettings(tester);
    await scrollTo(tester, loc.shareApp);
    await tester.tap(find.text(loc.shareApp));
    await tester.pump();
    expect(shares, hasLength(1));
    expect(shares.single.method, 'share');
    const link =
        'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde'
        '&referrer=utm_source%3Dapp_share%26utm_campaign%3Dinvite';
    expect(shares.single.arguments['text'], loc.shareText(link));
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
