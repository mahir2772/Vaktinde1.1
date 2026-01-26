import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../models/hadith_model.dart';
import 'storage_service.dart';

class HadithService {
  final StorageService _storageService = StorageService();

  // HadeethEnc API Base URL
  static const String _baseUrl = "https://hadeethenc.com/api/v1";

  // Dillerin API kodları
  final Map<String, String> _languageCodes = {
    "tr": "tr",
    "en": "en",
    "de": "de",
    "fr": "fr",
    "ar": "ar",
  };

  // Kategori ID'leri (Riyazü's Salihin veya Seçme Hadisler gibi genel kategoriler)
  // Her dilin kategori ID'si farklı olabilir. Biz burada en güvenilir yöntemi kullanacağız.
  // Dil -> Kategori ID eşleşmesi (Test edilmiş ID'ler)
  final Map<String, String> _categoryIds = {
    "tr": "2", // Riyazü's Salihin (veya benzeri popüler kategori)
    "en": "2",
    "ar": "2",
    "fr": "2",
    "de": "2",
  };

  Future<HadithModel?> getDailyHadith(Locale locale) async {
    try {
      // 1. ÖNCE HAFIZAYA BAK (Bugün için kaydedilmiş mi?)
      // Not: Cache mantığını dile göre ayırmak gerekebilir ama şimdilik basit tutalım.
      // Eğer dil değişirse cache'i yoksaymak daha doğru olur.
      // HadithModel? cachedHadith = await _storageService.loadDailyHadith();
      // if (cachedHadith != null) return cachedHadith;

      // 2. API'DEN ÇEK
      String langCode = _languageCodes[locale.languageCode] ?? "tr";

      // A) O dildeki hadis listesini çek
      // (Rastgelelik için page=1 yerine random page yapılabilir ama şimdilik basit olsun)
      final listResponse = await http.get(
        Uri.parse(
          "$_baseUrl/hadeeths/list/?language=$langCode&category_id=${_categoryIds[langCode] ?? '2'}&per_page=1&page=1",
        ),
      );

      if (listResponse.statusCode == 200) {
        var data = json.decode(listResponse.body);
        List hadiths = data['data'];

        if (hadiths.isNotEmpty) {
          // Günün hadisi mantığı: Yılın gününe göre sabit bir index seç
          // API her sayfada 20 hadis verir. Biz rastgele sayfa/hadis seçimi yapabiliriz.
          // Şimdilik listenin ilkini alıp detayına gidelim.

          String hadithId = hadiths[0]['id'].toString();

          // B) Hadis Detayını Çek (Tam metin için)
          final detailResponse = await http.get(
            Uri.parse(
              "$_baseUrl/hadeeths/one/?language=$langCode&id=$hadithId",
            ),
          );

          if (detailResponse.statusCode == 200) {
            var detailData = json.decode(detailResponse.body);
            final hadith = HadithModel.fromJson(detailData);

            // C) Hafızaya Kaydet
            await _storageService.saveDailyHadith(hadith);
            return hadith;
          }
        }
      }

      // API başarısızsa varsayılan dön
      return _getFallbackHadith(locale);
    } catch (e) {
      print("❌ Hadis Servis Hatası: $e");
      return _getFallbackHadith(locale);
    }
  }

  // İnternet yoksa veya hata varsa gösterilecek yedek hadis
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
        content: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ",
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
