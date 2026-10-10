import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart';
import '../models/hadith_model.dart';
import 'prayer_tracker.dart';

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
      'alarmStream': prefs.getBool(ezanAlarmStreamKey) ?? false,
    };
  }

  /// "Sessiz modda da çal": ezan alarm ses akışında çalar (varsayılan kapalı)
  static const String ezanAlarmStreamKey = 'ezan_alarm_stream';

  Future<void> saveEzanAlarmStream(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ezanAlarmStreamKey, enabled);
  }

  Future<void> saveLocation(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city', city);
  }

  Future<String?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_city');
  }

  Future<void> saveDistrict(String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_district', district);
  }

  Future<String?> loadDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_district');
  }

  Future<void> saveCoordinates(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_lat', lat);
    await prefs.setDouble('saved_lng', lng);
  }

  Future<void> clearCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_lat');
    await prefs.remove('saved_lng');
  }

  Future<({double lat, double lng})?> loadCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('saved_lat');
    final lng = prefs.getDouble('saved_lng');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// Vakit ince ayarı (dakika). Anahtarlar: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı
  Future<void> saveTimeOffsets(Map<String, int> offsets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('time_offsets', jsonEncode(offsets));
  }

  Future<Map<String, int>> loadTimeOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('time_offsets');
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(
        jsonDecode(raw),
      ).map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  Future<void> savePrayerTimesData(PrayerTimesModel data) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(data.toJson());
    await prefs.setString('cached_prayer_times', jsonString);

    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('cached_prayer_date', today);
  }

  Future<PrayerTimesModel?> loadPrayerTimesData() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedDate = prefs.getString('cached_prayer_date');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate != today) return null;

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

  // --- Namaz takibi: tarih (yyyy-MM-dd) → vakit bit maskesi (PrayerTracker) ---
  // Bildirim aksiyonu ayrı isolate'te yazar; okumadan önce reload şart.

  Future<Map<String, int>> loadPrayerLog() => _loadMaskMap('prayer_log');

  Future<void> savePrayerLog(Map<String, int> log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_log', jsonEncode(log));
  }

  /// Kazaya eklenmiş (tarih, vakit) çiftleri; aynı vakit iki kez eklenmez
  Future<Map<String, int>> loadKazaAdded() =>
      _loadMaskMap('prayer_kaza_added');

  Future<void> saveKazaAdded(Map<String, int> added) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_kaza_added', jsonEncode(added));
  }

  /// Takibin başladığı gün (ilk işaretlenen en eski tarih)
  Future<String?> loadTrackerSince() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('prayer_log_since');
  }

  Future<void> saveTrackerSince(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_log_since', dateKey);
  }

  // --- Ramazan orucu takibi: tutulan / kaza orucuna eklenen günler (yyyy-MM-dd) ---

  Future<Set<String>> loadFastLog() => _loadDaySet('fast_log');

  Future<void> saveFastLog(Set<String> days) => _saveDaySet('fast_log', days);

  Future<Set<String>> loadFastKazaAdded() => _loadDaySet('fast_kaza_added');

  Future<void> saveFastKazaAdded(Set<String> days) =>
      _saveDaySet('fast_kaza_added', days);

  Future<Set<String>> _loadDaySet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return {...?prefs.getStringList(key)};
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveDaySet(String key, Set<String> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, days.toList()..sort());
  }

  Future<Map<String, int>> _loadMaskMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final result = <String, int>{};
      Map<String, dynamic>.from(jsonDecode(raw)).forEach((k, v) {
        if (v is num) result[k] = v.toInt();
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  // --- "Vakit çıkmadan hatırlat" ayarı (varsayılan kapalı, 30 dk) ---

  Future<({bool enabled, int minutes})> loadEndReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('end_reminder_minutes');
    return (
      enabled: prefs.getBool('end_reminder_enabled') ?? false,
      minutes: PrayerTracker.endReminderMinuteOptions.contains(minutes)
          ? minutes!
          : PrayerTracker.defaultEndReminderMinutes,
    );
  }

  Future<void> saveEndReminderSettings({
    required bool enabled,
    required int minutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('end_reminder_enabled', enabled);
    await prefs.setInt('end_reminder_minutes', minutes);
  }

  /// "Günün ayeti ve hadisi" bildirimi (ID 1000/1900; varsayılan açık)
  static const String dailyContentEnabledKey = 'daily_content_enabled';

  Future<bool> loadDailyContentEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyContentEnabledKey) ?? true;
  }

  Future<void> saveDailyContentEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyContentEnabledKey, enabled);
  }

  /// Dini gün ve kandil bildirimleri (ID 2000-2399; varsayılan açık)
  static const String religiousDaysEnabledKey = 'religious_days_enabled';

  Future<bool> loadReligiousDaysEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(religiousDaysEnabledKey) ?? true;
  }

  Future<void> saveReligiousDaysEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(religiousDaysEnabledKey, enabled);
  }

  Future<void> saveDailyHadith(HadithModel hadith, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_hadith_content', hadith.content ?? "");
    await prefs.setString('daily_hadith_source', hadith.source ?? "");

    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('daily_hadith_date', today);
    await prefs.setString('daily_hadith_lang', languageCode);
  }

  Future<HadithModel?> loadDailyHadith(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();

    String? savedDate = prefs.getString('daily_hadith_date');
    String? savedLang = prefs.getString('daily_hadith_lang');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate != today || savedLang != languageCode) return null;

    String? content = prefs.getString('daily_hadith_content');
    String? source = prefs.getString('daily_hadith_source');

    if (content != null && content.isNotEmpty) {
      return HadithModel(content: content, source: source);
    }

    return null;
  }
}
