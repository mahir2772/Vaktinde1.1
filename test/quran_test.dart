// Kur'an-ı Kerim: gömülü sure listesi (114 sure, 6236 ayet), alquran.cloud
// yanıtının ayrıştırılması (besmele ayrı başlıkta), cihazdaki kopya (sınırlı
// önbellek), kaldığın yer, yazı boyutu ve tr/ar %130 yazıda liste + okuyucu.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String _surahsJson = File('assets/data/surahs.json').readAsStringSync();
final List<Surah> _surahs = QuranService.parseSurahs(_surahsJson);
Surah _surah(int number) => _surahs[number - 1];

/// alquran.cloud `surah/112/editions/quran-uthmani,tr.diyanet` yanıtı
final String _fixture = File(
  'test/fixtures/quran_surah_112.json',
).readAsStringSync();
final List<Map<String, dynamic>> _fixtureEditions = [
  for (final e in (jsonDecode(_fixture) as Map)['data'] as List)
    e as Map<String, dynamic>,
];
List<String> _fixtureTexts(int edition) => [
  for (final a in _fixtureEditions[edition]['ayahs'] as List)
    (a as Map)['text'] as String,
];
final List<String> _arabic = _fixtureTexts(0);
final List<String> _meal = _fixtureTexts(1);

/// Besmelesiz ilk ayet ("Kul hüvallâhü ehad")
final String _ikhlas1 = _arabic[0].substring(
  QuranService.bismillahText.length + 1,
);

/// Arapça arayüzün isteği: sadece Arapça baskı
final String _fixtureArabicOnly = jsonEncode({
  'code': 200,
  'status': 'OK',
  'data': [_fixtureEditions[0]],
});

/// alquran.cloud biçiminde yanıt (ilk ayetin başında besmele, Fâtiha ve Tevbe
/// hariç — API'deki gibi)
String _response(
  int surah,
  List<String> arabic, {
  List<String>? translation,
  String translationId = 'tr.diyanet',
  bool identifiers = true,
  bool withBismillah = true,
}) {
  final texts = [...arabic];
  if (withBismillah && surah != 1 && surah != 9) {
    texts[0] = '${QuranService.bismillahText} ${texts[0]}';
  }
  Map<String, Object?> edition(List<String> ayahs, String id) => {
    'number': surah,
    'numberOfAyahs': ayahs.length,
    'ayahs': [
      for (var i = 0; i < ayahs.length; i++)
        {'number': 5000 + i, 'text': ayahs[i], 'numberInSurah': i + 1},
    ],
    if (identifiers) 'edition': {'identifier': id},
  };
  return jsonEncode({
    'code': 200,
    'status': 'OK',
    'data': [
      edition(texts, QuranEdition.arabic),
      if (translation != null) edition(translation, translationId),
    ],
  });
}

/// [n] ayetlik yapay sure metni
List<String> _texts(int n, String word) => [
  for (var i = 1; i <= n; i++) '$word $i',
];

/// Yapay ağ: 112 için fikstür, diğer sureler için üretilmiş yanıt
String _fakeResponse(Uri url) {
  final match = RegExp(r'/surah/(\d+)/editions/(.+)$').firstMatch('$url')!;
  final number = int.parse(match.group(1)!);
  final editions = match.group(2)!.split(',');
  final translation = editions.length > 1 ? editions[1] : null;
  if (number == 112) {
    return translation == null ? _fixtureArabicOnly : _fixture;
  }
  final count = _surah(number).ayahCount;
  return _response(
    number,
    _texts(count, 'آية'),
    translation: translation == null ? null : _texts(count, 'meal'),
    translationId: translation ?? 'tr.diyanet',
  );
}

QuranService _service({
  List<Uri>? calls,
  Future<String?> Function(Uri url)? fetch,
}) => QuranService(
  loadAsset: () async => _surahsJson,
  fetch: (url) async {
    calls?.add(url);
    return fetch == null ? _fakeResponse(url) : fetch(url);
  },
);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('Sure listesi (assets/data/surahs.json)', () {
    test('114 sure, 6236 ayet; numaralar 1..114 sırayla ve tekil', () {
      final raw = jsonDecode(_surahsJson) as List;
      expect(raw, hasLength(QuranService.surahCount));
      // Geçersiz sayılıp atlanan kayıt yok
      expect(_surahs, hasLength(114));
      expect(
        [for (final s in _surahs) s.number],
        [for (var i = 1; i <= 114; i++) i],
      );
      expect(
        _surahs.fold<int>(0, (sum, s) => sum + s.ayahCount),
        QuranService.totalAyahs,
      );
      expect(QuranService.totalAyahs, 6236);
      for (final names in [
        [for (final s in _surahs) s.name],
        [for (final s in _surahs) s.englishName],
        [for (final s in _surahs) s.arabicName],
      ]) {
        expect(names.toSet(), hasLength(114));
      }
      // Her kayıtta yalnızca beklenen alanlar
      for (final e in raw) {
        expect((e as Map).keys.toSet(), {
          'number',
          'arabicName',
          'name',
          'englishName',
          'ayahCount',
          'revelation',
        });
      }
    });

    test('bilinen sureler', () {
      void check(
        int n,
        String tr,
        String en,
        String ar,
        int ayahs,
        String revelation,
      ) {
        final s = _surah(n);
        expect(
          [s.number, s.name, s.englishName, s.arabicName, s.ayahCount],
          [n, tr, en, ar, ayahs],
        );
        expect(s.revelation, revelation, reason: tr);
      }

      check(1, 'Fâtiha', 'Al-Fatihah', 'الفاتحة', 7, 'Mekke');
      check(2, 'Bakara', 'Al-Baqarah', 'البقرة', 286, 'Medine');
      check(9, 'Tevbe', 'At-Tawbah', 'التوبة', 129, 'Medine');
      check(18, 'Kehf', 'Al-Kahf', 'الكهف', 110, 'Mekke');
      check(36, 'Yâsîn', 'Ya-Sin', 'يس', 83, 'Mekke');
      check(67, 'Mülk', 'Al-Mulk', 'الملك', 30, 'Mekke');
      check(112, 'İhlâs', 'Al-Ikhlas', 'الإخلاص', 4, 'Mekke');
      check(114, 'Nâs', 'An-Nas', 'الناس', 6, 'Mekke');
      // En kısa / en uzun
      expect(
        _surahs.map((s) => s.ayahCount).reduce((a, b) => a < b ? a : b),
        3,
      );
      expect(
        _surahs.map((s) => s.ayahCount).reduce((a, b) => a > b ? a : b),
        286,
      );
    });

    test('28 Medine suresi (alquran.cloud / Tanzil sınıflaması)', () {
      expect(
        {
          for (final s in _surahs)
            if (s.isMedinan) s.number,
        },
        {
          2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 55, //
          57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 99, 110,
        },
      );
      expect(_surahs.where((s) => !s.isMedinan), hasLength(86));
    });

    test('dile göre ad: tr Türkçe, ar Arapça, en/de/fr Latin okunuş', () {
      final bakara = _surah(2);
      expect(bakara.displayName('tr'), 'Bakara');
      expect(bakara.displayName('ar'), 'البقرة');
      for (final lang in ['en', 'de', 'fr']) {
        expect(bakara.displayName(lang), 'Al-Baqarah');
      }
    });

    test('bozuk kayıt atlanır', () {
      final surahs = QuranService.parseSurahs(
        jsonEncode([
          {
            'number': 115,
            'arabicName': 'x',
            'name': 'x',
            'englishName': 'x',
            'ayahCount': 1,
            'revelation': 'Mekke',
          },
          {
            'number': 1,
            'arabicName': 'الفاتحة',
            'name': 'Fâtiha',
            'englishName': 'Al-Fatihah',
            'ayahCount': 7,
            'revelation': 'Mekka',
          },
          {'number': 2, 'name': 'Bakara'},
          'kayıt',
          {
            'number': 3,
            'arabicName': 'آل عمران',
            'name': 'Âl-i İmrân',
            'englishName': "Ali 'Imran",
            'ayahCount': 200,
            'revelation': 'Medine',
          },
        ]),
      );
      expect(surahs.map((s) => s.number), [3]);
      expect(QuranService.parseSurahs('{}'), isEmpty);
    });
  });

  group('Baskılar (günün ayeti ile ortak)', () {
    test('dile göre meal; Arapça arayüzde sadece Arapça', () {
      expect(QuranEdition.translationFor('tr'), 'tr.diyanet');
      expect(QuranEdition.translationFor('en'), 'en.sahih');
      expect(QuranEdition.translationFor('de'), 'de.aburida');
      expect(QuranEdition.translationFor('fr'), 'fr.hamidullah');
      expect(QuranEdition.translationFor('ar'), isNull);
      expect(QuranEdition.translationFor('es'), 'en.sahih');
      expect(
        '${QuranService.surahUrl(112, 'tr')}',
        'https://api.alquran.cloud/v1/surah/112/editions/quran-uthmani,tr.diyanet',
      );
      expect(
        '${QuranService.surahUrl(2, 'fr')}',
        'https://api.alquran.cloud/v1/surah/2/editions/quran-uthmani,fr.hamidullah',
      );
      expect(
        '${QuranService.surahUrl(1, 'ar')}',
        'https://api.alquran.cloud/v1/surah/1/editions/quran-uthmani',
      );
      for (final lang in ['tr', 'en', 'de', 'fr']) {
        expect(
          QuranEdition.translatorOf(QuranEdition.translationFor(lang)!),
          isNotNull,
        );
      }
    });

    test('günün ayeti aynı eşlemeyi kullanır', () {
      final source = File(
        'lib/data/services/ayah_service.dart',
      ).readAsStringSync();
      expect(source, contains('QuranEdition.translationFor(languageCode)'));
      for (final edition in ['tr.diyanet', 'en.sahih', 'de.aburida']) {
        expect(source, isNot(contains(edition)));
      }
    });
  });

  group('API yanıtı', () {
    SurahText? parse(
      String raw, {
      int surah = 112,
      int? ayahCount,
      String? translation = 'tr.diyanet',
    }) => QuranService.parseSurahResponse(
      raw,
      surah: surah,
      ayahCount: ayahCount ?? _surah(surah).ayahCount,
      translationEdition: translation,
    );

    test('fikstür (İhlâs): besmele başlıkta, 1. ayet besmelesiz, meal '
        'ayetlerle eşleşir', () {
      expect(_arabic[0], startsWith(QuranService.bismillahText));
      final text = parse(_fixture)!;
      expect(text.surah, 112);
      expect(text.translationEdition, 'tr.diyanet');
      expect(text.bismillah, QuranService.bismillahText);
      expect(text.ayahs.map((a) => a.number), [1, 2, 3, 4]);
      expect(text.ayahs.first.arabic, _ikhlas1);
      expect(text.ayahs.first.arabic, isNot(contains('ٱلرَّحِيمِ')));
      expect(text.ayahs.skip(1).map((a) => a.arabic), _arabic.skip(1));
      expect(text.ayahs.map((a) => a.translation), _meal);
      expect(text.ayahs.first.translation, "De ki: O, Allah'tır, bir tektir.");
    });

    test('Arapça arayüz: tek baskı, meal yok; data tek nesne de olabilir', () {
      final text = parse(_fixtureArabicOnly, translation: null)!;
      expect(text.translationEdition, isNull);
      expect(text.ayahs.every((a) => a.translation == null), isTrue);
      expect(text.ayahs.first.arabic, _ikhlas1);
      final single = jsonEncode({'code': 200, 'data': _fixtureEditions[0]});
      expect(parse(single, translation: null)!.ayahs, hasLength(4));
    });

    test('baskı sırası kimlikle; kimlik yoksa önce Arapça', () {
      final reversed = jsonEncode({
        'data': [_fixtureEditions[1], _fixtureEditions[0]],
      });
      expect(parse(reversed)!.ayahs.first.translation, _meal[0]);
      expect(parse(reversed)!.ayahs.first.arabic, _ikhlas1);
      final noIds = _response(
        113,
        _texts(5, 'آية'),
        translation: _texts(5, 'meal'),
        identifiers: false,
      );
      final text = parse(noIds, surah: 113)!;
      expect(text.ayahs.first.arabic, 'آية 1');
      expect(text.ayahs.last.translation, 'meal 5');
    });

    test('besmele farklı yazılışlarla da ayrılır', () {
      const b = QuranService.bismillahText;
      final variants = <String, String>{
        'BOM': '\uFEFF$b',
        'tatvil': b.replaceFirst(
          '\u0645\u064E\u0670',
          '\u0645\u064E\u0640\u0670',
        ),
        'şedde/üstün sırası': b.replaceAll('\u0651\u064E', '\u064E\u0651'),
        'şeddeli be': b.replaceFirst('\u0628\u0650', '\u0628\u0651\u0650'),
        'harekesiz': 'بسم الله الرحمن الرحيم',
        'sükun (U+0652)': b.replaceAll('\u06E1', '\u0652'),
      };
      for (final MapEntry(key: name, value: prefix) in variants.entries) {
        expect(prefix, isNot(b), reason: name); // gerçekten farklı yazılış
        final split = QuranService.splitBismillah('$prefix  $_ikhlas1 ');
        expect(split, isNotNull, reason: name);
        expect(split!.rest, _ikhlas1, reason: name);
        expect(
          QuranService.splitBismillah(split.bismillah),
          isNull, // ardından metin yok
          reason: name,
        );
      }
      // Besmele değil / eksik
      expect(QuranService.splitBismillah(_ikhlas1), isNull);
      expect(QuranService.splitBismillah(b), isNull);
      expect(QuranService.splitBismillah('بسم الله الرحيم قل هو'), isNull);
      expect(QuranService.splitBismillah('باسم الله الرحمن الرحيم قل'), isNull);
      expect(QuranService.splitBismillah(''), isNull);
    });

    test('Fâtiha: besmele 1. ayettir, ayrı başlık yok', () {
      final text = parse(
        _response(1, [QuranService.bismillahText, ..._texts(6, 'آية')]),
        surah: 1,
        translation: null,
      )!;
      expect(text.bismillah, isNull);
      expect(text.ayahs.first.arabic, QuranService.bismillahText);
      expect(text.ayahs, hasLength(7));
    });

    test('Tevbe: besmele yok, başlık yok', () {
      final text = parse(
        _response(9, _texts(129, 'آية'), translation: _texts(129, 'meal')),
        surah: 9,
      )!;
      expect(text.bismillah, isNull);
      expect(text.ayahs.first.arabic, 'آية 1');
    });

    test(
      'besmelesiz gelen ilk ayet değişmez, başlıkta besmele yine görünür',
      () {
        final text = parse(
          _response(113, _texts(5, 'آية'), withBismillah: false),
          surah: 113,
          translation: null,
        )!;
        expect(text.bismillah, QuranService.bismillahText);
        expect(text.ayahs.first.arabic, 'آية 1');
      },
    );

    test('bozuk yanıt null', () {
      final good = jsonDecode(_fixture) as Map<String, dynamic>;
      String mutate(void Function(List<dynamic> data) change) {
        final copy = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
        change(copy['data'] as List);
        return jsonEncode(copy);
      }

      for (final (name, raw) in [
        ('json değil', '<html>502</html>'),
        ('boş', ''),
        ('data yok', '{"code":404,"status":"NOT FOUND","data":"Not found"}'),
        ('boş liste', '{"data":[]}'),
        ('meal eksik', _fixtureArabicOnly),
        ('ayet eksik', mutate((d) => (d[0]['ayahs'] as List).removeLast())),
        (
          'fazla ayet',
          mutate((d) => (d[1]['ayahs'] as List).add(d[1]['ayahs'][0])),
        ),
        ('boş metin', mutate((d) => d[0]['ayahs'][2]['text'] = '  ')),
        (
          'yinelenen numara',
          mutate((d) => d[1]['ayahs'][3]['numberInSurah'] = 3),
        ),
        (
          'numara yok',
          mutate((d) => (d[0]['ayahs'][1] as Map).remove('numberInSurah')),
        ),
        (
          'başka meal',
          mutate((d) => d[1]['edition']['identifier'] = 'tr.ates'),
        ),
      ]) {
        expect(parse(raw), isNull, reason: name);
      }
      // Ayet sayısı listedekiyle aynı olmalı
      expect(parse(_fixture, ayahCount: 5), isNull);
      expect(parse(_fixture), isNotNull);
    });
  });

  group('Cihazdaki kopya', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('indirilen sure saklanır, ağ yokken kopyadan açılır', () async {
      final calls = <Uri>[];
      final online = _service(calls: calls);
      final first = await online.loadSurah(_surah(112), 'tr');
      expect(calls, [QuranService.surahUrl(112, 'tr')]);
      expect(first.ayahs.first.arabic, _ikhlas1);

      final prefs = await SharedPreferences.getInstance();
      final key = QuranService.cacheKey(112, 'tr.diyanet');
      expect(key, 'quran_surah_112_tr.diyanet');
      expect(prefs.getString(key), isNotNull);
      expect(prefs.getStringList(QuranService.cacheIndexKey), [key]);

      final offline = _service(
        calls: calls,
        fetch: (_) async => throw const SocketException('yok'),
      );
      final cached = await offline.loadSurah(_surah(112), 'tr');
      expect(calls, hasLength(1)); // ağa çıkmadı
      expect(cached.bismillah, QuranService.bismillahText);
      expect(
        cached.ayahs.map((a) => a.arabic),
        first.ayahs.map((a) => a.arabic),
      );
      expect(cached.ayahs.map((a) => a.translation), _meal);

      // Başka dil: ayrı kopya (Arapça arayüzde meal yok)
      final ar = await online.loadSurah(_surah(112), 'ar');
      expect(calls.last, QuranService.surahUrl(112, 'ar'));
      expect(ar.ayahs.first.translation, isNull);
      expect(prefs.getStringList(QuranService.cacheIndexKey), [
        'quran_surah_112_quran-uthmani',
        key,
      ]);
      await expectLater(
        offline.loadSurah(_surah(1), 'tr'),
        throwsA(isA<SocketException>()),
      );
    });

    test(
      'kopya okununca en yeni olur; bozuk kopya silinip yeniden indirilir',
      () async {
        final calls = <Uri>[];
        final service = _service(calls: calls);
        await service.loadSurah(_surah(112), 'tr');
        await service.loadSurah(_surah(113), 'tr');
        final prefs = await SharedPreferences.getInstance();
        final k112 = QuranService.cacheKey(112, 'tr.diyanet');
        final k113 = QuranService.cacheKey(113, 'tr.diyanet');
        expect(prefs.getStringList(QuranService.cacheIndexKey), [k113, k112]);
        await service.loadSurah(_surah(112), 'tr');
        expect(calls, hasLength(2));
        expect(prefs.getStringList(QuranService.cacheIndexKey), [k112, k113]);

        for (final bad in [
          'bozuk',
          '{"v":99}',
          // Başka surenin kopyası
          prefs.getString(k113)!,
        ]) {
          await prefs.setString(k112, bad);
          final text = await service.loadSurah(_surah(112), 'tr');
          expect(text.ayahs, hasLength(4));
          expect(
            QuranService.decodeCache(
              prefs.getString(k112),
              _surah(112),
              'tr.diyanet',
            ),
            isNotNull,
          );
        }
        expect(calls, hasLength(5));
      },
    );

    test('ağ hatası ya da bozuk yanıt: hata, kopya yazılmaz', () async {
      for (final fetch in <Future<String?> Function(Uri)>[
        (_) async => null, // HTTP hata kodu
        (_) async => '<html>503</html>',
        (_) async => _fixtureArabicOnly, // meal eksik
      ]) {
        await expectLater(
          _service(fetch: fetch).loadSurah(_surah(112), 'tr'),
          throwsA(anything),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.startsWith('quran_')), isEmpty);
    });

    test('sınır: en çok ${QuranService.maxCachedSurahs} sure; en eski silinir, '
        'kaldığın yerin suresi korunur', () async {
      final calls = <Uri>[];
      final service = _service(calls: calls);
      await service.saveBookmark(const QuranBookmark(surah: 104, ayah: 2));
      // 104..114: 11 kısa sure
      for (var n = 104; n <= 114; n++) {
        await service.loadSurah(_surah(n), 'tr');
      }
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getStringList(QuranService.cacheIndexKey)!;
      expect(index, hasLength(QuranService.maxCachedSurahs));
      expect(index.first, QuranService.cacheKey(114, 'tr.diyanet'));
      expect(index, contains(QuranService.cacheKey(104, 'tr.diyanet')));
      expect(index, isNot(contains(QuranService.cacheKey(105, 'tr.diyanet'))));
      expect(prefs.getString(QuranService.cacheKey(105, 'tr.diyanet')), isNull);
      expect(
        prefs.getKeys().where((k) => k.startsWith(QuranService.cachePrefix)),
        hasLength(QuranService.maxCachedSurahs),
      );

      calls.clear();
      await service.loadSurah(_surah(104), 'tr'); // korundu: ağsız
      expect(calls, isEmpty);
      await service.loadSurah(_surah(105), 'tr'); // silindi: yeniden indirilir
      expect(calls, [QuranService.surahUrl(105, 'tr')]);
    });

    test('karakter sınırı: uzun sure eskileri siler, kendisi kalır', () async {
      final long = List.filled(1500, 'ب').join();
      final service = _service(
        fetch: (url) async => '$url'.contains('/surah/2/')
            ? _response(
                2,
                List.filled(286, long),
                translation: _texts(286, 'meal'),
              )
            : _fakeResponse(url),
      );
      await service.loadSurah(_surah(112), 'tr');
      await service.loadSurah(_surah(2), 'tr');
      final prefs = await SharedPreferences.getInstance();
      final k2 = QuranService.cacheKey(2, 'tr.diyanet');
      expect(
        prefs.getString(k2)!.length,
        greaterThan(QuranService.maxCachedChars),
      );
      expect(prefs.getStringList(QuranService.cacheIndexKey), [k2]);
      expect(prefs.getString(QuranService.cacheKey(112, 'tr.diyanet')), isNull);
      // Uzun surenin kopyası da okunur
      final cached = await _service(
        fetch: (_) async => throw const SocketException('yok'),
      ).loadSurah(_surah(2), 'tr');
      expect(cached.ayahs, hasLength(286));
      expect(cached.ayahs.first.arabic, long);
    });
  });

  group('Kaldığın yer ve yazı boyutu', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('kaydedilir, okunur, silinir', () async {
      final service = _service();
      expect(await service.loadBookmark(), isNull);
      await service.saveBookmark(const QuranBookmark(surah: 2, ayah: 255));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(QuranService.bookmarkKey),
        '{"surah":2,"ayah":255}',
      );
      expect(
        await _service().loadBookmark(),
        const QuranBookmark(surah: 2, ayah: 255),
      );
      await service.clearBookmark();
      expect(await service.loadBookmark(), isNull);
      expect(prefs.containsKey(QuranService.bookmarkKey), isFalse);
    });

    test('bozuk kayıt yok sayılır', () async {
      for (final raw in [
        'bozuk',
        '[]',
        '{"surah":2}',
        '{"surah":0,"ayah":1}',
        '{"surah":115,"ayah":1}',
        '{"surah":2,"ayah":0}',
        '{"surah":"2","ayah":1}',
      ]) {
        SharedPreferences.setMockInitialValues({QuranService.bookmarkKey: raw});
        expect(await _service().loadBookmark(), isNull, reason: raw);
      }
      SharedPreferences.setMockInitialValues({QuranService.bookmarkKey: 7});
      expect(await _service().loadBookmark(), isNull);
    });

    test('yazı boyutu: varsayılan 1, sınırlar ve 0,1 adım', () async {
      final service = _service();
      expect(await service.loadFontScale(), 1);
      await service.saveFontScale(1.2000000001);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble(QuranService.fontScaleKey), 1.2);
      expect(await service.loadFontScale(), 1.2);
      expect(QuranService.clampFontScale(0.3), QuranService.minFontScale);
      expect(QuranService.clampFontScale(9), QuranService.maxFontScale);
      expect(QuranService.clampFontScale(1.04), 1.0);
      expect(QuranService.clampFontScale(double.nan), 1);
      expect(QuranService.clampFontScale(0.9 + 0.1), 1.0);
      await prefs.setDouble(QuranService.fontScaleKey, 5);
      expect(await service.loadFontScale(), QuranService.maxFontScale);
    });
  });

  group('Ekran', () {
    setUpAll(() async {
      await _loadFont('Poppins', [
        for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'assets/google_fonts/Poppins-$w.ttf',
      ]);
      await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
      // Araçlar'dan açılan gerçek servis listeyi rootBundle'dan okur: önbellek
      // gerçek zaman bölgesinde dolsun (sahte zamanda bekleyen Future kalmasın)
      await rootBundle.loadString(QuranService.surahsAsset);
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      messenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (message) async =>
            const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    });

    /// Sabit adımlar; gerçek zamanlı kısa bekleme gerçek bölgede önceden
    /// yüklenen varlığın (rootBundle) Future'ı tamamlansın diye
    Future<void> settle(WidgetTester tester) async {
      for (var round = 0; round < 2; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    Future<void> pump(
      WidgetTester tester,
      Widget home, {
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
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await settle(tester);
    }

    Future<void> dispose(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }

    Future<void> scrollThrough(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Finder ayahCard(String arabic) =>
        find.ancestor(of: find.text(arabic), matching: find.byType(AppCard));

    /// Ayet kartını tümüyle ekrana getirir (küçük ekranda aşağıda kalabilir;
    /// metin görünürken düğme satırı AppBar altında kalmasın)
    Future<void> reveal(WidgetTester tester, String arabic) async {
      await tester.scrollUntilVisible(
        find.text(arabic),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.ensureVisible(ayahCard(arabic));
      await tester.pump();
    }

    for (final lang in ['tr', 'ar']) {
      for (final dark in [false, true]) {
        testWidgets('$lang ${dark ? 'koyu' : 'açık'}: liste ve okuyucu, '
            '320dp, %130 yazı, taşma yok', (tester) async {
          final calls = <Uri>[];
          await pump(
            tester,
            QuranView(service: _service(calls: calls)),
            lang: lang,
            dark: dark,
          );
          final loc = lookupAppLocalizations(Locale(lang));
          final isArabic = lang == 'ar';
          expect(find.text(loc.quranTitle), findsOneWidget);
          expect(find.text(isArabic ? 'الفاتحة' : 'Fâtiha'), findsOneWidget);
          expect(find.text(loc.quranContinue), findsNothing);
          expect(calls, isEmpty); // liste gömülü
          expect(tester.takeException(), isNull);

          final ikhlas = find.text(isArabic ? 'الإخلاص' : 'İhlâs');
          await tester.scrollUntilVisible(ikhlas, 500);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.tap(ikhlas);
          await settle(tester);

          expect(find.byType(SurahReaderView), findsOneWidget);
          expect(calls, [QuranService.surahUrl(112, lang)]);
          expect(find.text(QuranService.bismillahText), findsOneWidget);
          expect(find.text(_ikhlas1), findsOneWidget);
          expect(find.text(_meal[0]), isArabic ? findsNothing : findsOneWidget);
          expect(tester.takeException(), isNull);

          await scrollThrough(tester);
          expect(find.text(_arabic[3]), findsOneWidget);
          expect(find.text(loc.quranTextSource), findsOneWidget);
          expect(
            find.text(loc.quranTranslationSource('Diyanet İşleri')),
            isArabic ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await dispose(tester);
        });
      }
    }

    testWidgets('kaldığın yer: ikonla kaydedilir, listede devam kartı, '
        'karttan o ayetten açılır', (tester) async {
      await pump(tester, QuranView(service: _service()), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      final prefs = await SharedPreferences.getInstance();
      await tester.scrollUntilVisible(find.text('İhlâs'), 500);
      await tester.pump();
      await tester.tap(find.text('İhlâs'));
      await settle(tester);

      await reveal(tester, _arabic[2]);
      await tester.tap(
        find.descendant(
          of: ayahCard(_arabic[2]),
          matching: find.byTooltip(loc.quranBookmarkSave),
        ),
      );
      await settle(tester);
      expect(
        prefs.getString(QuranService.bookmarkKey),
        '{"surah":112,"ayah":3}',
      );
      expect(find.text(loc.quranBookmarkSaved), findsOneWidget);
      expect(
        find.descendant(
          of: ayahCard(_arabic[2]),
          matching: find.byTooltip(loc.quranBookmarkRemove),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await tester.scrollUntilVisible(find.text(loc.quranContinue), -2000);
      await tester.pump();
      expect(find.text(loc.quranAyahRef('İhlâs', 3)), findsOneWidget);
      expect(loc.quranAyahRef('İhlâs', 3), 'İhlâs 3. ayet');

      await tester.tap(find.text(loc.quranContinue));
      await settle(tester);
      // 3. ayet en üstte; başlık ve önceki ayetler yukarıda
      final appBar = tester.getRect(find.byType(AppBar));
      final top = tester.getRect(ayahCard(_arabic[2])).top;
      expect(top - appBar.bottom, inInclusiveRange(0, AppSpacing.lg));
      expect(find.text(QuranService.bismillahText), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 800));
      await settle(tester);
      expect(find.text(QuranService.bismillahText), findsOneWidget);
      expect(find.text(_ikhlas1), findsOneWidget);

      // Kayıtlı ayette ikon kaldırır
      await reveal(tester, _arabic[2]);
      await tester.tap(
        find.descendant(
          of: ayahCard(_arabic[2]),
          matching: find.byTooltip(loc.quranBookmarkRemove),
        ),
      );
      await settle(tester);
      expect(prefs.containsKey(QuranService.bookmarkKey), isFalse);
      expect(find.text(loc.quranBookmarkRemoved), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text(loc.quranContinue), findsNothing);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('uzun basma kaydeder; A+/A- Arapça yazı boyutunu saklar', (
      tester,
    ) async {
      final loc = lookupAppLocalizations(const Locale('tr'));
      final prefs = await SharedPreferences.getInstance();
      Future<void> open() => pump(
        tester,
        SurahReaderView(surah: _surah(112), service: _service()),
        textScale: 1,
      );
      double size() => tester
          .widget<Text>(find.text(_arabic[1], skipOffstage: false))
          .style!
          .fontSize!;
      IconButton button(String tooltip) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

      await open();
      await reveal(tester, _arabic[1]);
      await tester.longPress(find.text(_arabic[1]));
      await settle(tester);
      expect(
        prefs.getString(QuranService.bookmarkKey),
        '{"surah":112,"ayah":2}',
      );
      // Uzun basma kaydı silmez
      await tester.longPress(find.text(_arabic[1]));
      await settle(tester);
      expect(prefs.getString(QuranService.bookmarkKey), isNotNull);

      expect(size(), 26);
      await tester.tap(find.byTooltip(loc.quranFontLarger));
      await tester.pump();
      await tester.tap(find.byTooltip(loc.quranFontLarger));
      await tester.pump();
      expect(size(), closeTo(26 * 1.2, 1e-9));
      expect(prefs.getDouble(QuranService.fontScaleKey), 1.2);
      await tester.tap(find.byTooltip(loc.quranFontSmaller));
      await tester.pump();
      expect(prefs.getDouble(QuranService.fontScaleKey), 1.1);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byTooltip(loc.quranFontLarger));
        await tester.pump();
      }
      expect(
        prefs.getDouble(QuranService.fontScaleKey),
        QuranService.maxFontScale,
      );
      expect(button(loc.quranFontLarger).onPressed, isNull);
      expect(button(loc.quranFontSmaller).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await dispose(tester);

      // Yeniden açılışta saklanan boyut
      await open();
      await reveal(tester, _arabic[1]);
      expect(size(), closeTo(26 * QuranService.maxFontScale, 1e-9));
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('ağ yokken hata ve Tekrar Dene; ikinci denemede açılır', (
      tester,
    ) async {
      var online = false;
      final service = _service(
        fetch: (url) async {
          if (!online) throw const SocketException('yok');
          return _fakeResponse(url);
        },
      );
      await pump(
        tester,
        SurahReaderView(surah: _surah(112), service: service),
        lang: 'ar',
      );
      final loc = lookupAppLocalizations(const Locale('ar'));
      expect(find.text(loc.quranLoadError), findsOneWidget);
      expect(tester.takeException(), isNull);
      online = true;
      await tester.tap(find.text(loc.retry));
      await settle(tester);
      expect(find.text(loc.quranLoadError), findsNothing);
      expect(find.text(_ikhlas1), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('ayet paylaşımı: başlık "<Sure> <n>. ayet", kampanya quran', (
      tester,
    ) async {
      final temp = Directory.systemTemp.createTempSync('vaktinde_quran');
      addTearDown(() => temp.deleteSync(recursive: true));
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      const share = MethodChannel('dev.fluttercommunity.plus/share');
      messenger.setMockMethodCallHandler(
        pathProvider,
        (call) async => temp.path,
      );
      MethodCall? shared;
      messenger.setMockMethodCallHandler(share, (call) async {
        shared = call;
        return 'dev.fluttercommunity.plus/share/success';
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(pathProvider, null);
        messenger.setMockMethodCallHandler(share, null);
      });

      await pump(
        tester,
        SurahReaderView(surah: _surah(112), service: _service()),
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      await reveal(tester, _arabic[1]);
      await tester.tap(
        find.descendant(
          of: ayahCard(_arabic[1]),
          matching: find.byTooltip(loc.quranShareAyah),
        ),
      );
      // Kart çizimi, PNG ve geçici dosya gerçek zaman ister
      for (var i = 0; i < 100 && shared == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(shared?.method, 'shareFiles');
      expect(
        (shared!.arguments as Map)['text'],
        'İhlâs 2. ayet · Vaktinde\n${AppLinks.playStoreLink('quran')}',
      );
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('Araçlar > Bilgi grubunun sonunda; geçiş reklamıyla açılır', (
      tester,
    ) async {
      await pump(
        tester,
        const ToolsView(),
        width: 411,
        height: 891,
        textScale: 1,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.scrollUntilVisible(find.text(loc.quranTitle), 200);
      await tester.pump();
      final quran = tester.getRect(find.text(loc.quranTitle));
      expect(
        quran.top,
        greaterThan(tester.getRect(find.text(loc.fridayMessagesTitle)).top),
      );
      expect(
        quran.top,
        lessThan(tester.getRect(find.text(loc.toolsGroupCalc)).top),
      );
      expect(find.text(loc.toolQuranDesc), findsOneWidget);

      final before = AdHelper.instance.debugShowRequests;
      await tester.tap(find.text(loc.quranTitle));
      await settle(tester);
      expect(AdHelper.instance.debugShowRequests, before + 1);
      expect(find.byType(QuranView), findsOneWidget);
      expect(find.text('Fâtiha'), findsOneWidget);
      // Sure açılışında reklam yok
      await tester.tap(find.text('Fâtiha'));
      await settle(tester);
      expect(find.byType(SurahReaderView), findsOneWidget);
      expect(AdHelper.instance.debugShowRequests, before + 1);
      await dispose(tester);
    });
  });
}
