import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

class PrayerTimeService {
  Future<PrayerTimesModel?> getPrayerTimes(
    String city, {
    String? district,
  }) async {
    try {
      String cleanCity = city.trim();
      String cleanDistrict = district?.trim() ?? "";

      String queryCity = cleanDistrict.isNotEmpty
          ? "$cleanDistrict, $cleanCity"
          : cleanCity;

      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': queryCity,
        'country': 'Turkey',
        'method': '13',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));
        final timings = decodedBody['data']['timings'];

        return PrayerTimesModel(
          imsak: timings['Fajr'],
          gunes: timings['Sunrise'],
          ogle: timings['Dhuhr'],
          ikindi: timings['Asr'],
          aksam: timings['Maghrib'],
          yatsi: timings['Isha'],
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
