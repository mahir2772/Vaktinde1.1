import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'http_client.dart';
import '../models/hadith_model.dart';
import 'prayer_tracker.dart';
import 'storage_service.dart';

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

  final Map<String, String> _languageCodes = {
    "tr": "tr",
    "en": "en",
    "de": "de",
    "fr": "fr",
    "ar": "ar",
  };

  // Kategori 2 genel bir kategori ama her dilde sayfa sayısı farklı olabilir
  final Map<String, String> _categoryIds = {
    "tr": "2",
    "en": "2",
    "ar": "2",
    "fr": "2",
    "de": "2",
  };

  /// [day] (varsayılan bugün) gününün hadisi: seçim güne bağlı; gün + dil
  /// başına bir kez ağdan alınır, sonra önbellekten. Alınamazsa yerel yedek.
  Future<HadithModel?> getDailyHadith(Locale locale, {DateTime? day}) async {
    final now = DateTime.now();
    final date = day ?? now;
    String langCode = _languageCodes[locale.languageCode] ?? "tr";
    try {
      // 1. Önce hafızaya bak (Bu gün için bu dilde kaydedilmiş mi?)
      final cached = await _storageService.loadDailyCache(
        cacheKey,
        date,
        langCode,
      );
      if (cached is Map<String, dynamic>) {
        final cachedHadith = HadithModel.fromJson(cached);
        if (cachedHadith.content != null) return cachedHadith;
      }

      // 2. Rastgelelik için günün tarihine göre bir tohum (seed) oluştur
      int seed = date.year * 10000 + date.month * 100 + date.day;
      Random random = Random(seed);

      // Sayfa sınırını aşmamak için 1 ile 3 arası rastgele bir sayfa seçiyoruz
      int randomPage = random.nextInt(3) + 1;

      // HTTP hatasında liste boş sayılır
      Future<List> list(int perPage, int page) async {
        final body = await _fetch(
          Uri.parse(
            "$_baseUrl/hadeeths/list/?language=$langCode&category_id=${_categoryIds[langCode] ?? '2'}&per_page=$perPage&page=$page",
          ),
        );
        return body == null ? [] : json.decode(body)['data'] ?? [];
      }

      List hadiths = await list(20, randomPage);

      // PLAN B: Eğer o sayfada hadis yoksa veya API boş döndüyse, hemen %100 GARANTİLİ olan 1. sayfaya dön!
      if (hadiths.isEmpty) {
        hadiths = await list(50, 1);
      }

      // Hala elimizde hadis varsa, o listenin içinden rastgele birini seç
      if (hadiths.isNotEmpty) {
        int randomIndex = random.nextInt(hadiths.length);
        String hadithId = hadiths[randomIndex]['id'].toString();

        final detailBody = await _fetch(
          Uri.parse("$_baseUrl/hadeeths/one/?language=$langCode&id=$hadithId"),
        );

        if (detailBody != null) {
          final hadith = HadithModel.fromJson(json.decode(detailBody));

          // Metni olan hadis bu günün hadisi olarak hafızaya kaydedilir
          if (hadith.content != null) {
            await _storageService.saveDailyCache(
              cacheKey,
              date,
              langCode,
              hadith.toJson(),
            );
            return hadith;
          }
        }
      }
    } catch (e) {
      print("❌ Hadis Servis Hatası: $e");
    }

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
