import 'dart:convert'; // JSON işlemleri için şart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart'; // Model yolunu kontrol et
import '../models/hadith_model.dart'; //  --- YENİ EKLENDİ ---

class StorageService {
  Future<void> saveSettings({
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    required Map<String, bool> silentModeSettings,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    onTimeAlarms.forEach((key, value) => prefs.setBool('onTime_$key', value));
    reminderAlarms.forEach(
      (key, value) => prefs.setBool('reminder_$key', value),
    );
    selectedSounds.forEach(
      (key, value) => prefs.setString('sound_$key', value),
    );
    selectedReminderSounds.forEach(
      (key, value) => prefs.setString('reminderSound_$key', value),
    );
    silentModeSettings.forEach(
      (key, value) => prefs.setBool('silent_$key', value),
    );
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, bool> onTime = {};
    Map<String, bool> reminder = {};
    Map<String, String> sounds = {};
    Map<String, String> reminderSounds = {};
    Map<String, bool> silentMode = {};

    List<String> vakitler = [
      "İmsak",
      "Güneş",
      "Öğle",
      "İkindi",
      "Akşam",
      "Yatsı",
    ];

    for (var vakit in vakitler) {
      onTime[vakit] = prefs.getBool('onTime_$vakit') ?? false;
      reminder[vakit] = prefs.getBool('reminder_$vakit') ?? false;
      sounds[vakit] = prefs.getString('sound_$vakit') ?? "ezan1";
      reminderSounds[vakit] =
          prefs.getString('reminderSound_$vakit') ?? "bildirim1";
      silentMode[vakit] = prefs.getBool('silent_$vakit') ?? false;
    }

    return {
      'onTime': onTime,
      'reminder': reminder,
      'sounds': sounds,
      'reminderSounds': reminderSounds,
      'silentMode': silentMode,
    };
  }

  Future<void> saveLocation(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city', city);
  }

  Future<String?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_city');
  }

  // --- İLÇE KAYDETME/OKUMA ---
  Future<void> saveDistrict(String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_district', district);
  }

  Future<String?> loadDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_district');
  }
  // ------------------------------------------------

  // --- Vakitleri JSON Olarak Kaydetme ---
  Future<void> savePrayerTimesData(PrayerTimesModel data) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(data.toJson());
    await prefs.setString('cached_prayer_times', jsonString);

    // Tarihi de kaydedelim ki eski veriyi göstermeyelim
    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('cached_prayer_date', today);
  }

  // --- Kayıtlı Vakitleri Okuma ---
  Future<PrayerTimesModel?> loadPrayerTimesData() async {
    final prefs = await SharedPreferences.getInstance();

    // Tarih kontrolü: Eğer kayıt bugüne ait değilse boş dön (Yenisini çeksin)
    String? savedDate = prefs.getString('cached_prayer_date');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate != today) {
      return null;
    }

    String? jsonString = prefs.getString('cached_prayer_times');
    if (jsonString != null) {
      try {
        Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return PrayerTimesModel.fromJson(jsonMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  // ---------------------------------------------

  Future<Map<String, int>> loadMissedPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "Sabah": prefs.getInt('kaza_Sabah') ?? 0,
      "Öğle": prefs.getInt('kaza_Öğle') ?? 0,
      "İkindi": prefs.getInt('kaza_İkindi') ?? 0,
      "Akşam": prefs.getInt('kaza_Akşam') ?? 0,
      "Yatsı": prefs.getInt('kaza_Yatsı') ?? 0,
      "Vitir": prefs.getInt('kaza_Vitir') ?? 0,
      "Oruç": prefs.getInt('kaza_Oruç') ?? 0,
    };
  }

  Future<void> updateMissedPrayer(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kaza_$key', value);
  }

  Future<void> saveDailyHadith(HadithModel hadith) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_hadith_content', hadith.content ?? "");
    await prefs.setString('daily_hadith_source', hadith.source ?? "");

    // Bugünü "YYYY-MM-DD" formatında kaydet (Örn: 2025-12-27)
    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('daily_hadith_date', today);
  }

  Future<HadithModel?> loadDailyHadith() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedDate = prefs.getString('daily_hadith_date');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate != today) {
      return null;
    }

    String? content = prefs.getString('daily_hadith_content');
    String? source = prefs.getString('daily_hadith_source');

    if (content != null && content.isNotEmpty) {
      return HadithModel(content: content, source: source);
    }

    return null;
  }
}
