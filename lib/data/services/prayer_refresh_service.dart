// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../models/hadith_model.dart';
import '../models/prayer_times_model.dart';
import 'ayah_service.dart';
import 'hadith_service.dart';
import 'notification_service.dart';
import 'prayer_time_service.dart';
import 'storage_service.dart';
import 'widget_service.dart';

/// Kurulacak tek bir ezan / hatırlatma bildirimi
class PlannedAlarm {
  final int id;
  final String title;
  final String body;
  final DateTime time;
  final String? sound; // null: sessiz (sadece yazılı) bildirim
  final String channelName;

  const PlannedAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.sound,
    required this.channelName,
  });
}

/// Vakitleri ekran dışına taşır: ana ekran widget'ları, kalıcı bildirim, ezan alarmları.
/// BuildContext gerektirmez; HomeViewModel ve WorkManager arka plan görevi ortak kullanır.
class PrayerRefreshService {
  PrayerRefreshService(this._notifications);

  final NotificationService _notifications;
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();

  static const List<String> vakitKeys = [
    "İmsak",
    "Güneş",
    "Öğle",
    "İkindi",
    "Akşam",
    "Yatsı",
  ];
  static const int alarmDays = 5; // gün başına 12 ID → 0-59
  static const String _alarmsDateKey = 'alarms_scheduled_date';

  static Map<String, String> timesMap(PrayerTimesModel t) => {
    "İmsak": t.imsak!,
    "Güneş": t.gunes!,
    "Öğle": t.ogle!,
    "İkindi": t.ikindi!,
    "Akşam": t.aksam!,
    "Yatsı": t.yatsi!,
  };

  static Map<String, String> vakitNames(AppLocalizations loc) => {
    "İmsak": loc.imsak,
    "Güneş": loc.gunes,
    "Öğle": loc.ogle,
    "İkindi": loc.ikindi,
    "Akşam": loc.aksam,
    "Yatsı": loc.yatsi,
  };

  /// Hicri tarih metni (örn. 7 Safer 1448). hijri paketinde sadece tr/en/ar var,
  /// diğer dillerde setLocal hata fırlattığı için İngilizce ay adları kullanılır.
  static String hijriDateText(String langCode) {
    final code = HijriCalendar.supportedLocales.contains(langCode)
        ? langCode
        : 'en';
    HijriCalendar.setLocal(code);
    return HijriCalendar.now().toFormat("dd MMMM yyyy");
  }

  /// Arka plan servisinin (kalıcı bildirim) kullandığı metinler
  static Map<String, String> displayTexts(
    AppLocalizations loc,
    String hijriDateText,
  ) {
    String langCode = loc.localeName;
    String remainingText = "Kalan";

    if (langCode.startsWith('en'))
      remainingText = "Left";
    else if (langCode.startsWith('de'))
      remainingText = "Übrig";
    else if (langCode.startsWith('fr'))
      remainingText = "Restant";
    else if (langCode.startsWith('ar'))
      remainingText = "الباقي";
    return {
      "next": loc.nextPrayer,
      "remaining": remainingText,
      "hijri_date": hijriDateText,
      "İmsak": loc.imsak,
      "Güneş": loc.gunes,
      "Öğle": loc.ogle,
      "İkindi": loc.ikindi,
      "Akşam": loc.aksam,
      "Yatsı": loc.yatsi,
      "to_İmsak": loc.toImsak,
      "to_Güneş": loc.toGunes,
      "to_Öğle": loc.toOgle,
      "to_İkindi": loc.toIkindi,
      "to_Akşam": loc.toAksam,
      "to_Yatsı": loc.toYatsi,
      "loading": loc.loading,
    };
  }

  /// Ana ekran widget'ları ve kalıcı bildirim (NotificationUpdater aynı veriyi okur).
  /// Hata fırlatmaz.
  Future<void> updateHomeWidget({
    required PrayerTimesModel times,
    required AppLocalizations? loc,
    required String? city,
    required String? district,
    required String hijriDateText,
  }) async {
    try {
      final now = DateTime.now();
      Map<String, String> vakitler = timesMap(times);
      Map<String, String> vakitIsimleri = {
        "İmsak": loc?.imsak ?? "İmsak",
        "Güneş": loc?.gunes ?? "Güneş",
        "Öğle": loc?.ogle ?? "Öğle",
        "İkindi": loc?.ikindi ?? "İkindi",
        "Akşam": loc?.aksam ?? "Akşam",
        "Yatsı": loc?.yatsi ?? "Yatsı",
      };
      String sonrakiVakitIsmi = "İmsak";
      DateTime? sonrakiVakitTarihi;
      bool bulundu = false;
      for (var entry in vakitler.entries) {
        if (entry.key == "Güneş") continue;
        List<String> parts = entry.value.split(':');
        DateTime vakitDate = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        if (vakitDate.isAfter(now)) {
          sonrakiVakitIsmi = entry.key;
          sonrakiVakitTarihi = vakitDate;
          bulundu = true;
          break;
        }
      }

      if (!bulundu) {
        sonrakiVakitIsmi = "İmsak";
        List<String> parts = vakitler["İmsak"]!.split(':');
        sonrakiVakitTarihi = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        ).add(const Duration(days: 1));
      }

      String dinamikBaslik = "";
      switch (sonrakiVakitIsmi) {
        case "İmsak":
          dinamikBaslik = loc?.toImsak ?? "Sabaha";
          break;
        case "Güneş":
          dinamikBaslik = loc?.toGunes ?? "Güneşe";
          break;
        case "Öğle":
          dinamikBaslik = loc?.toOgle ?? "Öğleye";
          break;
        case "İkindi":
          dinamikBaslik = loc?.toIkindi ?? "İkindiye";
          break;
        case "Akşam":
          dinamikBaslik = loc?.toAksam ?? "Akşama";
          break;
        case "Yatsı":
          dinamikBaslik = loc?.toYatsi ?? "Yatsıya";
          break;
        default:
          dinamikBaslik = "Kalan";
      }

      String guncelKonum = city ?? "Konum Bekleniyor";
      if (city != null && district != null && district.isNotEmpty) {
        guncelKonum = "$city, $district";
      }

      await WidgetService.widgetiGuncelle(
        baslik: dinamikBaslik,
        hedefZamanMs: sonrakiVakitTarihi!.millisecondsSinceEpoch,
        vakitler: vakitler,
        konum: guncelKonum,
        vakitIsimleri: vakitIsimleri,
        hijriDateText: hijriDateText,
      );
    } catch (e) {}
  }

  /// Ezan (çift ID) ve hatırlatma (tek ID) planı; gün başına 12 ID.
  /// [days] bugünden başlayan günlerin vakitleri. Tek gün varsa geçmiş vakit yarına kayar.
  static List<PlannedAlarm> buildAlarmPlan({
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    required Map<String, bool> silentModeSettings,
  }) {
    final vakitDisplayNames = vakitNames(loc);
    final plan = <PlannedAlarm>[];
    int idCounter = 0;
    for (int day = 0; day < days.length; day++) {
      final dayDate = DateTime(now.year, now.month, now.day + day);
      for (var entry in timesMap(days[day]).entries) {
        String vakitLogicKey = entry.key;
        String vakitDisplayName = vakitDisplayNames[vakitLogicKey]!;
        List<String> parts = entry.value.split(':');
        DateTime vakitDate = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        // Tek günlük modda geçmiş vakit yarına kayar; çok günlükte zaten yarın da kurulu
        if (days.length == 1 && vakitDate.isBefore(now)) {
          vakitDate = vakitDate.add(const Duration(days: 1));
        }

        if (onTimeAlarms[vakitLogicKey] == true && !vakitDate.isBefore(now)) {
          bool isSilent = silentModeSettings[vakitLogicKey] ?? false;
          String? soundToSend = isSilent
              ? null
              : (selectedSounds[vakitLogicKey] ?? "ezan1");
          plan.add(
            PlannedAlarm(
              id: idCounter,
              title: loc.notifTitleTime,
              body: loc.notifBodyTime(vakitDisplayName),
              time: vakitDate,
              sound: soundToSend,
              channelName: soundToSend != null
                  ? loc.channelSoundPrefix(soundToSend)
                  : loc.channelSilentPrayers,
            ),
          );
        }
        idCounter++;
        if (reminderAlarms[vakitLogicKey] == true) {
          int dakikaOnce =
              (vakitLogicKey == "İmsak" || vakitLogicKey == "Güneş") ? 30 : 15;
          DateTime hatirlatmaZamani = vakitDate.subtract(
            Duration(minutes: dakikaOnce),
          );
          if (hatirlatmaZamani.isAfter(now)) {
            String reminderSound =
                selectedReminderSounds[vakitLogicKey] ?? "bildirim1";
            plan.add(
              PlannedAlarm(
                id: idCounter,
                title: loc.notifTitleUpcoming,
                body: loc.notifBodyUpcoming(vakitDisplayName, dakikaOnce),
                time: hatirlatmaZamani,
                sound: reminderSound,
                channelName: loc.channelSoundPrefix(reminderSound),
              ),
            );
          }
        }
        idCounter++;
      }
    }
    return plan;
  }

  /// Ezan/hatırlatma alarmlarını kurar. Koordinat varsa 5 gün (uygulama açılmasa da ezan gelir),
  /// yoksa sadece [todayTimes] ile 1 gün.
  /// [replaceOnly] (arka plan): toplu iptal yerine aynı ID'nin üzerine yazılır, sadece plandan
  /// çıkan bekleyen alarmlar iptal edilir → ekrandaki ezan bildirimi silinmez, alarmda boşluk olmaz.
  Future<void> rescheduleAlarms({
    required PrayerTimesModel todayTimes,
    required AppLocalizations loc,
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    required Map<String, bool> silentModeSettings,
    bool replaceOnly = false,
  }) async {
    final now = DateTime.now();
    final days = <PrayerTimesModel>[todayTimes];
    final coords = await _storageService.loadCoordinates();
    if (coords != null) {
      final offsets = await _storageService.loadTimeOffsets();
      for (int day = 1; day < alarmDays; day++) {
        days.add(
          _prayerTimeService.calculate(
            coords.lat,
            coords.lng,
            date: DateTime(now.year, now.month, now.day + day),
            offsets: offsets,
          ),
        );
      }
    }
    final plan = buildAlarmPlan(
      days: days,
      now: now,
      loc: loc,
      onTimeAlarms: onTimeAlarms,
      reminderAlarms: reminderAlarms,
      selectedSounds: selectedSounds,
      selectedReminderSounds: selectedReminderSounds,
      silentModeSettings: silentModeSettings,
    );

    if (replaceOnly) {
      final plannedIds = plan.map((a) => a.id).toSet();
      for (final id in await _notifications.pendingIds()) {
        if (id >= 0 && id < alarmDays * 12 && !plannedIds.contains(id)) {
          await _notifications.cancel(id);
        }
      }
    } else {
      await _notifications.cancelSpecificAlarms();
    }

    for (final alarm in plan) {
      try {
        await _notifications.schedulePrayerNotification(
          id: alarm.id,
          title: alarm.title,
          body: alarm.body,
          scheduledTime: alarm.time,
          soundName: alarm.sound,
          localizedChannelName: alarm.channelName,
          localizedTicker: loc.tickerEzan,
        );
      } catch (e) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmsDateKey, _dateKey(now));
  }

  /// Günlük ayet (10:00, ID 1000) ve hadis (19:00, ID 1900) bildirimi
  Future<void> scheduleDailyContent({
    required String localeName,
    AyahModel? ayah,
    HadithModel? hadith,
  }) async {
    if (ayah != null) {
      String title = localeName.startsWith('tr')
          ? "Günün Ayeti"
          : "Ayah of the Day";
      String content = "${ayah.arabicText}\n\n${ayah.translatedText}";
      await _notifications.scheduleDailyContent(
        id: 1000,
        title: title,
        body: content,
        hour: 10,
        minute: 0,
        channelId: 'daily_ayah_channel',
        channelName: 'Günlük Ayet',
      );
    }
    if (hadith != null && hadith.content != null) {
      String title = localeName.startsWith('tr')
          ? "Günün Hadisi"
          : "Hadith of the Day";
      await _notifications.scheduleDailyContent(
        id: 1900,
        title: title,
        body: hadith.content!,
        hour: 19,
        minute: 0,
        channelId: 'daily_hadith_channel',
        channelName: 'Günlük Hadis',
      );
    }
  }

  // Günlük içerik tek seferlik kurulur; uygulama açılmazsa çalmış olanın yerine yenisi
  Future<void> _topUpDailyContent(AppLocalizations loc) async {
    try {
      final pending = await _notifications.pendingIds();
      final langCode = loc.localeName.substring(0, 2);
      AyahModel? ayah;
      HadithModel? hadith;
      if (!pending.contains(1000)) {
        ayah = await AyahService().getRandomAyah(langCode);
      }
      if (!pending.contains(1900)) {
        hadith = await HadithService().getDailyHadith(Locale(langCode));
      }
      await scheduleDailyContent(
        localeName: loc.localeName,
        ayah: ayah,
        hadith: hadith,
      );
    } catch (e) {}
  }

  static String _dateKey(DateTime d) => d.toIso8601String().split('T')[0];

  static AppLocalizations _localizations(String? languageCode) {
    try {
      return lookupAppLocalizations(Locale(languageCode ?? 'tr'));
    } catch (e) {
      return lookupAppLocalizations(const Locale('tr'));
    }
  }

  /// WorkManager görevi (uygulama kapalıyken de): bugünün vakitleri → cache, widget'lar,
  /// kalıcı bildirim; alarmlar günde bir kez 5 gün ileriye uzatılır. Hata fırlatmaz,
  /// beklenmeyen hatada false döner (WorkManager yeniden dener).
  static Future<bool> runHeadless() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs
          .reload(); // uygulama süreci açıksa diğer isolate'in yazdıkları

      final service = PrayerRefreshService(NotificationService());
      final now = DateTime.now();
      final times = await service._prayerTimeService.forDate(now);
      // Koordinat yoksa cihazda hesaplanamaz; uygulama açılınca çözülür
      if (times == null) return true;
      await service._storageService.savePrayerTimesData(times);

      final loc = _localizations(prefs.getString('language_code'));
      String hijri = "";
      try {
        hijri = hijriDateText(loc.localeName.substring(0, 2));
      } catch (e) {}

      // Arka plan servisi (yeniden) başlarken kalıcı bildirim metnini buradan okur
      await prefs.setString('bg_display', jsonEncode(displayTexts(loc, hijri)));
      final district = await service._storageService.loadDistrict();
      await service.updateHomeWidget(
        times: times,
        loc: loc,
        city: await service._storageService.loadLocation(),
        district: district,
        hijriDateText: hijri,
      );

      await service._notifications.init();
      if (prefs.getString(_alarmsDateKey) != _dateKey(now)) {
        final settings = await service._storageService.loadSettings();
        await service.rescheduleAlarms(
          todayTimes: times,
          loc: loc,
          onTimeAlarms: settings['onTime'],
          reminderAlarms: settings['reminder'],
          selectedSounds: settings['sounds'],
          selectedReminderSounds: settings['reminderSounds'],
          silentModeSettings: settings['silentMode'],
          replaceOnly: true,
        );
      }
      await service._topUpDailyContent(loc);
      return true;
    } catch (e) {
      return false;
    }
  }
}
