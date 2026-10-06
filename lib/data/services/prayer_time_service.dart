import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_times_model.dart';

class PrayerTimeService {
  /// Vakitleri internet gerektirmeden cihazda hesaplar (Diyanet yöntemi).
  PrayerTimesModel calculate(
    double latitude,
    double longitude, {
    DateTime? date,
  }) {
    final times = PrayerTimes(
      date: date ?? DateTime.now(),
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: CalculationMethodParameters.turkiye(),
    );
    String hhmm(DateTime t) => DateFormat('HH:mm').format(t.toLocal());
    return PrayerTimesModel(
      imsak: hhmm(times.fajr),
      gunes: hhmm(times.sunrise),
      ogle: hhmm(times.dhuhr),
      ikindi: hhmm(times.asr),
      aksam: hhmm(times.maghrib),
      yatsi: hhmm(times.isha),
    );
  }

  /// Yedek: koordinat bulunamazsa Aladhan API (şehir adıyla).
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

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

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
