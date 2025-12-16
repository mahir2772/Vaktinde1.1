import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveSettings({
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    // YENİ: Sessiz Mod Ayarları
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

    // YENİ: Kaydet
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
    // YENİ: Okunacak Map
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
      // YENİ: Oku (Varsayılan false = Sesli)
      silentMode[vakit] = prefs.getBool('silent_$vakit') ?? false;
    }

    return {
      'onTime': onTime,
      'reminder': reminder,
      'sounds': sounds,
      'reminderSounds': reminderSounds,
      'silentMode': silentMode, // YENİ
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
}
