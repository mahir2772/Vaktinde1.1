// Kur'an-ı Kerim: gömülü sure listesi (114 sure, 6236 ayet), sure arama ve
// 30 cüz; alquran.cloud yanıtının ayrıştırılması (besmele ayrı başlıkta,
// mushaf bilgisi: sayfa/cüz/hizb/secde), cihazdaki kopya (sınırlı önbellek,
// eski kopya), yer imi, son okunan, görünüm ve yazı boyutları; okuyucunun üç
// görünümü (sayfa, ayet ayet, meal), ayet alt sayfası, "Ayete git",
// önceki/sonraki sure ve tr/ar %130 yazıda tüm görünümler; hatim kartı
// (başlat, ilerleme, menü, bitiş) ve hatim okumasında sırayla ilerleme.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/hatim.dart';
import 'package:ezan_saati/data/services/hatim_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/common/widgets/ad_banner_widget.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/quran/view/surah_reader_view.dart';
import 'package:ezan_saati/features/quran/widgets/ayah_sheet.dart';
import 'package:ezan_saati/features/quran/widgets/go_to_ayah_dialog.dart';
import 'package:ezan_saati/features/quran/widgets/hatim_card.dart';
import 'package:ezan_saati/features/quran/widgets/mushaf_page.dart';
import 'package:ezan_saati/features/quran/widgets/translation_page.dart';
import 'package:ezan_saati/features/quran/widgets/view_settings_sheet.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final String _surahsJson = File('assets/data/surahs.json').readAsStringSync();
final List<Surah> _surahs = QuranService.parseSurahs(_surahsJson);
Surah _surah(int number) => _surahs[number - 1];

List<Map<String, dynamic>> _editionsOf(String raw) => [
  for (final e in (jsonDecode(raw) as Map)['data'] as List)
    e as Map<String, dynamic>,
];

List<String> _textsOf(Map<String, dynamic> edition) => [
  for (final a in edition['ayahs'] as List) (a as Map)['text'] as String,
];

/// alquran.cloud `surah/112/editions/quran-uthmani,tr.diyanet` yanıtı
final String _fixture = File(
  'test/fixtures/quran_surah_112.json',
).readAsStringSync();
final List<Map<String, dynamic>> _fixtureEditions = _editionsOf(_fixture);
final List<String> _arabic = _textsOf(_fixtureEditions[0]);
final List<String> _meal = _textsOf(_fixtureEditions[1]);

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

/// Mülk (67) fikstürü, alquran.cloud biçiminde: 30 ayet, gerçek mushaf
/// bilgisi (sayfa 562: 1–12, 563: 13–26, 564: 27–30; cüz 29)
final String _mulkFixture = File(
  'test/fixtures/quran_surah_67.json',
).readAsStringSync();
final List<Map<String, dynamic>> _mulkEditions = _editionsOf(_mulkFixture);
final List<String> _mulkMeal = _textsOf(_mulkEditions[1]);

/// Mülk ayetinin okuyucudaki Arapçası (1. ayet besmelesiz)
String _mulk(int ayah) {
  final text = _textsOf(_mulkEditions[0])[ayah - 1];
  return ayah == 1 ? QuranService.splitBismillah(text)!.rest : text;
}

/// Mülk yanıtı: meal baskısının kimliği isteğe göre (Arapça arayüzde meal yok)
String _mulkResponse(String? translation) {
  if (translation == null) {
    return jsonEncode({
      'code': 200,
      'data': [_mulkEditions[0]],
    });
  }
  final meal = jsonDecode(jsonEncode(_mulkEditions[1])) as Map<String, dynamic>;
  (meal['edition'] as Map)['identifier'] = translation;
  return jsonEncode({
    'code': 200,
    'data': [_mulkEditions[0], meal],
  });
}

/// Bakara'nın mushaf sayfa başları (sayfa 2–49; quran-meta ile aynı)
const List<int> _bakaraPageStarts = [
  1, 6, 17, 25, 30, 38, 49, 58, 62, 70, 77, 84, 89, 94, 102, 106, 113, //
  120, 127, 135, 142, 146, 154, 164, 170, 177, 182, 187, 191, 197, 203,
  211, 216, 220, 225, 231, 234, 238, 246, 249, 253, 257, 260, 265, 270,
  275, 282, 283,
];

/// Bakara ayetlerinin sayfası (1–5: 2 … 283–286: 49)
final List<int> _bakaraPages = [
  for (var a = 1; a <= 286; a++)
    _bakaraPageStarts.lastIndexWhere((s) => s <= a) + 2,
];

/// alquran.cloud biçiminde yanıt (ilk ayetin başında besmele, Fâtiha ve Tevbe
/// hariç — API'deki gibi). [pages] verilirse ayetlerde mushaf bilgisi
/// (sayfa, cüz, hizb çeyreği, secde) de olur.
String _response(
  int surah,
  List<String> arabic, {
  List<String>? translation,
  String translationId = 'tr.diyanet',
  bool identifiers = true,
  bool withBismillah = true,
  List<int>? pages,
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
        {
          'number': 5000 + i,
          'text': ayahs[i],
          'numberInSurah': i + 1,
          if (pages != null) ...{
            'page': pages[i],
            'juz': QuranService.juzOf(surah, i + 1),
            'hizbQuarter': 1,
            'sajda': false,
          },
        },
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

/// Yapay ağ: 112 ve 67 için fikstür, Bakara gerçek sayfa bilgisiyle, diğer
/// sureler sayfa bilgisi olmadan üretilmiş yanıt
String _fakeResponse(Uri url) {
  final match = RegExp(r'/surah/(\d+)/editions/(.+)$').firstMatch('$url')!;
  final number = int.parse(match.group(1)!);
  final editions = match.group(2)!.split(',');
  final translation = editions.length > 1 ? editions[1] : null;
  if (number == 112) {
    return translation == null ? _fixtureArabicOnly : _fixture;
  }
  if (number == 67) return _mulkResponse(translation);
  final count = _surah(number).ayahCount;
  return _response(
    number,
    _texts(count, 'آية'),
    translation: translation == null ? null : _texts(count, 'meal'),
    translationId: translation ?? 'tr.diyanet',
    pages: number == 2 ? _bakaraPages : null,
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

/// Eski (sürüm 1, mushaf bilgisi yok) İhlâs kopyası
String _legacyIkhlasCache() => jsonEncode({
  'v': 1,
  'surah': 112,
  'edition': 'tr.diyanet',
  'bismillah': QuranService.bismillahText,
  'arabic': [_ikhlas1, ..._arabic.skip(1)],
  'translation': _meal,
});

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Bugün başlamış, 30 gün sonra bitecek hatim; [position] 604 ise bugün bitti
String _hatimPlan(int position, {Map<String, int> log = const {}}) {
  final today = PrayerTracker.day(DateTime.now());
  return HatimPlan(
    start: today,
    target: PrayerTracker.addDays(today, 30),
    position: position,
    log: log,
    finished: position == HatimPlan.pageCount ? today : null,
  ).encode();
}

String _todayKey() => PrayerTracker.dateKey(DateTime.now());

Future<HatimPlan?> _savedPlan() async => HatimPlan.parse(
  (await SharedPreferences.getInstance()).getString(HatimService.planKey),
);

/// Okuyucu / liste kaydırması (TabBarView ve metin alanının yatay
/// kaydırıcıları değil)
Finder _vertical() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

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

  group('Sure arama', () {
    List<int> search(String query) => [
      for (final s in QuranService.searchSurahs(_surahs, query)) s.number,
    ];

    test('harf işaretleri, büyük/küçük harf, boşluk ve tire yok sayılır', () {
      expect(QuranService.searchKey('Yâsîn'), 'yasin');
      expect(QuranService.searchKey('Ya-Sin'), 'yasin');
      expect(QuranService.searchKey('Âl-i İmrân'), 'aliimran');
      expect(QuranService.searchKey("Ali 'Imran"), 'aliimran');
      expect(QuranService.searchKey("En'âm"), 'enam');
      expect(QuranService.searchKey('ŞÛRÂ'), 'sura');
      expect(QuranService.searchKey('الإخلاص'), 'الاخلاص');
      expect(QuranService.searchKey('١١٢'), '112');
      for (final query in ['yasin', 'YASİN', 'Yâsîn', 'ya sin', 'Ya-Sin']) {
        expect(search(query), [36], reason: query);
      }
      expect(search('ali imran'), [3]);
      // Dart'ın küçültmesi: 'İ' → i + U+0307 (üst nokta) de olur
      expect(search('âl-i ${'İmrân'.toLowerCase()}'), [3]);
      expect(search('ihlas'), [112]);
      expect(search('İHLÂS'), [112]);
      expect(search('ikhlas'), [112]); // Latin okunuş (Al-Ikhlas)
      expect(search('bakara'), [2]);
      expect(search('baqarah'), [2]);
    });

    test('Arapça ad: hareke ve hemze yazılışı fark etmez', () {
      expect(search('البقرة'), [2]);
      expect(search('الاخلاص'), [112]);
      expect(search('الإِخْلَاص'), [112]);
      expect(search('الملك'), [67]);
      expect(search('يس'), contains(36));
    });

    test(
      'numara: yazılan rakamlarla başlayan sureler; Arapça-Hint rakamlar',
      () {
        expect(search('36'), [36]);
        expect(search('٣٦'), [36]);
        expect(search('036'), [36]);
        expect(search('11'), [11, 110, 111, 112, 113, 114]);
        expect(search('115'), isEmpty);
        expect(search('0'), isEmpty);
      },
    );

    test('boş sorgu tüm liste; eşleşme yoksa boş', () {
      expect(search(''), hasLength(114));
      expect(search('  - '), hasLength(114));
      expect(search('zzz'), isEmpty);
    });
  });

  group('Cüzler', () {
    test('30 cüz başlangıcı (Hafs, Medine mushafı)', () {
      expect(QuranService.juzStarts, hasLength(QuranService.juzCount));
      expect(
        [for (final s in QuranService.juzStarts) '${s.surah}:${s.ayah}'],
        [
          '1:1', '2:142', '2:253', '3:93', '4:24', '4:148', '5:82', //
          '6:111', '7:88', '8:41', '9:93', '11:6', '12:53', '15:1', '17:1',
          '18:75', '21:1', '23:1', '25:21', '27:56', '29:46', '33:31',
          '36:28', '39:32', '41:47', '46:1', '51:31', '58:1', '67:1', '78:1',
        ],
      );
      // Sırayla artar; her başlangıç suresinin ayet sayısı içinde
      for (var i = 0; i < QuranService.juzStarts.length; i++) {
        final start = QuranService.juzStarts[i];
        expect(start.ayah, lessThanOrEqualTo(_surah(start.surah).ayahCount));
        if (i == 0) continue;
        final previous = QuranService.juzStarts[i - 1];
        expect(
          start.surah > previous.surah ||
              (start.surah == previous.surah && start.ayah > previous.ayah),
          isTrue,
          reason: 'cüz ${i + 1}',
        );
      }
    });

    test('ayetin cüzü', () {
      expect(QuranService.juzOf(1, 1), 1);
      expect(QuranService.juzOf(2, 141), 1);
      expect(QuranService.juzOf(2, 142), 2);
      expect(QuranService.juzOf(2, 252), 2);
      expect(QuranService.juzOf(2, 253), 3);
      expect(QuranService.juzOf(36, 27), 22);
      expect(QuranService.juzOf(36, 28), 23);
      expect(QuranService.juzOf(66, 12), 28);
      expect(QuranService.juzOf(67, 1), 29);
      expect(QuranService.juzOf(77, 50), 29);
      expect(QuranService.juzOf(78, 1), 30);
      expect(QuranService.juzOf(114, 6), 30);
      for (var juz = 1; juz <= 30; juz++) {
        final start = QuranService.juzStarts[juz - 1];
        expect(QuranService.juzOf(start.surah, start.ayah), juz);
      }
    });

    test('fikstürlerin cüz bilgisi tabloyla aynı', () {
      for (final (raw, surah) in [(_fixture, 112), (_mulkFixture, 67)]) {
        for (final a in _editionsOf(raw)[0]['ayahs'] as List) {
          final ayah = a as Map;
          expect(
            ayah['juz'],
            QuranService.juzOf(surah, ayah['numberInSurah'] as int),
            reason: '$surah:${ayah['numberInSurah']}',
          );
        }
      }
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

    test('mushaf bilgisi Arapça baskıdan: sayfa, cüz, hizb çeyreği, secde', () {
      final ikhlas = parse(_fixture)!;
      expect(ikhlas.hasPageInfo, isTrue);
      for (final a in ikhlas.ayahs) {
        expect([a.page, a.juz, a.hizbQuarter, a.sajda], [604, 30, 240, false]);
      }
      final mulk = parse(_mulkFixture, surah: 67)!;
      expect(mulk.hasPageInfo, isTrue);
      expect(mulk.ayahs.first.arabic, _mulk(1));
      expect(mulk.ayahs.map((a) => a.translation), _mulkMeal);
      expect(
        [for (final a in mulk.ayahs) a.page],
        [for (var n = 1; n <= 30; n++) n <= 12 ? 562 : (n <= 26 ? 563 : 564)],
      );
      expect(mulk.ayahs.map((a) => a.juz).toSet(), {29});
      expect(mulk.ayahs.every((a) => !a.sajda), isTrue);

      // Secde ayetinde nesne gelir
      String withAyah2(Object? field, Object? value) {
        final copy = jsonDecode(_fixture) as Map<String, dynamic>;
        ((copy['data'] as List)[0]['ayahs'] as List)[1][field] = value;
        return jsonEncode(copy);
      }

      final sajda = {'id': 1, 'recommended': true, 'obligatory': false};
      expect(parse(withAyah2('sajda', sajda))!.ayahs[1].sajda, isTrue);
      expect(parse(withAyah2('sajda', true))!.ayahs[1].sajda, isTrue);
      expect(parse(withAyah2('sajda', 'evet'))!.ayahs[1].sajda, isFalse);
      // Bozuk/eksik sayfa: ayet yine açılır, sayfa bilgisi yok sayılır
      for (final page in [0, 605, '604', null, 603]) {
        final text = parse(withAyah2('page', page))!;
        expect(text.ayahs, hasLength(4), reason: '$page');
        expect(text.hasPageInfo, isFalse, reason: '$page'); // 603: geri gider
      }
      expect(parse(withAyah2('juz', 31))!.ayahs[1].juz, isNull);
      expect(
        parse(withAyah2('hizbQuarter', 241))!.ayahs[1].hizbQuarter,
        isNull,
      );
      // Sayfa bilgisi olmayan yanıt
      final plain = parse(
        _response(113, _texts(5, 'آية'), translation: _texts(5, 'meal')),
        surah: 113,
      )!;
      expect(plain.hasPageInfo, isFalse);
      expect(plain.ayahs.every((a) => a.page == null && a.juz == null), isTrue);
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
      expect(parse(reversed)!.ayahs.first.page, 604);
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
        'BOM': '${String.fromCharCode(0xFEFF)}$b',
        'tatvil': b.replaceFirst(
          String.fromCharCodes([0x0645, 0x064E, 0x0670]),
          String.fromCharCodes([0x0645, 0x064E, 0x0640, 0x0670]),
        ),
        'şedde/üstün sırası': b.replaceAll(
          String.fromCharCodes([0x0651, 0x064E]),
          String.fromCharCodes([0x064E, 0x0651]),
        ),
        'şeddeli be': b.replaceFirst(
          String.fromCharCodes([0x0628, 0x0650]),
          String.fromCharCodes([0x0628, 0x0651, 0x0650]),
        ),
        'harekesiz': 'بسم الله الرحمن الرحيم',
        'sükun (U+0652)': b.replaceAll(
          String.fromCharCode(0x06E1),
          String.fromCharCode(0x0652),
        ),
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

  group('Sayfalar', () {
    SurahText parse(String raw, int surah, {String? translation}) =>
        QuranService.parseSurahResponse(
          raw,
          surah: surah,
          ayahCount: _surah(surah).ayahCount,
          translationEdition: translation,
        )!;

    List<int> numbers(QuranPageGroup g) => [for (final a in g.ayahs) a.number];

    test('aynı mushaf sayfasındaki ayetler bir arada (API sayfa bilgisi)', () {
      final mulk = QuranService.pageGroups(
        parse(_mulkFixture, 67, translation: 'tr.diyanet'),
      );
      expect([for (final g in mulk) g.page], [562, 563, 564]);
      expect([for (final g in mulk) g.juz], [29, 29, 29]);
      expect(numbers(mulk[0]), [for (var n = 1; n <= 12; n++) n]);
      expect(numbers(mulk[1]), [for (var n = 13; n <= 26; n++) n]);
      expect(numbers(mulk[2]), [27, 28, 29, 30]);
      expect(mulk[1].contains(13), isTrue);
      expect(mulk[1].contains(27), isFalse);
      expect([mulk[2].firstAyah, mulk[2].lastAyah], [27, 30]);

      final bakara = QuranService.pageGroups(
        parse(_response(2, _texts(286, 'آية'), pages: _bakaraPages), 2),
      );
      expect(bakara, hasLength(48));
      expect([bakara.first.page, bakara.first.juz], [2, 1]);
      expect(numbers(bakara.first), [1, 2, 3, 4, 5]);
      // Cüz başı sayfa başı: 2:142 sayfa 22, 2:253 sayfa 42
      final juz2 = bakara.firstWhere((g) => g.contains(142));
      expect([juz2.page, juz2.firstAyah, juz2.juz], [22, 142, 2]);
      final juz3 = bakara.firstWhere((g) => g.contains(253));
      expect([juz3.page, juz3.firstAyah, juz3.juz], [42, 253, 3]);
      expect([bakara.last.page, bakara.last.firstAyah], [49, 283]);
      // Uzun ayet tek başına bir sayfa (2:282)
      expect(numbers(bakara.firstWhere((g) => g.page == 48)), [282]);
      // Her ayet bir kez, sırayla
      expect(
        [for (final g in bakara) ...numbers(g)],
        [for (var n = 1; n <= 286; n++) n],
      );
    });

    test('sayfa bilgisi yoksa (eski kopya) 10 ayetlik gruplar, cüz başında '
        'yeni grup', () {
      final ikhlas = QuranService.pageGroups(
        parse(_response(112, _texts(4, 'آية')), 112),
      );
      expect(ikhlas, hasLength(1));
      expect([ikhlas.single.page, ikhlas.single.juz], [null, 30]);
      expect(numbers(ikhlas.single), [1, 2, 3, 4]);

      final bakara = QuranService.pageGroups(
        parse(_response(2, _texts(286, 'آية')), 2),
      );
      expect(bakara.every((g) => g.page == null), isTrue);
      expect(
        bakara.every((g) => g.ayahs.length <= QuranService.fallbackPageSize),
        isTrue,
      );
      expect(numbers(bakara.first), [for (var n = 1; n <= 10; n++) n]);
      // 1. cüz 141'de biter, 2. cüz 142'de başlar
      expect(numbers(bakara.firstWhere((g) => g.contains(141))), [141]);
      final juz2 = bakara.firstWhere((g) => g.contains(142));
      expect([juz2.firstAyah, juz2.lastAyah, juz2.juz], [142, 151, 2]);
      expect(numbers(bakara.firstWhere((g) => g.contains(252))), [252]);
      expect(bakara.firstWhere((g) => g.contains(253)).juz, 3);
      expect(
        [for (final g in bakara) ...numbers(g)],
        [for (var n = 1; n <= 286; n++) n],
      );
    });

    test('ayet sonu işareti: süslü parantez içinde Arapça-Hint rakamları', () {
      expect(QuranService.arabicIndicDigits(7).codeUnits, [0x0667]);
      expect(QuranService.arabicIndicDigits(286).codeUnits, [
        0x0662,
        0x0668,
        0x0666,
      ]);
      // Mantıksal sıra (sağdan sola): U+FD3F, rakamlar, U+FD3E → ﴿١٢﴾
      expect(QuranService.ayahEndMarker(12).codeUnits, [
        0xFD3F,
        0x0661,
        0x0662,
        0xFD3E,
      ]);
      expect(QuranService.ayahEndMarker(12), '﴿١٢﴾');
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
      expect(cached.ayahs.map((a) => a.page), everyElement(604));

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

    test('sürüm 2: sayfa, cüz, hizb ve secde saklanır; sayfa bilgisi '
        'olmayan kopya yeniden indirilmez', () async {
      final copy = jsonDecode(_mulkFixture) as Map<String, dynamic>;
      ((copy['data'] as List)[0]['ayahs'] as List)[4]['sajda'] = {
        'id': 9,
        'recommended': true,
        'obligatory': false,
      };
      final calls = <Uri>[];
      final service = _service(
        calls: calls,
        fetch: (url) async => '$url'.contains('/surah/67/')
            ? jsonEncode(copy)
            : _fakeResponse(url),
      );
      final text = await service.loadSurah(_surah(67), 'tr');
      expect(text.ayahs[4].sajda, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(QuranService.cacheKey(67, 'tr.diyanet'))!;
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      expect(saved['v'], 2);
      expect(saved['page'], [for (final a in text.ayahs) a.page]);
      expect(saved['juz'], everyElement(29));
      expect(saved['hizb'], hasLength(30));
      expect(saved['sajda'], [5]);

      final cached = await service.loadSurah(_surah(67), 'tr');
      expect(calls, hasLength(1));
      for (var i = 0; i < 30; i++) {
        final (a, b) = (text.ayahs[i], cached.ayahs[i]);
        expect(
          [b.arabic, b.translation, b.page, b.juz, b.hizbQuarter, b.sajda],
          [a.arabic, a.translation, a.page, a.juz, a.hizbQuarter, a.sajda],
        );
      }
      // Sayfa bilgisi gelmeyen sure (113) de saklanır, tekrar istenmez
      await service.loadSurah(_surah(113), 'tr');
      await service.loadSurah(_surah(113), 'tr');
      expect(calls.where((u) => '$u'.contains('/surah/113/')), hasLength(1));
      expect(
        (jsonDecode(prefs.getString(QuranService.cacheKey(113, 'tr.diyanet'))!)
                as Map)
            .containsKey('page'),
        isFalse,
      );
    });

    test('bozuk mushaf bilgili kopya silinip yeniden indirilir', () async {
      final calls = <Uri>[];
      final service = _service(calls: calls);
      await service.loadSurah(_surah(67), 'tr');
      final prefs = await SharedPreferences.getInstance();
      final key = QuranService.cacheKey(67, 'tr.diyanet');
      final good = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      for (final (name, field, value) in [
        ('sayfa 0', 'page', [0, ...List.filled(29, 562)]),
        ('eksik sayfa', 'page', List.filled(29, 562)),
        ('cüz metin', 'juz', List.filled(30, '29')),
        ('hizb 241', 'hizb', List.filled(30, 241)),
      ]) {
        final bad = {...good, field: value};
        expect(
          QuranService.decodeCache(jsonEncode(bad), _surah(67), 'tr.diyanet'),
          isNull,
          reason: name,
        );
        await prefs.setString(key, jsonEncode(bad));
        final text = await service.loadSurah(_surah(67), 'tr');
        expect(text.hasPageInfo, isTrue, reason: name);
      }
      expect(calls, hasLength(5));
      expect(
        QuranService.decodeCache(
          prefs.getString(key),
          _surah(67),
          'tr.diyanet',
        ),
        isNotNull,
      );
    });

    test('eski kopya (sürüm 1, mushaf bilgisi yok): ağ yoksa kopya açılır, '
        'ağ varsa sayfa bilgisiyle yenilenir', () async {
      final key = QuranService.cacheKey(112, 'tr.diyanet');
      final legacy = _legacyIkhlasCache();
      SharedPreferences.setMockInitialValues({
        key: legacy,
        QuranService.cacheIndexKey: [key],
      });
      final prefs = await SharedPreferences.getInstance();
      final calls = <Uri>[];
      final offline = _service(
        calls: calls,
        fetch: (_) async => throw const SocketException('yok'),
      );
      final old = await offline.loadSurah(_surah(112), 'tr');
      expect(calls, [QuranService.surahUrl(112, 'tr')]); // yenileme denendi
      expect(old.hasPageInfo, isFalse);
      expect(old.bismillah, QuranService.bismillahText);
      expect(old.ayahs.first.arabic, _ikhlas1);
      expect(old.ayahs.map((a) => a.translation), _meal);
      expect(prefs.getString(key), legacy); // silinmedi
      final groups = QuranService.pageGroups(old);
      expect(groups, hasLength(1));
      expect([groups.single.page, groups.single.juz], [null, 30]);

      calls.clear();
      final fresh = await _service(calls: calls).loadSurah(_surah(112), 'tr');
      expect(calls, [QuranService.surahUrl(112, 'tr')]);
      expect(fresh.hasPageInfo, isTrue);
      expect((jsonDecode(prefs.getString(key)!) as Map)['v'], 2);

      calls.clear();
      final cached = await offline.loadSurah(_surah(112), 'tr');
      expect(calls, isEmpty);
      expect(cached.ayahs.map((a) => a.page), everyElement(604));
    });

    testWidgets('eski kopyanın yenilemesi yavaşsa '
        '${QuranService.upgradeTimeout.inSeconds} sn sonra kopya açılır', (
      tester,
    ) async {
      final key = QuranService.cacheKey(112, 'tr.diyanet');
      SharedPreferences.setMockInitialValues({key: _legacyIkhlasCache()});
      final never = Completer<String?>();
      SurahText? result;
      _service(
        fetch: (_) => never.future,
      ).loadSurah(_surah(112), 'tr').then((text) => result = text);
      await tester.pump(
        QuranService.upgradeTimeout - const Duration(seconds: 1),
      );
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(result, isNotNull);
      expect(result!.hasPageInfo, isFalse);
      expect(result!.ayahs.first.arabic, _ikhlas1);
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
        'yer iminin ve son okunanın suresi korunur', () async {
      final calls = <Uri>[];
      final service = _service(calls: calls);
      await service.saveBookmark(const QuranBookmark(surah: 104, ayah: 2));
      await service.saveLastRead(const QuranBookmark(surah: 105, ayah: 1));
      // 103..114: 12 kısa sure
      for (var n = 103; n <= 114; n++) {
        await service.loadSurah(_surah(n), 'tr');
      }
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getStringList(QuranService.cacheIndexKey)!;
      expect(index, hasLength(QuranService.maxCachedSurahs));
      expect(index.first, QuranService.cacheKey(114, 'tr.diyanet'));
      expect(index, contains(QuranService.cacheKey(104, 'tr.diyanet')));
      expect(index, contains(QuranService.cacheKey(105, 'tr.diyanet')));
      for (final n in [103, 106]) {
        expect(index, isNot(contains(QuranService.cacheKey(n, 'tr.diyanet'))));
        expect(prefs.getString(QuranService.cacheKey(n, 'tr.diyanet')), isNull);
      }
      expect(
        prefs.getKeys().where((k) => k.startsWith(QuranService.cachePrefix)),
        hasLength(QuranService.maxCachedSurahs),
      );

      calls.clear();
      await service.loadSurah(_surah(104), 'tr'); // korundu: ağsız
      await service.loadSurah(_surah(105), 'tr');
      expect(calls, isEmpty);
      await service.loadSurah(_surah(106), 'tr'); // silindi: yeniden indirilir
      expect(calls, [QuranService.surahUrl(106, 'tr')]);
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

  group('Yer imi, son okunan, görünüm ve yazı boyutu', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('yer imi: kaydedilir, okunur, silinir', () async {
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

    test('son okunan ayet yer iminden ayrı saklanır', () async {
      final service = _service();
      expect(await service.loadLastRead(), isNull);
      await service.saveLastRead(const QuranBookmark(surah: 36, ayah: 12));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":36,"ayah":12}',
      );
      expect(await service.loadBookmark(), isNull);
      expect(
        await _service().loadLastRead(),
        const QuranBookmark(surah: 36, ayah: 12),
      );
      await prefs.setString(QuranService.lastReadKey, '{"surah":0,"ayah":1}');
      expect(await service.loadLastRead(), isNull);
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
        SharedPreferences.setMockInitialValues({
          QuranService.bookmarkKey: raw,
          QuranService.lastReadKey: raw,
        });
        expect(await _service().loadBookmark(), isNull, reason: raw);
        expect(await _service().loadLastRead(), isNull, reason: raw);
      }
      SharedPreferences.setMockInitialValues({
        QuranService.bookmarkKey: 7,
        QuranService.lastReadKey: 7,
      });
      expect(await _service().loadBookmark(), isNull);
      expect(await _service().loadLastRead(), isNull);
    });

    test('görünüm: varsayılan sayfa, seçim saklanır; Arapça arayüzde meal '
        'yerine sayfa', () async {
      final service = _service();
      expect(await service.loadViewMode(), QuranViewMode.page);
      final prefs = await SharedPreferences.getInstance();
      for (final mode in QuranViewMode.values) {
        await service.saveViewMode(mode);
        expect(prefs.getString(QuranService.viewModeKey), mode.name);
        expect(await _service().loadViewMode(), mode);
      }
      expect(
        [for (final m in QuranViewMode.values) m.name],
        ['page', 'ayah', 'translation'],
      );
      for (final raw in ['', 'mushaf', 'PAGE']) {
        await prefs.setString(QuranService.viewModeKey, raw);
        expect(await service.loadViewMode(), QuranViewMode.page, reason: raw);
      }
      await prefs.setInt(QuranService.viewModeKey, 1);
      expect(await service.loadViewMode(), QuranViewMode.page);

      expect(
        QuranService.effectiveViewMode(QuranViewMode.translation, 'ar'),
        QuranViewMode.page,
      );
      expect(
        QuranService.effectiveViewMode(QuranViewMode.ayah, 'ar'),
        QuranViewMode.ayah,
      );
      for (final lang in ['tr', 'en', 'de', 'fr']) {
        for (final mode in QuranViewMode.values) {
          expect(QuranService.effectiveViewMode(mode, lang), mode);
        }
      }
    });

    test(
      'yazı boyutu: varsayılan 1, sınırlar ve 0,1 adım; meal ayrı',
      () async {
        final service = _service();
        expect(await service.loadFontScale(), 1);
        expect(await service.loadTranslationScale(), 1);
        await service.saveFontScale(1.2000000001);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble(QuranService.fontScaleKey), 1.2);
        expect(await service.loadFontScale(), 1.2);
        expect(await service.loadTranslationScale(), 1);
        await service.saveTranslationScale(0.84);
        expect(prefs.getDouble(QuranService.translationScaleKey), 0.8);
        expect(await service.loadTranslationScale(), 0.8);
        expect(await service.loadFontScale(), 1.2);
        expect(QuranService.clampFontScale(0.3), QuranService.minFontScale);
        expect(QuranService.clampFontScale(9), QuranService.maxFontScale);
        expect(QuranService.clampFontScale(1.04), 1.0);
        expect(QuranService.clampFontScale(double.nan), 1);
        expect(QuranService.clampFontScale(0.9 + 0.1), 1.0);
        await prefs.setDouble(QuranService.fontScaleKey, 5);
        await prefs.setDouble(QuranService.translationScaleKey, 0.1);
        expect(await service.loadFontScale(), QuranService.maxFontScale);
        expect(await service.loadTranslationScale(), QuranService.minFontScale);
      },
    );
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
      // Hatim: sayfa tablosu ve Ramazan takvimi uygulama boyu önbelleklenir
      await HatimService.loadPages();
      await loadRamadanCalendar();
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

    /// Tipik telefon (411x891 dp), %100 yazı
    Future<void> pumpPhone(
      WidgetTester tester,
      Widget home, {
      String lang = 'tr',
    }) => pump(tester, home, lang: lang, width: 411, height: 891, textScale: 1);

    Future<void> dispose(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }

    Future<void> scrollThrough(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.drag(_vertical(), const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> scrollToTop(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.drag(_vertical(), const Offset(0, 600));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settle(tester);
    }

    Future<void> closeSheet(WidgetTester tester, Type sheet) async {
      Navigator.of(tester.element(find.byType(sheet))).pop();
      await settle(tester);
    }

    /// Hatim kartının menüsünden [label] seçilir
    Future<void> hatimMenu(WidgetTester tester, String label) async {
      final tooltip = MaterialLocalizations.of(
        tester.element(find.byType(HatimCard)),
      ).showMenuTooltip;
      await tester.tap(find.byTooltip(tooltip));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(label));
      await settle(tester);
    }

    /// "Görünüm" alt sayfasından görünüm seçer (sayfa açıkken taşma denetlenir)
    Future<void> chooseMode(
      WidgetTester tester,
      AppLocalizations loc,
      String label,
    ) async {
      await tester.tap(find.byTooltip(loc.quranViewSettings));
      await settle(tester);
      expect(find.byType(QuranViewSettings), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await settle(tester);
      await closeSheet(tester, QuranViewSettings);
    }

    Finder ayahCard(String arabic) =>
        find.ancestor(of: find.text(arabic), matching: find.byType(AppCard));

    /// Ayet kartını tümüyle ekrana getirir (küçük ekranda aşağıda kalabilir;
    /// metin görünürken düğme satırı AppBar altında kalmasın)
    Future<void> reveal(WidgetTester tester, String arabic) async {
      await tester.scrollUntilVisible(
        find.text(arabic),
        150,
        scrollable: _vertical(),
      );
      await tester.pump();
      await tester.ensureVisible(ayahCard(arabic));
      await tester.pump();
    }

    MushafPage mushafPageOf(WidgetTester tester, String arabic) =>
        tester.widget<MushafPage>(
          find.ancestor(
            of: find.textContaining(arabic),
            matching: find.byType(MushafPage),
          ),
        );

    /// Okuyucu listesinin üst kenarı (AppBar altı)
    double listTop(WidgetTester tester) =>
        tester.getRect(find.byType(AppBar)).bottom;

    /// Sayfa metninde [ayah] metninin başladığı satırın ekrandaki üstü
    double lineTopOf(WidgetTester tester, String ayah) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.textContaining(ayah),
          matching: find.byType(RichText),
        ),
      );
      final index = paragraph.text.toPlainText().indexOf(ayah);
      final caret = paragraph.getOffsetForCaret(
        TextPosition(offset: index),
        Rect.zero,
      );
      return paragraph.localToGlobal(caret).dy;
    }

    for (final lang in ['tr', 'ar']) {
      for (final dark in [false, true]) {
        testWidgets('$lang ${dark ? 'koyu' : 'açık'}: liste, cüzler, '
            'okuyucunun tüm görünümleri ve pencereler, 320dp, %130 yazı, '
            'taşma yok', (tester) async {
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
          expect(find.text(loc.quranTabSurahs), findsOneWidget);
          expect(find.text(isArabic ? 'الفاتحة' : 'Fâtiha'), findsOneWidget);
          expect(find.text(loc.quranContinue), findsNothing);
          expect(find.text(loc.quranBookmark), findsNothing);
          expect(calls, isEmpty); // liste gömülü
          expect(tester.takeException(), isNull);

          // Hatim kartı: hatim yok → açıklama ve "Hatim Başlat"; seçenekler
          expect(find.text(loc.hatimIntro), findsOneWidget);
          await tester.tap(find.text(loc.hatimStart));
          await settle(tester);
          expect(
            find.text('${loc.hatimPagesPerDay(20)} · ${loc.hatimDuration(1)}'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.text('${loc.hatimPagesPerDay(10)} · ${loc.hatimDuration(2)}'),
          );
          await settle(tester);
          // Sürüyor: ilerleme, bugünün okuması, Devam Et ve menü
          expect(find.text(loc.hatimToday(0, 10)), findsOneWidget);
          expect(find.text(loc.hatimContinue), findsOneWidget);
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
          await hatimMenu(tester, loc.hatimReminder);
          expect(find.text(loc.hatimReminderDaily), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.text(loc.hatimReminderDaily))).pop();
          await settle(tester);

          // Cüzler
          await tester.tap(find.text(loc.quranTabJuz));
          await settle(tester);
          expect(find.text(loc.quranJuz(1)), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text(loc.quranJuz(30)),
            500,
            scrollable: _vertical(),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(loc.quranTabSurahs));
          await settle(tester);

          final ikhlas = find.text(isArabic ? 'الإخلاص' : 'İhlâs');
          await tester.scrollUntilVisible(ikhlas, 500, scrollable: _vertical());
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.tap(ikhlas);
          await settle(tester);

          // Sayfa görünümü (varsayılan)
          expect(find.byType(SurahReaderView), findsOneWidget);
          expect(calls, [QuranService.surahUrl(112, lang)]);
          expect(find.byType(MushafPage), findsOneWidget);
          expect(find.text(QuranService.bismillahText), findsOneWidget);
          expect(find.textContaining(_ikhlas1), findsOneWidget);
          // Dar ekranda satıra az kelime sığar: iki yana yaslanmaz
          expect(
            tester.widget<Text>(find.textContaining(_ikhlas1)).textAlign,
            TextAlign.start,
          );
          expect(
            find.text(
              '${loc.quranPage(604)} · ${loc.quranJuz(30)}',
              skipOffstage: false,
            ),
            findsOneWidget,
          );
          // İlk açılış ipucu taşmasız görünür; metnin üstünde yüzdüğü için
          // kapatılır (dar ekranda kaydırma noktasını örter)
          expect(find.text(loc.tipQuranReader), findsOneWidget);
          await tester.tap(find.text(loc.tipGotIt));
          await settle(tester);
          expect(find.text(loc.tipQuranReader), findsNothing);
          expect(tester.takeException(), isNull);
          await scrollThrough(tester);
          expect(find.text(loc.quranTextSource), findsOneWidget);
          expect(
            find.text(loc.quranTranslationSource('Diyanet İşleri')),
            isArabic ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          // Ayet alt sayfası
          await scrollToTop(tester);
          await tester.ensureVisible(find.textContaining(_arabic[1]));
          await tester.pump();
          await tester.tapOnText(find.textRange.ofSubstring(_arabic[1]));
          await settle(tester);
          expect(find.byType(AyahSheet), findsOneWidget);
          expect(
            find.text(loc.quranAyahRef(_surah(112).displayName(lang), 2)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await closeSheet(tester, AyahSheet);

          // Ayet ayet
          await chooseMode(tester, loc, loc.quranModeAyah);
          expect(find.byType(MushafPage), findsNothing);
          await scrollThrough(tester);
          expect(find.text(_arabic[3]), findsOneWidget);
          expect(find.text(_meal[3]), isArabic ? findsNothing : findsOneWidget);
          expect(tester.takeException(), isNull);

          // Meal (Arapça arayüzde yok)
          if (!isArabic) {
            await chooseMode(tester, loc, loc.quranModeTranslation);
            expect(find.byType(TranslationPage), findsOneWidget);
            expect(find.textContaining(_meal[0]), findsOneWidget);
            expect(find.textContaining(_ikhlas1), findsNothing);
            await scrollThrough(tester);
            expect(tester.takeException(), isNull);
          }

          // Ayete git
          await tester.tap(find.byTooltip(loc.quranGoToAyah));
          await settle(tester);
          expect(find.text(loc.quranAyahNumberLabel(4)), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(loc.cancel));
          await settle(tester);
          expect(tester.takeException(), isNull);
          await dispose(tester);
        });
      }
    }

    testWidgets('görünüm: varsayılan sayfa; seçim saklanır, yeniden açılışta '
        'gelir; Arapça arayüzde meal seçeneği yok', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      Future<void> open({String lang = 'tr'}) => pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
        lang: lang,
      );
      final loc = lookupAppLocalizations(const Locale('tr'));

      await open();
      expect(find.byType(MushafPage), findsWidgets);
      expect(prefs.getString(QuranService.viewModeKey), isNull);
      expect(
        find.byIcon(quranViewModeIcon(QuranViewMode.page)),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip(loc.quranViewSettings));
      await settle(tester);
      for (final label in [
        loc.quranModePage,
        loc.quranModeAyah,
        loc.quranModeTranslation,
        loc.quranArabicSize,
        loc.quranTranslationSize,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text(loc.quranModeAyah));
      await settle(tester);
      // Seçim hemen uygulanır (alt sayfa açık kalır) ve saklanır
      expect(find.byType(QuranViewSettings), findsOneWidget);
      expect(prefs.getString(QuranService.viewModeKey), 'ayah');
      expect(find.byType(MushafPage), findsNothing);
      await closeSheet(tester, QuranViewSettings);
      expect(find.text(_mulk(1)), findsOneWidget);
      expect(
        find.byIcon(quranViewModeIcon(QuranViewMode.ayah)),
        findsOneWidget,
      );
      await dispose(tester);

      await open();
      expect(find.byType(MushafPage), findsNothing);
      expect(find.text(_mulk(1)), findsOneWidget);
      await chooseMode(tester, loc, loc.quranModeTranslation);
      expect(prefs.getString(QuranService.viewModeKey), 'translation');
      expect(find.byType(TranslationPage), findsWidgets);
      await dispose(tester);

      // Arapça arayüz: meal yok, sayfa görünümü açılır; seçim saklı kalır
      final ar = lookupAppLocalizations(const Locale('ar'));
      await open(lang: 'ar');
      expect(find.byType(TranslationPage), findsNothing);
      expect(find.byType(MushafPage), findsWidgets);
      await tester.tap(find.byTooltip(ar.quranViewSettings));
      await settle(tester);
      expect(find.text(ar.quranModePage), findsOneWidget);
      expect(find.text(ar.quranModeAyah), findsOneWidget);
      expect(find.text(ar.quranModeTranslation), findsNothing);
      expect(find.text(ar.quranTranslationSize), findsNothing);
      expect(prefs.getString(QuranService.viewModeKey), 'translation');
      await closeSheet(tester, QuranViewSettings);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('okuyucu ipucu: ilk açılışta Görünüm ve ayete dokunma bir '
        'kez; metnin üstünde yüzer, okuma yeri kaymaz', (tester) async {
      FeatureTip.debugReset();
      final loc = lookupAppLocalizations(const Locale('tr'));
      Future<void> open() => pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
      );

      await open();
      expect(find.text(loc.tipQuranReader), findsOneWidget);
      final page = tester.getTopLeft(find.byType(MushafPage).first);
      await tester.tap(find.text(loc.tipGotIt));
      await settle(tester);
      expect(find.text(loc.tipQuranReader), findsNothing);
      expect(tester.getTopLeft(find.byType(MushafPage).first), page);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(FeatureTip.seenKey('quran_reader')), isTrue);
      await dispose(tester);

      await open();
      expect(find.text(loc.tipQuranReader), findsNothing);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('sayfa görünümü: mushaf sayfaları (API sayfa bilgisi), '
        '"Sayfa · Cüz" başlıkları, ayet sonunda işaret', (tester) async {
      await pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      final first = tester.widget<MushafPage>(find.byType(MushafPage).first);
      expect(first.group.page, 562);
      expect(first.group.ayahs.map((a) => a.number), [
        for (var n = 1; n <= 12; n++) n,
      ]);
      expect(
        find.text('${loc.quranPage(562)} · ${loc.quranJuz(29)}'),
        findsOneWidget,
      );
      // Sayfa tek Text.rich: ayetler sırayla, her birinin sonunda ﴿n﴾
      final page = tester.widget<Text>(find.textContaining(_mulk(1)));
      final plain = page.textSpan!.toPlainText();
      final nbsp = String.fromCharCode(0xA0);
      var from = 0;
      for (var n = 1; n <= 12; n++) {
        final part = '${_mulk(n)}$nbsp${QuranService.ayahEndMarker(n)}';
        final at = plain.indexOf(part, from);
        expect(at, greaterThanOrEqualTo(from), reason: '$n');
        from = at + part.length;
      }
      expect(plain, isNot(contains(_mulk(13))));
      expect(page.textDirection, TextDirection.rtl);
      expect(page.textAlign, TextAlign.justify);
      expect(page.style!.fontFamily, AppTheme.arabicFamily);
      expect(page.style!.fontSize, mushafFontSize);
      // Sonraki sayfalar kaydırınca
      for (final (number, firstAyah) in [(563, 13), (564, 27)]) {
        await tester.scrollUntilVisible(
          find.text('${loc.quranPage(number)} · ${loc.quranJuz(29)}'),
          400,
          scrollable: _vertical(),
        );
        await tester.pump();
        expect(mushafPageOf(tester, _mulk(firstAyah)).group.page, number);
      }
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('eski kopya (sayfa bilgisi yok, ağ yok): 10 ayetlik grup, '
        'başlıkta ayet aralığı ve cüz', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.cacheKey(112, 'tr.diyanet'): _legacyIkhlasCache(),
      });
      final calls = <Uri>[];
      await pumpPhone(
        tester,
        SurahReaderView(
          surah: _surah(112),
          service: _service(
            calls: calls,
            fetch: (_) async => throw const SocketException('yok'),
          ),
        ),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(calls, [QuranService.surahUrl(112, 'tr')]);
      expect(find.text(loc.quranLoadError), findsNothing);
      expect(
        find.text('${loc.quranAyahRange(1, 4)} · ${loc.quranJuz(30)}'),
        findsOneWidget,
      );
      expect(
        tester.widget<MushafPage>(find.byType(MushafPage)).group.page,
        isNull,
      );
      expect(find.textContaining(_ikhlas1), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('sayfa görünümü: ayete dokununca alt sayfa — Arapça + meal, '
        'yer imi, kopyala, resimli paylaş', (tester) async {
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
      String? clipboard;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(pathProvider, null);
        messenger.setMockMethodCallHandler(share, null);
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));

      await tester.tapOnText(find.textRange.ofSubstring(_mulk(2)));
      await settle(tester);
      final sheet = find.byType(AyahSheet);
      expect(sheet, findsOneWidget);
      Finder inSheet(Finder finder) =>
          find.descendant(of: sheet, matching: finder);
      expect(inSheet(find.text(loc.quranAyahRef('Mülk', 2))), findsOneWidget);
      expect(
        inSheet(find.text('${loc.quranPage(562)} · ${loc.quranJuz(29)}')),
        findsOneWidget,
      );
      expect(inSheet(find.textContaining(_mulk(2))), findsOneWidget);
      expect(inSheet(find.text(_mulkMeal[1])), findsOneWidget);
      // Ayet sayfada vurgulanır
      expect(mushafPageOf(tester, _mulk(1)).selectedAyah, 2);

      // Yer imi
      await tester.tap(inSheet(find.text(loc.quranBookmarkSave)));
      await settle(tester);
      expect(
        prefs.getString(QuranService.bookmarkKey),
        '{"surah":67,"ayah":2}',
      );
      expect(inSheet(find.text(loc.quranBookmarkRemove)), findsOneWidget);
      expect(mushafPageOf(tester, _mulk(1)).bookmarkedAyah, 2);

      // Kopyala: Arapça, meal ve kaynak
      await tester.tap(inSheet(find.text(loc.copy)));
      await settle(tester);
      expect(
        clipboard,
        [
          _mulk(2),
          _mulkMeal[1],
          '— ${loc.quranAyahRef('Mülk', 2)}',
        ].join('\n\n'),
      );
      expect(inSheet(find.text(loc.textCopied)), findsOneWidget);

      // Resimli paylaş (kampanya quran)
      await tester.tap(inSheet(find.text(loc.shareAsImage)));
      for (var i = 0; i < 100 && shared == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(shared?.method, 'shareFiles');
      expect(
        (shared!.arguments as Map)['text'],
        'Mülk 2. ayet · Vaktinde\n${AppLinks.playStoreLink('quran')}',
      );

      // Yer imini kaldır; kapanınca vurgu kalkar
      await tester.tap(inSheet(find.text(loc.quranBookmarkRemove)));
      await settle(tester);
      expect(prefs.containsKey(QuranService.bookmarkKey), isFalse);
      await closeSheet(tester, AyahSheet);
      expect(find.byType(AyahSheet), findsNothing);
      final page = mushafPageOf(tester, _mulk(1));
      expect([page.selectedAyah, page.bookmarkedAyah], [null, null]);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('meal görünümü: numaralı meal paragrafları; dokununca ayetin '
        'Arapçası alt sayfada', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.viewModeKey: 'translation',
      });
      await pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.byType(TranslationPage), findsWidgets);
      expect(find.byType(MushafPage), findsNothing);
      expect(
        find.text('${loc.quranPage(562)} · ${loc.quranJuz(29)}'),
        findsOneWidget,
      );
      // Arapça ayet metni yok (yalnızca başlıktaki besmele)
      expect(find.textContaining(_mulk(2)), findsNothing);
      final paragraph = find.textContaining(_mulkMeal[1]);
      expect(paragraph, findsOneWidget);
      expect(
        tester.widget<Text>(paragraph).textSpan!.toPlainText(),
        startsWith('2'),
      );
      await tester.tap(paragraph);
      await settle(tester);
      expect(find.byType(AyahSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AyahSheet),
          matching: find.textContaining(_mulk(2)),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TranslationPage>(find.byType(TranslationPage).first)
            .selectedAyah,
        2,
      );
      await closeSheet(tester, AyahSheet);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('son okunan: açılışta ve kaydırma durunca görünen ilk ayet '
        'saklanır; listede devam kartı o ayetten açar', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.viewModeKey: 'ayah',
      });
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.enterText(find.byType(TextField), 'mülk');
      await tester.pump();
      await tester.tap(find.text('Mülk'));
      await settle(tester);
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":67,"ayah":1}',
      );

      await tester.drag(_vertical(), const Offset(0, -1500));
      await settle(tester);
      // Görünen ilk kart: üst kenarın 16 dp altını kesen kart
      final top = listTop(tester) + AppSpacing.lg;
      int? visible;
      for (var n = 1; n <= 30 && visible == null; n++) {
        final card = ayahCard(_mulk(n));
        if (card.evaluate().isEmpty) continue;
        if (tester.getRect(card).bottom > top) visible = n;
      }
      expect(visible, greaterThan(1));
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":67,"ayah":$visible}',
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text(loc.quranContinue), findsOneWidget);
      expect(find.text(loc.quranAyahRef('Mülk', visible!)), findsOneWidget);
      expect(find.text(loc.quranBookmark), findsNothing);
      await tester.tap(find.text(loc.quranContinue));
      await settle(tester);
      expect(
        tester.getRect(ayahCard(_mulk(visible))).top - listTop(tester),
        inInclusiveRange(0, AppSpacing.lg),
      );
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('Ayete git: sayfadaki ayetin satırına kayar, ayet kısa süre '
        'vurgulanır ve son okunan olur; geçersiz numara kabul edilmez', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(
        tester,
        SurahReaderView(surah: _surah(67), service: _service()),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.byTooltip(loc.quranGoToAyah));
      await settle(tester);
      expect(find.text(loc.quranAyahNumberLabel(30)), findsOneWidget);
      FilledButton go() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, loc.quranGo),
      );
      expect(go().onPressed, isNull);
      for (final invalid in ['0', '31', '999']) {
        await tester.enterText(find.byType(TextField), invalid);
        await tester.pump();
        expect(go().onPressed, isNull, reason: invalid);
      }
      // Harf girilmez; Arapça-Hint rakamlar olur
      await tester.enterText(find.byType(TextField), 'a2');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '2',
      );
      await tester.enterText(find.byType(TextField), '٢٠');
      await tester.pump();
      expect(go().onPressed, isNotNull);
      await tester.tap(find.text(loc.quranGo));
      await settle(tester);

      expect(
        lineTopOf(tester, _mulk(20)) - listTop(tester),
        inInclusiveRange(0, AppSpacing.xl),
      );
      final page = mushafPageOf(tester, _mulk(20));
      expect(page.group.page, 563);
      expect(page.selectedAyah, 20);
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":67,"ayah":20}',
      );
      await tester.pump(const Duration(seconds: 3));
      expect(mushafPageOf(tester, _mulk(20)).selectedAyah, isNull);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('Cüzler: dokununca sure cüzün başladığı ayetten (sayfa '
        'görünümünde o sayfa en üstte) açılır', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.quranTabJuz));
      await settle(tester);
      expect(find.text(loc.quranAyahRef('Fâtiha', 1)), findsOneWidget);
      expect(find.text(loc.quranAyahRef('Bakara', 142)), findsOneWidget);
      await tester.tap(find.text(loc.quranJuz(2)));
      await settle(tester);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect([reader.surah.number, reader.initialAyah], [2, 142]);
      final label = find.text('${loc.quranPage(22)} · ${loc.quranJuz(2)}');
      expect(label, findsOneWidget);
      expect(
        tester.getRect(label).top - listTop(tester),
        inInclusiveRange(0, 48),
      );
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":2,"ayah":142}',
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      // Liste cüz sekmesinde kalır; son cüz Nebe' başı
      await tester.scrollUntilVisible(
        find.text(loc.quranJuz(30)),
        500,
        scrollable: _vertical(),
      );
      await tester.pump();
      await tester.tap(find.text(loc.quranJuz(30)));
      await settle(tester);
      final last = tester.widget<SurahReaderView>(find.byType(SurahReaderView));
      expect([last.surah.number, last.initialAyah], [78, 1]);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('sure arama: işaretsiz ad, Arapça ad, numara; sonuç yok; '
        'temizle', (tester) async {
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      Future<void> search(String query) async {
        await tester.enterText(find.byType(TextField), query);
        await tester.pump();
      }

      expect(find.text(loc.quranSearchHint), findsOneWidget);
      await search('yasin');
      expect(find.text('Yâsîn'), findsOneWidget);
      expect(find.text('Fâtiha'), findsNothing);
      await search('36');
      expect(find.text('Yâsîn'), findsOneWidget);
      expect(find.text('Bakara'), findsNothing);
      await search('الملك');
      expect(find.text('Mülk'), findsOneWidget);
      expect(find.text('Yâsîn'), findsNothing);
      await search('zzz');
      expect(find.text(loc.quranNoResults), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('Fâtiha'), findsOneWidget);
      expect(find.text(loc.quranNoResults), findsNothing);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('trackLastRead: false iken okunan yer saklanmaz, sonraki '
        'sureye geçişte de', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(QuranService.lastReadKey);
      await pumpPhone(
        tester,
        SurahReaderView(
          surah: _surah(112),
          service: _service(),
          trackLastRead: false,
        ),
      );
      await scrollThrough(tester);
      await tester.tap(find.text('Felak'));
      await settle(tester);
      final reader = tester.widget<SurahReaderView>(
        find.byType(SurahReaderView),
      );
      expect(reader.surah.number, 113);
      expect(reader.trackLastRead, isFalse);
      expect(prefs.getString(QuranService.lastReadKey), isNull);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('önceki / sonraki sure: başta önceki, sonda sonraki; listeye '
        'dönünce son okunan görünür', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.enterText(find.byType(TextField), '112');
      await tester.pump();
      await tester.tap(find.text('İhlâs'));
      await settle(tester);
      expect(find.text(loc.quranPreviousSurah), findsOneWidget);
      expect(find.text(_surah(111).name), findsOneWidget);
      await scrollThrough(tester);
      expect(find.text(loc.quranNextSurah), findsOneWidget);
      await tester.tap(find.text('Felak'));
      await settle(tester);
      expect(
        tester
            .widget<SurahReaderView>(find.byType(SurahReaderView))
            .surah
            .number,
        113,
      );
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":113,"ayah":1}',
      );
      // Liste arkada hemen yenilenir (ana ekran kartı okuyucuyu sekmenin
      // üstünde açar; geri gelince güncel yer görünür)
      expect(
        find.text(loc.quranAyahRef('Felak', 1), skipOffstage: false),
        findsOneWidget,
      );
      // Önceki sure düğmesi geri getirir (yerine geçer)
      expect(find.text('İhlâs'), findsOneWidget);
      await tester.tap(find.text('İhlâs'));
      await settle(tester);
      expect(
        tester
            .widget<SurahReaderView>(find.byType(SurahReaderView))
            .surah
            .number,
        112,
      );
      // Geri: doğrudan listeye; liste kapanan okuyucunun yerini gösterir
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(SurahReaderView), findsNothing);
      expect(find.text(loc.quranAyahRef('İhlâs', 1)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('Bakara (286 ayet, 48 sayfa): sayfalar tembel kurulur, uzun '
        'kaydırmada taşma yok', (tester) async {
      await pump(
        tester,
        SurahReaderView(surah: _surah(2), service: _service()),
        width: 411,
        height: 891,
      );
      expect(
        tester.widget<MushafPage>(find.byType(MushafPage).first).group.page,
        2,
      );
      int built() =>
          find.byType(MushafPage, skipOffstage: false).evaluate().length;
      expect(built(), lessThan(10));
      for (var i = 0; i < 25; i++) {
        await tester.drag(_vertical(), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(built(), lessThan(10));
      final pages = [
        for (final e in find.byType(MushafPage).evaluate())
          (e.widget as MushafPage).group.page!,
      ];
      expect(pages.first, greaterThan(10));
      await dispose(tester);
    });

    testWidgets('ayet ayet: yer imi ikonla eklenir, listede "Yer imi" kartı '
        '(son okunandan ayrı), karttan o ayetten açılır', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.viewModeKey: 'ayah',
      });
      await pump(tester, QuranView(service: _service()), textScale: 1);
      final loc = lookupAppLocalizations(const Locale('tr'));
      final prefs = await SharedPreferences.getInstance();
      await tester.scrollUntilVisible(
        find.text('İhlâs'),
        500,
        scrollable: _vertical(),
      );
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

      // Başa dön: son okunan 1. ayet, yer imi 3. ayet
      await scrollToTop(tester);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(
        prefs.getString(QuranService.lastReadKey),
        '{"surah":112,"ayah":1}',
      );
      // Liste başı: önce son okunan, altında yer imi
      await tester.scrollUntilVisible(
        find.text(loc.quranContinue),
        -2000,
        scrollable: _vertical(),
      );
      await tester.pump();
      expect(
        tester.getRect(find.text(loc.quranBookmark)).top,
        greaterThan(tester.getRect(find.text(loc.quranContinue)).top),
      );
      expect(find.text(loc.quranAyahRef('İhlâs', 1)), findsOneWidget);
      expect(find.text(loc.quranAyahRef('İhlâs', 3)), findsOneWidget);
      expect(loc.quranAyahRef('İhlâs', 3), 'İhlâs 3. ayet');

      await tester.tap(find.text(loc.quranBookmark));
      await settle(tester);
      // 3. ayet en üstte; başlık ve önceki ayetler yukarıda
      final top = tester.getRect(ayahCard(_arabic[2])).top;
      expect(top - listTop(tester), inInclusiveRange(0, AppSpacing.lg));
      expect(find.text(QuranService.bismillahText), findsNothing);
      await tester.drag(_vertical(), const Offset(0, 800));
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
      expect(find.text(loc.quranBookmark), findsNothing);
      expect(find.text(loc.quranContinue), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('ayet ayet: uzun basma yer imi ekler; A+/A- (Görünüm) Arapça '
        'yazı boyutunu saklar, sayfa görünümüne de uygulanır', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.viewModeKey: 'ayah',
      });
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
      Future<void> tapScale(String tooltip) async {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pump();
        await tester.pump();
      }

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
      await tester.tap(find.byTooltip(loc.quranViewSettings));
      await settle(tester);
      await tapScale(loc.quranFontLarger);
      await tapScale(loc.quranFontLarger);
      expect(size(), closeTo(26 * 1.2, 1e-9));
      expect(prefs.getDouble(QuranService.fontScaleKey), 1.2);
      expect(find.text('%120'), findsOneWidget);
      await tapScale(loc.quranFontSmaller);
      expect(prefs.getDouble(QuranService.fontScaleKey), 1.1);
      for (var i = 0; i < 10; i++) {
        await tapScale(loc.quranFontLarger);
      }
      expect(
        prefs.getDouble(QuranService.fontScaleKey),
        QuranService.maxFontScale,
      );
      expect(button(loc.quranFontLarger).onPressed, isNull);
      expect(button(loc.quranFontSmaller).onPressed, isNotNull);
      // Meal yazısı ayrı
      await tapScale(loc.quranTranslationSmaller);
      expect(prefs.getDouble(QuranService.translationScaleKey), 0.9);
      expect(
        tester
            .widget<Text>(find.text(_meal[1], skipOffstage: false))
            .style!
            .fontSize,
        closeTo(16 * 0.9, 1e-9),
      );
      await closeSheet(tester, QuranViewSettings);
      expect(tester.takeException(), isNull);
      await dispose(tester);

      // Yeniden açılışta saklanan boyut; sayfa görünümünde de
      await open();
      await reveal(tester, _arabic[1]);
      expect(size(), closeTo(26 * QuranService.maxFontScale, 1e-9));
      await chooseMode(tester, loc, loc.quranModePage);
      expect(
        tester.widget<Text>(find.textContaining(_ikhlas1)).style!.fontSize,
        closeTo(mushafFontSize * QuranService.maxFontScale, 1e-9),
      );
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
      expect(find.textContaining(_ikhlas1), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('ayet ayet: kart paylaşımı başlığı "<Sure> <n>. ayet", '
        'kampanya quran', (tester) async {
      SharedPreferences.setMockInitialValues({
        QuranService.viewModeKey: 'ayah',
      });
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

    testWidgets(
      "Araçlar'da Kur'an satırı yok (alt menü sekmesi); sekmede banner ve "
      'sure açılışında reklam yok',
      (tester) async {
        await pump(
          tester,
          const ToolsView(),
          width: 411,
          height: 891,
          textScale: 1,
        );
        final loc = lookupAppLocalizations(const Locale('tr'));
        // Bilgi grubu Cuma Mesajları ile biter, ardından Hesap grubu
        await tester.scrollUntilVisible(find.text(loc.toolsGroupCalc), 200);
        await tester.pump();
        expect(find.text(loc.fridayMessagesTitle), findsOneWidget);
        expect(find.text(loc.quranTitle), findsNothing);
        expect(find.text(loc.toolQuranDesc), findsNothing);

        // Alt menü sekmesi: kendi banner'ı yok (alt menüde tek banner)
        final before = AdHelper.instance.debugShowRequests;
        await pump(
          tester,
          const QuranView(asTab: true),
          width: 411,
          height: 891,
          textScale: 1,
        );
        expect(find.byType(AdBannerWidget), findsNothing);
        expect(
          tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
          isFalse,
        );
        expect(find.text('Fâtiha'), findsOneWidget);
        // Sure açılışında reklam yok
        await tester.tap(find.text('Fâtiha'));
        await settle(tester);
        expect(find.byType(SurahReaderView), findsOneWidget);
        expect(AdHelper.instance.debugShowRequests, before);
        await dispose(tester);

        // Sayfa olarak (sekme dışı) iç banner'ı korunur
        await pumpPhone(tester, QuranView(service: _service()));
        expect(find.byType(AdBannerWidget), findsOneWidget);
        await dispose(tester);
      },
    );

    testWidgets('hatim okuması: Devam Et sonraki sayfanın başından açar, '
        'görünen sayfadan öncekiler okunmuş sayılır (sonraki sure dahil); '
        'kaydırarak ilerleme takılmaz; uzak atlama ve geri dönüş sayılmaz; '
        'reklam yok', (tester) async {
      SharedPreferences.setMockInitialValues({
        HatimService.planKey: _hatimPlan(0),
      });
      final pages = QuranPages.parse(
        File(QuranPages.asset).readAsStringSync(),
      )!;
      final ads = AdHelper.instance.debugShowRequests;
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.hatimProgress(0, 604, '%0')), findsOneWidget);
      expect(find.text(loc.hatimToday(0, 20)), findsOneWidget);

      await tester.tap(find.text(loc.hatimContinue));
      await settle(tester);
      var reader = tester.widget<SurahReaderView>(find.byType(SurahReaderView));
      expect(
        [reader.surah.number, reader.initialAyah, reader.hatim],
        [1, 1, true],
      );
      // Açılan sayfa (1) henüz okunmadı
      expect((await _savedPlan())!.position, 0);

      // Sonraki sure (Bakara, 2. sayfa) oturumu sürdürür: 1. sayfa bitti
      await scrollThrough(tester);
      await tester.tap(find.text('Bakara'));
      await settle(tester);
      reader = tester.widget<SurahReaderView>(find.byType(SurahReaderView));
      expect([reader.surah.number, reader.hatim], [2, true]);
      expect((await _savedPlan())!.position, 1);

      // Kaydırdıkça görünen sayfa: konum ve bugünün kaydı onu izler
      final prefs = await SharedPreferences.getInstance();
      int visiblePage() {
        final last = QuranService.parseBookmark(
          prefs.getString(QuranService.lastReadKey),
        )!;
        return pages.pageOf(last.surah, last.ayah);
      }

      for (var i = 0; i < 6; i++) {
        await tester.drag(_vertical(), const Offset(0, -300));
        await settle(tester);
        final plan = (await _savedPlan())!;
        expect(plan.position, visiblePage() - 1, reason: 'adım $i');
        expect(plan.readOn(DateTime.now()), plan.position);
      }
      // Tek kaydırmada birkaç sayfa (hızlı kaydırma) da sayılır, ilerleme
      // takılmaz
      await tester.drag(_vertical(), const Offset(0, -2400));
      await settle(tester);
      expect((await _savedPlan())!.position, visiblePage() - 1);
      final reached = (await _savedPlan())!.position;
      expect(reached, greaterThan(2));

      // Geri dönüş sayılmaz
      await tester.drag(_vertical(), const Offset(0, 900));
      await settle(tester);
      expect(visiblePage(), lessThan(reached));
      expect((await _savedPlan())!.position, reached);

      // Ayete git ile uzak sayfa (Âyetü'l-Kürsî, 42. sayfa) okuma sayılmaz;
      // oradan kaydırmak da
      await tester.tap(find.byTooltip(loc.quranGoToAyah));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '255');
      await tester.pump();
      await tester.tap(find.text(loc.quranGo));
      await settle(tester);
      expect(visiblePage(), 42);
      await tester.drag(_vertical(), const Offset(0, -300));
      await settle(tester);
      expect((await _savedPlan())!.position, reached);

      // Listeye dönünce kart güncel; hiçbir adımda reklam yok
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(
        find.text(
          loc.hatimProgress(
            reached,
            604,
            '%${reached * 100 ~/ HatimPlan.pageCount}',
          ),
        ),
        findsOneWidget,
      );
      expect(AdHelper.instance.debugShowRequests, ads);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('hatim Nâs\'ın sonunda tamamlanır: kısa bildirim, sayaç, '
        'kartta "Hatim tamamlandı"', (tester) async {
      SharedPreferences.setMockInitialValues({
        HatimService.planKey: _hatimPlan(603),
      });
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.hatimContinue));
      await settle(tester);
      // 604. sayfa İhlâs'la başlar; Felak ve Nâs da bu sayfada
      expect(
        tester.widget<SurahReaderView>(find.byType(SurahReaderView)).surah.name,
        'İhlâs',
      );
      for (final next in ['Felak', 'Nâs']) {
        expect((await _savedPlan())!.position, 603, reason: next);
        await scrollThrough(tester);
        await tester.tap(find.text(next));
        await settle(tester);
      }
      await scrollThrough(tester);
      await settle(tester);
      final plan = (await _savedPlan())!;
      expect(plan.isFinished, isTrue);
      expect(find.text(loc.hatimCompleted), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(HatimService.countKey), 1);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text(loc.hatimDone), findsOneWidget);
      expect(find.text(loc.hatimCount(1)), findsOneWidget);
      expect(find.text(loc.hatimContinue), findsNothing);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('hatim kartı: seçenekler, Sayfa Gir, Planı Değiştir (kalan '
        'sayfalara göre), hatırlatma, Hatmi Sil', (tester) async {
      final notifications = <MethodCall>[];
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      // Uygulamada NotificationService.init kurar
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      messenger.setMockMethodCallHandler(channel, (call) async {
        notifications.add(call);
        return call.method == 'pendingNotificationRequests' ? [] : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final prefs = await SharedPreferences.getInstance();
      await pumpPhone(tester, QuranView(service: _service()));
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.hatimTitle), findsOneWidget);
      expect(find.text(loc.hatimIntro), findsOneWidget);

      await tester.tap(find.text(loc.hatimStart));
      await settle(tester);
      expect(
        [
          for (final (pages, months) in [(20, 1), (10, 2), (5, 4)])
            '${loc.hatimPagesPerDay(pages)} · ${loc.hatimDuration(months)}',
        ],
        [
          'Günde 20 sayfa · 30 günde',
          'Günde 10 sayfa · 2 ayda',
          'Günde 5 sayfa · 4 ayda',
        ],
      );
      for (final text in [
        'Günde 20 sayfa · 30 günde',
        'Günde 10 sayfa · 2 ayda',
        'Günde 5 sayfa · 4 ayda',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Ramazan seçeneği sadece Ramazan'da / 15 gün kala
      final ramadan = HatimPlan.ramadanTarget(
        (await tester.runAsync(loadRamadanCalendar))!,
        DateTime.now(),
      );
      expect(
        find.text(loc.hatimRamadan),
        ramadan == null ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.text('Günde 20 sayfa · 30 günde'));
      await settle(tester);
      final today = PrayerTracker.day(DateTime.now());
      var plan = (await _savedPlan())!;
      expect(plan.start, today);
      expect(plan.target, PrayerTracker.addDays(today, 30));
      expect(find.text('Sayfa 0 / 604 · %0'), findsOneWidget);
      expect(find.text('Bugün 0 / 20 sayfa'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Sayfa Gir (basılı mushaf): 1–604
      await hatimMenu(tester, loc.hatimEnterPage);
      expect(find.text(loc.hatimPageLabel(604)), findsOneWidget);
      FilledButton save() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, loc.save),
      );
      final pageField = find.descendant(
        of: find.byType(NumberDialog),
        matching: find.byType(TextField),
      );
      for (final invalid in ['0', '605']) {
        await tester.enterText(pageField, invalid);
        await tester.pump();
        expect(save().onPressed, isNull, reason: invalid);
      }
      await tester.enterText(pageField, '120');
      await tester.pump();
      await tester.tap(find.text(loc.save));
      await settle(tester);
      plan = (await _savedPlan())!;
      expect(plan.position, 120);
      expect(plan.readOn(today), 120);
      expect(find.text('Sayfa 120 / 604 · %19'), findsOneWidget);
      expect(find.text('Bugün 120 / 20 sayfa'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Hatırlatma (varsayılan kapalı): açılınca 21:00, bildirim kurulur
      await hatimMenu(tester, loc.hatimReminder);
      expect(find.text(loc.hatimReminderTime), findsNothing);
      await tester.tap(find.text(loc.hatimReminderDaily));
      await settle(tester);
      expect(prefs.getBool(HatimService.reminderKey), isTrue);
      expect(find.text('21:00'), findsOneWidget);
      // Bugünün hedefi tamam: hatırlatmalar yarından başlar
      final scheduled = notifications
          .where((c) => c.method == 'zonedSchedule')
          .toList();
      final tomorrow = PrayerTracker.addDays(today, 1);
      expect(scheduled.first.arguments['id'], HatimService.reminderIdFor(tomorrow));
      expect(scheduled.first.arguments['payload'], HatimService.reminderPayload);
      expect(
        scheduled.first.arguments['scheduledDateTime'],
        startsWith(PrayerTracker.dateKey(tomorrow)),
      );
      await tester.tap(find.text(loc.hatimReminderTime));
      await settle(tester);
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(TimePickerDialog)),
          ).cancelButtonLabel,
        ),
      );
      await settle(tester);
      Navigator.of(tester.element(find.text(loc.hatimReminderDaily))).pop();
      await settle(tester);

      // Planı Değiştir: konum korunur, günlük hedef kalan sayfalara göre
      await prefs.setString(
        HatimService.planKey,
        HatimPlan(
          start: plan.start,
          target: plan.target,
          position: 300,
          log: {PrayerTracker.dateKey(PrayerTracker.addDays(today, -1)): 30},
        ).encode(),
      );
      HatimService.changes.value++; // kart kayıttan yenilenir
      await settle(tester);
      expect(find.text('Sayfa 300 / 604 · %49'), findsOneWidget);
      await hatimMenu(tester, loc.hatimChangePlan);
      expect(find.text(loc.hatimChangePlan), findsOneWidget);
      for (final text in [
        'Günde 10 sayfa · 30 günde',
        'Günde 5 sayfa · 2 ayda',
        'Günde 3 sayfa · 4 ayda',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      await tester.tap(find.text('Günde 5 sayfa · 2 ayda'));
      await settle(tester);
      plan = (await _savedPlan())!;
      expect(plan.position, 300);
      expect(plan.target, PrayerTracker.addDays(today, 60));
      expect(find.text('Bugün 0 / 5 sayfa'), findsOneWidget);

      // Hatmi Sil (onaylı): kart başa döner
      await hatimMenu(tester, loc.hatimDelete);
      expect(find.text(loc.hatimDeleteConfirm), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, loc.hatimDelete));
      await settle(tester);
      expect(prefs.containsKey(HatimService.planKey), isFalse);
      expect(find.text(loc.hatimIntro), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang 320dp %130: tamamlanan hatim (tarih, sayaç) ve '
          '"Yeni Hatim Başlat" taşmaz', (tester) async {
        SharedPreferences.setMockInitialValues({
          HatimService.planKey: _hatimPlan(604, log: {_todayKey(): 2}),
          HatimService.countKey: 2,
        });
        await pump(tester, QuranView(service: _service()), lang: lang);
        final loc = lookupAppLocalizations(Locale(lang));
        expect(find.text(loc.hatimDone), findsOneWidget);
        expect(
          find.text(DateFormat.yMMMMd(loc.localeName).format(DateTime.now())),
          findsOneWidget,
        );
        expect(find.text(loc.hatimCount(2)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(loc.hatimNew));
        await settle(tester);
        expect(find.text(loc.hatimStart), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.text('${loc.hatimPagesPerDay(5)} · ${loc.hatimDuration(4)}'),
        );
        await settle(tester);
        expect((await _savedPlan())!.position, 0);
        expect(
          (await SharedPreferences.getInstance()).getInt(HatimService.countKey),
          2,
        );
        expect(find.text(loc.hatimToday(0, 5)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await dispose(tester);
      });
    }
  });
}
