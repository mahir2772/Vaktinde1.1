// Araçlar ekranları: tr/de/ar, açık/koyu, 320dp genişlik ve %130 yazıda
// taşmadan çizilmeli; zekat açılır listeleri her dilde geçerli değerle açılmalı.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/duas/view/duas_view.dart';
import 'package:ezan_saati/features/esmaul_husna/view/esmaul_husna_view.dart';
import 'package:ezan_saati/features/fitre/view/fitre_view.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/imsakiye/view/imsakiye_view.dart';
import 'package:ezan_saati/features/prayer_guide/prayer_guide_data.dart';
import 'package:ezan_saati/features/prayer_guide/view/prayer_guide_view.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/religious_days/view/religious_days_view.dart';
import 'package:ezan_saati/features/stories/view/stories_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/zakat/view/zakat_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langs = ['tr', 'de', 'ar'];

String _dk(int daysAgo) =>
    PrayerTracker.dateKey(PrayerTracker.addDays(DateTime.now(), -daysAgo));

Map<String, Object> _prefs() => {
  'saved_city': 'İstanbul',
  'saved_district': 'Kadıköy',
  'saved_lat': 41.0082,
  'saved_lng': 28.9784,
  'prayer_log_since': _dk(10),
  'prayer_log': '{"${_dk(1)}":31,"${_dk(2)}":5}',
  'prayer_kaza_added': '{"${_dk(3)}":31}',
  'kaza_Sabah': 12,
  'kaza_Öğle': 1500,
  'kaza_Oruç': 2,
};

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Gerçek yazı tipleri: taşma denetimi cihazdaki ölçülere yakın olsun
Future<void> _loadFonts() async {
  await _loadFont('Poppins', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/google_fonts/Poppins-$w.ttf',
  ]);
  await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
}

/// Zamanlayıcılı/animasyonlu ekranlar için sabit adımlar + varlık yüklemesi
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 3; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  String lang = 'tr',
  bool dark = false,
  double width = 320,
  double height = 640,
  double textScale = 1.3,
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Bütün kaydırılabilir içeriği gezer (geç çizilen öğeler de denetlensin)
Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollables.first, const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() async {
    await _loadFonts();
    // Uygulama boyu önbelleklenen Future'lar (takvim, rootBundle varlıkları)
    // ilk testin sahte zaman bölgesinde oluşursa sonraki testlerde
    // tamamlanmaz; gerçek bölgede önceden yüklenir
    await loadRamadanCalendar();
    await DiniGunlerService.loadResmiGunler();
    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      await rootBundle.loadString('assets/data/esmaul_husna_$lang.json');
      await rootBundle.loadString('assets/data/friday_messages_$lang.json');
      await rootBundle.loadString('assets/data/greetings_$lang.json');
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(_prefs());
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  });

  final screens = <String, Widget Function()>{
    'Araçlar': () => const ToolsView(),
    'İmsakiye': () => const ImsakiyeView(),
    'Zekat': () => const ZakatView(),
    'Esmaül Hüsna': () => const EsmaulHusnaView(),
    'Kıssalar': () => const StoriesView(),
    'Cuma mesajları': () => const FridayMessagesView(),
    'Dini günler': () => const ReligiousDaysView(),
    'Kaza': () => const PrayerTrackerView(initialTab: TrackerTab.kaza),
    'Namaz takibi': () => const PrayerTrackerView(),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final lang in _langs) {
      for (final dark in [false, true]) {
        final theme = dark ? 'koyu' : 'açık';
        testWidgets('$name $lang $theme: 320dp, %130 yazı, taşma yok', (
          tester,
        ) async {
          await _pumpScreen(tester, build(), lang: lang, dark: dark);
          expect(tester.takeException(), isNull);
          await _scrollThrough(tester);
          expect(tester.takeException(), isNull);
          await _dispose(tester);
        });
      }
    }
  }

  group('Araçlar', () {
    final loc = lookupAppLocalizations(const Locale('tr'));
    // Araç → açıklaması (ekran okuyucu ipucu), açılışta geçiş reklamı ve açılan
    // sayfa. Dualar, Namaz Hocası ve uygulamadan çıkan Yakındaki Camiler
    // reklamsız; Kaza Takibi Namaz Takibi'nin sekmesi.
    final tools = <String, (String, bool, Type?)>{
      loc.imsakiyeTitle: (loc.toolImsakiyeDesc, true, ImsakiyeView),
      loc.trackerTitle: (loc.toolTrackerDesc, true, PrayerTrackerView),
      loc.duasTitle: (loc.toolDuasDesc, false, DuasView),
      loc.prayerGuideTitle: (loc.toolPrayerGuideDesc, false, PrayerGuideView),
      loc.nearbyMosquesTitle: (loc.toolNearbyMosquesDesc, false, null),
      loc.religiousDaysTitle: (
        loc.toolReligiousDaysDesc,
        true,
        ReligiousDaysView,
      ),
      loc.esmaulHusnaTitle: (loc.toolEsmaDesc, true, EsmaulHusnaView),
      loc.storiesTitle: (loc.toolStoriesDesc, true, StoriesView),
      loc.fridayMessagesTitle: (loc.toolFridayDesc, true, FridayMessagesView),
      loc.zakatTitle: (loc.toolZakatDesc, true, ZakatView),
      loc.fitreTitle: (loc.toolFitreDesc, true, FitreView),
    };
    Finder tile(String title) => find.widgetWithText(ToolTile, title);

    testWidgets('11 araç kutucuğu (kaza ayrı değil) + Ayarlar satırı; '
        'kutucuk düğme, başlık etiket, açıklama ipucu', (tester) async {
      await _pumpScreen(tester, const ToolsView(), width: 411, textScale: 1);
      final semantics = tester.ensureSemantics();
      for (final MapEntry(key: title, value: (hint, _, _)) in tools.entries) {
        await tester.scrollUntilVisible(tile(title), 200);
        expect(tile(title), findsOneWidget);
        expect(
          tester.getSize(tile(title)).height,
          greaterThanOrEqualTo(AppSizes.minTouch),
        );
        expect(
          tester.getSemantics(tile(title)),
          containsSemantics(
            label: title,
            hint: hint,
            isButton: true,
            hasTapAction: true,
          ),
          reason: title,
        );
      }
      await tester.scrollUntilVisible(find.text(loc.menuTitle), 200);
      expect(find.widgetWithText(AppListTile, loc.menuTitle), findsOneWidget);
      expect(find.text(loc.missedPrayersTitle), findsNothing);
      semantics.dispose();
      await _dispose(tester);
    });

    // Genişlik / yazı boyutu / dil → sütun sayısı (en uzun başlık kelimesi
    // bölünmeden sığar: Almanca "Gebetsanleitung" 411dp'de de iki sütun)
    for (final (lang, width, scale, columns) in [
      ('tr', 411.0, 1.0, 3),
      ('tr', 360.0, 1.0, 3),
      ('tr', 320.0, 1.3, 2),
      ('tr', 411.0, 2.0, 2),
      ('tr', 320.0, 2.0, 1),
      ('ar', 411.0, 1.0, 3),
      ('de', 411.0, 1.0, 2),
      ('de', 320.0, 2.0, 1),
    ]) {
      testWidgets('$lang ${width.toInt()}dp %${(scale * 100).toInt()} yazı: '
          '$columns sütun; satırdaki kutucuklar eşit, taşma yok', (
        tester,
      ) async {
        // Uzun ekran: bütün kutucuklar kurulsun
        await _pumpScreen(
          tester,
          const ToolsView(),
          lang: lang,
          width: width,
          height: 3200,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final rects = [
          for (final element in find.byType(ToolTile).evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ];
        expect(rects, hasLength(tools.length));
        // Namaz grubunun (6 araç) ilk satırı
        expect(
          rects.where((r) => (r.top - rects.first.top).abs() < 0.5),
          hasLength(columns),
        );
        for (final rect in rects) {
          final row = rects.where((r) => (r.top - rect.top).abs() < 0.5);
          for (final other in row) {
            expect(other.height, moreOrLessEquals(rect.height));
            expect(other.width, moreOrLessEquals(rect.width));
          }
          expect(rect.left, greaterThanOrEqualTo(AppSpacing.lg - 0.5));
          expect(rect.right, lessThanOrEqualTo(width - AppSpacing.lg + 0.5));
        }
        await _dispose(tester);
      });
    }

    testWidgets('her araç kutucuğu aracını açar; geçiş reklamı eskisi gibi '
        'sadece reklamlı araçlarda', (tester) async {
      await tester.runAsync(DuaLibrary.load);
      await tester.runAsync(PrayerGuide.load);
      const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
      final launches = <MethodCall>[];
      messenger.setMockMethodCallHandler(urlLauncher, (call) async {
        launches.add(call);
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(urlLauncher, null));
      await _pumpScreen(tester, const ToolsView(), width: 411, textScale: 1);
      final ads = AdHelper.instance;
      for (final MapEntry(key: title, value: (_, showsAd, page))
          in tools.entries) {
        final before = ads.debugShowRequests;
        await tester.scrollUntilVisible(tile(title), 200);
        await tester.pump();
        await tester.tap(tile(title));
        await _settle(tester);
        expect(
          ads.debugShowRequests,
          before + (showsAd ? 1 : 0),
          reason: title,
        );
        if (page == null) {
          // Yakındaki Camiler: harita uygulaması açılır
          expect(launches, isNotEmpty);
          continue;
        }
        expect(find.byType(page), findsOneWidget, reason: title);
        Navigator.of(tester.element(find.byType(page))).pop();
        await _settle(tester);
      }
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('411×891 ekranda Ayarlar üst çubuktan kaydırmadan açılır', (
      tester,
    ) async {
      // Alt menü yüksekliği kadar (≈ 80dp) kısaltılmış gövde. Liste uzadığı
      // için en alttaki Ayarlar satırının yanında üst çubukta da düğme var
      await _pumpScreen(
        tester,
        const ToolsView(),
        width: 411,
        height: 891 - 80,
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      final screen = tester.getRect(find.byType(ToolsView));
      final gear = find.byTooltip(loc.menuTitle);
      expect(gear, findsOneWidget);
      expect(tester.getRect(gear).bottom, lessThanOrEqualTo(screen.bottom));
      final button = tester.widget<IconButton>(
        find.ancestor(of: gear, matching: find.byType(IconButton)),
      );
      expect(button.onPressed, isNotNull);
      await _dispose(tester);
    });
  });

  group('Zekat', () {
    test('virgüllü ve noktalı tutarlar okunur', () {
      const cases = <String, double>{
        // Tek ayraç + tam 3 rakam (önünde 1-3 rakam): binlik
        '10.000': 10000,
        '250.000': 250000,
        '1.500': 1500,
        '1,500': 1500,
        '10,000': 10000,
        '999.999': 999999,
        // Tek ayraç, diğer durumlar: ondalık
        '2500,50': 2500.5,
        '2500.50': 2500.5,
        '2500.5': 2500.5,
        '2500,5': 2500.5,
        '1.5': 1.5,
        '1,25': 1.25,
        '0,750': 0.75,
        '0.500': 0.5,
        '2500.500': 2500.5,
        '1.2345': 1.2345,
        ',5': 0.5,
        '2500,': 2500,
        // Uygulamanın yazdığı kurlar (2 ondalık) etkilenmez
        '1.00': 1,
        '2500.00': 2500,
        '38.45': 38.45,
        '123.45': 123.45,
        // İki farklı ayraç: sonuncusu ondalık
        '2.500,50': 2500.5,
        '2,500.50': 2500.5,
        '1,234.56': 1234.56,
        '1.234.567,89': 1234567.89,
        '1,234,567.8': 1234567.8,
        // Aynı ayraç birden çok: binlik
        '1.234.567': 1234567,
        '1,234,567': 1234567,
        '10.000.000': 10000000,
        // Boşluk, ₺, düz sayı, okunamayan
        ' 3000 ₺': 3000,
        '3 000': 3000,
        '₺1.500': 1500,
        '3000': 3000,
        '0': 0,
        '': 0,
        'abc': 0,
        '.': 0,
        ',': 0,
      };
      cases.forEach((input, expected) {
        expect(parseAmount(input), closeTo(expected, 1e-9), reason: input);
      });
    });

    test('tutar alanı yazarken binlik ayraç koyar; okunan değer aynı', () {
      String type(AmountInputFormatter f, String keys) {
        var value = TextEditingValue.empty;
        for (final key in keys.split('')) {
          final text = value.text + key;
          value = f.formatEditUpdate(
            value,
            TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            ),
          );
        }
        return value.text;
      }

      const tr = AmountInputFormatter(decimal: ',');
      const en = AmountInputFormatter(decimal: '.');
      final cases = <(AmountInputFormatter, String, String, double)>[
        (tr, '100000', '100.000', 100000),
        (tr, '1234567', '1.234.567', 1234567),
        (tr, '2500,5', '2.500,5', 2500.5),
        (tr, '2500.5', '2.500,5', 2500.5), // klavyede sadece nokta
        (tr, '0012', '12', 12),
        (tr, ',5', '0,5', 0.5),
        (tr, '12,5,6', '12,56', 12.56),
        (en, '100000', '100,000', 100000),
        (en, '2500.75', '2,500.75', 2500.75),
        (en, '999', '999', 999),
      ];
      for (final (f, keys, text, number) in cases) {
        final typed = type(f, keys);
        expect(typed, text, reason: keys);
        expect(parseAmount(typed), closeTo(number, 1e-9), reason: keys);
      }
      expect(tr.format(1), '1,00');
      expect(tr.format(2500.5), '2.500,50');
      expect(en.format(1234567.891), '1,234,567.89');
      for (final f in [tr, en]) {
        expect(parseAmount(f.format(2500.5)), 2500.5);
      }
      // Silince boşalır; ortadan silmede imleç rakamın yerinde kalır
      expect(
        tr.formatEditUpdate(
          const TextEditingValue(text: '5'),
          const TextEditingValue(text: ''),
        ),
        TextEditingValue.empty,
      );
      final edited = tr.formatEditUpdate(
        const TextEditingValue(text: '100.000'),
        const TextEditingValue(
          text: '10.000',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(edited.text, '10.000');
      expect(edited.selection.baseOffset, 1);
    });

    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      testWidgets('$lang: tüm bölümler açılır, varsayılan seçimler geçerli', (
        tester,
      ) async {
        await _pumpScreen(tester, const ZakatView(), lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        for (final title in [
          loc.cashAndCurrencyTitle,
          loc.goldAndSilverTitle,
          loc.commercialGoodsTitle,
          loc.receivablesTitle,
          loc.otherAssetsTitle,
          loc.agriProductsTitle,
          loc.debtsTitle,
        ]) {
          final finder = find.text(title);
          await tester.ensureVisible(finder);
          await tester.pump();
          await tester.tap(finder);
          await _settle(tester);
          expect(tester.takeException(), isNull, reason: title);
        }
        // Varsayılan "Diğer varlık" türü ve tarım türü listede (dile göre)
        expect(find.text(loc.assetStock), findsOneWidget);
        expect(find.text(loc.agriSoil), findsOneWidget);
        await _dispose(tester);
      });
    }

    testWidgets('canlı kur yoksa uyarı + elle altın fiyatı; sonuç hemen', (
      tester,
    ) async {
      await _pumpScreen(tester, const ZakatView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.zakatRatesUnavailable), findsOneWidget);

      // Nisab: 80,18 gr × 3000 ₺ = 240.540 ₺; nakit 300.000 ₺ → 7.500 ₺
      await tester.enterText(
        find.widgetWithText(TextField, loc.zakatGoldGramPrice),
        '3000',
      );
      await tester.tap(find.text(loc.cashAndCurrencyTitle));
      await _settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, loc.zakatCashTry),
        '300000,00',
      );
      final button = find.text(loc.calculateButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await _settle(tester);
      expect(find.text(loc.zakatEligible), findsOneWidget);
      expect(find.text('7.500,00 ₺'), findsOneWidget);
      expect(find.text('240.540,00 ₺'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('altın fiyatı yoksa "zekat gerekir" yerine nisab uyarısı', (
      tester,
    ) async {
      await _pumpScreen(tester, const ZakatView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.goldAndSilverTitle));
      await _settle(tester);
      // Gümüş fiyatı artık elle girilebilir
      await tester.enterText(
        find.widgetWithText(TextField, loc.silverGram),
        '100',
      );
      // Altın ve gümüş birim fiyatı aynı etiketi taşır; gümüşünki sonuncusu
      await tester.enterText(
        find.widgetWithText(TextField, loc.unitPrice).last,
        '40,5',
      );
      final button = find.text(loc.calculateButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await _settle(tester);
      expect(find.text(loc.zakatNisabUnknown), findsOneWidget);
      expect(find.text('4.050,00 ₺'), findsOneWidget); // net varlık
      // Nisab bilinmeden "zekat gerekir" ve %2,5 tutarı (101,25 ₺) yok
      expect(find.text(loc.zakatEligible), findsNothing);
      expect(find.text(loc.zakatResultTitle), findsNothing);
      expect(find.text('101,25 ₺'), findsNothing);
      await _dispose(tester);
    });
  });

  group('Reklam', () {
    test('zekat ve genel geçiş reklamı ortak sıklık sınırına uyar: 4 dk '
        'soğuma, günde en çok 8; saat geri alınınca beklemez', () {
      final ads = AdHelper.instance..debugReset();
      addTearDown(ads.debugReset);
      final t = DateTime(2026, 1, 1, 12);
      expect(ads.canShowInterstitial(t), isTrue);
      ads.markInterstitialShown(t);
      expect(
        ads.canShowInterstitial(t.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(
        ads.canShowInterstitial(t.add(const Duration(minutes: 3))),
        isFalse,
      );
      expect(
        ads.canShowInterstitial(t.add(const Duration(minutes: 4))),
        isTrue,
      );
      expect(ads.canShowInterstitial(t.add(const Duration(hours: 1))), isTrue);
      expect(
        ads.canShowInterstitial(t.subtract(const Duration(hours: 2))),
        isTrue,
      );

      // Aynı gün 8 reklam (soğuma aralıklarıyla) → günün geri kalanı reklamsız
      for (var i = 1; i < AdHelper.dailyCap; i++) {
        ads.markInterstitialShown(t.add(Duration(minutes: 5 * i)));
      }
      final late = t.add(const Duration(hours: 6));
      expect(ads.canShowInterstitial(late), isFalse);
      // Ertesi gün sayaç sıfırdan
      expect(ads.canShowInterstitial(DateTime(2026, 1, 2, 0, 1)), isTrue);
      ads.markInterstitialShown(DateTime(2026, 1, 2, 0, 1));
      expect(ads.canShowInterstitial(DateTime(2026, 1, 2, 0, 10)), isTrue);
    });

    test('yeni kullanıcıya ilk kurulumdan 24 saat geçiş reklamı yok; kurulum '
        'zamanı bilinmiyorsa kısıt yok, sonra soğuma ve günlük sınır', () {
      final ads = AdHelper.instance..debugReset();
      addTearDown(ads.debugReset);
      final installed = DateTime(2026, 1, 1, 12);
      expect(ads.canShowInterstitial(installed), isTrue); // bilinmiyor
      ads.installTime = installed;
      expect(ads.canShowInterstitial(installed), isFalse);
      expect(
        ads.canShowInterstitial(
          installed.add(const Duration(hours: 23, minutes: 59)),
        ),
        isFalse,
      );
      final after = installed.add(AdHelper.newUserGrace);
      expect(ads.canShowInterstitial(after), isTrue);
      // Mevcut kullanıcı (kurulum 24 saatten eski) etkilenmez
      expect(
        ads.canShowInterstitial(installed.add(const Duration(days: 30))),
        isTrue,
      );
      // Saat kurulumdan önceye alındıysa beklenmez
      expect(
        ads.canShowInterstitial(installed.subtract(const Duration(hours: 1))),
        isTrue,
      );

      ads.markInterstitialShown(after);
      expect(
        ads.canShowInterstitial(after.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(ads.canShowInterstitial(after.add(AdHelper.cooldown)), isTrue);
      for (var i = 1; i < AdHelper.dailyCap; i++) {
        ads.markInterstitialShown(after.add(Duration(minutes: 5 * i)));
      }
      expect(
        ads.canShowInterstitial(after.add(const Duration(hours: 6))),
        isFalse,
      );
    });

    test(
      'süreç yeniden başlayınca son gösterim ve günün sayısı korunur',
      () async {
        final ads = AdHelper.instance..debugReset();
        addTearDown(ads.debugReset);
        SharedPreferences.setMockInitialValues({});
        final t = DateTime(2026, 1, 1, 12);
        for (var i = 0; i < AdHelper.dailyCap; i++) {
          ads.markInterstitialShown(t.add(Duration(minutes: 5 * i)));
        }
        await Future<void>.delayed(Duration.zero);
        final prefs = await SharedPreferences.getInstance();
        final last = t.add(Duration(minutes: 5 * (AdHelper.dailyCap - 1)));
        expect(
          prefs.getString(AdHelper.logKey),
          '${last.millisecondsSinceEpoch}|2026-01-01|${AdHelper.dailyCap}',
        );

        ads.debugReset();
        expect(
          ads.canShowInterstitial(t.add(const Duration(hours: 6))),
          isTrue,
        );
        await ads.restoreLog();
        expect(
          ads.canShowInterstitial(last.add(const Duration(minutes: 1))),
          isFalse,
        );
        expect(
          ads.canShowInterstitial(t.add(const Duration(hours: 6))),
          isFalse,
        );
        expect(ads.canShowInterstitial(DateTime(2026, 1, 2, 9)), isTrue);

        // Bozuk kayıt yok sayılır
        ads.debugReset();
        SharedPreferences.setMockInitialValues({AdHelper.logKey: 'x|y'});
        await ads.restoreLog();
        expect(ads.canShowInterstitial(t), isTrue);
      },
    );
  });

  group('Kaza', () {
    testWidgets('artır/azalt kaydedilir; büyük değişiklik onay ister', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const PrayerTrackerView(initialTab: TrackerTab.kaza),
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text('12'), findsOneWidget);
      expect(find.byType(CounterStepper), findsAtLeastNWidgets(5));

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      expect(find.text('13'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('kaza_Sabah'), 13);

      // Elle 13 → 0: onay penceresi; iptal edilirse değişmez
      await tester.tap(find.text('13'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text(loc.save));
      await _settle(tester);
      expect(
        find.text(loc.missedChangeConfirm(loc.sabah, 13, 0)),
        findsOneWidget,
      );
      await tester.tap(find.text(loc.cancel));
      await _settle(tester);
      expect(prefs.getInt('kaza_Sabah'), 13);

      // Küçük değişiklik onaysız kaydedilir
      await tester.tap(find.text('13'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), '15');
      await tester.tap(find.text(loc.save));
      await _settle(tester);
      expect(prefs.getInt('kaza_Sabah'), 15);
      expect(find.text('15'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('Kaza hesapla: tahmin onaylanınca sayaçlara eklenir', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const PrayerTrackerView(initialTab: TrackerTab.kaza),
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.kazaCalcTitle));
      await _settle(tester);
      final sheet = find.byType(BottomSheet);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await _settle(tester);
      }

      final add = inSheet(find.text(loc.kazaCalcAdd));
      bool addEnabled() => tester
          .widget<ButtonStyleButton>(
            find.ancestor(
              of: add,
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .enabled;
      // Süre 0: ekleme kapalı (ekran okuyucuda da)
      expect(addEnabled(), isFalse);
      expect(
        tester.getSemantics(add),
        containsSemantics(
          label: loc.kazaCalcAdd,
          isButton: true,
          isEnabled: false,
        ),
      );

      // Yıl elle (sayıya dokununca) 2; ay +1, özel gün +2, Ramazan +1
      await tap(inSheet(find.text('0')).first);
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text(loc.save));
      await _settle(tester);
      final plus = inSheet(find.byIcon(Icons.add));
      await tap(plus.at(1));
      await tap(plus.at(2));
      await tap(plus.at(2));
      await tap(plus.at(3));
      expect(
        tester.getSemantics(inSheet(find.byType(CounterStepper)).first),
        containsSemantics(
          label: loc.kazaCalcYears,
          value: '2',
          hasIncreaseAction: true,
          hasTapAction: true,
        ),
      );
      // 2 × 365 + 30 − 25 ay × 2 gün = 710; oruç 30
      expect(inSheet(find.text('710')), findsOneWidget);
      expect(inSheet(find.text('30')), findsOneWidget);
      expect(addEnabled(), isTrue);

      // İptal: sayfa açık kalır, sayaçlar değişmez
      await tap(add);
      expect(find.text(loc.kazaCalcConfirm(710, 30)), findsOneWidget);
      await tester.tap(find.text(loc.cancel));
      await _settle(tester);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('kaza_Sabah'), 12);
      expect(sheet, findsOneWidget);

      // Onay: mevcut sayıların üzerine eklenir, sayfa kapanır, bilgi verilir
      await tap(add);
      await tester.tap(find.text(loc.trackerKazaAdd));
      await _settle(tester);
      expect(sheet, findsNothing);
      expect(prefs.getInt('kaza_Sabah'), 722);
      expect(prefs.getInt('kaza_Öğle'), 2210);
      for (final key in ['İkindi', 'Akşam', 'Yatsı', 'Vitir']) {
        expect(prefs.getInt('kaza_$key'), 710);
      }
      expect(prefs.getInt('kaza_Oruç'), 32);
      expect(find.text(loc.kazaCalcAdded), findsOneWidget);
      expect(find.text('722'), findsOneWidget);
      // "Kaza" sekmesinin listesi (sekmeler yatay kaydırılır)
      await tester.scrollUntilVisible(
        find.text('32'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('32'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    for (final lang in _langs) {
      for (final dark in [false, true]) {
        testWidgets(
          'Kaza hesapla $lang ${dark ? 'koyu' : 'açık'}: 320dp, %130 yazı, '
          'taşma yok',
          (tester) async {
            await _pumpScreen(
              tester,
              const PrayerTrackerView(initialTab: TrackerTab.kaza),
              lang: lang,
              dark: dark,
            );
            final loc = lookupAppLocalizations(Locale(lang));
            await tester.tap(find.text(loc.kazaCalcTitle));
            await _settle(tester);
            final sheet = find.byType(BottomSheet);
            // Her girdi bir artırılır: sonuçlar dolu, düğme açık
            final plus = find.descendant(
              of: sheet,
              matching: find.byIcon(Icons.add),
            );
            for (final i in [0, 1, 2, 3]) {
              await tester.ensureVisible(plus.at(i));
              await tester.pump();
              await tester.tap(plus.at(i));
              await tester.pump();
            }
            final add = find.descendant(
              of: sheet,
              matching: find.text(loc.kazaCalcAdd),
            );
            await tester.ensureVisible(add);
            await _settle(tester);
            expect(add.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            await _dispose(tester);
          },
        );
      }
    }
  });

  group('Dini günler', () {
    testWidgets('sıradaki gün "x gün kaldı" ile vurgulanır', (tester) async {
      await _pumpScreen(tester, const ReligiousDaysView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      final labels = [for (var d = 0; d <= 366; d++) loc.daysLeft(d)];
      final found = labels.where((l) => find.text(l).evaluate().isNotEmpty);
      // Yılın kalan günü yoksa (Aralık sonu) sonraki yıla geçilince çıkar
      if (found.isEmpty) {
        await tester.tap(find.byTooltip(loc.nextYear));
        await _settle(tester);
      }
      expect(
        labels.where((l) => find.text(l).evaluate().isNotEmpty),
        hasLength(1),
      );
      await _dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: sıradaki günün tebrik mesajları, %130 yazı', (
        tester,
      ) async {
        await _pumpScreen(tester, const ReligiousDaysView(), lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        // Yılın kalan günü yoksa (Aralık sonu) sıradaki gün sonraki yılda
        if (find.text(loc.sendGreeting).evaluate().isEmpty) {
          await tester.tap(find.byTooltip(loc.nextYear));
          await _settle(tester);
        }
        final button = find.text(loc.sendGreeting).first;
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await _settle(tester);
        expect(find.text(loc.greetingsTitle), findsOneWidget);
        expect(find.byType(MessageCard), findsWidgets);
        expect(find.text(loc.shareAsImage), findsWidgets);
        expect(tester.takeException(), isNull);
        final sheet = find.byType(DraggableScrollableSheet);
        for (var i = 0; i < 8; i++) {
          await tester.dragFrom(tester.getCenter(sheet), const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      });
    }
  });

  group('Cuma mesajları', () {
    testWidgets('kopyala geri bildirim verir, metinler yerelleştirilmiş', (
      tester,
    ) async {
      String? copied;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _pumpScreen(
        tester,
        const FridayMessagesView(),
        lang: 'de',
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('de'));
      expect(find.byTooltip(loc.shuffle), findsOneWidget);
      await tester.tap(find.text(loc.copy).first);
      await tester.pump();
      expect(copied, isNotNull);
      expect(find.text(loc.messageCopied), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('metin paylaşımı Play bağlantısıyla biter', (tester) async {
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      String? text;
      messenger.setMockMethodCallHandler(channel, (call) async {
        text = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await _pumpScreen(tester, const FridayMessagesView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.shareAsText).first);
      await tester.pump();
      expect(
        text,
        endsWith(
          '\n\n${loc.fridayGreeting} · Vaktinde\n'
          '${AppLinks.playStoreLink('friday')}',
        ),
      );
      await _dispose(tester);
    });
  });

  group('Esmaül Hüsna', () {
    test(
      'her dilde 99 isim; Arapçalar tekil ve Arapça dosyayla aynı sırada',
      () {
        List<dynamic> read(String lang) =>
            jsonDecode(
                  File(
                    'assets/data/esmaul_husna_$lang.json',
                  ).readAsStringSync(),
                )
                as List<dynamic>;
        final arabic = [for (final e in read('ar')) e['arabic'] as String];
        expect(arabic, hasLength(99));
        expect(arabic.toSet(), hasLength(99));
        for (final lang in ['tr', 'en', 'de', 'fr']) {
          expect(
            [for (final e in read(lang)) e['arabic'] as String],
            arabic,
            reason: lang,
          );
        }
      },
    );

    testWidgets('kart dokununca ayrıntı; önceki/sonraki düğmeleri', (
      tester,
    ) async {
      await _pumpScreen(tester, const EsmaulHusnaView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text('Er-Rahman'));
      await _settle(tester);
      expect(find.text('2. Er-Rahman'), findsOneWidget);
      await tester.tap(find.byTooltip(loc.nextItem));
      await _settle(tester);
      expect(find.text('3. Er-Rahim'), findsOneWidget);
      await tester.tap(find.text(loc.close));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });
  });
}
