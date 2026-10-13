// Namaz Hocası: prayer_guide.json bütünlüğü (5 dil, yalnız izinli Arapça
// zikirler, dua bağlantıları duas.json'da, rekât tablosu), ekran sekmeleri,
// dua ve Fâtiha bağlantıları, 320dp %130 yazıda taşmaz (tr/ar), Arapçada RTL.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/duas/view/duas_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/prayer_guide/prayer_guide_data.dart';
import 'package:ezan_saati/features/prayer_guide/view/prayer_guide_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langs = ['tr', 'en', 'de', 'fr', 'ar'];

/// Adımlarda gösterilebilecek Arapça metinlerin tamamı (harfi harfine)
const _allowedArabic = {
  'اللَّهُ أَكْبَرُ',
  'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
  'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ',
  'رَبَّنَا لَكَ الْحَمْدُ',
  'سُبْحَانَ رَبِّيَ الْأَعْلَى',
  'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
  'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
};

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

QuranService _quran() => QuranService(
  loadAsset: () async => File(QuranService.surahsAsset).readAsStringSync(),
  fetch: (_) async => null,
);

Future<void> _pump(
  WidgetTester tester, {
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
        home: PrayerGuideView(quranService: _quran()),
      ),
    ),
  );
  await _settle(tester);
}

/// Açık sekmenin listesi (TabBar da kaydırılabilir; dikey olan liste)
Finder get _list => find.byType(ListView).hitTestable().first;

/// Açık sekmeyi baştan sona gezer (geç çizilen öğeler de denetlensin)
Future<void> _scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.drag(_list, const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
  await tester.drag(_list, const Offset(0, 20000));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PrayerGuide guide;
  late DuaLibrary duas;

  setUpAll(() async {
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
    // Önbelleklenen Future'lar sahte zaman bölgesinde oluşmasın
    guide = await PrayerGuide.load();
    duas = await DuaLibrary.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  });

  group('prayer_guide.json', () {
    final raw =
        json.decode(File(PrayerGuide.asset).readAsStringSync())
            as Map<String, dynamic>;
    final parsed = PrayerGuide.fromJson(raw);
    final library = DuaLibrary.fromJson(
      json.decode(File(DuaLibrary.asset).readAsStringSync())
          as Map<String, dynamic>,
    );

    /// Dile göre metin içeren her harita (zikirlerin anlamı ve okunuşu hariç)
    Iterable<(String, Map)> texts(Object? node, [String path = '']) sync* {
      if (node is Map) {
        if (node.containsKey('tr') && !node.containsKey('latin')) {
          yield (path, node);
          return;
        }
        for (final MapEntry(:key, :value) in node.entries) {
          if (path.startsWith('/dhikr') && key == 'meaning') continue;
          yield* texts(value, '$path/$key');
        }
      } else if (node is List) {
        for (final (i, value) in node.indexed) {
          yield* texts(value, '$path[$i]');
        }
      }
    }

    test(
      'her metin 5 dilde; Fransızcada noktalamadan önce bölünmez boşluk',
      () {
        final all = texts(raw).toList();
        expect(all, hasLength(greaterThan(100)));
        for (final (path, map) in all) {
          expect(map.keys.toSet(), _langs.toSet(), reason: path);
          for (final lang in _langs) {
            expect(map[lang], isA<String>(), reason: '$path $lang');
            expect((map[lang] as String).trim(), isNotEmpty, reason: path);
          }
          final fr = map['fr'] as String;
          expect(fr, isNot(matches(r' [!?:;»]|« ')), reason: fr);
        }
      },
    );

    test(
      'zikirler: yalnız izinli Arapça metinler, okunuş ve 4 dilde anlam',
      () {
        final dhikr = raw['dhikr'] as Map<String, dynamic>;
        expect({
          for (final d in dhikr.values) (d as Map)['arabic'],
        }, _allowedArabic);
        for (final MapEntry(:key, :value) in dhikr.entries) {
          final dua = Dua.fromJson({
            ...value as Map<String, dynamic>,
            'id': key,
          });
          expect(dua.translit['tr'], isNotEmpty, reason: key);
          expect(dua.translit['latin'], isNotEmpty, reason: key);
          for (final lang in ['tr', 'en', 'de', 'fr']) {
            expect(dua.meaning[lang], isNotEmpty, reason: '$key $lang');
          }
          expect(dua.translitFor('ar'), isNull);
          expect(dua.meaningFor('ar'), isNull);
        }
        // Okunuşlar Türkçe harflerle
        final tr = {
          for (final MapEntry(:key, :value) in dhikr.entries)
            key: (value as Map)['translit']['tr'],
        };
        expect(tr['tekbir'], 'Allâhu ekber');
        expect(tr['ruku'], "Sübhâne rabbiye'l-azîm");
        expect(tr['semi'], 'Semiallâhü li men hamideh');
        expect(tr['tahmid'], "Rabbenâ leke'l-hamd");
        expect(tr['sajda'], "Sübhâne rabbiye'l-a'lâ");
        expect(tr['salam'], 'Esselâmü aleyküm ve rahmetullâh');
      },
    );

    test('dua bağlantıları duas.json\'da, sûre bağlantısı sadece Fâtiha', () {
      final steps = [
        for (final s in [...parsed.wudu, ...parsed.fards]) ...s.items,
        for (final m in parsed.methods) ...m.steps,
      ];
      final recite = [for (final s in steps) ...s.recite];
      final duaIds = {for (final r in recite) ?r.dua};
      expect(duaIds, {
        'subhaneke',
        'ettehiyyatu',
        'salli',
        'barik',
        'rabbena_atina',
        'rabbenagfirli',
        'kunut_1',
        'kunut_2',
        'ihlas_felak_nas',
      });
      for (final id in duaIds) {
        expect(library.byId(id), isNotNull, reason: id);
      }
      expect({for (final r in recite) ?r.surah}, {1});
      for (final r in recite.where((r) => r.surah != null)) {
        expect(r.titleFor('tr'), 'Fâtiha Sûresi');
      }
      // Her öge tek türden: zikir, dua, sûre ya da açıklama
      for (final r in recite) {
        final kinds = [
          r.dhikr != null,
          r.dua != null,
          r.surah != null,
          r.text.isNotEmpty && r.dua == null,
        ].where((k) => k);
        expect(kinds, hasLength(1));
      }
    });

    test('abdest ve namazın farzları', () {
      expect(parsed.wudu.map((s) => s.items.length), [4, 9, 7]);
      expect(parsed.fards.map((s) => s.items.length), [6, 6]);
      expect(parsed.wudu.first.items.map((i) => i.textFor('tr')), [
        'Yüzü yıkamak',
        'Kolları dirseklerle birlikte yıkamak',
        'Başın dörtte birini meshetmek',
        'Ayakları topuklarla birlikte yıkamak',
      ]);
      expect(parsed.fards.first.items.map((i) => i.titleFor('tr')), [
        'Hadesten taharet',
        'Necasetten taharet',
        'Setr-i avret',
        'İstikbâl-i kıble',
        'Vakit',
        'Niyet',
      ]);
      expect(parsed.fards.last.items.map((i) => i.titleFor('tr')), [
        'İftitah tekbiri',
        'Kıyam',
        'Kıraat',
        'Rükû',
        'Secde',
        "Ka'de-i âhîre",
      ]);
    });

    test('rekât tablosu', () {
      expect(
        {
          for (final row in parsed.rakats)
            row.id: [for (final p in row.parts) '${p.kind} ${p.count}'],
        },
        {
          'fajr': ['sunnah 2', 'fard 2'],
          'dhuhr': ['first_sunnah 4', 'fard 4', 'last_sunnah 2'],
          'asr': ['sunnah_ghayr 4', 'fard 4'],
          'maghrib': ['fard 3', 'sunnah 2'],
          'isha': ['first_sunnah_ghayr 4', 'fard 4', 'last_sunnah 2', 'witr 3'],
          'jumuah': ['first_sunnah 4', 'fard 2', 'last_sunnah 4'],
        },
      );
      for (final row in parsed.rakats) {
        for (final part in row.parts) {
          for (final lang in _langs) {
            expect(parsed.rakatKindFor(part.kind, lang), isNotEmpty);
          }
        }
      }
    });

    test('kılınış: 2 / 3 / 4 rekâtlı ve vitir adımları', () {
      final methods = {
        for (final m in raw['methods'] as List)
          m['id']: [...m['steps'] as List],
      };
      const first = [
        'niyet',
        'tekbir',
        'kiyam',
        'ruku',
        'kavma',
        'sajda',
        'jalsa',
        'sajda2',
        'rakat2',
      ];
      expect(methods, {
        'two': [...first, 'last_sitting', 'salam'],
        'three': [
          ...first,
          'first_sitting',
          'rakat3_fard',
          'last_sitting',
          'salam',
        ],
        'four': [
          ...first,
          'first_sitting',
          'rakat3_fard',
          'rakat4_fard',
          'last_sitting',
          'salam',
        ],
        'witr': [
          ...first,
          'first_sitting',
          'rakat3_witr',
          'qunut',
          'last_sitting',
          'salam',
        ],
      });
      final steps = raw['steps'] as Map<String, dynamic>;
      List<String> refs(String step) => [
        for (final r in steps[step]['recite'] as List)
          (r['dua'] ??
                  r['dhikr'] ??
                  (r['surah'] == null ? 'text' : 'surah ${r['surah']}'))
              as String,
      ];
      expect(refs('kiyam').take(4), [
        'subhaneke',
        'euzu',
        'besmele',
        'surah 1',
      ]);
      expect(refs('ruku'), ['ruku']);
      expect(refs('kavma'), ['semi', 'tahmid']);
      expect(refs('first_sitting'), ['ettehiyyatu']);
      expect(refs('last_sitting'), [
        'ettehiyyatu',
        'salli',
        'barik',
        'rabbena_atina',
        'rabbenagfirli',
      ]);
      expect(refs('qunut'), ['tekbir', 'kunut_1', 'kunut_2']);
      expect(refs('salam'), ['salam']);
      for (final s in ['ruku', 'sajda', 'sajda2']) {
        expect(steps[s]['recite'].first['times'], 3, reason: s);
      }
      // Farzların 3. ve 4. rekâtında zamm-ı sûre yok, vitirde var
      expect(refs('rakat3_fard'), ['besmele', 'surah 1']);
      expect(steps['rakat3_witr']['text']['tr'], contains('zamm-ı sûre'));
      expect(parsed.methods.last.notes, isEmpty);
      expect(
        parsed.methods.firstWhere((m) => m.id == 'four').notes,
        hasLength(2),
      );
    });
  });

  group('Ekran', () {
    testWidgets('sekmeler: abdest, farzlar, rekâtlar, kılınış', (tester) async {
      await _pump(tester, textScale: 1, width: 411, height: 891);
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.prayerGuideTitle), findsOneWidget);
      expect(find.text(guide.wudu.first.titleFor('tr')), findsOneWidget);
      expect(find.text('Yüzü yıkamak'), findsOneWidget);

      await _openTab(tester, loc.prayerGuideTabFards);
      expect(find.text('Hadesten taharet'), findsOneWidget);

      await _openTab(tester, loc.prayerGuideTabRakats);
      expect(find.text('Sabah'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Vitir (vacip)'),
        200,
        scrollable: find
            .descendant(of: _list, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.text('Vitir (vacip)'), findsOneWidget);

      await _openTab(tester, loc.prayerGuideTabSteps);
      expect(find.text('Ör. sabah namazının farzı'), findsOneWidget);
      expect(find.text('Allâhu ekber'), findsOneWidget);
      expect(find.text('Kunut'), findsNothing);
      await tester.tap(find.text('Vitir'));
      await tester.pump();
      expect(find.text('3 rekât, vacip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('dua bağlantısı dua sayfasını açar', (tester) async {
      await _pump(tester, textScale: 1, width: 411, height: 891);
      final loc = lookupAppLocalizations(const Locale('tr'));
      await _openTab(tester, loc.prayerGuideTabSteps);
      final subhaneke = duas.byId('subhaneke')!;
      final link = find.text(subhaneke.titleFor('tr'));
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
      await _settle(tester);
      final page = tester.widget<DuaDetailView>(find.byType(DuaDetailView));
      expect(page.dua.id, 'subhaneke');
      expect(find.text(subhaneke.arabic), findsOneWidget);

      // Vitir: Kunut duaları
      Navigator.of(tester.element(find.byType(DuaDetailView))).pop();
      await _settle(tester);
      await tester.drag(_list, const Offset(0, 20000));
      await tester.pump();
      await tester.tap(find.text('Vitir'));
      await tester.pump();
      final kunut = find.text(duas.byId('kunut_2')!.titleFor('tr'));
      await tester.scrollUntilVisible(
        kunut,
        300,
        scrollable: find
            .descendant(of: _list, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pump();
      await tester.tap(kunut);
      await _settle(tester);
      expect(
        tester.widget<DuaDetailView>(find.byType(DuaDetailView)).dua.id,
        'kunut_2',
      );
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    testWidgets('Fâtiha bağlantısı Kur\'an okuyucusunda Fâtiha\'yı açar', (
      tester,
    ) async {
      await _pump(tester, textScale: 1, width: 411, height: 891);
      final loc = lookupAppLocalizations(const Locale('tr'));
      await _openTab(tester, loc.prayerGuideTabSteps);
      final link = find.text('Fâtiha Sûresi').first;
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
      await _settle(tester);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect(reader.surah.number, 1);
      expect(reader.surahs, hasLength(QuranService.surahCount));
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: 320dp %130 yazıda her sekme ve kılınış taşmaz', (
        tester,
      ) async {
        await _pump(tester, lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        expect(tester.takeException(), isNull);
        for (final tab in [
          loc.prayerGuideTabWudu,
          loc.prayerGuideTabFards,
          loc.prayerGuideTabRakats,
        ]) {
          await _openTab(tester, tab);
          await _scrollThrough(tester);
        }
        await _openTab(tester, loc.prayerGuideTabSteps);
        for (final method in guide.methods) {
          await tester.tap(find.text(method.titleFor(lang)));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: method.id);
          await _scrollThrough(tester);
        }
        await _dispose(tester);
      });
    }

    testWidgets('ar: sağdan sola, Arapça zikir Amiri, okunuş/anlam yok', (
      tester,
    ) async {
      await _pump(tester, lang: 'ar', textScale: 1, width: 411, height: 891);
      final loc = lookupAppLocalizations(const Locale('ar'));
      expect(
        Directionality.of(tester.element(find.byType(ListView).first)),
        TextDirection.rtl,
      );
      await _openTab(tester, loc.prayerGuideTabSteps);
      final tekbir = tester.widget<Text>(find.text('اللَّهُ أَكْبَرُ'));
      expect(tekbir.textDirection, TextDirection.rtl);
      expect(tekbir.style?.fontFamily, AppTheme.arabicFamily);
      expect(find.text('Allahu akbar'), findsNothing);
      expect(find.text('Allah is the Greatest.'), findsNothing);
      expect(find.text(guide.methods.first.titleFor('ar')), findsOneWidget);
      // Bölüm ve adım başlıkları Arapça
      expect(find.text('النية'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });
  });
}
