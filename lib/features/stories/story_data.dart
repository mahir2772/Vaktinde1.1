import 'dart:convert';

import 'package:flutter/services.dart';

import '../duas/dua_data.dart' show localizedTexts, pickText;

/// Kıssa: başlık, kısa tanım (dönem / unvan), metin (paragraflar boş
/// satırla), ibret ve kaynak; hepsi dil başına (assets/data/stories.json)
class Story {
  final String id;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final Map<String, String> text;
  final Map<String, String> lesson;
  final Map<String, String> source;

  const Story({
    required this.id,
    required this.title,
    this.subtitle = const {},
    this.text = const {},
    this.lesson = const {},
    this.source = const {},
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    title: localizedTexts(json['title']),
    subtitle: localizedTexts(json['subtitle']),
    text: localizedTexts(json['text']),
    lesson: localizedTexts(json['lesson']),
    source: localizedTexts(json['source']),
  );

  String titleFor(String lang) => pickText(title, lang) ?? id;
  String? subtitleFor(String lang) => pickText(subtitle, lang);
  String? lessonFor(String lang) => pickText(lesson, lang);
  String? sourceFor(String lang) => pickText(source, lang);

  List<String> paragraphsFor(String lang) => (pickText(text, lang) ?? '')
      .split('\n\n')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}

class StoryCategory {
  final String id;
  final Map<String, String> title;
  final List<Story> stories;

  const StoryCategory({
    required this.id,
    required this.title,
    required this.stories,
  });

  String titleFor(String lang) => pickText(title, lang) ?? id;
}

/// Kıssalar (çevrimdışı): peygamberler, Peygamberimizin hayatı, sahabe,
/// İslam âlimleri
class StoryLibrary {
  static const String asset = 'assets/data/stories.json';

  final List<StoryCategory> categories;

  const StoryLibrary(this.categories);

  factory StoryLibrary.fromJson(Map<String, dynamic> json) => StoryLibrary([
    for (final c in json['categories'] as List)
      StoryCategory(
        id: c['id'] as String,
        title: localizedTexts(c['title']),
        stories: [
          for (final s in c['items'] as List)
            Story.fromJson(s as Map<String, dynamic>),
        ],
      ),
  ]);

  static Future<StoryLibrary>? _cache;

  /// Bir kez okunur; hata olursa sonraki çağrı yeniden dener
  static Future<StoryLibrary> load() => _cache ??= _read();

  static Future<StoryLibrary> _read() async {
    try {
      final raw = await rootBundle.loadString(asset);
      return StoryLibrary.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
