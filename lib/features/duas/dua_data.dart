import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/services/quran_service.dart';

/// Dualar (assets/data/duas.json, çevrimdışı): kategoriler + namaz sonrası
/// tesbihat adımları + zikirmatiğin hazır zikirleri. Arapça tek; okunuş Türkçe ("tr") ve diğer Latin
/// diller için ortak ("latin"); anlam/not/kaynak dil başına. Arapça arayüzde
/// okunuş ve anlam gösterilmez (not ve kaynak gösterilir).
class Dua {
  final String id;
  final Map<String, String> title;
  final String arabic;
  final Map<String, String> translit;
  final Map<String, String> meaning;
  final Map<String, String> note;
  final Map<String, String> source;

  /// Tesbihat adımında hedef sayı (0: sayaçsız son adım)
  final int count;

  const Dua({
    required this.id,
    required this.title,
    this.arabic = '',
    this.translit = const {},
    this.meaning = const {},
    this.note = const {},
    this.source = const {},
    this.count = 0,
  });

  factory Dua.fromJson(Map<String, dynamic> json, {int? count}) => Dua(
    id: json['id'] as String,
    title: localizedTexts(json['title']),
    arabic: (json['arabic'] as String? ?? '').trim(),
    translit: localizedTexts(json['translit']),
    meaning: localizedTexts(json['meaning']),
    note: localizedTexts(json['note']),
    source: localizedTexts(json['source']),
    count: count ?? (json['count'] as int? ?? 0),
  );

  String titleFor(String lang) => pickText(title, lang) ?? id;

  String? translitFor(String lang) => switch (lang) {
    'ar' => null,
    'tr' => _nonEmpty(translit['tr']),
    _ => _nonEmpty(translit['latin']),
  };

  /// Arapçada yok (metin zaten Arapça); diğer diller kendi çevirisi
  String? meaningFor(String lang) =>
      lang == 'ar' ? null : _nonEmpty(meaning[lang]) ?? pickText(meaning, 'en');

  String? noteFor(String lang) => pickText(note, lang);

  String? sourceFor(String lang) => pickText(source, lang);

  /// Kopyalanan / metin olarak paylaşılan hali
  String plainText(String lang) {
    final source = sourceFor(lang);
    return [
      arabic,
      translitFor(lang) ?? '',
      meaningFor(lang) ?? '',
      if (arabic.isEmpty && meaningFor(lang) == null) noteFor(lang) ?? '',
      if (source != null) '— $source',
    ].where((part) => part.isNotEmpty).join('\n\n');
  }
}

class DuaCategory {
  final String id;
  final Map<String, String> title;
  final List<Dua> duas;

  const DuaCategory({
    required this.id,
    required this.title,
    required this.duas,
  });

  String titleFor(String lang) => pickText(title, lang) ?? id;
}

class DuaLibrary {
  static const String asset = 'assets/data/duas.json';

  final List<DuaCategory> categories;

  /// Namaz sonrası tesbihat: Âyetü'l-Kürsî → 33'er tesbih → tevhid → dua
  final List<Dua> tesbihat;

  /// Zikirmatiğin hazır zikirleri (kimlik = sayaç kaydı anahtarı; [Dua.count]
  /// kaynakta geçen sayı, 0: yok)
  final List<Dua> dhikrs;

  const DuaLibrary({
    required this.categories,
    required this.tesbihat,
    this.dhikrs = const [],
  });

  /// Kategorilerdeki bütün dualar (sırayla)
  Iterable<Dua> get allDuas => categories.expand((c) => c.duas);

  /// Kimliğiyle dua (Namaz Hocası bağlantıları); yoksa null
  Dua? byId(String id) => allDuas.where((d) => d.id == id).firstOrNull;

  /// Başlık, okunuş, anlam ya da Arapça metinde geçen dualar (harf
  /// işaretleri ve büyük/küçük harf yok sayılır); boş sorgu: boş liste
  List<Dua> search(String query, String lang) {
    final key = QuranService.searchKey(query);
    if (key.isEmpty) return const [];
    return [
      for (final dua in allDuas)
        if ([
          dua.titleFor(lang),
          dua.translitFor(lang),
          dua.meaningFor(lang),
          dua.arabic,
        ].any((text) => QuranService.searchKey(text ?? '').contains(key)))
          dua,
    ];
  }

  factory DuaLibrary.fromJson(Map<String, dynamic> json) {
    final categories = [
      for (final c in json['categories'] as List)
        DuaCategory(
          id: c['id'] as String,
          title: localizedTexts(c['title']),
          duas: [
            for (final d in c['duas'] as List)
              Dua.fromJson(d as Map<String, dynamic>),
          ],
        ),
    ];
    final byId = {
      for (final c in categories)
        for (final d in c.duas) d.id: d,
    };
    final tesbihat = <Dua>[];
    for (final step in json['tesbihat'] as List) {
      final ref = step['ref'] as String?;
      final count = step['count'] as int? ?? 0;
      if (ref == null) {
        tesbihat.add(Dua.fromJson(step as Map<String, dynamic>));
        continue;
      }
      final dua = byId[ref];
      if (dua == null) throw FormatException('unknown dua: $ref');
      tesbihat.add(
        Dua(
          id: dua.id,
          title: dua.title,
          arabic: dua.arabic,
          translit: dua.translit,
          meaning: dua.meaning,
          note: dua.note,
          source: dua.source,
          count: count,
        ),
      );
    }
    return DuaLibrary(
      categories: categories,
      tesbihat: tesbihat,
      dhikrs: [
        for (final d in json['dhikrs'] as List? ?? const [])
          Dua.fromJson(d as Map<String, dynamic>),
      ],
    );
  }

  static Future<DuaLibrary>? _cache;

  /// Okunmuşsa kitaplık (beklemeden kullanılır), değilse null
  static DuaLibrary? get loaded => _loaded;
  static DuaLibrary? _loaded;

  /// Bir kez okunur; hata olursa sonraki çağrı yeniden dener
  static Future<DuaLibrary> load() => _cache ??= _read();

  static Future<DuaLibrary> _read() async {
    try {
      final raw = await rootBundle.loadString(asset);
      return _loaded = DuaLibrary.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}

/// Dil kodu → metin (Namaz Hocası da kullanır)
Map<String, String> localizedTexts(Object? json) => json is Map
    ? {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String) '$key': value.trim(),
      }
    : const {};

String? _nonEmpty(String? value) =>
    (value == null || value.isEmpty) ? null : value;

/// Dildeki metin; yoksa İngilizce, o da yoksa Türkçe
String? pickText(Map<String, String> texts, String lang) =>
    _nonEmpty(texts[lang]) ?? _nonEmpty(texts['en']) ?? _nonEmpty(texts['tr']);
