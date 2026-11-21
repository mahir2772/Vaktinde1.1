import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';
import '../models/hadith_model.dart';
import 'prayer_tracker.dart';
import 'storage_service.dart';

typedef _HadithItem = Map<String, dynamic>;

class _HadithPage {
  final List<_HadithItem> items;
  final int? lastPage;

  const _HadithPage(this.items, this.lastPage);
}

class HadithService {
  final StorageService _storageService = StorageService();
  final Future<String?> Function(Uri url) _fetch;

  /// [fetch]: test için (varsayılan: httpGet 10 sn)
  HadithService({Future<String?> Function(Uri url)? fetch})
    : _fetch = fetch ?? _httpFetch;

  static Future<String?> _httpFetch(Uri url) async {
    final response = await httpGet(url);
    // Gövde UTF-8 çözülür (başlıkta karakter kümesi yoksa http latin1 sanar)
    return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null;
  }

  static const String _baseUrl = "https://hadeethenc.com/api/v1";

  /// Gün + dil başına seçilen hadis ({content, source}; yerel yedek dahil);
  /// sadece önbellek, yedeğe girmez
  static const String cacheKey = 'daily_hadith_cache';

  /// Daha önce gösterilen hadis kimlikleri (en eskiden en yeniye, en fazla
  /// [_maxSeenHistory]); güncellemede ve yedekten dönüşte başa sarmasın diye
  /// kalıcı tutulur (BackupService)
  static const String seenKey = 'seen_hadith_ids';

  /// Gün → seçilen hadis kimliği (son 14 gün): aynı gün dil değişirse mümkünse
  /// aynı hadis yeni dilde alınır; sadece önbellek
  static const String assignmentsKey = 'daily_hadith_assignments';

  /// Dil + kategori başına son okunan sayfa (tükenen sayfaya tekrar dönmez)
  static const String _categoryPagesKey = 'hadith_category_pages';

  static const int _maxSeenHistory = 1000;
  static const int _recentKeep = 30;
  static const int _assignmentKeepDays = 14;
  static const int _defaultLastPage = 3;
  static const int _maxPageAttempts = 5;

  final Map<String, String> _languageCodes = const {
    "tr": "tr",
    "en": "en",
    "de": "de",
    "fr": "fr",
    "ar": "ar",
  };

  // HadeethEnc ana kök kategorileri: her hafta farklı kategoriden seçilir,
  // sayfa bitince sonraki sayfaya geçilir → binlerce hadislik geniş havuz
  static const List<String> _categories = ["2", "5", "3", "4", "7", "1", "6"];

  final Map<String, _HadithPage> _lists = {};

  static List<String> _loadSeen(SharedPreferences prefs) =>
      List<String>.from(prefs.getStringList(seenKey) ?? const []);

  static Map<String, String> _loadStringMap(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is String && (e.value as String).trim().isNotEmpty)
            e.key: e.value as String,
      };
    } catch (e) {
      return {};
    }
  }

  static Map<String, int> _loadCategoryPages(SharedPreferences prefs) {
    final raw = prefs.getString(_categoryPagesKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is num && (e.value as num).toInt() >= 1)
            e.key: (e.value as num).toInt(),
      };
    } catch (e) {
      return {};
    }
  }

  Future<_HadithPage> _fetchList(
    String langCode,
    String categoryId,
    int perPage,
    int page,
  ) async {
    final url =
        "$_baseUrl/hadeeths/list/?language=$langCode&category_id=$categoryId&per_page=$perPage&page=$page";
    final known = _lists[url];
    if (known != null) return known;
    final body = await _fetch(Uri.parse(url));
    if (body == null) return const _HadithPage([], null);
    final decoded = json.decode(body);
    if (decoded is! Map<String, dynamic>) return const _HadithPage([], null);
    final data = decoded['data'];
    if (data is! List) return const _HadithPage([], null);
    final items = <_HadithItem>[];
    for (final entry in data) {
      if (entry is Map && entry['id'] != null) {
        items.add(Map<String, dynamic>.from(entry));
      }
    }
    int? lastPage;
    final meta = decoded['meta'];
    if (meta is Map) {
      final parsed = int.tryParse('${meta['last_page']}');
      if (parsed != null && parsed >= 1) lastPage = parsed;
    }
    final result = _HadithPage(items, lastPage);
    if (items.isNotEmpty) _lists[url] = result;
    return result;
  }

  Future<HadithModel?> _fetchDetail(String langCode, String hadithId) async {
    final detailBody = await _fetch(
      Uri.parse("$_baseUrl/hadeeths/one/?language=$langCode&id=$hadithId"),
    );
    if (detailBody == null) return null;
    final hadith = HadithModel.fromJson(json.decode(detailBody));
    return hadith.content != null ? hadith : null;
  }

  static Future<void> _recordShown(
    SharedPreferences prefs,
    DateTime date,
    String hadithId,
  ) async {
    final dateKey = PrayerTracker.dateKey(date);
    final now = DateTime.now();
    final oldest = PrayerTracker.dateKey(
      PrayerTracker.addDays(
        date.isBefore(now) ? date : now,
        -_assignmentKeepDays,
      ),
    );
    final assignments = _loadStringMap(prefs, assignmentsKey)
      ..removeWhere((k, _) => k.compareTo(oldest) < 0)
      ..[dateKey] = hadithId;
    await prefs.setString(assignmentsKey, jsonEncode(assignments));

    final seen = _loadSeen(prefs)
      ..remove(hadithId)
      ..add(hadithId);
    if (seen.length > _maxSeenHistory) {
      seen.removeRange(0, seen.length - _maxSeenHistory);
    }
    await prefs.setStringList(seenKey, seen);
  }

  /// [day] (varsayılan bugün) gününün hadisi: seçim güne bağlı, görülen
  /// hadisler ([seenKey]) tekrar edilmez; gün + dil başına bir kez ağdan
  /// alınır, sonra önbellekten. Alınamazsa yerel yedek; [useFallback] false
  /// ise (bildirim) yedek yerine null: her gün aynı yedek hadis bildirime girmez.
  Future<HadithModel?> getDailyHadith(
    Locale locale, {
    DateTime? day,
    bool useFallback = true,
  }) async {
    final now = DateTime.now();
    final date = day ?? now;
    final langCode = _languageCodes[locale.languageCode] ?? "tr";
    try {
      // 1. Önce hafızaya bak (Bu gün için bu dilde kaydedilmiş mi?)
      final cached = await _storageService.loadDailyCache(
        cacheKey,
        date,
        langCode,
      );
      if (cached is Map<String, dynamic>) {
        final cachedHadith = HadithModel.fromJson(cached);
        if (cachedHadith.content != null) {
          return useFallback || !isFallback(cachedHadith, locale)
              ? cachedHadith
              : null;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final dateKey = PrayerTracker.dateKey(date);

      // 2. Aynı gün başka bir dilde seçilmiş hadis varsa önce onu yeni dilde dene
      final assignedId = _loadStringMap(prefs, assignmentsKey)[dateKey];
      if (assignedId != null) {
        final sameDay = await _fetchDetail(langCode, assignedId);
        if (sameDay != null) {
          await _storageService.saveDailyCache(
            cacheKey,
            date,
            langCode,
            sameDay.toJson(),
          );
          await _recordShown(prefs, date, assignedId);
          return sameDay;
        }
      }

      // 3. Geniş havuzdan daha önce görülmemiş bir hadis seç
      final seenList = _loadSeen(prefs);
      final seenSet = seenList.toSet();
      final categoryPages = _loadCategoryPages(prefs);
      var pagesDirty = false;

      final epoch = PrayerTracker.epochDay(date);
      final weekBucket = epoch ~/ 7;
      final catStart = weekBucket % _categories.length;
      final seed = date.year * 10000 + date.month * 100 + date.day;
      final random = Random(seed);

      var catOffset = 0;
      var catId = _categories[catStart];
      var page = categoryPages['$langCode|$catId'] ?? 1;

      String? chosenId;
      final fallbackPool = <String>[];
      final seenInPool = <String>{};

      for (var attempt = 0; attempt < _maxPageAttempts; attempt++) {
        var result = await _fetchList(langCode, catId, 50, page);
        if (result.items.isEmpty && page > 1) {
          page = 1;
          categoryPages['$langCode|$catId'] = 1;
          pagesDirty = true;
          result = await _fetchList(langCode, catId, 50, 1);
        }

        if (result.items.isNotEmpty) {
          final unseen = <String>[];
          for (final item in result.items) {
            final id = item['id'].toString();
            if (seenInPool.add(id)) fallbackPool.add(id);
            if (!seenSet.contains(id)) unseen.add(id);
          }
          if (unseen.isNotEmpty) {
            chosenId = unseen[random.nextInt(unseen.length)];
            break;
          }
          // Bu sayfadaki tüm hadisler görülmüş: varsa sıradaki sayfaya ilerle
          final lastPage = result.lastPage ?? _defaultLastPage;
          if (page < lastPage) {
            page++;
            categoryPages['$langCode|$catId'] = page;
            pagesDirty = true;
            continue;
          }
          // Kategorinin son sayfası da bittiyse başa sar ve sıradaki kategoriye geç
          categoryPages['$langCode|$catId'] = 1;
          pagesDirty = true;
        }

        catOffset++;
        if (catOffset >= _categories.length) break;
        catId = _categories[(catStart + catOffset) % _categories.length];
        page = categoryPages['$langCode|$catId'] ?? 1;
      }

      // PLAN B: Seçilen kategorilerden hiç veri gelmediyse 2. kategori 1. sayfa
      if (chosenId == null && fallbackPool.isEmpty) {
        final planB = await _fetchList(langCode, "2", 50, 1);
        for (final item in planB.items) {
          final id = item['id'].toString();
          if (seenInPool.add(id)) fallbackPool.add(id);
        }
        final unseen = fallbackPool
            .where((id) => !seenSet.contains(id))
            .toList();
        if (unseen.isNotEmpty) {
          chosenId = unseen[random.nextInt(unseen.length)];
        }
      }

      // Tüm havuz tükendiyse son 30 hadisi atlayarak en eski görülenlerden seç
      if (chosenId == null && fallbackPool.isNotEmpty) {
        final recent = seenList.length > _recentKeep
            ? seenList.sublist(seenList.length - _recentKeep).toSet()
            : <String>{};
        final older = fallbackPool.where((id) => !recent.contains(id)).toList();
        final pool = older.isNotEmpty ? older : fallbackPool;
        chosenId = pool[random.nextInt(pool.length)];
      }

      if (pagesDirty) {
        await prefs.setString(_categoryPagesKey, jsonEncode(categoryPages));
      }

      if (chosenId != null) {
        final hadith = await _fetchDetail(langCode, chosenId);
        if (hadith != null) {
          await _storageService.saveDailyCache(
            cacheKey,
            date,
            langCode,
            hadith.toJson(),
          );
          await _recordShown(prefs, date, chosenId);
          return hadith;
        }
      }
    } catch (e) {
      print("❌ Hadis Servis Hatası: $e");
    }

    if (!useFallback) return null;

    // Yukarıdaki işlemlerin hiçbirinden sağ çıkamazsak mecburen yedeği göster.
    // Bugün gösterilen yedek gün boyu kalır (hafızaya yazılır); ileri bir günün
    // (yarının bildirimi) yedeği yazılmaz, o gün ağdan yeniden denenir
    final fallback = _getFallbackHadith(locale);
    if (PrayerTracker.dateKey(date) == PrayerTracker.dateKey(now)) {
      try {
        await _storageService.saveDailyCache(
          cacheKey,
          date,
          langCode,
          fallback.toJson(),
        );
      } catch (e) {
        // Yazılamazsa da gösterilir
      }
    }
    return fallback;
  }

  /// Önümüzdeki [days] günün hadisi önbelleğe alınır (uygulama açıkken): ağ
  /// yokken arka planda kurulan bildirim de o günün hadisini bulur. Ağ
  /// yoksa ilk başarısız günde durur; hata fırlatmaz.
  Future<void> prefetch(Locale locale, {int days = 7}) async {
    final today = DateTime.now();
    for (var i = 1; i <= days; i++) {
      final day = PrayerTracker.addDays(today, i);
      if (await getDailyHadith(locale, day: day, useFallback: false) == null) {
        return;
      }
    }
  }

  /// Ağdan alınamayınca gösterilen yerel yedek mi
  bool isFallback(HadithModel hadith, Locale locale) =>
      hadith.content == _getFallbackHadith(locale).content;

  HadithModel _getFallbackHadith(Locale locale) {
    if (locale.languageCode == 'en') {
      return HadithModel(
        content: "Actions are judged by intentions.",
        source: "Bukhari",
      );
    } else if (locale.languageCode == 'de') {
      return HadithModel(
        content: "Taten werden nach Absichten beurteilt.",
        source: "Bukhari",
      );
    } else if (locale.languageCode == 'fr') {
      return HadithModel(
        content: "Les actes ne valent que par les intentions.",
        source: "Bukhari",
      );
    } else if (locale.languageCode == 'ar') {
      return HadithModel(
        content: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ",
        source: "Bukhari",
      );
    } else {
      return HadithModel(
        content: "Ameller niyetlere göredir.",
        source: "Buhârî",
      );
    }
  }
}
