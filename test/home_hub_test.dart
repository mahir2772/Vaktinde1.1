// Ana ekran günlük merkez: "Bugün için" kısayolları (Cuma, dini gün tebrik
// penceresi, hatim ya da Kur'an'da kaldığın yer, tesbihat, sıradaki dini gün;
// sıra ve gezinme), vakit hücresine dokununca o vaktin alarm alt sayfası, üst
// çubukta reklamsız Ayarlar dişlisi (dünya simgesi yok); tr/ar %130 ve %200
// yazıda 320 dp taşmasız.
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/hadith_model.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/hatim.dart';
import 'package:ezan_saati/data/services/hatim_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/app_analytics.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/duas/view/tesbihat_view.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/home/widgets/alarm_settings_list.dart';
import 'package:ezan_saati/features/home/widgets/prayer_times_grid.dart';
import 'package:ezan_saati/features/home/widgets/today_hub.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/features/main_wrapper/main_tabs.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/features/religious_days/view/religious_days_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:package_info_plus/package_info_plus.dart';
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
}

final String _surahsJson = File('assets/data/surahs.json').readAsStringSync();

/// Gömülü sure listesi; sure metni istenmez (okuyucu açılışı yeter)
QuranService _quranService() =>
    QuranService(loadAsset: () async => _surahsJson, fetch: (_) async => null);

const String _lastReadBakara = '{"surah":2,"ayah":255}';

// 11 Ekim 2026 Pazar; 16 Ekim Cuma. Regaib Kandili (ve üç aylar) 10 Aralık
// 2026 Perşembe, Miraç Kandili 4 Ocak 2027 (religious_days.json)
final DateTime _sunday = DateTime(2026, 10, 11, 10);
final DateTime _friday = DateTime(2026, 10, 16, 10);
final DateTime _regaib = DateTime(2026, 12, 10);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Sabit adımlar; kısa gerçek bekleme: gerçek bölgede önceden yüklenen
/// varlıkların (rootBundle) Future'ları tamamlansın
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

double _top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalSink = AppAnalytics.sink;

  setUpAll(() async {
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    // Uygulama boyu önbelleklenen Future'lar gerçek zaman bölgesinde dolsun
    // (sahte zamanda oluşan, sonraki testlerde hiç tamamlanmaz)
    await loadRamadanCalendar();
    await DiniGunlerService.loadResmiGunler();
    await DuaLibrary.load();
    await rootBundle.loadString(QuranService.surahsAsset);
    await HatimService.loadPages();
    for (final lang in ['tr', 'ar']) {
      await rootBundle.loadString('assets/data/greetings_$lang.json');
      await rootBundle.loadString('assets/data/friday_messages_$lang.json');
    }
    PackageInfo.setMockInitialValues(
      appName: 'Vaktinde',
      packageName: 'com.mmdigital.vaktinde',
      version: '1.2.0',
      buildNumber: '17',
      buildSignature: '',
    );
  });

  setUp(() => AppAnalytics.sink = (name, parameters) async {});
  tearDown(() => AppAnalytics.sink = originalSink);

  group('Bugün için', () {
    final loc = lookupAppLocalizations(const Locale('tr'));

    Future<void> pumpHub(
      WidgetTester tester, {
      required DateTime now,
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = const Size(411 * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TodayHub(clock: () => now, quranService: _quranService()),
              ],
            ),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('pazar, kaldığın yer yok: Kur\'an-ı Kerim\'i aç, tesbihat, '
        'sıradaki dini gün (Regaib · 60 gün); Cuma ve tebrik yok', (
      tester,
    ) async {
      await pumpHub(tester, now: _sunday);
      expect(find.text(loc.todayHubTitle), findsOneWidget);
      expect(find.text(loc.todayQuranOpen), findsOneWidget);
      expect(find.text(loc.toolQuranDesc), findsOneWidget);
      expect(find.text(loc.quranContinue), findsNothing);
      expect(find.text(loc.tesbihatTitle), findsOneWidget);
      expect(find.text(loc.regaipKandili), findsOneWidget);
      expect(find.text(loc.daysLeft(60)), findsOneWidget);
      expect(loc.daysLeft(60), '60 gün kaldı');
      expect(find.text(loc.fridayGreeting), findsNothing);
      expect(find.text(loc.sendGreeting), findsNothing);
      // Sıra: Kur'an, tesbihat, dini gün
      expect(
        _top(tester, find.text(loc.todayQuranOpen)),
        lessThan(_top(tester, find.text(loc.tesbihatTitle))),
      );
      expect(
        _top(tester, find.text(loc.tesbihatTitle)),
        lessThan(_top(tester, find.text(loc.regaipKandili))),
      );
      expect(find.byType(AppListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('Cuma + kaldığın yer: önce Hayırlı Cumalar, sonra "Kaldığın '
        'yerden devam" (Bakara 255)', (tester) async {
      await pumpHub(
        tester,
        now: _friday,
        prefs: {QuranService.lastReadKey: _lastReadBakara},
      );
      expect(find.text(loc.fridayGreeting), findsOneWidget);
      expect(find.text(loc.todayFridayMessage), findsOneWidget);
      expect(find.text(loc.quranContinue), findsOneWidget);
      expect(find.text(loc.quranAyahRef('Bakara', 255)), findsOneWidget);
      expect(find.text(loc.todayQuranOpen), findsNothing);
      expect(find.text(loc.daysLeft(55)), findsOneWidget);
      final order = [
        loc.fridayGreeting,
        loc.quranContinue,
        loc.tesbihatTitle,
        loc.regaipKandili,
      ].map((t) => _top(tester, find.text(t))).toList();
      expect(order, [...order]..sort());
      expect(find.byType(AppListTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('tebrik penceresi: 2 gün kala dini gün en üstte, "Tebrik '
        'gönder" Regaib ve üç aylar tebriklerini açar', (tester) async {
      await pumpHub(tester, now: DateTime(2026, 12, 8, 9));
      expect(find.text(loc.daysLeft(2)), findsOneWidget);
      expect(
        _top(tester, find.text(loc.regaipKandili)),
        lessThan(_top(tester, find.text(loc.todayQuranOpen))),
      );
      expect(find.text(loc.sendGreeting), findsOneWidget);

      await tester.tap(find.text(loc.sendGreeting));
      await _settle(tester);
      expect(find.text(loc.greetingsTitle), findsOneWidget);
      expect(find.byType(MessageCard), findsWidgets);
      // Regaib mesajlarının ardından üç aylar tebrikleri
      await tester.scrollUntilVisible(
        find.text(loc.ucAylarBaslangici),
        300,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(loc.ucAylarBaslangici), findsWidgets);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('geçtikten sonra 3 gün tarih + tebrik (Cuma ile dört satır); '
        '4. gün sıradaki dini gün en altta, tebrik yok', (tester) async {
      // 11 Aralık 2026 Cuma: Regaib dün
      await pumpHub(tester, now: DateTime(2026, 12, 11, 9));
      final date = DateFormat.MMMMEEEEd('tr').format(_regaib);
      expect(date, '10 Aralık Perşembe');
      expect(find.text(date), findsOneWidget);
      expect(find.text(loc.sendGreeting), findsOneWidget);
      final order = [
        loc.fridayGreeting,
        loc.regaipKandili,
        loc.todayQuranOpen,
        loc.tesbihatTitle,
      ].map((t) => _top(tester, find.text(t))).toList();
      expect(order, [...order]..sort());
      await _dispose(tester);

      await pumpHub(tester, now: DateTime(2026, 12, 14, 9));
      expect(find.text(loc.regaipKandili), findsNothing);
      expect(find.text(loc.miracKandili), findsOneWidget);
      expect(find.text(loc.daysLeft(21)), findsOneWidget);
      expect(find.text(loc.sendGreeting), findsNothing);
      expect(
        _top(tester, find.text(loc.tesbihatTitle)),
        lessThan(_top(tester, find.text(loc.miracKandili))),
      );
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    test('dini gün seçimi: önce bugün/gelecek, pencere dışında sıradaki', () {
      final resmi = DiniGunlerService.parseResmiGunler([
        {'name': 'Regaib Kandili', 'date': '10 Aralık 2026'},
        {'name': 'Miraç Kandili', 'date': '04 Ocak 2027'},
      ]);
      FeaturedReligiousDay? at(DateTime day) =>
          featuredReligiousDay(loc, day, resmi);
      expect(at(DateTime(2026, 12, 10))!.daysLeft, 0);
      expect(at(DateTime(2026, 12, 10))!.day.tur, DiniGunTuru.regaipKandili);
      expect(at(DateTime(2026, 12, 13))!.daysLeft, -3);
      expect(at(DateTime(2026, 12, 14))!.day.tur, DiniGunTuru.miracKandili);
      expect(at(DateTime(2026, 12, 14))!.daysLeft, 21);
      // Yıl dönümünde de: yaklaşan gün, sonra geçen gün (3 güne kadar)
      expect(at(DateTime(2027, 1, 2))!.day.tur, DiniGunTuru.miracKandili);
      expect(at(DateTime(2027, 1, 2))!.daysLeft, 2);
      expect(at(DateTime(2027, 1, 6))!.day.tur, DiniGunTuru.miracKandili);
      expect(at(DateTime(2027, 1, 6))!.daysLeft, -2);
    });

    testWidgets('dokununca: Kur\'an kaldığın ayetten ve tesbihat reklamsız; '
        'Cuma mesajları ve dini günler geçiş reklamıyla açılır', (
      tester,
    ) async {
      await pumpHub(
        tester,
        now: _friday,
        prefs: {QuranService.lastReadKey: _lastReadBakara},
      );
      final ads = AdHelper.instance.debugShowRequests;

      await tester.tap(find.text(loc.quranContinue));
      await _settle(tester);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect(reader.surah.number, 2);
      expect(reader.initialAyah, 255);
      _navigator(tester).pop();
      await _settle(tester);

      for (final (text, type, ad) in [
        (loc.tesbihatTitle, TesbihatView, 0),
        (loc.fridayGreeting, FridayMessagesView, 1),
        (loc.regaipKandili, ReligiousDaysView, 1),
      ]) {
        final before = AdHelper.instance.debugShowRequests;
        await tester.tap(find.text(text));
        await _settle(tester);
        expect(AdHelper.instance.debugShowRequests, before + ad, reason: text);
        expect(find.byType(type), findsOneWidget, reason: text);
        if (type == TesbihatView) {
          expect(
            tester.widget<TesbihatView>(find.byType(TesbihatView)).steps,
            isNotEmpty,
          );
        }
        _navigator(tester).pop();
        await _settle(tester);
      }
      expect(AdHelper.instance.debugShowRequests, ads + 2);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('ana çerçevede: Kur\'an sekmesine geçilir, okuyucu üstünde '
        'açılır; kaldığın yer yoksa ayrıca liste açılmaz', (tester) async {
      final requests = <MainTab>[];
      bool handler(MainTab tab) {
        requests.add(tab);
        return true;
      }

      MainTabRequests.attach(handler);
      addTearDown(() => MainTabRequests.detach(handler));

      await pumpHub(
        tester,
        now: _sunday,
        prefs: {QuranService.lastReadKey: _lastReadBakara},
      );
      await tester.tap(find.text(loc.quranContinue));
      await _settle(tester);
      expect(requests, [MainTab.quran]);
      expect(find.byType(SurahReaderView), findsOneWidget);
      _navigator(tester).pop();
      await _settle(tester);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(QuranService.lastReadKey);
      await _dispose(tester);
      await pumpHub(tester, now: _sunday);
      await tester.tap(find.text(loc.todayQuranOpen));
      await _settle(tester);
      expect(requests, [MainTab.quran, MainTab.quran]);
      expect(find.byType(QuranView), findsNothing);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('kaldığın yer yoksa Kur\'an ekranı açılır; okununca dönüşte '
        'satır "Kaldığın yerden devam" olur', (tester) async {
      await pumpHub(tester, now: _sunday);
      await tester.tap(find.text(loc.todayQuranOpen));
      await _settle(tester);
      expect(find.byType(QuranView), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(QuranService.lastReadKey, '{"surah":67,"ayah":3}');
      _navigator(tester).pop();
      await _settle(tester);
      expect(find.text(loc.quranContinue), findsOneWidget);
      expect(find.text(loc.quranAyahRef('Mülk', 3)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('hatim sürüyorsa Kur\'an satırı yerine "Hatim · Bugün a / b '
        'sayfa": Kur\'an sekmesine geçilir, okuyucu hatim sayfasının başından '
        'hatim kipinde açılır (reklamsız); %200 yazıda 320 dp taşmaz; bitmiş '
        'hatimde kaldığın yer', (tester) async {
      final requests = <MainTab>[];
      bool handler(MainTab tab) {
        requests.add(tab);
        return true;
      }

      MainTabRequests.attach(handler);
      addTearDown(() => MainTabRequests.detach(handler));

      final today = PrayerTracker.day(_sunday);
      final plan = HatimPlan(
        start: today,
        target: PrayerTracker.addDays(today, 30),
        position: 41,
        log: {PrayerTracker.dateKey(today): 3},
      );
      await pumpHub(
        tester,
        now: _sunday,
        prefs: {
          QuranService.lastReadKey: _lastReadBakara,
          HatimService.planKey: plan.encode(),
        },
      );
      // Bugünün başında 566 sayfa, 31 gün: günde 19
      expect(find.text(loc.hatimTitle), findsOneWidget);
      expect(find.text('Bugün 3 / 19 sayfa'), findsOneWidget);
      expect(find.text(loc.quranContinue), findsNothing);
      expect(find.byType(AppListTile), findsNWidgets(3));

      final ads = AdHelper.instance.debugShowRequests;
      await tester.tap(find.text(loc.hatimTitle));
      await _settle(tester);
      expect(requests, [MainTab.quran]);
      final start = QuranPages.parse(
        File(QuranPages.asset).readAsStringSync(),
      )!.startOf(41);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect(
        [reader.surah.number, reader.initialAyah, reader.hatim],
        [start.surah, start.ayah, true],
      );
      expect(AdHelper.instance.debugShowRequests, ads);
      _navigator(tester).pop();
      await _settle(tester);

      // Küçük ekran, en büyük yazı
      tester.view.physicalSize = const Size(320 * 3, 1600 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _settle(tester);
      expect(find.text('Bugün 3 / 19 sayfa').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Hatim bitince (başka ekranda) satır hemen kaldığın yere döner
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        HatimService.planKey,
        plan.withPosition(604, today).encode(),
      );
      HatimService.changes.value++;
      await _settle(tester);
      expect(find.text(loc.hatimTitle), findsNothing);
      expect(find.text(loc.quranContinue), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });
  });

  group('Ana ekran', () {
    final times = PrayerTimesModel(
      imsak: '05:35',
      gunes: '07:00',
      ogle: '12:57',
      ikindi: '16:08',
      aksam: '18:43',
      yatsi: '20:02',
    );

    Future<_FakeHomeViewModel> pumpHome(
      WidgetTester tester, {
      String lang = 'tr',
      bool dark = false,
      DateTime? now,
      double width = 411,
      double height = 891,
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues({
        'language_code': lang,
        'is_language_selected': true,
        ...prefs,
      });
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final vm = _FakeHomeViewModel()
        ..city = 'İstanbul'
        ..district = 'Kadıköy'
        ..isLoading = false
        ..prayerTimes = times
        ..dailyAyah = AyahModel(
          number: 293,
          surahName: 'Bakara',
          numberInSurah: 286,
          arabicText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
          translatedText:
              'Allah hiç kimseye gücünün yetmeyeceği bir yük yüklemez.',
        )
        ..dailyHadith = HadithModel(
          content: 'Ameller ancak niyetlere göredir.',
          source: 'Buhârî',
        )
        ..onTimeAlarms = {'Öğle': true}
        ..reminderAlarms = {'Öğle': true};
      final clock = now ?? DateTime(2026, 10, 11, 14);
      await tester.pumpWidget(
        MultiProvider(
          key: UniqueKey(),
          providers: [
            ChangeNotifierProvider<HomeViewModel>(
              create: (_) => vm,
              lazy: false,
            ),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            locale: Locale(lang),
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShowCaseWidget(
              builder: (context) => HomeView(clock: () => clock),
            ),
          ),
        ),
      );
      await _settle(tester);
      return vm;
    }

    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(PrayerAlarmSheet), matching: finder);

    testWidgets('üst çubukta Ayarlar dişlisi (dünya simgesi yok); reklamsız '
        'Ayarlar açılır, dil ilk satır', (tester) async {
      final loc = lookupAppLocalizations(const Locale('tr'));
      await pumpHome(tester);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byTooltip(loc.changeLanguage), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byTooltip(loc.refreshLocation), findsOneWidget);

      final ads = AdHelper.instance.debugShowRequests;
      await tester.tap(find.byTooltip(loc.menuTitle));
      await _settle(tester);
      expect(find.byType(SettingsView), findsOneWidget);
      expect(find.text(loc.changeLanguage), findsOneWidget);
      expect(AdHelper.instance.debugShowRequests, ads);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('vakit hücresi: etiket korunur, düğme + "Alarm ayarları" '
        'ipucu; dokununca o vaktin alarm sayfası, anahtarlar çalışır', (
      tester,
    ) async {
      final loc = lookupAppLocalizations(const Locale('tr'));
      final vm = await pumpHome(tester);
      // 14:00: öğle şu an, ikindi sıradaki
      final label = 'İkindi, 16:08, ${loc.nextPrayer}';
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        containsSemantics(
          label: label,
          isButton: true,
          hasTapAction: true,
          onTapHint: loc.a11yAlarmSettingsHint,
        ),
      );
      expect(
        find.bySemanticsLabel('Öğle, 12:57, ${loc.currentPrayer}'),
        findsOneWidget,
      );

      // Ekran okuyucuyla dokunma da açar
      tester.semantics.tap(find.semantics.byLabel(label));
      await _settle(tester);
      expect(find.byType(PrayerAlarmSheet), findsOneWidget);
      expect(
        tester
            .widget<PrayerAlarmSheet>(find.byType(PrayerAlarmSheet))
            .prayerKey,
        'İkindi',
      );
      expect(inSheet(find.text(loc.ikindi)), findsOneWidget);
      expect(inSheet(find.text('16:08')), findsOneWidget);
      expect(inSheet(find.text(loc.silentNotif)), findsNothing);

      await tester.tap(inSheet(find.text(loc.exactAlarm)));
      await _settle(tester);
      expect(vm.onTimeAlarms['İkindi'], isTrue);
      expect(inSheet(find.text(loc.silentNotif)), findsOneWidget);
      await tester.tap(inSheet(find.text(loc.warningAlarm('15'))));
      await _settle(tester);
      expect(vm.reminderAlarms['İkindi'], isTrue);
      await tester.tap(inSheet(find.text(loc.silentNotif)));
      await _settle(tester);
      expect(vm.silentModeSettings['İkindi'], isTrue);
      // Diğer vakitlere dokunulmaz
      expect(vm.onTimeAlarms['Öğle'], isTrue);
      expect(vm.onTimeAlarms['Akşam'], isNull);

      // Kapanınca çalan önizleme susar
      vm.currentlyPlayingSound = 'bildirim1';
      _navigator(tester).pop();
      await _settle(tester);
      expect(find.byType(PrayerAlarmSheet), findsNothing);
      expect(vm.currentlyPlayingSound, isNull);

      // Parmakla dokunma: Öğle (ezan + hatırlatma açık, ses seçicileri)
      await tester.tap(
        find.descendant(
          of: find.byType(PrayerTimesGrid),
          matching: find.text(loc.ogle),
        ),
      );
      await _settle(tester);
      expect(
        tester
            .widget<PrayerAlarmSheet>(find.byType(PrayerAlarmSheet))
            .prayerKey,
        'Öğle',
      );
      expect(inSheet(find.byType(DropdownButton<String>)), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      for (final scale in [1.3, 2.0]) {
        testWidgets('$lang %${(scale * 100).round()}, 320 dp: dört satırlı '
            '"Bugün için" ve alarm sayfası taşmaz', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final loc = lookupAppLocalizations(Locale(lang));
          // Cuma, Regaib dün (tebrik), kaldığın yer var: en dolu hali
          await pumpHome(
            tester,
            lang: lang,
            dark: lang == 'ar',
            now: DateTime(2026, 12, 11, 14),
            width: 320,
            height: 3200,
            prefs: {QuranService.lastReadKey: _lastReadBakara},
          );
          expect(tester.takeException(), isNull);
          for (final text in [
            loc.todayHubTitle,
            loc.fridayGreeting,
            loc.regaipKandili,
            loc.sendGreeting,
            loc.quranContinue,
            loc.tesbihatTitle,
          ]) {
            expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
          }

          await tester.tap(
            find.descendant(
              of: find.byType(PrayerTimesGrid),
              matching: find.text(loc.ogle),
            ),
          );
          await _settle(tester);
          expect(find.byType(PrayerAlarmSheet), findsOneWidget);
          // Telefon boyunda: alarm sayfası kaydırılır, taşmaz
          tester.view.physicalSize = const Size(320 * 3, 640 * 3);
          await _settle(tester);
          expect(find.byType(PrayerAlarmSheet), findsOneWidget);
          expect(inSheet(find.text(loc.exactAlarm)), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _dispose(tester);
        });
      }
    }
  });
}
