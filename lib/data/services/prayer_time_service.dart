import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

class PrayerTimeService {
  // city: İl (Örn: Antalya)
  // district: İlçe (Örn: Alanya) - Opsiyonel parametre yapıldı
  Future<PrayerTimesModel?> getPrayerTimes(
    String city, {
    String? district,
  }) async {
    try {
      String cleanCity = city.trim();
      String cleanDistrict = district?.trim() ?? "";

      // API'ye gönderilecek sorgu metni
      // Eğer ilçe varsa: "Alanya, Antalya" formatında gider.
      // İlçe yoksa sadece: "Antalya" formatında gider.
      String queryCity = cleanDistrict.isNotEmpty
          ? "$cleanDistrict, $cleanCity"
          : cleanCity;

      print("🚀 Aladhan API (Diyanet Metodu) ile istek atılıyor: $queryCity");

      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': queryCity, // Buraya artık birleşik metni veriyoruz
        'country': 'Turkey',
        'method': '13',
      });

      final response = await http.get(uri);

      print("📡 İstek Sonucu: ${response.statusCode}");

      if (response.statusCode == 200) {
        // UTF8 Decode işlemi
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));
        final timings = decodedBody['data']['timings'];

        print("✅ Veri Geldi! İmsak: ${timings['Fajr']}");

        return PrayerTimesModel(
          imsak: timings['Fajr'],
          gunes: timings['Sunrise'],
          ogle: timings['Dhuhr'],
          ikindi: timings['Asr'],
          aksam: timings['Maghrib'],
          yatsi: timings['Isha'],
        );
      } else {
        print("❌ Hata Kodu: ${response.statusCode} - Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Kritik Hata (PrayerService): $e");
      return null;
    }
  }
}
