import 'dart:convert';

import 'package:flutter/services.dart';

import '../duas/dua_data.dart';

/// Adımda okunan: kısa zikir (Arapça + okunuş + anlam, [times] kez), dua
/// bağlantısı (duas.json kimliği), sûre bağlantısı (Kur'an okuyucusu) ya da
/// başlıklı açıklama (zamm-ı sûre).
class GuideRecitation {
  final Dua? dhikr;
  final String? dua;
  final int? surah;
  final int times;
  final Map<String, String> title;
  final Map<String, String> text;

  const GuideRecitation({
    this.dhikr,
    this.dua,
    this.surah,
    this.times = 1,
    this.title = const {},
    this.text = const {},
  });

  String? titleFor(String lang) => pickText(title, lang);

  String? textFor(String lang) => pickText(text, lang);
}

/// Numaralı adım / madde: başlık (duruş adı, terim), açıklama ve okunanlar
class GuideStep {
  final Map<String, String> title;
  final Map<String, String> text;
  final List<GuideRecitation> recite;

  const GuideStep({
    this.title = const {},
    this.text = const {},
    this.recite = const [],
  });

  String? titleFor(String lang) => pickText(title, lang);

  String? textFor(String lang) => pickText(text, lang);
}

class GuideSection {
  final Map<String, String> title;
  final List<GuideStep> items;

  const GuideSection({required this.title, required this.items});

  String titleFor(String lang) => pickText(title, lang) ?? '';
}

/// Rekât tablosu satırı: vakit + sırayla kısımlar (tür, rekât)
class RakatRow {
  final String id;
  final Map<String, String> title;
  final List<({String kind, int count})> parts;

  const RakatRow({required this.id, required this.title, required this.parts});

  String titleFor(String lang) => pickText(title, lang) ?? id;
}

/// Kılınış: 2 / 3 / 4 rekâtlı ya da vitir; adımlar ortak tanımlardan
class PrayerMethod {
  final String id;
  final Map<String, String> title;
  final Map<String, String> example;
  final List<GuideStep> steps;
  final List<Map<String, String>> notes;

  const PrayerMethod({
    required this.id,
    required this.title,
    required this.example,
    required this.steps,
    this.notes = const [],
  });

  String titleFor(String lang) => pickText(title, lang) ?? id;

  String? exampleFor(String lang) => pickText(example, lang);
}

/// Namaz Hocası (assets/data/prayer_guide.json, çevrimdışı; Diyanet
/// İlmihali, Hanefî): abdest, namazın farzları, rekât sayıları ve kılınış.
/// Metinler dil başına; kısa zikirler Dua olarak okunur (Arapçada okunuş ve
/// anlam yok), dualar duas.json'a bağlanır. Bilinmeyen adım/zikir kimliği
/// FormatException.
class PrayerGuide {
  static const String asset = 'assets/data/prayer_guide.json';

  final List<GuideSection> wudu;
  final List<GuideSection> fards;
  final Map<String, String> rakatsTitle;
  final Map<String, Map<String, String>> rakatKinds;
  final List<RakatRow> rakats;
  final List<PrayerMethod> methods;
  final Map<String, String> note;

  const PrayerGuide({
    required this.wudu,
    required this.fards,
    required this.rakatsTitle,
    required this.rakatKinds,
    required this.rakats,
    required this.methods,
    required this.note,
  });

  factory PrayerGuide.fromJson(Map<String, dynamic> json) {
    final dhikr = {
      for (final MapEntry(:key, :value)
          in (json['dhikr'] as Map<String, dynamic>).entries)
        key: Dua.fromJson({...value as Map<String, dynamic>, 'id': key}),
    };

    GuideRecitation recitation(Map<String, dynamic> r) {
      final id = r['dhikr'] as String?;
      final dua = id == null ? null : dhikr[id];
      if (id != null && dua == null) throw FormatException('dhikr: $id');
      return GuideRecitation(
        dhikr: dua,
        dua: r['dua'] as String?,
        surah: r['surah'] as int?,
        times: r['times'] as int? ?? 1,
        title: localizedTexts(r['title']),
        text: localizedTexts(r['text']),
      );
    }

    GuideStep step(Map<String, dynamic> s) => GuideStep(
      title: localizedTexts(s['title']),
      text: localizedTexts(s['text']),
      recite: [
        for (final r in s['recite'] as List? ?? const [])
          recitation(r as Map<String, dynamic>),
      ],
    );

    List<GuideSection> sections(Object? list) => [
      for (final s in list as List)
        GuideSection(
          title: localizedTexts(s['title']),
          items: [for (final i in s['items'] as List) step(i)],
        ),
    ];

    final steps = {
      for (final MapEntry(:key, :value)
          in (json['steps'] as Map<String, dynamic>).entries)
        key: step(value as Map<String, dynamic>),
    };
    final rakats = json['rakats'] as Map<String, dynamic>;
    return PrayerGuide(
      wudu: sections(json['wudu']),
      fards: sections(json['fards']),
      rakatsTitle: localizedTexts(rakats['title']),
      rakatKinds: {
        for (final MapEntry(:key, :value)
            in (rakats['kinds'] as Map<String, dynamic>).entries)
          key: localizedTexts(value),
      },
      rakats: [
        for (final p in rakats['prayers'] as List)
          RakatRow(
            id: p['id'] as String,
            title: localizedTexts(p['title']),
            parts: [
              for (final part in p['parts'] as List)
                (kind: part['kind'] as String, count: part['count'] as int),
            ],
          ),
      ],
      methods: [
        for (final m in json['methods'] as List)
          PrayerMethod(
            id: m['id'] as String,
            title: localizedTexts(m['title']),
            example: localizedTexts(m['example']),
            steps: [
              for (final id in m['steps'] as List)
                steps[id] ?? (throw FormatException('step: $id')),
            ],
            notes: [
              for (final n in m['notes'] as List? ?? const [])
                localizedTexts(n),
            ],
          ),
      ],
      note: localizedTexts(json['note']),
    );
  }

  String? rakatKindFor(String kind, String lang) =>
      pickText(rakatKinds[kind] ?? const {}, lang);

  String? noteFor(String lang) => pickText(note, lang);

  static Future<PrayerGuide>? _cache;

  /// Bir kez okunur; hata olursa sonraki çağrı yeniden dener
  static Future<PrayerGuide> load() => _cache ??= _read();

  static Future<PrayerGuide> _read() async {
    try {
      final raw = await rootBundle.loadString(asset);
      return PrayerGuide.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
