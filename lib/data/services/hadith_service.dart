import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'http_client.dart';
import '../models/hadith_model.dart';
import 'storage_service.dart';

class HadithService {
  final StorageService _storageService = StorageService();

  static const String _baseUrl = "https://hadeethenc.com/api/v1";

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

  Future<HadithModel?> getDailyHadith(Locale locale) async {
    try {
      String langCode = _languageCodes[locale.languageCode] ?? "tr";

      // 1. Önce hafızaya bak (Bugün için bu dilde kaydedilmiş mi?)
      HadithModel? cachedHadith = await _storageService.loadDailyHadith(
        langCode,
      );
      if (cachedHadith != null) return cachedHadith;

      // 2. Rastgelelik için bugünün tarihine göre bir tohum (seed) oluştur
      DateTime now = DateTime.now();
      int seed = now.year * 10000 + now.month * 100 + now.day;
      Random random = Random(seed);

      // Sayfa sınırını aşmamak için 1 ile 3 arası rastgele bir sayfa seçiyoruz
      int randomPage = random.nextInt(3) + 1;

      var listResponse = await httpGet(
        Uri.parse(
          "$_baseUrl/hadeeths/list/?language=$langCode&category_id=${_categoryIds[langCode] ?? '2'}&per_page=20&page=$randomPage",
        ),
      );

      var data = json.decode(listResponse.body);
      List hadiths = data['data'] ?? [];

      // PLAN B: Eğer o sayfada hadis yoksa veya API boş döndüyse, hemen %100 GARANTİLİ olan 1. sayfaya dön!
      if (hadiths.isEmpty) {
        listResponse = await httpGet(
          Uri.parse(
            "$_baseUrl/hadeeths/list/?language=$langCode&category_id=${_categoryIds[langCode] ?? '2'}&per_page=50&page=1",
          ),
        );
        data = json.decode(listResponse.body);
        hadiths = data['data'] ?? [];
      }

      // Hala elimizde hadis varsa, o listenin içinden rastgele birini seç
      if (hadiths.isNotEmpty) {
        int randomIndex = random.nextInt(hadiths.length);
        String hadithId = hadiths[randomIndex]['id'].toString();

        final detailResponse = await httpGet(
          Uri.parse("$_baseUrl/hadeeths/one/?language=$langCode&id=$hadithId"),
        );

        if (detailResponse.statusCode == 200) {
          var detailData = json.decode(detailResponse.body);
          final hadith = HadithModel.fromJson(detailData);

          // API'den başarıyla çektik, bunu hemen bugünün tarihiyle hafızaya kaydet
          await _storageService.saveDailyHadith(hadith, langCode);
          return hadith;
        }
      }

      // Yukarıdaki işlemlerin hiçbirinden sağ çıkamazsak mecburen yedeği göster
      return _getFallbackHadith(locale);
    } catch (e) {
      print("❌ Hadis Servis Hatası: $e");
      return _getFallbackHadith(locale);
    }
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
