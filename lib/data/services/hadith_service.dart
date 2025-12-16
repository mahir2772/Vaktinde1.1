import 'dart:math';
import '../models/hadith_model.dart';
import 'json_service.dart'; // Json servisini çağır

class HadithService {
  final JsonService _jsonService = JsonService();
  int? _lastShownIndex;

  Future<HadithModel?> getDailyHadith() async {
    try {
      // JSON'dan tüm hadisleri çek
      List<HadithModel> hadiths = await _jsonService.getHadiths();

      if (hadiths.isEmpty) return null;

      final random = Random();
      int index;

      if (hadiths.length <= 1) {
        index = 0;
      } else {
        do {
          index = random.nextInt(hadiths.length);
        } while (index == _lastShownIndex);
      }
      _lastShownIndex = index;
      return hadiths[index];
    } catch (e) {
      print("Hadis okuma hatası: $e");
      // Hata olursa yedek dön
      return HadithModel(
        content: "Ameller niyetlere göredir.",
        source: "Buhârî",
      );
    }
  }
}
