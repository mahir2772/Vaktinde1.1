import 'dart:convert';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'http_client.dart';
import 'prayer_tracker.dart';
import 'quran_service.dart';
import 'storage_service.dart';

class AyahService {
  // Kurandaki toplam ayet sayısı
  static const int totalAyahs = QuranService.totalAyahs;

  /// Gün + dil başına alınan ayet (ham API yanıtı); sadece önbellek, yedeğe girmez
  static const String cacheKey = 'daily_ayah_cache';

  // Ardışık günlerin ayet adımı: totalAyahs (4 × 1559) ile aralarında asal →
  // 6236 gün boyunca her ayet bir kez; altın oran: komşu günler birbirinden uzak
  static const int _dayStep = 3853;

  final StorageService _storageService = StorageService();
  final Future<String?> Function(Uri url) _fetch;

  /// [fetch]: test için (varsayılan: httpGet 10 sn)
  AyahService({Future<String?> Function(Uri url)? fetch})
    : _fetch = fetch ?? _httpFetch;

  static Future<String?> _httpFetch(Uri url) async {
    final response = await httpGet(url);
    if (response.statusCode == 200) return utf8.decode(response.bodyBytes);
    print("Ayet API Hatası: ${response.statusCode}");
    return null;
  }

  /// [day] gününün ayeti (1..[totalAyahs]): takvim gününe bağlı, dilden bağımsız
  /// (dil değişince aynı ayetin meali gelir); ardışık günler farklı
  static int ayahNumberFor(DateTime day) =>
      PrayerTracker.epochDay(day) * _dayStep % totalAyahs + 1;

  /// [day] (varsayılan bugün) gününün ayeti: gün + dil başına bir kez ağdan
  /// alınır, sonra önbellekten (internetsiz de). Alınamazsa null.
  Future<AyahModel?> getDailyAyah(String languageCode, {DateTime? day}) async {
    final date = day ?? DateTime.now();
    try {
      final cached = await _storageService.loadDailyCache(
        cacheKey,
        date,
        languageCode,
      );
      if (cached is String) {
        return AyahModel.fromJson(json.decode(cached), languageCode);
      }
    } catch (e) {
      // Bozuk kayıt: ağdan yeniden alınır
    }

    // Meal baskısı Kur'an okuyucuyla ortak (QuranEdition); Arapça arayüzde
    // meal yerine yine Arapça metin döner
    final edition =
        QuranEdition.translationFor(languageCode) ?? QuranEdition.arabic;

    // Hem Arapça orijinalini (quran-uthmani) hem de meali aynı anda çeken endpoint
    final String url =
        '${QuranEdition.apiBase}/ayah/${ayahNumberFor(date)}/editions/${QuranEdition.arabic},$edition';

    try {
      final body = await _fetch(Uri.parse(url));
      if (body == null) return null;
      final ayah = AyahModel.fromJson(json.decode(body), languageCode);
      await _storageService.saveDailyCache(cacheKey, date, languageCode, body);
      return ayah;
    } catch (e) {
      print("Ayet çekerken hata oluştu: $e");
      return null;
    }
  }
}
