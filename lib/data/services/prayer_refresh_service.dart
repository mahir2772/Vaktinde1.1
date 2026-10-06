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
import 'prayer_tracker.dart';
import 'prayer_tracker_service.dart';
import 'serial_queue.dart';
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
  final String? payload; // "Kıldım" aksiyonu için tarih + vakit
  final String? actionLabel; // null: aksiyon butonu yok

  const PlannedAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.sound,
    required this.channelName,
    this.payload,
    this.actionLabel,
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
          // Farz vakitlerde "Kıldım" butonu (Güneş hariç)
          final tracked = PrayerTracker.prayerKeys.contains(vakitLogicKey);
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
              payload: tracked
                  ? PrayerTracker.payload(vakitDate, vakitLogicKey)
                  : null,
              actionLabel: tracked ? loc.trackerPrayedAction : null,
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

  /// "Vakit çıkmadan hatırlat" planı (ID 100-124). [days][0] bugün, [previous] dünün
  /// vakitleri (dünkü yatsının süresi için). Hatırlatma günü d: dünkü yatsı (d'nin
  /// imsakında biter), sabah (güneşte), öğle (ikindide), ikindi (akşamda), akşam (yatsıda).
  /// Geçmiş, [minutes] >= vakit süresi veya kılındı işaretli vakitler atlanır.
  static List<PlannedAlarm> buildEndReminderPlan({
    required PrayerTimesModel previous,
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
    required int minutes,
    required Map<String, int> prayerLog,
  }) {
    final names = {
      "İmsak": loc.sabah,
      "Öğle": loc.ogle,
      "İkindi": loc.ikindi,
      "Akşam": loc.aksam,
      "Yatsı": loc.yatsi,
    };
    DateTime at(DateTime date, String hhmm) {
      final parts = hhmm.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    final plan = <PlannedAlarm>[];
    for (int d = 0; d < days.length && d < PrayerTracker.endReminderDays; d++) {
      final date = PrayerTracker.addDays(now, d);
      final prevDate = PrayerTracker.addDays(now, d - 1);
      final t = days[d];
      final prev = d == 0 ? previous : days[d - 1];
      // (vakit, namazın günü, başlangıç, bitiş)
      final windows = [
        ("Yatsı", prevDate, at(prevDate, prev.yatsi!), at(date, t.imsak!)),
        ("İmsak", date, at(date, t.imsak!), at(date, t.gunes!)),
        ("Öğle", date, at(date, t.ogle!), at(date, t.ikindi!)),
        ("İkindi", date, at(date, t.ikindi!), at(date, t.aksam!)),
        ("Akşam", date, at(date, t.aksam!), at(date, t.yatsi!)),
      ];
      for (final (key, prayerDate, start, end) in windows) {
        if (minutes >= end.difference(start).inMinutes) continue;
        final remindAt = end.subtract(Duration(minutes: minutes));
        if (!remindAt.isAfter(now)) continue;
        if (PrayerTracker.isPrayed(prayerLog, prayerDate, key)) continue;
        plan.add(
          PlannedAlarm(
            id: PrayerTracker.endReminderId(date, key),
            title: loc.endReminderNotifTitle,
            body: loc.endReminderNotifBody(names[key]!, minutes),
            time: remindAt,
            sound: null,
            channelName: loc.endReminderChannel,
            payload: PrayerTracker.payload(prayerDate, key),
            actionLabel: loc.trackerPrayedAction,
          ),
        );
      }
    }
    return plan;
  }

  /// Alarm planı için günlerin vakitleri. Koordinat varsa bugün + 4 gün ve dün yeniden
  /// hesaplanır ([todayTimes] gece yarısından kalma olabilir); yoksa sadece [todayTimes]
  /// (dün/yarın yerine bugünkü vakitler yaklaşık kullanılır).
  Future<
    ({
      List<PrayerTimesModel> days,
      PrayerTimesModel previous,
      List<PrayerTimesModel> reminderDays,
    })
  >
  _planDays(PrayerTimesModel todayTimes, DateTime now) async {
    final coords = await _storageService.loadCoordinates();
    if (coords == null) {
      return (
        days: [todayTimes],
        previous: todayTimes,
        reminderDays: [todayTimes, todayTimes],
      );
    }
    final offsets = await _storageService.loadTimeOffsets();
    final days = <PrayerTimesModel>[];
    for (int day = 0; day < alarmDays; day++) {
      days.add(
        _prayerTimeService.calculate(
          coords.lat,
          coords.lng,
          date: DateTime(now.year, now.month, now.day + day),
          offsets: offsets,
        ),
      );
    }
    final previous = _prayerTimeService.calculate(
      coords.lat,
      coords.lng,
      date: DateTime(now.year, now.month, now.day - 1),
      offsets: offsets,
    );
    return (days: days, previous: previous, reminderDays: days);
  }

  /// "Vakit çıkıyor" hatırlatmalarını ayara ve takip kaydına göre eşitler (sadece
  /// 100-124): plandan çıkan bekleyenler iptal, plandakiler aynı ID'nin üzerine kurulur.
  /// Ayar kapalıysa hepsi iptal edilir. Hata fırlatmaz.
  Future<void> syncEndReminders({
    required PrayerTimesModel todayTimes,
    required AppLocalizations loc,
  }) => _serializeAlarms(() async {
    final now = DateTime.now();
    try {
      final planDays = await _planDays(todayTimes, now);
      await _syncEndReminders(
        previous: planDays.previous,
        days: planDays.reminderDays,
        now: now,
        loc: loc,
      );
    } catch (e) {}
  });

  /// Plan boşsa ya da en az bir hatırlatma kurulduysa true
  Future<bool> _syncEndReminders({
    required PrayerTimesModel previous,
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
  }) => PrayerTrackerService.runExclusive(() async {
    int succeeded = 0;
    List<PlannedAlarm> plan = const [];
    try {
      // Plan çıkarılamazsa (okuma hatası) kurulu hatırlatmalara dokunulmaz
      final settings = await _storageService.loadEndReminderSettings();
      if (settings.enabled) {
        plan = buildEndReminderPlan(
          previous: previous,
          days: days,
          now: now,
          loc: loc,
          minutes: settings.minutes,
          prayerLog: await _storageService.loadPrayerLog(),
        );
      }
      final plannedIds = plan.map((a) => a.id).toSet();
      for (final id in await _notifications.pendingIds()) {
        if (PrayerTracker.isEndReminderId(id) && !plannedIds.contains(id)) {
          await _notifications.cancel(id);
        }
      }
      for (final alarm in plan) {
        try {
          await _notifications.scheduleEndReminder(
            id: alarm.id,
            title: alarm.title,
            body: alarm.body,
            scheduledTime: alarm.time,
            localizedChannelName: alarm.channelName,
            actionLabel: alarm.actionLabel!,
            payload: alarm.payload!,
          );
          succeeded++;
        } catch (e) {}
      }
    } catch (e) {
      return false;
    }
    return plan.isEmpty || succeeded > 0;
  });

  // Uygulama içinde alarm kurma işleri üst üste binmez (iptal/kur sırası karışmasın).
  // Arka plan görevi ayrı isolate'tedir.
  static final SerialQueue _alarmQueue = SerialQueue();

  static Future<T> _serializeAlarms<T>(Future<T> Function() action) =>
      _alarmQueue.run(action);

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
  }) => _serializeAlarms(() async {
    final now = DateTime.now();
    final planDays = await _planDays(todayTimes, now);
    final plan = buildAlarmPlan(
      days: planDays.days,
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

    int succeeded = 0;
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
          payload: alarm.payload,
          actionLabel: alarm.actionLabel,
        );
        succeeded++;
      } catch (e) {}
    }

    final remindersOk = await _syncEndReminders(
      previous: planDays.previous,
      days: planDays.reminderDays,
      now: now,
      loc: loc,
    );

    // Hiçbiri kurulamadıysa tarih yazılmaz: arka plan görevi aynı gün yeniden dener
    if ((plan.isEmpty || succeeded > 0) && remindersOk) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alarmsDateKey, _dateKey(now));
    }
  });

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
