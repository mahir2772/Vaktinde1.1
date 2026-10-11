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

/// Bir ayet: Arapça metin + (Arapça arayüz dışında) meal
class QuranAyah {
  final int number;
  final String arabic;
  final String? translation;

  const QuranAyah({
    required this.number,
    required this.arabic,
    this.translation,
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
}

/// Kaldığın yer
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

/// Kur'an okuyucu: sure listesi (gömülü), sure metni (alquran.cloud; açılan
/// sureler cihazda saklanır, sonra internetsiz açılır), kaldığın yer ve
/// Arapça yazı boyutu.
///
/// Önbellek SharedPreferences'ta (path_provider doğrudan bağımlılık değil):
/// boyut sınırlı — en çok [maxCachedSurahs] sure ve [maxCachedChars] karakter;
/// en uzun süredir açılmayan silinir, kaldığın yerin suresi korunur.
class QuranService {
  static const int surahCount = 114;
  static const int totalAyahs = 6236;
  static const String surahsAsset = 'assets/data/surahs.json';

  static const String bookmarkKey = 'quran_bookmark';
  static const String fontScaleKey = 'quran_font_scale';

  /// Önbellek kayıtları (en son açılan başta) ve kayıt anahtarı öneki
  static const String cacheIndexKey = 'quran_cache_index';
  static const String cachePrefix = 'quran_surah_';
  static const int maxCachedSurahs = 10;
  static const int maxCachedChars = 400000;
  static const int _cacheVersion = 1;

  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.6;
  static const double fontScaleStep = 0.1;

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

  /// Baskının ayetleri (suredeki sıra → metin); eksik/bozuksa null
  static Map<int, String>? _ayahTexts(Object? edition, int ayahCount) {
    if (edition is! Map) return null;
    final ayahs = edition['ayahs'];
    if (ayahs is! List || ayahs.length != ayahCount) return null;
    final texts = <int, String>{};
    for (final a in ayahs) {
      if (a is! Map) return null;
      final number = a['numberInSurah'];
      final text = a['text'];
      if (number is! int || number < 1 || number > ayahCount) return null;
      if (text is! String || _clean(text).isEmpty) return null;
      texts[number] = _clean(text);
    }
    return texts.length == ayahCount ? texts : null;
  }

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
  /// başındaki besmele ayrı başlığa alınır.
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

      final arabic = _ayahTexts(arabicData, ayahCount);
      if (arabic == null) return null;
      Map<int, String>? meal;
      if (translationEdition != null) {
        meal = _ayahTexts(translationData, ayahCount);
        if (meal == null) return null;
      }

      String? bismillah;
      if (surah != 1 && surah != 9) {
        final split = splitBismillah(arabic[1]!);
        bismillah = split?.bismillah ?? bismillahText;
        if (split != null) arabic[1] = split.rest;
      }
      return SurahText(
        surah: surah,
        translationEdition: translationEdition,
        bismillah: bismillah,
        ayahs: [
          for (var n = 1; n <= ayahCount; n++)
            QuranAyah(number: n, arabic: arabic[n]!, translation: meal?[n]),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// Sure metni: önce cihazdaki kopya, yoksa ağdan (indirilen saklanır).
  /// Ağ yoksa / yanıt bozuksa hata fırlatır (ekran "Tekrar Dene" gösterir).
  Future<SurahText> loadSurah(Surah surah, String languageCode) async {
    final translation = QuranEdition.translationFor(languageCode);
    final key = cacheKey(surah.number, translation);
    final cached = await _readCache(key, surah, translation);
    if (cached != null) return cached;

    final raw = await _fetch(surahUrl(surah.number, languageCode));
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

  static String encodeCache(SurahText text) => jsonEncode({
    'v': _cacheVersion,
    'surah': text.surah,
    'edition': text.translationEdition,
    'bismillah': text.bismillah,
    'arabic': [for (final a in text.ayahs) a.arabic],
    if (text.translationEdition != null)
      'translation': [for (final a in text.ayahs) a.translation],
  });

  /// Saklanan kopya; sürümü, suresi, meali ya da ayet sayısı tutmuyorsa null
  static SurahText? decodeCache(
    String? raw,
    Surah surah,
    String? translationEdition,
  ) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['v'] != _cacheVersion ||
          data['surah'] != surah.number ||
          data['edition'] != translationEdition) {
        return null;
      }
      final bismillah = data['bismillah'];
      final arabic = data['arabic'];
      final translation = data['translation'];
      if (bismillah is! String?) return null;
      if (arabic is! List || arabic.length != surah.ayahCount) return null;
      final hasTranslation = translationEdition != null;
      if (hasTranslation &&
          (translation is! List || translation.length != surah.ayahCount)) {
        return null;
      }
      final ayahs = <QuranAyah>[];
      for (var i = 0; i < arabic.length; i++) {
        final a = arabic[i];
        final Object? t = hasTranslation ? (translation as List)[i] : null;
        if (a is! String || a.isEmpty) return null;
        if (hasTranslation && (t is! String || t.isEmpty)) return null;
        ayahs.add(
          QuranAyah(number: i + 1, arabic: a, translation: t as String?),
        );
      }
      return SurahText(
        surah: surah.number,
        translationEdition: translationEdition,
        bismillah: bismillah,
        ayahs: ayahs,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SurahText?> _readCache(
    String key,
    Surah surah,
    String? translationEdition,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = decodeCache(prefs.getString(key), surah, translationEdition);
      if (text == null) {
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
      return text;
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

  /// Saklar ve sınırı aşan eski kopyaları siler (en yeni ve kaldığın yerin
  /// suresi silinmez). Kayıt hatası okumayı engellemez.
  Future<void> _writeCache(String key, SurahText text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, encodeCache(text));
      final index = [
        key,
        ..._index(prefs).where((k) => k != key && prefs.containsKey(k)),
      ];
      final keep = (await loadBookmark())?.surah;
      var total = 0;
      for (final k in index) {
        total += prefs.getString(k)?.length ?? 0;
      }
      for (var i = index.length - 1; i > 0; i--) {
        if (index.length <= maxCachedSurahs && total <= maxCachedChars) break;
        final k = index[i];
        if (_surahOfKey(k) == keep) continue;
        total -= prefs.getString(k)?.length ?? 0;
        await prefs.remove(k);
        index.removeAt(i);
      }
      await prefs.setStringList(cacheIndexKey, index);
    } catch (_) {}
  }

  // --------------------------------------------------------- Kaldığın yer

  /// Kayıtlı yer; bozuk ya da sure aralığı dışındaysa null
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

  Future<QuranBookmark?> loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return parseBookmark(prefs.getString(bookmarkKey));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBookmark(QuranBookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      bookmarkKey,
      jsonEncode({'surah': bookmark.surah, 'ayah': bookmark.ayah}),
    );
  }

  Future<void> clearBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(bookmarkKey);
  }

  // ------------------------------------------------------ Arapça yazı boyutu

  /// Sınırlar içinde, adıma (0,1) yuvarlanmış ölçek
  static double clampFontScale(double scale) {
    if (!scale.isFinite) return 1;
    final rounded = (scale / fontScaleStep).round() * fontScaleStep;
    return double.parse(
      rounded.clamp(minFontScale, maxFontScale).toStringAsFixed(1),
    );
  }

  Future<double> loadFontScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(fontScaleKey);
      return value == null ? 1 : clampFontScale(value);
    } catch (_) {
      return 1;
    }
  }

  Future<void> saveFontScale(double scale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(fontScaleKey, clampFontScale(scale));
    } catch (_) {}
  }
}
