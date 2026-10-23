import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client.dart';

/// Kur'an sesinin kârîsi (Quran Foundation chapter reciter)
class QuranReciter {
  final int id;
  final String name;

  /// Okuma tarzı (Murattal, Mujawwad…); yoksa boş
  final String style;

  const QuranReciter({required this.id, required this.name, this.style = ''});

  @override
  bool operator ==(Object other) => other is QuranReciter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Bir surenin sesi: akış adresi ve ayet zamanları (ayet n → verses[n-1],
/// ms; zaman yoksa boş: ayet vurgusu ve ayete atlama olmaz)
class QuranChapterAudio {
  final Uri url;
  final List<({int from, int to})> verses;

  const QuranChapterAudio({required this.url, this.verses = const []});

  bool get hasTimings => verses.isNotEmpty;

  /// Konumdaki ayet (ayetler arası boşlukta öndeki; besmele / girişte 1);
  /// zaman yoksa null
  int? ayahAt(Duration position) {
    if (verses.isEmpty) return null;
    final ms = position.inMilliseconds;
    var low = 0;
    var high = verses.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (verses[mid].from <= ms) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  /// Ayetin başladığı an; zaman yoksa ya da ayet dışındaysa null
  Duration? startOf(int ayah) => ayah < 1 || ayah > verses.length
      ? null
      : Duration(milliseconds: verses[ayah - 1].from);

  /// Ayetin bittiği an
  Duration? endOf(int ayah) => ayah < 1 || ayah > verses.length
      ? null
      : Duration(milliseconds: verses[ayah - 1].to);
}

/// Dinlemenin durumu (ekranda gösterilecek hata)
enum QuranAudioFailure { offline, unavailable, notFound }

class QuranAudioException implements Exception {
  final QuranAudioFailure failure;

  const QuranAudioException(this.failure);
}

/// Vaktinde'nin Kur'an sesi ara sunucusu (server/quran-audio, Quran
/// Foundation Content API): kârî listesi ve sure sesi. Adres derlemede
/// `--dart-define=QURAN_AUDIO_API=https://…` ile verilir; yoksa dinleme
/// görünmez. Yanıtlar oturum boyunca bellekte tutulur (diske yazılmaz: QF
/// içeriği en çok 1 hafta saklanabilir); seçilen kârî 'quran_reciter'.
class QuranAudioService {
  static const String apiBase = String.fromEnvironment('QURAN_AUDIO_API');
  static const String reciterKey = 'quran_reciter';

  /// Ara sunucu adresi verilmiş (sadece https)
  static bool get configured => _base(apiBase) != null;

  final Uri? _api;
  final Future<http.Response> Function(Uri url) _get;

  /// [api], [get]: test için
  QuranAudioService({String? api, Future<http.Response> Function(Uri)? get})
    : _api = _base(api ?? apiBase),
      _get = get ?? httpGet;

  static Uri? _base(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static final Map<String, List<QuranReciter>> _reciters = {};
  static final Map<String, QuranChapterAudio> _chapters = {};

  /// Bellekteki sure sayısı (en eski atılır)
  static const int _chapterCacheSize = 20;

  /// Test için
  static void clearCache() {
    _reciters.clear();
    _chapters.clear();
  }

  /// Dinleme kullanılabilir mi (ara sunucu açık ve kârî listesi geldi);
  /// liste oturumda saklanır, başarısızsa sonraki açılışta yeniden sorulur.
  /// Sunucu kapalıyken (QF onayı beklenirken) okuyucu Dinle'yi göstermez.
  Future<bool> isAvailable(String language) async {
    if (_api == null) return false;
    try {
      await reciters(language);
      return true;
    } on QuranAudioException {
      return false;
    }
  }

  Future<List<QuranReciter>> reciters(String language) async {
    final cached = _reciters[language];
    if (cached != null) return cached;
    final body = await _fetch(['v1', 'reciters'], {'lang': language});
    final list = parseReciters(body);
    if (list.isEmpty) {
      throw const QuranAudioException(QuranAudioFailure.unavailable);
    }
    return _reciters[language] = list;
  }

  Future<QuranChapterAudio> chapter(int reciter, int surah) async {
    final key = '$reciter/$surah';
    final cached = _chapters.remove(key);
    if (cached != null) return _chapters[key] = cached;
    final audio = parseChapter(
      await _fetch(['v1', 'chapter', '$reciter', '$surah']),
    );
    if (audio == null) {
      throw const QuranAudioException(QuranAudioFailure.notFound);
    }
    if (_chapters.length >= _chapterCacheSize) {
      _chapters.remove(_chapters.keys.first);
    }
    return _chapters[key] = audio;
  }

  Future<Object?> _fetch(
    List<String> path, [
    Map<String, String>? query,
  ]) async {
    final api = _api;
    if (api == null) {
      throw const QuranAudioException(QuranAudioFailure.unavailable);
    }
    final url = api.replace(
      pathSegments: [...api.pathSegments.where((s) => s.isNotEmpty), ...path],
      queryParameters: query,
    );
    final http.Response response;
    try {
      response = await _get(url);
    } catch (_) {
      throw const QuranAudioException(QuranAudioFailure.offline);
    }
    if (response.statusCode == 404) {
      throw const QuranAudioException(QuranAudioFailure.notFound);
    }
    if (response.statusCode != 200) {
      throw const QuranAudioException(QuranAudioFailure.unavailable);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const QuranAudioException(QuranAudioFailure.unavailable);
    }
  }

  /// {reciters: [{id, name, style}]}; bozuk kayıt atlanır
  static List<QuranReciter> parseReciters(Object? json) {
    final list = json is Map ? json['reciters'] : null;
    if (list is! List) return const [];
    return [
      for (final r in list)
        if (r is Map &&
            r['id'] is int &&
            r['name'] is String &&
            (r['name'] as String).trim().isNotEmpty)
          QuranReciter(
            id: r['id'] as int,
            name: (r['name'] as String).trim(),
            style: r['style'] is String ? (r['style'] as String).trim() : '',
          ),
    ];
  }

  /// Ses sadece Quran Foundation / Quran.com sunucularından (alt alan
  /// adları dahil; ara sunucu da aynı listeyle süzer)
  static const List<String> audioHosts = [
    'quranicaudio.com',
    'qurancdn.com',
    'quran.foundation',
    'quran.com',
  ];

  /// {url, verses: [[başlangıç, bitiş], …]}; adres https değilse ya da bilinen
  /// ses sunucusunda değilse null, zaman listesi bozuksa zamansız
  static QuranChapterAudio? parseChapter(Object? json) {
    if (json is! Map) return null;
    final url = Uri.tryParse(
      json['url'] is String ? json['url'] as String : '',
    );
    if (url == null ||
        url.scheme != 'https' ||
        url.userInfo.isNotEmpty ||
        !audioHosts.any((h) => url.host == h || url.host.endsWith('.$h'))) {
      return null;
    }
    final verses = <({int from, int to})>[];
    final raw = json['verses'];
    if (raw is List) {
      for (final v in raw) {
        if (v is! List ||
            v.length != 2 ||
            v[0] is! int ||
            v[1] is! int ||
            (v[1] as int) < (v[0] as int) ||
            (verses.isNotEmpty && (v[0] as int) < verses.last.from)) {
          verses.clear();
          break;
        }
        verses.add((from: v[0] as int, to: v[1] as int));
      }
    }
    return QuranChapterAudio(url: url, verses: List.unmodifiable(verses));
  }

  /// Seçilen kârî; listede yoksa (ilk kullanım ya da kaldırılmış) Mişari
  /// Raşid el-Afasi (ad dile göre: Afasy / Afasi / العفاسي), o da yoksa ilk
  static QuranReciter pickReciter(List<QuranReciter> reciters, int? savedId) =>
      reciters.where((r) => r.id == savedId).firstOrNull ??
      reciters.where((r) {
        final name = r.name.toLowerCase();
        return name.contains('afas') || name.contains('عفاسي');
      }).firstOrNull ??
      reciters.first;

  static Future<int?> loadReciterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(reciterKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveReciterId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(reciterKey, id);
    } catch (_) {}
  }
}
