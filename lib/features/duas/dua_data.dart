import 'dart:convert';

import 'package:flutter/services.dart';

/// Dualar (assets/data/duas.json, çevrimdışı): kategoriler + namaz sonrası
/// tesbihat adımları. Arapça tek; okunuş Türkçe ("tr") ve diğer Latin
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
    title: _texts(json['title']),
    arabic: (json['arabic'] as String? ?? '').trim(),
    translit: _texts(json['translit']),
    meaning: _texts(json['meaning']),
    note: _texts(json['note']),
    source: _texts(json['source']),
    count: count ?? (json['count'] as int? ?? 0),
  );

  String titleFor(String lang) => _pick(title, lang) ?? id;

  String? translitFor(String lang) => switch (lang) {
    'ar' => null,
    'tr' => _nonEmpty(translit['tr']),
    _ => _nonEmpty(translit['latin']),
  };

  /// Arapçada yok (metin zaten Arapça); diğer diller kendi çevirisi
  String? meaningFor(String lang) =>
      lang == 'ar' ? null : _nonEmpty(meaning[lang]) ?? _pick(meaning, 'en');

  String? noteFor(String lang) => _pick(note, lang);

  String? sourceFor(String lang) => _pick(source, lang);

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

  String titleFor(String lang) => _pick(title, lang) ?? id;
}

class DuaLibrary {
  static const String asset = 'assets/data/duas.json';

  final List<DuaCategory> categories;

  /// Namaz sonrası tesbihat: Âyetü'l-Kürsî → 33'er tesbih → tevhid → dua
  final List<Dua> tesbihat;

  const DuaLibrary({required this.categories, required this.tesbihat});

  factory DuaLibrary.fromJson(Map<String, dynamic> json) {
    final categories = [
      for (final c in json['categories'] as List)
        DuaCategory(
          id: c['id'] as String,
          title: _texts(c['title']),
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
    return DuaLibrary(categories: categories, tesbihat: tesbihat);
  }

  static Future<DuaLibrary>? _cache;

  /// Bir kez okunur; hata olursa sonraki çağrı yeniden dener
  static Future<DuaLibrary> load() => _cache ??= _read();

  static Future<DuaLibrary> _read() async {
    try {
      final raw = await rootBundle.loadString(asset);
      return DuaLibrary.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}

Map<String, String> _texts(Object? json) => json is Map
    ? {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String) '$key': value.trim(),
      }
    : const {};

String? _nonEmpty(String? value) =>
    (value == null || value.isEmpty) ? null : value;

/// Dildeki metin; yoksa İngilizce, o da yoksa Türkçe
String? _pick(Map<String, String> texts, String lang) =>
    _nonEmpty(texts[lang]) ?? _nonEmpty(texts['en']) ?? _nonEmpty(texts['tr']);
