import 'dart:convert';
import 'dart:math';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';
import 'prayer_tracker.dart';
import 'quran_service.dart';
import 'storage_service.dart';

class AyahService {
  // Kurandaki toplam ayet sayısı
  static const int totalAyahs = QuranService.totalAyahs;

  /// Gün + dil başına alınan ayet (ham API yanıtı); sadece önbellek, yedeğe girmez
  static const String cacheKey = 'daily_ayah_cache';

  /// Daha önce gösterilen ayet numaraları (en eskiden en yeniye); güncellemede
  /// ve yedekten dönüşte başa sarmasın diye kalıcı tutulur (BackupService)
  static const String seenKey = 'seen_ayah_numbers';

  /// Gün → seçilen ayet numarası (son 14 gün): aynı gün dil değişirse aynı
  /// ayetin meali gelir; sadece önbellek
  static const String assignmentsKey = 'daily_ayah_assignments';

  /// Günün ayeti adayları: tek başına anlaşılır, orta uzunlukta ayetler
  /// (kısa ayetler, hurûf-ı mukattaa, karşılıklı konuşma hariç; tool/daily_ayahs.py)
  static const String candidatesAsset = 'assets/data/daily_ayahs.json';

  // Ardışık günlerin adımı: asal, liste uzunluğuyla aralarında asal → liste
  // bitene kadar her ayet bir kez; komşu günler listede birbirinden uzak
  static const int _dayStep = 3853;

  // Liste tamamen bitince yeni döngüde son 30 günün ayetleri hemen dönmez
  static const int _recentKeep = 30;
  static const int _assignmentKeepDays = 14;

  static Future<List<int>>? _candidates;

  static Future<List<int>> _loadCandidates() async {
    try {
      final raw = await rootBundle.loadString(candidatesAsset);
      final list = List<int>.from(json.decode(raw)['ayahs'] as List);
      if (list.isNotEmpty) return list;
    } catch (e) {
      print("Günün ayeti listesi okunamadı: $e");
    }
    _candidates = null; // sonraki çağrı yeniden dener
    return const [];
  }

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

  /// [day] gününün taban ayeti (1..[totalAyahs]): adaylardan, takvim gününe
  /// bağlı ve dilden bağımsız; ardışık günler farklı. Liste okunamazsa bütün
  /// ayetlerden.
  static Future<int> ayahNumberFor(DateTime day) async {
    final candidates = await (_candidates ??= _loadCandidates());
    final step = PrayerTracker.epochDay(day) * _dayStep;
    return candidates.isEmpty
        ? step % totalAyahs + 1
        : candidates[step % candidates.length];
  }

  static List<int> _loadSeen(SharedPreferences prefs) {
    final raw = prefs.getStringList(seenKey);
    if (raw == null) return [];
    final result = <int>[];
    for (final item in raw) {
      final n = int.tryParse(item);
      if (n != null && n >= 1 && n <= totalAyahs) result.add(n);
    }
    return result;
  }

  static Map<String, int> _loadAssignments(SharedPreferences prefs) {
    final raw = prefs.getString(assignmentsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final result = <String, int>{};
      decoded.forEach((k, v) {
        if (v is num) {
          final n = v.toInt();
          if (n >= 1 && n <= totalAyahs) result[k] = n;
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  /// [day] için gösterilecek ayet numarası: o gün zaten atanmışsa aynısı
  /// (dil değişiminde aynı ayet), yoksa geçmişte ([seenKey]) olmayan ilk aday.
  /// Liste güncellenip boyutu değişse de daha önce görülenler tekrar edilmez.
  static Future<({int number, int poolSize})> _pickAyahNumber(
    DateTime day,
  ) async {
    final candidates = await (_candidates ??= _loadCandidates());
    final poolSize = candidates.isEmpty ? totalAyahs : candidates.length;
    final prefs = await SharedPreferences.getInstance();
    final dateKey = PrayerTracker.dateKey(day);

    final assigned = _loadAssignments(prefs)[dateKey];
    if (assigned != null) return (number: assigned, poolSize: poolSize);

    final seenList = _loadSeen(prefs);
    final seenSet = seenList.toSet();
    final step = PrayerTracker.epochDay(day) * _dayStep;

    int candidateAt(int index) =>
        candidates.isEmpty ? (index % totalAyahs) + 1 : candidates[index];

    final start = step % poolSize;

    // 1. Öncelik: daha önce hiç görülmemiş ayet
    for (var i = 0; i < poolSize; i++) {
      final number = candidateAt((start + i) % poolSize);
      if (!seenSet.contains(number)) {
        return (number: number, poolSize: poolSize);
      }
    }

    // 2. Tüm havuz görüldüyse son 30 günü atlayarak yeni döngü başlat
    final keep = min(_recentKeep, poolSize > 1 ? poolSize - 1 : 0);
    final recent = keep > 0 && seenList.length > keep
        ? seenList.sublist(seenList.length - keep).toSet()
        : <int>{};
    for (var i = 0; i < poolSize; i++) {
      final number = candidateAt((start + i) % poolSize);
      if (!recent.contains(number)) {
        return (number: number, poolSize: poolSize);
      }
    }
    return (number: candidateAt(start), poolSize: poolSize);
  }

  static Future<void> _recordShown(
    DateTime day,
    int number,
    int poolSize,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = PrayerTracker.dateKey(day);
    final now = DateTime.now();
    final oldest = PrayerTracker.dateKey(
      PrayerTracker.addDays(
        day.isBefore(now) ? day : now,
        -_assignmentKeepDays,
      ),
    );
    final assignments = _loadAssignments(prefs)
      ..removeWhere((k, _) => k.compareTo(oldest) < 0)
      ..[dateKey] = number;
    await prefs.setString(assignmentsKey, jsonEncode(assignments));

    var seen = _loadSeen(prefs);
    if (poolSize > 0 && seen.length >= poolSize) {
      final keep = min(_recentKeep, poolSize > 1 ? poolSize - 1 : 0);
      seen = keep > 0 && seen.length > keep
          ? seen.sublist(seen.length - keep)
          : <int>[];
    }
    seen.remove(number);
    seen.add(number);
    await prefs.setStringList(seenKey, [for (final n in seen) '$n']);
  }

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

    final picked = await _pickAyahNumber(date);

    // Meal baskısı Kur'an okuyucuyla ortak (QuranEdition); Arapça arayüzde
    // meal yerine yine Arapça metin döner
    final edition =
        QuranEdition.translationFor(languageCode) ?? QuranEdition.arabic;

    // Hem Arapça orijinalini (quran-uthmani) hem de meali aynı anda çeken endpoint
    final String url =
        '${QuranEdition.apiBase}/ayah/${picked.number}/editions/${QuranEdition.arabic},$edition';

    try {
      final body = await _fetch(Uri.parse(url));
      if (body == null) return null;
      final ayah = AyahModel.fromJson(json.decode(body), languageCode);
      await _storageService.saveDailyCache(cacheKey, date, languageCode, body);
      await _recordShown(date, picked.number, picked.poolSize);
      return ayah;
    } catch (e) {
      print("Ayet çekerken hata oluştu: $e");
      return null;
    }
  }
}
