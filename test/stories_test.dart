// Kıssalar: stories.json bütünlüğü (4 kategori, tekil kimlik, 5 dilde başlık,
// tanım, metin; ibret ve kaynak varsa 5 dilde; Fransızca bölünmez boşluk) ve
// ekranlar tr/ar 320dp %130 yazıda taşmaz.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/stories/story_data.dart';
import 'package:ezan_saati/features/stories/view/stories_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langs = ['tr', 'en', 'de', 'fr', 'ar'];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _pump(WidgetTester tester, Widget screen, String lang) async {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scrollables.first, const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late StoryLibrary library;

  setUpAll(() async {
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
    library = await StoryLibrary.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  });

  group('stories.json', () {
    final raw =
        json.decode(File(StoryLibrary.asset).readAsStringSync())
            as Map<String, dynamic>;
    final parsed = StoryLibrary.fromJson(raw);
    final all = [for (final c in parsed.categories) ...c.stories];

    test('4 kategori: 25 peygamber, siyer, sahabe, âlimler; kimlik tekil', () {
      expect(parsed.categories.map((c) => c.id), [
        'prophets',
        'siyer',
        'sahabe',
        'ulema',
      ]);
      expect(parsed.categories.first.stories, hasLength(25));
      for (final c in parsed.categories) {
        expect(c.stories, isNotEmpty, reason: c.id);
        for (final lang in _langs) {
          expect(c.title[lang], isNotEmpty, reason: '${c.id} $lang');
        }
      }
      final ids = all.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('her kıssada 5 dilde başlık, tanım ve en az bir paragraf; ibret ve '
        'kaynak varsa 5 dilde; Fransızcada bölünmez boşluk', () {
      for (final story in all) {
        for (final lang in _langs) {
          expect(story.title[lang], isNotEmpty, reason: '${story.id} $lang');
          expect(story.subtitle[lang], isNotEmpty, reason: '${story.id} $lang');
          expect(story.paragraphsFor(lang), isNotEmpty, reason: story.id);
        }
        for (final texts in [story.lesson, story.source]) {
          if (texts.isEmpty) continue;
          for (final lang in _langs) {
            expect(texts[lang], isNotEmpty, reason: '${story.id} $lang');
          }
        }
        for (final texts in [
          story.title,
          story.subtitle,
          story.text,
          story.lesson,
          story.source,
        ]) {
          expect(texts['fr'] ?? '', isNot(matches(r' [!?:;»]|« ')));
        }
        expect(story.text['ar'], matches(RegExp('[ء-ي]')), reason: story.id);
      }
      // Peygamber ve siyer kıssaları Kur'an'a dayanır
      for (final c in parsed.categories.take(2)) {
        for (final story in c.stories) {
          if (story.id == 'siyer_genclik') continue;
          expect(story.sourceFor('tr'), contains("Kur'an"), reason: story.id);
        }
      }
    });
  });

  group('Ekranlar %130 yazıda taşmaz', () {
    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: liste, kategoriler ve her kıssa', (tester) async {
        await _pump(tester, const StoriesView(), lang);
        final loc = lookupAppLocalizations(Locale(lang));
        expect(find.text(loc.storiesNote), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final category in library.categories) {
          await _pump(tester, StoryCategoryView(category: category), lang);
          expect(tester.takeException(), isNull, reason: category.id);
          await _scrollThrough(tester);
          expect(tester.takeException(), isNull, reason: category.id);
          for (final story in category.stories) {
            await _pump(tester, StoryDetailView(story: story), lang);
            expect(tester.takeException(), isNull, reason: story.id);
            await _scrollThrough(tester);
            expect(tester.takeException(), isNull, reason: story.id);
          }
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('liste → kategori → kıssa', (tester) async {
      await _pump(tester, const StoriesView(), 'tr');
      final prophets = library.categories.first;
      await tester.tap(find.text(prophets.titleFor('tr')));
      await tester.pumpAndSettle();
      expect(find.byType(StoryCategoryView), findsOneWidget);
      final adem = prophets.stories.first;
      await tester.tap(find.text(adem.titleFor('tr')));
      await tester.pumpAndSettle();
      expect(find.byType(StoryDetailView), findsOneWidget);
      expect(find.text(adem.paragraphsFor('tr').first), findsOneWidget);
      expect(find.text('— ${adem.sourceFor('tr')}'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
