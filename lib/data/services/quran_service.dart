import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client.dart';

/// alquran.cloud baskıları — tek kaynak: günün ayeti (AyahService) ve Kur'an
/// okuyucu aynı Arapça metni ve aynı mealleri kullanır.
abstract final class QuranEdition {
  static const String apiBase = 'https://api.alquran.cloud/v1';

  /// Arapça asıl metin (Tanzil, Osmanlı hattı)
  static const String arabic = 'quran-uthmani';

  /// Arayüz diline göre meal; Arapça arayüzde meal yok (null). Desteklenmeyen
  /// dilde İngilizce.
  static String? translationFor(String languageCode) => switch (languageCode) {
    'tr' => 'tr.diyanet',
    'en' => 'en.sahih',
    'de' => 'de.aburida',
    'fr' => 'fr.hamidullah',
    'ar' => null,
    _ => 'en.sahih',
  };

  /// Mealin kaynağı (sure sonundaki kaynak satırı)
  static String? translatorOf(String edition) => switch (edition) {
    'tr.diyanet' => 'Diyanet İşleri',
    'en.sahih' => 'Saheeh International',
    'de.aburida' => 'Abu Rida Muhammad ibn Ahmad ibn Rassoul',
    'fr.hamidullah' => 'Muhammad Hamidullah',
    _ => null,
  };
}

/// Sure bilgisi (assets/data/surahs.json)
class Surah {
  final int number;
  final String arabicName;

  /// Türkçe okunuş ("Bakara")
  final String name;

  /// Latin harfli okunuş ("Al-Baqarah"; en/de/fr)
  final String englishName;
  final int ayahCount;

  /// "Mekke" / "Medine"
  final String revelation;

  const Surah({
    required this.number,
    required this.arabicName,
    required this.name,
    required this.englishName,
    required this.ayahCount,
    required this.revelation,
  });

  bool get isMedinan => revelation == 'Medine';

  /// Arayüz diline göre ad: tr Türkçe, ar Arapça, diğerleri Latin okunuş
  String displayName(String languageCode) => switch (languageCode) {
    'tr' => name,
    'ar' => arabicName,
    _ => englishName,
  };

  static Surah? fromJson(Object? json) {
    if (json is! Map) return null;
    final number = json['number'];
    final ayahCount = json['ayahCount'];
    final revelation = json['revelation'];
    final names = [json['arabicName'], json['name'], json['englishName']];
    if (number is! int || number < 1 || number > QuranService.surahCount) {
      return null;
    }
    if (ayahCount is! int || ayahCount < 1) return null;
    if (revelation != 'Mekke' && revelation != 'Medine') return null;
    if (names.any((n) => n is! String || n.trim().isEmpty)) return null;
    return Surah(
      number: number,
      arabicName: (names[0] as String).trim(),
      name: (names[1] as String).trim(),
      englishName: (names[2] as String).trim(),
      ayahCount: ayahCount,
      revelation: revelation as String,
    );
  }
}

/// Okuyucunun görünümü ('quran_view_mode'; seçilen saklanır)
enum QuranViewMode {
  /// Mushaf düzeninde kesintisiz Arapça metin (varsayılan)
  page,

  /// Ayet kartları: Arapça + meal, ayet başına yer imi ve paylaşım
  ayah,

  /// Yalnızca meal, kesintisiz (Arapça arayüzde yok)
  translation,
}

/// Bir ayet: Arapça metin + (Arapça arayüz dışında) meal. Mushaf bilgisi
/// (sayfa, cüz, hizb çeyreği, secde) API'den gelir; eski kopyada yoktur.
class QuranAyah {
  final int number;
  final String arabic;
  final String? translation;

  /// Medine mushafındaki sayfa (1–604)
  final int? page;

  /// Cüz (1–30)
  final int? juz;

  /// Hizb çeyreği (1–240)
  final int? hizbQuarter;

  /// Secde ayeti
  final bool sajda;

  const QuranAyah({
    required this.number,
    required this.arabic,
    this.translation,
    this.page,
    this.juz,
    this.hizbQuarter,
    this.sajda = false,
  });
}

/// Okuyucunun gösterdiği sure metni
class SurahText {
  final int surah;

  /// Meal baskısı (Arapça arayüzde null)
  final String? translationEdition;

  /// Ayrı başlıkta gösterilen besmele: Fâtiha'da (1. ayettir) ve Tevbe'de null
  final String? bismillah;
  final List<QuranAyah> ayahs;

  const SurahText({
    required this.surah,
    required this.translationEdition,
    required this.bismillah,
    required this.ayahs,
  });

  /// Her ayetin mushaf sayfası biliniyor ve sayfalar artan sırada
  bool get hasPageInfo {
    int? previous;
    for (final ayah in ayahs) {
      final page = ayah.page;
      if (page == null || (previous != null && page < previous)) return false;
      previous = page;
    }
    return ayahs.isNotEmpty;
  }
}

/// Sayfa görünümünün bir sayfası: aynı mushaf sayfasındaki ayetler. Sayfa
/// bilgisi yoksa (eski kopya) en çok [QuranService.fallbackPageSize] ayetlik
/// grup ([page] null).
class QuranPageGroup {
  final int? page;
  final int juz;
  final List<QuranAyah> ayahs;

  const QuranPageGroup({
    required this.page,
    required this.juz,
    required this.ayahs,
  });

  int get firstAyah => ayahs.first.number;
  int get lastAyah => ayahs.last.number;

  bool contains(int ayah) => ayah >= firstAyah && ayah <= lastAyah;
}

/// Kur'an'da bir konum: yer imi ('quran_bookmark') ya da son okunan ayet
/// ('quran_last_read')
class QuranBookmark {
  final int surah;
  final int ayah;

  const QuranBookmark({required this.surah, required this.ayah});

  @override
  bool operator ==(Object other) =>
      other is QuranBookmark && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}

/// Cüz başlangıcı (sure:ayet)
typedef QuranJuzStart = ({int surah, int ayah});

/// Kur'an okuyucu: sure listesi (gömülü), sure metni (alquran.cloud; açılan
/// sureler cihazda saklanır, sonra internetsiz açılır), yer imi, son okunan
/// ayet, görünüm ve yazı boyutları.
///
/// Önbellek SharedPreferences'ta (path_provider doğrudan bağımlılık değil):
/// boyut sınırlı — en çok [maxCachedSurahs] sure ve [maxCachedChars] karakter;
/// en uzun süredir açılmayan silinir, yer iminin ve son okunanın suresi
/// korunur.
class QuranService {
  static const int surahCount = 114;
  static const int totalAyahs = 6236;
  static const int juzCount = 30;
  static const int pageCount = 604;
  static const int hizbQuarterCount = 240;
  static const String surahsAsset = 'assets/data/surahs.json';

  static const String bookmarkKey = 'quran_bookmark';
  static const String lastReadKey = 'quran_last_read';
  static const String viewModeKey = 'quran_view_mode';
  static const String fontScaleKey = 'quran_font_scale';
  static const String translationScaleKey = 'quran_translation_scale';

  /// Önbellek kayıtları (en son açılan başta) ve kayıt anahtarı öneki
  static const String cacheIndexKey = 'quran_cache_index';
  static const String cachePrefix = 'quran_surah_';
  static const int maxCachedSurahs = 10;
  static const int maxCachedChars = 400000;

  /// 2: mushaf bilgisi (sayfa, cüz, hizb, secde) eklendi. Sürüm 1 kopyası
  /// okunur; ağ varsa yenilenir.
  static const int _cacheVersion = 2;
  static const int _legacyCacheVersion = 1;

  /// Eski kopyayı yenileme isteğinin süresi (aşılırsa kopya açılır)
  static const Duration upgradeTimeout = Duration(seconds: 5);

  /// Sayfa bilgisi yoksa sayfa görünümünde grup başına ayet
  static const int fallbackPageSize = 10;

  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.6;
  static const double fontScaleStep = 0.1;

  /// Hafs rivayeti, Medine mushafı cüz başlangıçları (quran-meta ile
  /// karşılaştırıldı; test/quran_test.dart)
  static const List<QuranJuzStart> juzStarts = [
    (surah: 1, ayah: 1),
    (surah: 2, ayah: 142),
    (surah: 2, ayah: 253),
    (surah: 3, ayah: 93),
    (surah: 4, ayah: 24),
    (surah: 4, ayah: 148),
    (surah: 5, ayah: 82),
    (surah: 6, ayah: 111),
    (surah: 7, ayah: 88),
    (surah: 8, ayah: 41),
    (surah: 9, ayah: 93),
    (surah: 11, ayah: 6),
    (surah: 12, ayah: 53),
    (surah: 15, ayah: 1),
    (surah: 17, ayah: 1),
    (surah: 18, ayah: 75),
    (surah: 21, ayah: 1),
    (surah: 23, ayah: 1),
    (surah: 25, ayah: 21),
    (surah: 27, ayah: 56),
    (surah: 29, ayah: 46),
    (surah: 33, ayah: 31),
    (surah: 36, ayah: 28),
    (surah: 39, ayah: 32),
    (surah: 41, ayah: 47),
    (surah: 46, ayah: 1),
    (surah: 51, ayah: 31),
    (surah: 58, ayah: 1),
    (surah: 67, ayah: 1),
    (surah: 78, ayah: 1),
  ];

  /// Besmele (API'de ayrılamazsa başlıkta bu gösterilir)
  static const String bismillahText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';
  static const List<String> _bismillahWords = [
    'بسم',
    'الله',
    'الرحمن',
    'الرحيم',
  ];

  /// Karşılaştırmada yok sayılanlar: harekeler, Kur'an işaretleri, tatvil,
  /// BOM ve yön/sıfır genişlik karakterleri
  static final RegExp _marks = RegExp(
    '[\u0610-\u061A\u061C\u0640\u064B-\u065F\u0670\u06D6-\u06ED'
    '\u200B-\u200F\uFEFF]',
  );
  static final RegExp _word = RegExp(r'\S+');

  final Future<String> Function() _loadAsset;
  final Future<String?> Function(Uri url) _fetch;

  /// [loadAsset] / [fetch]: test için (varsayılan: rootBundle, httpGet 10 sn)
  QuranService({
    Future<String> Function()? loadAsset,
    Future<String?> Function(Uri url)? fetch,
  }) : _loadAsset = loadAsset ?? (() => rootBundle.loadString(surahsAsset)),
       _fetch = fetch ?? _httpFetch;

  static Future<String?> _httpFetch(Uri url) async {
    final response = await httpGet(url);
    // Gövde UTF-8 çözülür (başlıkta karakter kümesi yoksa http latin1 sanar)
    return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null;
  }

  // ---------------------------------------------------------------- Sureler

  /// Geçerli sure kayıtları (sırayla); bozuk kayıt atlanır
  static List<Surah> parseSurahs(String raw) {
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (Surah.fromJson(e) case final surah?) surah,
    ]..sort((a, b) => a.number.compareTo(b.number));
  }

  Future<List<Surah>> loadSurahs() async {
    final surahs = parseSurahs(await _loadAsset());
    if (surahs.isEmpty) throw StateError('surahs.json okunamadı');
    return surahs;
  }

  // ------------------------------------------------------------ Sure arama

  /// Harf işaretleri yok sayılarak arama: Türkçe/Latin (â, î, ı, ş…) ve
  /// Arapça (harekeler, elif/ye/te-i merbuta yazılışları) sadeleşir; boşluk,
  /// tire ve kesme atılır, Arapça-Hint rakamları 0-9 olur.
  static String searchKey(String text) {
    final buffer = StringBuffer();
    final lower = text
        .replaceAll('İ', 'i')
        .toLowerCase()
        .replaceAll(_marks, '');
    for (final rune in lower.runes) {
      var code = rune;
      if (code >= 0x0660 && code <= 0x0669) code = 0x30 + code - 0x0660;
      if (code >= 0x06F0 && code <= 0x06F9) code = 0x30 + code - 0x06F0;
      final char = String.fromCharCode(code);
      final folded = _latinFold[char] ?? _arabicFold[char] ?? char;
      for (final c in folded.codeUnits) {
        final keep =
            (c >= 0x61 && c <= 0x7A) || // a-z
            (c >= 0x30 && c <= 0x39) || // 0-9
            (c >= 0x0621 && c <= 0x063A) ||
            (c >= 0x0641 && c <= 0x064A);
        if (keep) buffer.writeCharCode(c);
      }
    }
    return buffer.toString();
  }

  static const Map<String, String> _latinFold = {
    'â': 'a', 'á': 'a', 'à': 'a', 'ä': 'a', 'ā': 'a', 'ã': 'a', //
    'î': 'i', 'í': 'i', 'ì': 'i', 'ï': 'i', 'ī': 'i', 'ı': 'i',
    'û': 'u', 'ú': 'u', 'ù': 'u', 'ü': 'u', 'ū': 'u',
    'ê': 'e', 'é': 'e', 'è': 'e', 'ë': 'e', 'ē': 'e',
    'ô': 'o', 'ó': 'o', 'ò': 'o', 'ö': 'o', 'ō': 'o',
    'ç': 'c', 'ş': 's', 'ğ': 'g', 'ñ': 'n', 'ß': 'ss',
    'ḥ': 'h', 'ṣ': 's', 'ṭ': 't', 'ẓ': 'z', 'ḍ': 'd',
  };

  static const Map<String, String> _arabicFold = {
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ة': 'ه', //
    'ؤ': 'و', 'ئ': 'ي',
  };

  /// Sure numarası (yazılan rakamlarla başlayan) ya da Türkçe, Latin veya
  /// Arapça adı ile arama; boş sorgu tüm liste
  static List<Surah> searchSurahs(List<Surah> surahs, String query) {
    final key = searchKey(query);
    if (key.isEmpty) return surahs;
    if (RegExp(r'^\d+$').hasMatch(key)) {
      final number = key.replaceFirst(RegExp('^0+'), '');
      if (number.isEmpty) return const [];
      return [
        for (final s in surahs)
          if ('${s.number}'.startsWith(number)) s,
      ];
    }
    return [
      for (final s in surahs)
        if (searchKey(s.name).contains(key) ||
            searchKey(s.englishName).contains(key) ||
            searchKey(s.arabicName).contains(key))
          s,
    ];
  }

  // ------------------------------------------------------------------ Cüz

  /// Ayetin cüzü (1–30)
  static int juzOf(int surah, int ayah) {
    for (var i = juzStarts.length - 1; i > 0; i--) {
      final start = juzStarts[i];
      if (surah > start.surah || (surah == start.surah && ayah >= start.ayah)) {
        return i + 1;
      }
    }
    return 1;
  }

  // ------------------------------------------------------------ Sayfalar

  /// Sayfa görünümünün sayfaları: aynı mushaf sayfasındaki ayetler bir arada.
  /// Sayfa bilgisi yoksa (eski kopya) [fallbackPageSize] ayetlik gruplar
  /// (cüz başında yeni grup).
  static List<QuranPageGroup> pageGroups(SurahText text) {
    final byPage = text.hasPageInfo;
    final groups = <QuranPageGroup>[];
    var current = <QuranAyah>[];
    int juzOfAyah(QuranAyah a) => a.juz ?? juzOf(text.surah, a.number);

    void close() {
      if (current.isEmpty) return;
      final first = current.first;
      groups.add(
        QuranPageGroup(
          page: byPage ? first.page : null,
          juz: juzOfAyah(first),
          ayahs: List.unmodifiable(current),
        ),
      );
      current = <QuranAyah>[];
    }

    for (final ayah in text.ayahs) {
      if (current.isNotEmpty) {
        final split = byPage
            ? ayah.page != current.first.page
            : current.length >= fallbackPageSize ||
                  juzOfAyah(ayah) != juzOfAyah(current.first);
        if (split) close();
      }
      current.add(ayah);
    }
    close();
    return groups;
  }

  /// Arapça-Hint rakamları (١٢)
  static String arabicIndicDigits(int number) => String.fromCharCodes([
    for (final c in '$number'.codeUnits) c - 0x30 + 0x0660,
  ]);

  /// Ayet sonu işareti: süslü parantez içinde numara (﴿١٢﴾). Sağdan sola
  /// metinde mantıksal sıra U+FD3F, rakamlar, U+FD3E.
  static String ayahEndMarker(int number) =>
      '\uFD3F${arabicIndicDigits(number)}\uFD3E';

  // ----------------------------------------------------------- Sure metni

  /// Sure isteği: Arapça + dile göre meal (Arapça arayüzde sadece Arapça)
  static Uri surahUrl(int surah, String languageCode) {
    final translation = QuranEdition.translationFor(languageCode);
    final editions = [QuranEdition.arabic, ?translation].join(',');
    return Uri.parse('${QuranEdition.apiBase}/surah/$surah/editions/$editions');
  }

  /// Besmele karşılaştırması için sade harfler
  static String _plain(String word) => word
      .replaceAll(_marks, '')
      .replaceAll('\u0671', '\u0627') // elif-i vasla → elif
      .replaceAll('\u0649', '\u064A'); // elif-i maksura → ye

  /// İlk ayetin başındaki besmeleyi ayırır (harekeler/işaretler farklı
  /// yazılsa da). Besmele yoksa ya da ardından metin gelmiyorsa null.
  static ({String bismillah, String rest})? splitBismillah(String text) {
    final words = _word.allMatches(text).take(5).toList();
    if (words.length < 5) return null;
    for (var i = 0; i < _bismillahWords.length; i++) {
      if (_plain(words[i].group(0)!) != _bismillahWords[i]) return null;
    }
    return (
      bismillah: text.substring(words[0].start, words[3].end),
      rest: text.substring(words[4].start).trim(),
    );
  }

  static String _clean(String text) => text.replaceAll('\uFEFF', '').trim();

  /// Baskının ayetleri (suredeki sıra → API kaydı); eksik/bozuksa null
  static Map<int, Map<Object?, Object?>>? _editionAyahs(
    Object? edition,
    int ayahCount,
  ) {
    if (edition is! Map) return null;
    final ayahs = edition['ayahs'];
    if (ayahs is! List || ayahs.length != ayahCount) return null;
    final result = <int, Map<Object?, Object?>>{};
    for (final a in ayahs) {
      if (a is! Map) return null;
      final number = a['numberInSurah'];
      final text = a['text'];
      if (number is! int || number < 1 || number > ayahCount) return null;
      if (text is! String || _clean(text).isEmpty) return null;
      result[number] = a;
    }
    return result.length == ayahCount ? result : null;
  }

  /// Aralıktaki tam sayı; değilse null
  static int? _intIn(Object? value, int max) =>
      value is int && value >= 1 && value <= max ? value : null;

  static String? _identifier(Object? edition) {
    if (edition is! Map) return null;
    final info = edition['edition'];
    return info is Map && info['identifier'] is String
        ? info['identifier'] as String
        : null;
  }

  /// alquran.cloud `surah/<n>/editions/...` yanıtı. Ayet sayısı tutmuyorsa,
  /// istenen meal yoksa ya da yanıt bozuksa null. Baskılar kimliğiyle, kimlik
  /// yoksa sırayla (önce Arapça) eşlenir. Fâtiha ve Tevbe dışında ilk ayetin
  /// başındaki besmele ayrı başlığa alınır. Mushaf bilgisi (sayfa, cüz, hizb
  /// çeyreği, secde) Arapça baskıdan; eksik/bozuk alan null kalır.
  static SurahText? parseSurahResponse(
    String raw, {
    required int surah,
    required int ayahCount,
    String? translationEdition,
  }) {
    try {
      final body = jsonDecode(raw);
      if (body is! Map) return null;
      final data = body['data'];
      final editions = data is List ? data : [data];
      if (editions.isEmpty) return null;

      Object? arabicData;
      Object? translationData;
      for (final e in editions) {
        final id = _identifier(e);
        if (id == QuranEdition.arabic) {
          arabicData ??= e;
        } else if (id != null && id == translationEdition) {
          translationData ??= e;
        }
      }
      if (editions.every((e) => _identifier(e) == null)) {
        arabicData = editions.first;
        if (translationEdition != null && editions.length > 1) {
          translationData = editions[1];
        }
      }

      final arabic = _editionAyahs(arabicData, ayahCount);
      if (arabic == null) return null;
      Map<int, Map<Object?, Object?>>? meal;
      if (translationEdition != null) {
        meal = _editionAyahs(translationData, ayahCount);
        if (meal == null) return null;
      }

      final texts = {
        for (final MapEntry(:key, :value) in arabic.entries)
          key: _clean(value['text'] as String),
      };
      String? bismillah;
      if (surah != 1 && surah != 9) {
        final split = splitBismillah(texts[1]!);
        bismillah = split?.bismillah ?? bismillahText;
        if (split != null) texts[1] = split.rest;
      }
      return SurahText(
        surah: surah,
        translationEdition: translationEdition,
        bismillah: bismillah,
        ayahs: [
          for (var n = 1; n <= ayahCount; n++)
            QuranAyah(
              number: n,
              arabic: texts[n]!,
              translation: meal == null
                  ? null
                  : _clean(meal[n]!['text'] as String),
              page: _intIn(arabic[n]!['page'], pageCount),
              juz: _intIn(arabic[n]!['juz'], juzCount),
              hizbQuarter: _intIn(arabic[n]!['hizbQuarter'], hizbQuarterCount),
              // Secde ayetinde nesne ({id, recommended, obligatory}), yoksa false
              sajda: arabic[n]!['sajda'] == true || arabic[n]!['sajda'] is Map,
            ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// Sure metni: önce cihazdaki kopya, yoksa ağdan (indirilen saklanır).
  /// Sayfa bilgisi olmayan eski kopya ağ varsa yenilenir, yoksa (ya da
  /// [upgradeTimeout] aşılırsa) kopya açılır. Kopya yokken ağ yoksa / yanıt
  /// bozuksa hata fırlatır (ekran "Tekrar Dene" gösterir).
  Future<SurahText> loadSurah(Surah surah, String languageCode) async {
    final translation = QuranEdition.translationFor(languageCode);
    final key = cacheKey(surah.number, translation);
    final cached = await _readCache(key, surah, translation);
    if (cached != null && !cached.legacy) return cached.text;

    try {
      final request = _fetch(surahUrl(surah.number, languageCode));
      final raw = await (cached == null
          ? request
          : request.timeout(upgradeTimeout));
      if (raw == null) throw StateError('sure indirilemedi');
      final text = parseSurahResponse(
        raw,
        surah: surah.number,
        ayahCount: surah.ayahCount,
        translationEdition: translation,
      );
      if (text == null) throw const FormatException('sure yanıtı bozuk');
      await _writeCache(key, text);
      return text;
    } catch (_) {
      if (cached != null) return cached.text;
      rethrow;
    }
  }

  // ------------------------------------------------------------- Önbellek

  static String cacheKey(int surah, String? translationEdition) =>
      '$cachePrefix${surah}_${translationEdition ?? QuranEdition.arabic}';

  static int? _surahOfKey(String key) {
    if (!key.startsWith(cachePrefix)) return null;
    final rest = key.substring(cachePrefix.length);
    final end = rest.indexOf('_');
    return end > 0 ? int.tryParse(rest.substring(0, end)) : null;
  }

  static String encodeCache(SurahText text) {
    final ayahs = text.ayahs;

    /// Alan her ayette varsa liste; yoksa yazılmaz
    List<int>? all(int? Function(QuranAyah a) field) {
      final values = [for (final a in ayahs) field(a)];
      return values.contains(null) ? null : values.cast<int>();
    }

    final page = all((a) => a.page);
    final juz = all((a) => a.juz);
    final hizb = all((a) => a.hizbQuarter);
    return jsonEncode({
      'v': _cacheVersion,
      'surah': text.surah,
      'edition': text.translationEdition,
      'bismillah': text.bismillah,
      'arabic': [for (final a in ayahs) a.arabic],
      if (text.translationEdition != null)
        'translation': [for (final a in ayahs) a.translation],
      'page': ?page,
      'juz': ?juz,
      'hizb': ?hizb,
      'sajda': [
        for (final a in ayahs)
          if (a.sajda) a.number,
      ],
    });
  }

  /// Saklanan kopya; sürümü, suresi, meali ya da ayet sayısı tutmuyorsa null
  static SurahText? decodeCache(
    String? raw,
    Surah surah,
    String? translationEdition,
  ) => _decodeCache(raw, surah, translationEdition)?.text;

  /// [legacy]: sürüm 1 kopyası (mushaf bilgisi yok)
  static ({SurahText text, bool legacy})? _decodeCache(
    String? raw,
    Surah surah,
    String? translationEdition,
  ) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final version = data['v'];
      if ((version != _cacheVersion && version != _legacyCacheVersion) ||
          data['surah'] != surah.number ||
          data['edition'] != translationEdition) {
        return null;
      }
      final count = surah.ayahCount;
      final bismillah = data['bismillah'];
      final arabic = data['arabic'];
      final translation = data['translation'];
      if (bismillah is! String?) return null;
      if (arabic is! List || arabic.length != count) return null;
      final hasTranslation = translationEdition != null;
      if (hasTranslation &&
          (translation is! List || translation.length != count)) {
        return null;
      }

      // Mushaf bilgisi (sürüm 2): alan varsa her ayet için geçerli olmalı
      List<int>? meta(String name, int max) {
        final values = data[name];
        if (values == null) return null;
        if (values is! List || values.length != count) {
          throw const FormatException('bozuk kopya');
        }
        return [
          for (final v in values)
            _intIn(v, max) ?? (throw const FormatException('bozuk kopya')),
        ];
      }

      final legacy = version == _legacyCacheVersion;
      final page = legacy ? null : meta('page', pageCount);
      final juz = legacy ? null : meta('juz', juzCount);
      final hizb = legacy ? null : meta('hizb', hizbQuarterCount);
      final sajdaRaw = legacy ? null : data['sajda'];
      final sajda = <int>{
        if (sajdaRaw is List)
          for (final n in sajdaRaw)
            if (n is int) n,
      };

      final ayahs = <QuranAyah>[];
      for (var i = 0; i < count; i++) {
        final a = arabic[i];
        final Object? t = hasTranslation ? (translation as List)[i] : null;
        if (a is! String || a.isEmpty) return null;
        if (hasTranslation && (t is! String || t.isEmpty)) return null;
        ayahs.add(
          QuranAyah(
            number: i + 1,
            arabic: a,
            translation: t as String?,
            page: page?[i],
            juz: juz?[i],
            hizbQuarter: hizb?[i],
            sajda: sajda.contains(i + 1),
          ),
        );
      }
      return (
        text: SurahText(
          surah: surah.number,
          translationEdition: translationEdition,
          bismillah: bismillah,
          ayahs: ayahs,
        ),
        legacy: legacy,
      );
    } catch (_) {
      return null;
    }
  }

  Future<({SurahText text, bool legacy})?> _readCache(
    String key,
    Surah surah,
    String? translationEdition,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = _decodeCache(
        prefs.getString(key),
        surah,
        translationEdition,
      );
      if (cached == null) {
        if (prefs.containsKey(key)) await _dropCache(prefs, key);
        return null;
      }
      final index = _index(prefs);
      if (index.isEmpty || index.first != key) {
        await prefs.setStringList(cacheIndexKey, [
          key,
          ...index.where((k) => k != key),
        ]);
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  static List<String> _index(SharedPreferences prefs) {
    try {
      return prefs.getStringList(cacheIndexKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _dropCache(SharedPreferences prefs, String key) async {
    await prefs.remove(key);
    await prefs.setStringList(
      cacheIndexKey,
      _index(prefs).where((k) => k != key).toList(),
    );
  }

  /// Saklar ve sınırı aşan eski kopyaları siler (en yeni, yer iminin ve son
  /// okunanın suresi silinmez). Kayıt hatası okumayı engellemez.
  Future<void> _writeCache(String key, SurahText text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, encodeCache(text));
      final index = [
        key,
        ..._index(prefs).where((k) => k != key && prefs.containsKey(k)),
      ];
      final keep = {
        (await loadBookmark())?.surah,
        (await loadLastRead())?.surah,
      };
      var total = 0;
      for (final k in index) {
        total += prefs.getString(k)?.length ?? 0;
      }
      for (var i = index.length - 1; i > 0; i--) {
        if (index.length <= maxCachedSurahs && total <= maxCachedChars) break;
        final k = index[i];
        if (keep.contains(_surahOfKey(k))) continue;
        total -= prefs.getString(k)?.length ?? 0;
        await prefs.remove(k);
        index.removeAt(i);
      }
      await prefs.setStringList(cacheIndexKey, index);
    } catch (_) {}
  }

  // ------------------------------------------- Yer imi ve son okunan ayet

  /// Kayıtlı konum; bozuk ya da sure aralığı dışındaysa null
  static QuranBookmark? parseBookmark(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final surah = data['surah'];
      final ayah = data['ayah'];
      if (surah is! int || surah < 1 || surah > surahCount) return null;
      if (ayah is! int || ayah < 1) return null;
      return QuranBookmark(surah: surah, ayah: ayah);
    } catch (_) {
      return null;
    }
  }

  static String _encodePosition(QuranBookmark position) =>
      jsonEncode({'surah': position.surah, 'ayah': position.ayah});

  Future<QuranBookmark?> _loadPosition(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return parseBookmark(prefs.getString(key));
    } catch (_) {
      return null;
    }
  }

  /// Elle eklenen yer imi
  Future<QuranBookmark?> loadBookmark() => _loadPosition(bookmarkKey);

  Future<void> saveBookmark(QuranBookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookmarkKey, _encodePosition(bookmark));
  }

  Future<void> clearBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(bookmarkKey);
  }

  /// Son okunan ayet (okuyucu kaydırma durunca ve çıkarken kendisi yazar)
  Future<QuranBookmark?> loadLastRead() => _loadPosition(lastReadKey);

  /// Kayıt hatası okumayı engellemez
  Future<void> saveLastRead(QuranBookmark position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastReadKey, _encodePosition(position));
    } catch (_) {}
  }

  // -------------------------------------------------------------- Görünüm

  /// Saklanan görünüm; yoksa / bilinmiyorsa sayfa
  static QuranViewMode parseViewMode(Object? raw) =>
      QuranViewMode.values.where((m) => m.name == raw).firstOrNull ??
      QuranViewMode.page;

  /// Arapça arayüzde meal yok: meal görünümü sayfa olarak açılır (seçim
  /// saklı kalır, dil değişince geri gelir)
  static QuranViewMode effectiveViewMode(
    QuranViewMode mode,
    String languageCode,
  ) =>
      mode == QuranViewMode.translation &&
          QuranEdition.translationFor(languageCode) == null
      ? QuranViewMode.page
      : mode;

  Future<QuranViewMode> loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return parseViewMode(prefs.get(viewModeKey));
    } catch (_) {
      return QuranViewMode.page;
    }
  }

  Future<void> saveViewMode(QuranViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(viewModeKey, mode.name);
    } catch (_) {}
  }

  // ------------------------------------------------- Arapça / meal boyutu

  /// Sınırlar içinde, adıma (0,1) yuvarlanmış ölçek
  static double clampFontScale(double scale) {
    if (!scale.isFinite) return 1;
    final rounded = (scale / fontScaleStep).round() * fontScaleStep;
    return double.parse(
      rounded.clamp(minFontScale, maxFontScale).toStringAsFixed(1),
    );
  }

  Future<double> _loadScale(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(key);
      return value == null ? 1 : clampFontScale(value);
    } catch (_) {
      return 1;
    }
  }

  Future<void> _saveScale(String key, double scale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, clampFontScale(scale));
    } catch (_) {}
  }

  /// Arapça yazı ölçeği (tüm görünümlerde)
  Future<double> loadFontScale() => _loadScale(fontScaleKey);

  Future<void> saveFontScale(double scale) => _saveScale(fontScaleKey, scale);

  /// Meal yazı ölçeği
  Future<double> loadTranslationScale() => _loadScale(translationScaleKey);

  Future<void> saveTranslationScale(double scale) =>
      _saveScale(translationScaleKey, scale);
}
