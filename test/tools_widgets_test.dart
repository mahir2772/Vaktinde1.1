// Araçlar ekranları: tr/de/ar, açık/koyu, 320dp genişlik ve %130 yazıda
// taşmadan çizilmeli; zekat açılır listeleri her dilde geçerli değerle açılmalı.
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/esmaul_husna/view/esmaul_husna_view.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/imsakiye/view/imsakiye_view.dart';
import 'package:ezan_saati/features/missed_prayers/view/missed_prayers_view.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/religious_days/view/religious_days_view.dart';
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
    'Cuma mesajları': () => const FridayMessagesView(),
    'Dini günler': () => const ReligiousDaysView(),
    'Kaza': () => const MissedPrayersView(),
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
    testWidgets('8 araç + Ayarlar satırı tek listede', (tester) async {
      await _pumpScreen(tester, const ToolsView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      for (final title in [
        loc.imsakiyeTitle,
        loc.trackerTitle,
        loc.missedPrayersTitle,
        loc.nearbyMosquesTitle,
        loc.religiousDaysTitle,
        loc.esmaulHusnaTitle,
        loc.fridayMessagesTitle,
        loc.zakatTitle,
        loc.menuTitle,
      ]) {
        await tester.scrollUntilVisible(find.text(title), 200);
        expect(find.text(title), findsOneWidget);
      }
      expect(find.byType(AppListTile), findsWidgets);
      await _dispose(tester);
    });

    testWidgets('411×891 ekranda Zekat ve Ayarlar kaydırmadan görünür', (
      tester,
    ) async {
      // Alt menü yüksekliği kadar (≈ 80dp) kısaltılmış gövde
      await _pumpScreen(
        tester,
        const ToolsView(),
        width: 411,
        height: 891 - 80,
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      final screen = tester.getRect(find.byType(ToolsView));
      for (final title in [loc.zakatTitle, loc.menuTitle]) {
        final rect = tester.getRect(find.text(title));
        expect(rect.bottom, lessThanOrEqualTo(screen.bottom), reason: title);
      }
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
    test('zekat ve genel geçiş reklamı ortak soğuma süresine uyar', () {
      final ads = AdHelper.instance;
      final t = DateTime(2026, 1, 1, 12);
      ads.markInterstitialShown(t);
      expect(ads.isCoolingDown(t.add(const Duration(minutes: 1))), isTrue);
      expect(ads.isCoolingDown(t.add(const Duration(minutes: 4))), isTrue);
      expect(ads.isCoolingDown(t.add(const Duration(minutes: 5))), isFalse);
      expect(ads.isCoolingDown(t.add(const Duration(hours: 1))), isFalse);
    });
  });

  group('Kaza', () {
    testWidgets('artır/azalt kaydedilir; büyük değişiklik onay ister', (
      tester,
    ) async {
      await _pumpScreen(tester, const MissedPrayersView(), textScale: 1);
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
  });

  group('Dini günler', () {
    testWidgets('sıradaki gün "x gün kaldı" ile vurgulanır', (tester) async {
      await _pumpScreen(tester, const ReligiousDaysView(), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      final labels = [
        for (var d = 0; d <= 366; d++) loc.daysLeft(d),
      ];
      final found = labels.where(
        (l) => find.text(l).evaluate().isNotEmpty,
      );
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
