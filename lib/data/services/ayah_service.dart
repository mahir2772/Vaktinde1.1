import 'dart:convert';
import 'dart:math';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'http_client.dart';

class AyahService {
  // Kurandaki toplam ayet sayısı
  static const int totalAyahs = 6236;

  Future<AyahModel?> getRandomAyah(String languageCode) async {
    // 1 ile 6236 arasında rastgele bir ayet numarası seç
    final randomAyahNumber = Random().nextInt(totalAyahs) + 1;

    // Dil koduna göre API'nin desteklediği meal çevirmenlerini belirliyoruz
    String edition;
    switch (languageCode) {
      case 'tr':
        edition = 'tr.diyanet';
        break;
      case 'en':
        edition = 'en.sahih';
        break;
      case 'de':
        edition = 'de.aburida';
        break;
      case 'fr':
        edition = 'fr.hamidullah';
        break;
      case 'ar':
        edition = 'quran-uthmani'; // Zaten Arapçaysa sadece Arapça döner
        break;
      default:
        edition = 'en.sahih'; // Desteklenmeyen dillerde varsayılan İngilizce
    }

    // Hem Arapça orijinalini (quran-uthmani) hem de meali aynı anda çeken endpoint
    final String url =
        'https://api.alquran.cloud/v1/ayah/$randomAyahNumber/editions/quran-uthmani,$edition';

    try {
      final response = await httpGet(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        return AyahModel.fromJson(decodedData, languageCode);
      } else {
        print("Ayet API Hatası: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Ayet çekerken hata oluştu: $e");
      return null;
    }
  }
}
