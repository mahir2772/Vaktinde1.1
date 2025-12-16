import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

class PrayerTimeService {
  Future<PrayerTimesModel?> getPrayerTimes(String city) async {
    try {
      print("🚀 Aladhan API (Diyanet Metodu) ile istek atılıyor: $city");

      // Method 13 = Türkiye Diyanet İşleri Başkanlığı standardı
      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': city,
        'country': 'Turkey',
        'method': '13',
      });

      final response = await http.get(uri);

      print("📡 İstek Sonucu: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        final timings = decodedBody['data']['timings'];

        print("✅ Veri Geldi! İmsak: ${timings['Fajr']}");

        return PrayerTimesModel(
          imsak: timings['Fajr'], // Fajr = İmsak
          gunes: timings['Sunrise'],
          ogle: timings['Dhuhr'],
          ikindi: timings['Asr'],
          aksam: timings['Maghrib'],
          yatsi: timings['Isha'],
        );
      } else {
        print("❌ Hata Kodu: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Kritik Hata: $e");
      return null;
    }
  }
}
