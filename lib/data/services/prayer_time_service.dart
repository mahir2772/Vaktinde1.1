import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_times_model.dart';
import 'storage_service.dart';

class PrayerTimeService {
  /// Vakitleri internet gerektirmeden cihazda hesaplar (Diyanet yöntemi).
  /// [offsets]: vakit ince ayarı (dk), anahtarlar İmsak/Güneş/Öğle/İkindi/Akşam/Yatsı.
  PrayerTimesModel calculate(
    double latitude,
    double longitude, {
    DateTime? date,
    Map<String, int> offsets = const {},
  }) {
    final times = PrayerTimes(
      date: date ?? DateTime.now(),
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: CalculationMethodParameters.turkiye(),
    );
    String hhmm(DateTime t, String key) => DateFormat(
      'HH:mm',
    ).format(t.toLocal().add(Duration(minutes: offsets[key] ?? 0)));
    return PrayerTimesModel(
      imsak: hhmm(times.fajr, 'İmsak'),
      gunes: hhmm(times.sunrise, 'Güneş'),
      ogle: hhmm(times.dhuhr, 'Öğle'),
      ikindi: hhmm(times.asr, 'İkindi'),
      aksam: hhmm(times.maghrib, 'Akşam'),
      yatsi: hhmm(times.isha, 'Yatsı'),
    );
  }

  /// Kayıtlı koordinat + ince ayar ile verilen günün vakitleri (koordinat yoksa null).
  /// Ana ekran, alarmlar, imsakiye ve arka plan yenileme hep bunu kullanır.
  Future<PrayerTimesModel?> forDate(DateTime date) async {
    final storage = StorageService();
    final coords = await storage.loadCoordinates();
    if (coords == null) return null;
    return calculate(
      coords.lat,
      coords.lng,
      date: date,
      offsets: await storage.loadTimeOffsets(),
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
