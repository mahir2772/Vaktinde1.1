// Dualar: duas.json bütünlüğü (Arapça, okunuş, 4 dilde anlam), ekranlar tr/ar
// %130 yazıda taşmaz, tesbihat sayacı hedefte sonraki adıma geçer, paylaşım
// metni kampanyalı Play bağlantısıyla biter.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/duas/view/duas_view.dart';
import 'package:ezan_saati/features/duas/view/tesbihat_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arapçası olmayan tek kayıt: Türkçe usulü sahur niyeti
const _noArabic = {'sahur_niyeti'};

final RegExp _arabicScript = RegExp('[ء-ي]');

/// Harfler, harekeler (ünlü, tenvin, şedde, sükûn, hançer elif), boşluk,
/// satır sonu ve Arapça virgül
final RegExp _arabicOnly = RegExp('^[ء-ْٰ \n،]+\$');

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Önceden yüklenmiş (gerçek bölgede tamamlanmış) Future'ların geri
/// çağrıları gerçek olay döngüsünde çalışır: kısa bir runAsync + kareler
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  String lang = 'tr',
  double textScale = 1.3,
  double width = 320,
  double height = 640,
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
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await _settle(tester);
}

/// Bütün kaydırılabilir içeriği gezer (geç çizilen öğeler de denetlensin)
Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  for (var i = 0; i < 10; i++) {
    await tester.drag(scrollables.first, const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DuaLibrary library;

  setUpAll(() async {
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
    // Önbelleklenen Future sahte zaman bölgesinde oluşmasın
    library = await DuaLibrary.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  });

  group('duas.json', () {
    final raw =
        json.decode(File('assets/data/duas.json').readAsStringSync())
            as Map<String, dynamic>;
    final parsed = DuaLibrary.fromJson(raw);
    final all = [for (final c in parsed.categories) ...c.duas];

    test('kategoriler dolu, kimlikler tekil, 5 dilde başlık', () {
      expect(parsed.categories.map((c) => c.id), [
        'prayer',
        'morning_evening',
        'daily',
        'ramadan',
      ]);
      for (final category in parsed.categories) {
        expect(category.duas, isNotEmpty, reason: category.id);
        for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
          expect(category.title[lang], isNotEmpty, reason: category.id);
        }
      }
      final ids = all.map((d) => d.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final dua in all) {
        for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
          expect(dua.title[lang], isNotEmpty, reason: '${dua.id} $lang');
        }
      }
    });

    test('her duada Arapça, tr ve Latin okunuş, tr/en/de/fr anlam', () {
      for (final dua in all) {
        for (final lang in ['tr', 'en', 'de', 'fr']) {
          expect(dua.meaning[lang], isNotEmpty, reason: '${dua.id} $lang');
        }
        if (_noArabic.contains(dua.id)) {
          expect(dua.arabic, isEmpty, reason: dua.id);
          continue;
        }
        expect(dua.arabic, matches(_arabicScript), reason: dua.id);
        expect(dua.arabic, matches(_arabicOnly), reason: dua.id);
        expect(dua.translit['tr'], isNotEmpty, reason: dua.id);
        expect(dua.translit['latin'], isNotEmpty, reason: dua.id);
      }
    });

    test('not ve kaynak varsa 5 dilde; Fransızcada noktalamadan önce '
        'bölünmez boşluk', () {
      final steps = parsed.tesbihat.where((s) => s.arabic.isEmpty);
      for (final dua in [...all, ...steps]) {
        for (final texts in [dua.note, dua.source]) {
          if (texts.isEmpty) continue;
          for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
            expect(texts[lang], isNotEmpty, reason: '${dua.id} $lang');
          }
        }
        for (final texts in [dua.title, dua.meaning, dua.note, dua.source]) {
          final fr = texts['fr'] ?? '';
          expect(fr, isNot(matches(r' [!?:;»]|« ')), reason: fr);
        }
      }
    });

    test('tesbihat: Âyetü\'l-Kürsî, 33 × 3, tevhid, dua', () {
      expect(parsed.tesbihat.map((s) => (s.id, s.count)), [
        ('ayetel_kursi', 1),
        ('subhanallah', 33),
        ('elhamdulillah', 33),
        ('allahu_ekber', 33),
        ('tevhid', 1),
        ('dua', 0),
      ]);
      expect(
        parsed.tesbihat.first.arabic,
        all.firstWhere((d) => d.id == 'ayetel_kursi').arabic,
      );
      for (final step in parsed.tesbihat.where((s) => s.count > 0)) {
        expect(step.arabic, matches(_arabicOnly), reason: step.id);
        expect(step.translit['tr'], isNotEmpty, reason: step.id);
      }
      for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
        expect(parsed.tesbihat.last.noteFor(lang), isNotEmpty);
      }
    });

    test('dil seçimi: Arapçada okunuş ve anlam yok, diğerlerinde var', () {
      final subhaneke = all.firstWhere((d) => d.id == 'subhaneke');
      expect(subhaneke.translitFor('tr'), startsWith('Sübhânekellâhümme'));
      expect(subhaneke.translitFor('de'), subhaneke.translit['latin']);
      expect(subhaneke.translitFor('ar'), isNull);
      expect(subhaneke.meaningFor('ar'), isNull);
      expect(subhaneke.noteFor('ar'), isNotEmpty);
      final text = subhaneke.plainText('tr');
      expect(text, startsWith(subhaneke.arabic));
      expect(text, contains(subhaneke.translitFor('tr')));
      expect(text, contains(subhaneke.meaningFor('tr')));
      expect(text, endsWith('— ${subhaneke.sourceFor('tr')}'));
      expect(subhaneke.plainText('ar'), isNot(contains('Sübhâneke')));
    });
  });

  group('Ekranlar %130 yazıda taşmaz', () {
    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: Dualar listesi', (tester) async {
        await _pump(tester, const DuasView(), lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        expect(find.text(loc.tesbihatTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _scrollThrough(tester);
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      });

      testWidgets('$lang: her dua sayfası', (tester) async {
        for (final category in library.categories) {
          for (final dua in category.duas) {
            await _pump(tester, DuaDetailView(dua: dua), lang: lang);
            expect(tester.takeException(), isNull, reason: dua.id);
            if (dua.arabic.isNotEmpty) {
              final arabic = tester.widget<Text>(find.text(dua.arabic));
              expect(arabic.textDirection, TextDirection.rtl);
              expect(arabic.style?.fontFamily, AppTheme.arabicFamily);
            }
            await _scrollThrough(tester);
            expect(tester.takeException(), isNull, reason: dua.id);
          }
        }
        await _dispose(tester);
      });

      testWidgets('$lang: tesbihat adımları', (tester) async {
        await _pump(tester, TesbihatView(steps: library.tesbihat), lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        for (var i = 0; i < library.tesbihat.length; i++) {
          expect(
            find.text(loc.tesbihatStep(i + 1, library.tesbihat.length)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await _scrollThrough(tester);
          if (i < library.tesbihat.length - 1) {
            await tester.tap(find.byTooltip(loc.nextItem));
            await _settle(tester);
          }
        }
        expect(find.text(loc.tesbihatRestart), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      });
    }
  });

  testWidgets('tesbihat: 33 dokunuşta sonraki adım, sonda baştan başla', (
    tester,
  ) async {
    await _pump(
      tester,
      TesbihatView(steps: library.tesbihat),
      textScale: 1,
      width: 411,
      height: 891,
    );
    final loc = lookupAppLocalizations(const Locale('tr'));
    final counter = find.byKey(TesbihatView.counterKey);
    String step(int i) => loc.tesbihatStep(i, 6);
    String count() => tester
        .widget<TabularText>(
          find.descendant(of: counter, matching: find.byType(TabularText)),
        )
        .text;

    // Âyetü'l-Kürsî: tek dokunuş
    expect(find.text(step(1)), findsOneWidget);
    expect(find.text(loc.tesbihatTapWhenRead), findsOneWidget);
    await tester.tap(counter);
    await tester.pump(TesbihatView.advanceDelay);
    await tester.pump();
    expect(find.text(step(2)), findsOneWidget);
    expect(find.text('Sübhânallâh'), findsWidgets);
    expect(find.text(loc.tapToCount), findsOneWidget);

    for (var i = 0; i < 32; i++) {
      await tester.tap(counter);
      await tester.pump();
    }
    await tester.pump(TesbihatView.advanceDelay);
    expect(find.text(step(2)), findsOneWidget, reason: '32 < 33');
    expect(count(), '32');

    await tester.tap(counter);
    await tester.pump();
    expect(count(), '33');
    // Bekleme sırasında fazladan dokunuş sayılmaz
    await tester.tap(counter);
    await tester.pump(TesbihatView.advanceDelay);
    await tester.pump();
    expect(find.text(step(3)), findsOneWidget);
    expect(find.text('Elhamdülillâh'), findsWidgets);
    expect(count(), '0');

    // Sona atla: sayaç yerine baştan başla / kapat
    for (var i = 3; i < 6; i++) {
      await tester.tap(find.byTooltip(loc.nextItem));
      await tester.pump();
    }
    expect(find.text(step(6)), findsOneWidget);
    expect(counter, findsNothing);
    await tester.tap(find.text(loc.tesbihatRestart));
    await tester.pump();
    expect(find.text(step(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('Araçlar > Dualar > dua sayfası; metin paylaşımı bağlantılı', (
    tester,
  ) async {
    MethodCall? shared;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared = call;
        return 'dev.fluttercommunity.plus/share/success';
      },
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      ),
    );
    await _pump(
      tester,
      const ToolsView(),
      textScale: 1,
      width: 411,
      height: 891,
    );
    final loc = lookupAppLocalizations(const Locale('tr'));
    await tester.scrollUntilVisible(find.text(loc.duasTitle), 200);
    await tester.tap(find.text(loc.duasTitle));
    await _settle(tester);
    expect(find.byType(DuasView), findsOneWidget);

    final dua = library.categories.first.duas.first;
    await tester.tap(find.text(dua.titleFor('tr')));
    await _settle(tester);
    expect(find.byType(DuaDetailView), findsOneWidget);

    await tester.scrollUntilVisible(find.text(loc.shareAsText), 200);
    await tester.tap(find.text(loc.shareAsText));
    await tester.pump();
    expect(shared?.method, 'share');
    final text = (shared!.arguments as Map)['text'] as String;
    expect(text, startsWith(dua.arabic));
    expect(text, endsWith(shareCaption(dua.titleFor('tr'), 'dua')));
    expect(text, endsWith(AppLinks.playStoreLink('dua')));
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
