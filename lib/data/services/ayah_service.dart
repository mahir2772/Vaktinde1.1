import 'dart:convert';
import 'dart:math';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'http_client.dart';
import 'quran_service.dart';

class AyahService {
  // Kurandaki toplam ayet sayısı
  static const int totalAyahs = QuranService.totalAyahs;

  Future<AyahModel?> getRandomAyah(String languageCode) async {
    // 1 ile 6236 arasında rastgele bir ayet numarası seç
    final randomAyahNumber = Random().nextInt(totalAyahs) + 1;

    // Meal baskısı Kur'an okuyucuyla ortak (QuranEdition); Arapça arayüzde
    // meal yerine yine Arapça metin döner
    final edition =
        QuranEdition.translationFor(languageCode) ?? QuranEdition.arabic;

    // Hem Arapça orijinalini (quran-uthmani) hem de meali aynı anda çeken endpoint
    final String url =
        '${QuranEdition.apiBase}/ayah/$randomAyahNumber/editions/${QuranEdition.arabic},$edition';

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
