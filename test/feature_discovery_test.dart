// Özellik keşfi: bağlamsal ipuçları (kurulum başına bir kez, aynı anda tek,
// açılış pencerelerinden sonra), "Yenilikler" (güncellemede bir kez, yeni
// kurulumda yok; satırlar ilgili ekranı açar), "Uygulamayı Tanı" (Ayarlar
// satırı, satırların açtığı ekranlar, turu tekrar izle) ve 320dp %130 yazıda
// tr/de/ar taşma.
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/location_catalog.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/app_guide/view/app_guide_view.dart';
import 'package:ezan_saati/features/app_guide/whats_new.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/duas/view/duas_view.dart';
import 'package:ezan_saati/features/esmaul_husna/view/esmaul_husna_view.dart';
import 'package:ezan_saati/features/fitre/view/fitre_view.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/home/widgets/alarm_settings_list.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/imsakiye/view/imsakiye_view.dart';
import 'package:ezan_saati/features/location_search_dialog/location_search_dialog.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/notification_health/view/notification_health_view.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/prayer_guide/prayer_guide_data.dart';
import 'package:ezan_saati/features/prayer_guide/view/prayer_guide_view.dart';
import 'package:ezan_saati/features/prayer_tracker/streak_review.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/religious_days/view/religious_days_view.dart';
import 'package:ezan_saati/features/settings/view/notification_settings_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/settings/view/time_adjust_view.dart';
import 'package:ezan_saati/features/zakat/view/zakat_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:ezan_saati/features/stories/view/stories_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const homeWidget = MethodChannel('home_widget');
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
  final tr = lookupAppLocalizations(const Locale('tr'));

  var pinSupported = true;
  final pinRequests = <MethodCall>[];
  final launches = <MethodCall>[];

  // Uygulama boyu önbelleklenen Future'lar gerçek zaman bölgesinde dolsun
  // (sahte zamanda oluşanlar sonraki testlerde tamamlanmaz)
  setUpAll(() async {
    await rootBundle.loadString(QuranService.surahsAsset);
    await DiniGunlerService.loadResmiGunler();
    await loadRamadanCalendar();
    await PrayerGuide.load();
    await DuaLibrary.load();
    await LocationCatalog.load();
    for (final name in ['esmaul_husna_tr', 'friday_messages_tr']) {
      await rootBundle.loadString('assets/data/$name.json');
    }
  });

  setUp(() {
    FeatureTip.debugReset();
    AdConsent.debugReset();
    debugResetPermissionPriming();
    pinSupported = true;
    pinRequests.clear();
    launches.clear();
    messenger.setMockMethodCallHandler(homeWidget, (call) async {
      switch (call.method) {
        case 'isRequestPinWidgetSupported':
          return pinSupported;
        case 'requestPinWidget':
          pinRequests.add(call);
          return null;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(urlLauncher, (call) async {
      launches.add(call);
      return true;
    });
    // Diğer eklentiler (reklam, cihaz kanalı, titreşim): "başarılı, null"
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

  tearDown(() {
    messenger.allMessagesHandler = null;
    messenger.setMockMethodCallHandler(homeWidget, null);
    messenger.setMockMethodCallHandler(urlLauncher, null);
  });

  Future<_FakeHomeViewModel> pumpApp(
    WidgetTester tester,
    Widget home, {
    String lang = 'tr',
    Map<String, Object> prefs = const {},
    double width = 411,
    double height = 891,
    double textScale = 1,
    void Function(_FakeHomeViewModel vm)? configure,
  }) async {
    SharedPreferences.setMockInitialValues({
      'language_code': lang,
      'is_language_selected': true,
      ...prefs,
    });
    tester.view.physicalSize = Size(width * 3, height * 3);
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
    configure?.call(vm);
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
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await settle(tester);
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

  /// Listede öğeye kaydırır ve tamamen görünür yapar (dokunuş ıskalamasın)
  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    final scroll = scrollable ?? find.byType(Scrollable).first;
    // Henüz kurulmadıysa baştan aşağı aranır
    if (finder.evaluate().isEmpty) {
      await tester.drag(scroll, const Offset(0, 20000));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.scrollUntilVisible(finder, 200, scrollable: scroll);
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  NavigatorState navigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator).first);

  Future<Map<String, Object>> savedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final key in prefs.getKeys()) key: prefs.get(key)!};
  }

  group('İpucu', () {
    Widget page(List<Widget> tips) => Scaffold(body: ListView(children: tips));

    testWidgets('ilk ziyarette görünür; "Anladım" ile kapanır, kayıtlıysa bir '
        'daha çıkmaz', (tester) async {
      await pumpApp(
        tester,
        page([const FeatureTip(id: 'deneme', message: 'İpucu A')]),
      );
      expect(find.text('İpucu A'), findsOneWidget);
      await tester.tap(find.text(tr.tipGotIt));
      await tester.pump();
      expect(find.text('İpucu A'), findsNothing);
      final prefs = await savedPrefs();
      expect(prefs[FeatureTip.seenKey('deneme')], isTrue);
      expect(FeatureTip.seenKey('deneme'), 'tip_deneme_seen');
      await finish(tester);

      await pumpApp(
        tester,
        page([const FeatureTip(id: 'deneme', message: 'İpucu A')]),
        prefs: prefs,
      );
      expect(find.text('İpucu A'), findsNothing);
      await finish(tester);
    });

    testWidgets('aynı anda tek ipucu: ilki kapanınca sıradaki görünür', (
      tester,
    ) async {
      await pumpApp(
        tester,
        page(const [
          FeatureTip(id: 'a', message: 'İpucu A'),
          FeatureTip(id: 'b', message: 'İpucu B'),
        ]),
      );
      int shown(String text) => find.text(text).evaluate().length;
      expect(shown('İpucu A') + shown('İpucu B'), 1);
      final first = shown('İpucu A') == 1 ? 'İpucu A' : 'İpucu B';
      final second = first == 'İpucu A' ? 'İpucu B' : 'İpucu A';
      await tester.tap(find.text(tr.tipGotIt));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(first), findsNothing);
      expect(find.text(second), findsOneWidget);
      await finish(tester);
    });

    testWidgets('açılış pencereleri (tur, izin, Yenilikler) açıkken beklenir', (
      tester,
    ) async {
      var open = true;
      bool gate() => !open;
      FeatureTip.attachGate(gate);
      addTearDown(() => FeatureTip.detachGate(gate));
      await pumpApp(
        tester,
        page(const [FeatureTip(id: 'a', message: 'İpucu A')]),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('İpucu A'), findsNothing);
      open = false;
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('İpucu A'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('koşul sağlanmazsa çıkmaz; eylem düğmesi çalışır ve kapatır', (
      tester,
    ) async {
      var actions = 0;
      await pumpApp(
        tester,
        page([
          FeatureTip(id: 'kosul', message: 'Koşullu', when: () async => false),
          FeatureTip(
            id: 'eylem',
            message: 'Eylemli',
            actionLabel: 'Ekle',
            onAction: () => actions++,
          ),
        ]),
      );
      expect(find.text('Koşullu'), findsNothing);
      expect(find.text('Eylemli'), findsOneWidget);
      // TalkBack: düğmeler adlarıyla okunur
      expect(find.bySemanticsLabel(tr.tipGotIt), findsOneWidget);
      await tester.tap(find.text('Ekle'));
      await tester.pump();
      expect(actions, 1);
      expect(find.text('Eylemli'), findsNothing);
      expect((await savedPrefs())[FeatureTip.seenKey('eylem')], isTrue);
      await finish(tester);
    });

    testWidgets('Alarmlar sekmesi: "Durdur" ve "Sessiz modda da çal" ipucu '
        '(8.0 altında sadece Durdur)', (tester) async {
      for (final supported in [true, false]) {
        FeatureTip.debugReset();
        await pumpApp(
          tester,
          Scaffold(
            body: Consumer<HomeViewModel>(
              builder: (context, vm, _) =>
                  AlarmSettingsList(viewModel: vm, nextKey: null),
            ),
          ),
          configure: (vm) => vm.alarmStreamSupported = supported,
        );
        final message = supported
            ? '${tr.whatsNewStopDesc} ${tr.tipAlarmsSilent}'
            : tr.whatsNewStopDesc;
        expect(find.text(message), findsOneWidget);
        await tester.tap(find.text(tr.tipGotIt));
        await tester.pump();
        expect(find.text(message), findsNothing);
        await finish(tester);
      }
    });

    testWidgets('Namaz Takibi ve Zikirmatik: ilk ziyarette kendi ipucu', (
      tester,
    ) async {
      await pumpApp(tester, const PrayerTrackerView());
      // "Takip" sekmesinin listesi (sekmeler yatay kaydırılır)
      await reveal(
        tester,
        find.text(tr.tipTracker),
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(tr.tipTracker), findsOneWidget);
      await tester.tap(find.text(tr.tipGotIt));
      await tester.pump();
      expect(find.text(tr.tipTracker), findsNothing);
      final prefs = await savedPrefs();
      expect(prefs[FeatureTip.seenKey('tracker')], isTrue);
      await finish(tester);

      await pumpApp(tester, const ZikirView(), prefs: prefs);
      expect(find.text(tr.tipZikir), findsOneWidget);
      // Bir önceki ekranın ipucu bir daha çıkmaz
      expect(find.text(tr.tipTracker), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('Ana ekran widget ipucu: 3 farklı günden sonra ve başlatıcı '
        'destekliyorsa; "Widget ekle" seçimi açar', (tester) async {
      Widget home() => ShowCaseWidget(builder: (context) => const HomeView());
      Future<void> pumpHome(int days) async {
        FeatureTip.debugReset();
        await pumpApp(
          tester,
          home(),
          prefs: {UsageReviewPrompt.countKey: days},
          height: 1600,
        );
      }

      await pumpHome(2);
      expect(find.text(tr.tipWidget), findsNothing);
      await finish(tester);

      pinSupported = false;
      await pumpHome(3);
      expect(find.text(tr.tipWidget), findsNothing);
      await finish(tester);

      pinSupported = true;
      await pumpHome(3);
      expect(find.text(tr.tipWidget), findsOneWidget);
      await tester.tap(find.text(tr.tipWidgetAction));
      await settle(tester);
      expect(find.text(tr.addWidgetHint), findsOneWidget);
      expect(find.text(tr.tipWidget), findsNothing);
      expect((await savedPrefs())[FeatureTip.seenKey('home_widget')], isTrue);
      await finish(tester);
    });
  });

  group('Yenilikler', () {
    int selected(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    testWidgets('yeni kurulum: tur başlar, Yenilikler çıkmaz; bu sürümün '
        'listesi görüldü sayılır', (tester) async {
      await pumpApp(tester, mainWrapper());
      expect(ShowcaseView.get().isShowcaseRunning, isTrue);
      expect(find.text(tr.whatsNewTitle), findsNothing);
      expect((await savedPrefs())[WhatsNew.seenKey], WhatsNew.version);
      await finish(tester);
    });

    testWidgets('güncelleme: açılış akışından sonra bir kez; kapanınca bir '
        'daha çıkmaz, eski listeyi görene yenisi çıkar', (tester) async {
      final updated = {tourSeenKey: false, permissionsPrimedKey: true};
      await pumpApp(tester, mainWrapper(), prefs: updated);
      expect(find.text(tr.whatsNewTitle), findsOneWidget);
      expect(find.text(tr.versionLabel(WhatsNew.version)), findsOneWidget);
      for (final item in WhatsNew.items(tr)) {
        expect(find.text(item.title), findsOneWidget, reason: item.title);
      }
      expect(WhatsNew.items(tr), hasLength(inInclusiveRange(5, 6)));
      await tester.tap(find.text(tr.tipGotIt));
      await settle(tester);
      expect(find.text(tr.whatsNewTitle), findsNothing);
      final prefs = await savedPrefs();
      expect(prefs[WhatsNew.seenKey], WhatsNew.version);
      await finish(tester);

      await pumpApp(tester, mainWrapper(), prefs: prefs);
      expect(find.text(tr.whatsNewTitle), findsNothing);
      await finish(tester);

      await pumpApp(
        tester,
        mainWrapper(),
        prefs: {...updated, WhatsNew.seenKey: '1.2.0'},
      );
      expect(find.text(tr.whatsNewTitle), findsOneWidget);
      await finish(tester);
    });

    testWidgets('satırlar ilgili ekranı/sekmeyi reklamsız açar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        mainWrapper(),
        prefs: {
          tourSeenKey: false,
          permissionsPrimedKey: true,
          WhatsNew.seenKey: WhatsNew.version,
        },
      );
      final ads = AdHelper.instance.debugShowRequests;
      Future<void> openRow(String title) async {
        showWhatsNewSheet(tester.element(find.byType(MainWrapper)));
        await settle(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(title),
          ),
        );
        await settle(tester);
        expect(find.text(tr.whatsNewTitle), findsNothing);
      }

      for (final title in [tr.hatimTitle, tr.whatsNewQuranTitle]) {
        await openRow(title);
        expect(selected(tester), MainTab.quran.index, reason: title);
        expect(find.byType(QuranView), findsOneWidget, reason: title);
      }

      // Araçlar sekmesinden: ana sekme + "Alarmlar"
      await tester.tap(find.text(tr.navTools));
      await settle(tester);
      await openRow(tr.whatsNewStopTitle);
      expect(selected(tester), MainTab.home.index);
      expect(find.text(tr.ezanAlarmStreamTitle).hitTestable(), findsOneWidget);

      // Cuma bildirimi: Bildirim Ayarları
      await openRow(tr.fridayNotifTitle);
      expect(find.byType(NotificationSettingsView), findsOneWidget);
      expect(find.text(tr.fridayNotifSub), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      await openRow(tr.whatsNewWidgetsTitle);
      expect(find.text(tr.addWidgetHint), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      // Yazı boyutu: Görünüm Ayarları alt sayfası
      await openRow(tr.textSizeTitle);
      expect(find.text(tr.textSizeExtraLarge), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      expect(AdHelper.instance.debugShowRequests, ads);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });

  group('Uygulamayı Tanı', () {
    testWidgets('Ayarlar satırı sayfayı açar', (tester) async {
      await pumpApp(tester, const SettingsView());
      await reveal(tester, find.text(tr.appGuideTitle));
      expect(find.text(tr.appGuideSub), findsOneWidget);
      await tester.tap(find.text(tr.appGuideTitle));
      await settle(tester);
      expect(find.byType(AppGuideView), findsOneWidget);
      expect(find.text(tr.appGuideReplayTour), findsOneWidget);
      await finish(tester);
    });

    testWidgets('satırlar ilgili ekranı ya da sekmeyi reklamsız açar', (
      tester,
    ) async {
      final tabs = <MainTab>[];
      bool handler(MainTab tab) {
        tabs.add(tab);
        return true;
      }

      MainTabRequests.attach(handler);
      addTearDown(() => MainTabRequests.detach(handler));
      await pumpApp(tester, const AppGuideView());
      final ads = AdHelper.instance.debugShowRequests;
      Future<void> tapRow(String title) async {
        await reveal(tester, find.text(title));
        await tester.tap(find.text(title));
        await settle(tester);
      }

      for (final (title, type) in [
        (tr.timeAdjustTitle, TimeAdjustView),
        (tr.healthTitle, NotificationHealthView),
        (tr.notificationSettingsTitle, NotificationSettingsView),
        (tr.trackerTitle, PrayerTrackerView),
        (tr.missedPrayersTitle, PrayerTrackerView),
        (tr.prayerGuideTitle, PrayerGuideView),
        (tr.duasTitle, DuasView),
        (tr.imsakiyeTitle, ImsakiyeView),
        (tr.religiousDaysTitle, ReligiousDaysView),
        (tr.esmaulHusnaTitle, EsmaulHusnaView),
        (tr.storiesTitle, StoriesView),
        (tr.fridayMessagesTitle, FridayMessagesView),
        (tr.zakatTitle, ZakatView),
        (tr.fitreTitle, FitreView),
      ]) {
        await tapRow(title);
        expect(find.byType(type), findsOneWidget, reason: title);
        // Kaza Takibi satırı takip ekranını "Kaza" sekmesinde açar
        if (title == tr.missedPrayersTitle) {
          expect(find.text(tr.missedPrayersInfo), findsOneWidget);
        } else if (title == tr.trackerTitle) {
          expect(find.text(tr.trackerLast7Days), findsOneWidget);
        }
        navigator(tester).pop();
        await settle(tester);
      }

      for (final (title, tab) in [
        (tr.qiblaTitle, MainTab.qibla),
        (tr.zikirmatikTitle, MainTab.zikir),
        (tr.quranTitle, MainTab.quran),
        (tr.hatimTitle, MainTab.quran),
      ]) {
        tabs.clear();
        await tapRow(title);
        expect(tabs, [tab], reason: title);
      }

      for (final title in [tr.tabAlarms, tr.whatsNewStopTitle]) {
        final before = HomeView.alarmsTabRequests.value;
        await tapRow(title);
        expect(HomeView.alarmsTabRequests.value, before + 1, reason: title);
      }

      await tapRow(tr.changeLocation);
      expect(find.byType(LocationSearchDialog), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      await tapRow(tr.textSizeTitle);
      expect(find.text(tr.textSizeExtraLarge), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      await tapRow(tr.nearbyMosquesTitle);
      expect(launches, isNotEmpty);

      await tapRow(tr.addWidgetTitle);
      expect(find.text(tr.addWidgetHint), findsOneWidget);
      navigator(tester).pop();
      await settle(tester);

      // Başlatıcı desteklemiyorsa nasıl ekleneceği yazılır
      pinSupported = false;
      await tapRow(tr.addWidgetTitle);
      expect(find.text(tr.guideWidgets), findsNWidgets(2));
      expect(find.byType(SnackBar), findsOneWidget);

      expect(AdHelper.instance.debugShowRequests, ads);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('"Tanıtım turunu tekrar izle": sayfalar kapanır, ana sekmenin '
        'Vakitler görünümünde tur baştan başlar; izin penceresi açılmaz', (
      tester,
    ) async {
      await pumpApp(
        tester,
        mainWrapper(),
        prefs: {
          tourSeenKey: false,
          permissionsPrimedKey: true,
          WhatsNew.seenKey: WhatsNew.version,
        },
      );
      final view = ShowcaseView.get();
      expect(view.isShowcaseRunning, isFalse);
      // Alarmlar görünümü ve Araçlar sekmesindeyken Ayarlar > Uygulamayı Tanı
      HomeView.openAlarmsTab();
      await settle(tester);
      await tester.tap(find.text(tr.navTools));
      await settle(tester);
      navigator(
        tester,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
      await settle(tester);
      await reveal(
        tester,
        find.text(tr.appGuideTitle),
        scrollable: find
            .descendant(
              of: find.byType(SettingsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text(tr.appGuideTitle));
      await settle(tester);
      await tester.tap(find.text(tr.appGuideReplayTour));
      await settle(tester);

      expect(find.byType(AppGuideView), findsNothing);
      expect(find.byType(SettingsView), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        MainTab.home.index,
      );
      expect(view.isShowcaseRunning, isTrue);
      final seen = <GlobalKey>[];
      for (var i = 0; i < 10 && view.isShowcaseRunning; i++) {
        seen.add(view.getActiveShowcaseKey!);
        view.next();
        for (var j = 0; j < 5; j++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      expect(seen.first, homeLangKey);
      expect(seen, contains(homeTrackerKey)); // "Vakitler" görünümüne dönüldü
      expect(seen.last, toolsKey);
      await settle(tester);
      expect(find.text(tr.permissionPrimingTitle), findsNothing);
      await finish(tester);
    });
  });

  group('320dp %130 yazı, taşma yok', () {
    for (final lang in ['tr', 'de', 'ar']) {
      testWidgets('$lang: Uygulamayı Tanı, Yenilikler ve ipucu', (
        tester,
      ) async {
        final loc = lookupAppLocalizations(Locale(lang));
        await pumpApp(
          tester,
          const AppGuideView(),
          lang: lang,
          width: 320,
          height: 640,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        // Arapçada sağdan sola
        expect(
          Directionality.of(tester.element(find.text(loc.appGuideReplayTour))),
          lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await reveal(tester, find.text(loc.addWidgetTitle));
        expect(find.text(loc.guideWidgets), findsOneWidget);
        expect(tester.takeException(), isNull);

        showWhatsNewSheet(tester.element(find.byType(AppGuideView)));
        await settle(tester);
        expect(find.text(loc.whatsNewTitle), findsOneWidget);
        await reveal(
          tester,
          find.text(loc.tipGotIt),
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text(loc.tipGotIt).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await finish(tester);

        await pumpApp(
          tester,
          Scaffold(
            body: ListView(
              children: [
                FeatureTip(
                  id: 'uzun',
                  message: loc.tipTracker,
                  actionLabel: loc.tipWidgetAction,
                  onAction: () {},
                  padding: const EdgeInsets.all(AppSpacing.lg),
                ),
              ],
            ),
          ),
          lang: lang,
          width: 320,
          height: 640,
          textScale: 1.3,
        );
        expect(find.text(loc.tipTracker), findsOneWidget);
        expect(find.text(loc.tipWidgetAction), findsOneWidget);
        expect(tester.takeException(), isNull);
        await finish(tester);
      });
    }
  });
}

/// Varlık yüklemeleri (gerçek zaman) ve geçiş animasyonları
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
