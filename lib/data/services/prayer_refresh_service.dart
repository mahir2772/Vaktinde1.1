// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_saati/core/ui/app_format.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../models/hadith_model.dart';
import '../models/prayer_times_model.dart';
import 'ayah_service.dart';
import 'error_reporter.dart';
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
  final bool alarmStream; // "sessiz modda da çal" (sadece sesli ezan)

  const PlannedAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.sound,
    required this.channelName,
    this.payload,
    this.actionLabel,
    this.alarmStream = false,
  });
}

/// Vakitleri ekran dışına taşır: ana ekran widget'ları, kalıcı bildirim, ezan alarmları.
/// BuildContext gerektirmez; HomeViewModel ve WorkManager arka plan görevi ortak kullanır.
class PrayerRefreshService {
  PrayerRefreshService(this._notifications, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final NotificationService _notifications;
  // Alarm planının "şimdi"si (testte sabit saat verilebilir)
  final DateTime Function() _clock;
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
  static const int alarmDays = 5;
  // ID vaktin tarihine bağlı: 6 günlük döngü (plan + dünün geç kalan ezanı) x 12 → 0-71
  static const int _idDays = alarmDays + 1;
  static const int alarmIdCount = _idDays * 12;
  static const String _alarmsDateKey = 'alarms_scheduled_date';

  /// Kurulan farz ezanlarının ID → [alarmFingerprint] kaydı (eklentinin bekleyen
  /// listesi saat/ayar vermez; geç ezanı korumadan önce karşılaştırılır)
  static const String planMetaKey = 'alarm_plan_meta';

  /// Tam zamanlı izin yokken (Android 12) gecikmeli ezan vaktinden sonra bu süre
  /// bekleyebilir: pencere 1 saate kadar + Doze'da uygulamanın diğer gecikmeli
  /// alarmlarıyla 9 dk arayla sıra
  static const Duration lateWindow = Duration(minutes: 90);

  /// [day] günündeki vaktin ([vakitIndex], [vakitKeys] sırası) ezan (çift) ya da
  /// hatırlatma (tek) ID'si. Farklı günlerde kurulan planlar aynı vakte aynı ID'yi verir.
  static int alarmId(DateTime day, int vakitIndex, {bool reminder = false}) =>
      (PrayerTracker.epochDay(day) % _idDays) * 12 +
      vakitIndex * 2 +
      (reminder ? 1 : 0);

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
  /// [date] verilmezse bugün.
  static String hijriDateText(String langCode, {DateTime? date}) {
    final code = HijriCalendar.supportedLocales.contains(langCode)
        ? langCode
        : 'en';
    // Ay adı dönüştürme anında seçili dilden alınır: setLocal önce
    HijriCalendar.setLocal(code);
    final hijri = date == null
        ? HijriCalendar.now()
        : HijriCalendar.fromDate(date);
    return hijri.toFormat("dd MMMM yyyy");
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

  // Widget yazımları sırayla: üst üste gelen çağrılar anahtarları karıştırmasın
  static final SerialQueue _widgetQueue = SerialQueue();

  /// Ana ekran widget'ları ve kalıcı bildirim (NotificationUpdater aynı veriyi okur).
  /// [times] bugünün vakitleri. Gece yarısı ve yatsı sonrası için setin günü ve
  /// (koordinat varsa) yarının vakitleri + hicri tarihi de yazılır. Hata fırlatmaz.
  Future<void> updateHomeWidget({
    required PrayerTimesModel times,
    required AppLocalizations? loc,
    required String? city,
    required String? district,
    required String hijriDateText,
  }) => _widgetQueue.run(() async {
    try {
      final now = DateTime.now();
      Map<String, String> vakitler = timesMap(times);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final yarinVakitler = await _tomorrowTimes(tomorrow);
      String? yarinHijri;
      if (yarinVakitler != null && loc != null) {
        try {
          yarinHijri = PrayerRefreshService.hijriDateText(
            loc.localeName.substring(0, 2),
            date: tomorrow,
          );
        } catch (e) {}
      }
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
        // Yatsıdan sonra yarının imsakı (yoksa bugünkü saat, yarın)
        List<String> parts = (yarinVakitler?["İmsak"] ?? vakitler["İmsak"]!)
            .split(':');
        sonrakiVakitTarihi = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      String dinamikBaslik = "";
      switch (sonrakiVakitIsmi) {
        case "İmsak":
          dinamikBaslik = loc?.toImsak ?? "İmsaka";
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
        tarih: _dateKey(now),
        yarinVakitler: yarinVakitler,
        yarinHijriDateText: yarinHijri,
      );
    } catch (e) {}
  });

  // Yarının vakitleri (kayıtlı koordinat + ince ayar); koordinat yoksa null
  Future<Map<String, String>?> _tomorrowTimes(DateTime tomorrow) async {
    try {
      final times = await _prayerTimeService.forDate(tomorrow);
      return times == null ? null : timesMap(times);
    } catch (e) {
      return null;
    }
  }

  /// Ezan (çift ID) ve hatırlatma (tek ID) planı; ID vaktin tarihine bağlı ([alarmId]).
  /// [days] bugünden başlayan günlerin vakitleri. Tek gün varsa geçmiş vakit yarına kayar.
  /// [ramadan] verilirse Ramazan günlerinde imsak/akşam ezanı sahur/iftar metniyle gelir.
  /// [alarmStream] ("sessiz modda da çal") sadece sesli ezanı alarm kanalına alır;
  /// hatırlatmalar ve sessiz (yazılı) bildirimler değişmez.
  /// [exact] false (tam zamanlı izin yok, alarm bir saate kadar gecikebilir): geç
  /// okunduğunda yanıltmasın diye "X dakika kaldı" yerine vaktin saati yazılır
  /// (hatırlatma ve Ramazan'da sahur bitişi).
  static List<PlannedAlarm> buildAlarmPlan({
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    required Map<String, bool> silentModeSettings,
    RamadanCalendar? ramadan,
    bool alarmStream = false,
    bool exact = true,
  }) {
    final vakitDisplayNames = vakitNames(loc);
    final plan = <PlannedAlarm>[];
    for (int day = 0; day < days.length; day++) {
      final dayDate = DateTime(now.year, now.month, now.day + day);
      for (var entry in timesMap(days[day]).entries) {
        String vakitLogicKey = entry.key;
        final vakitIndex = vakitKeys.indexOf(vakitLogicKey);
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
          String title = loc.notifTitleTime;
          String body = loc.notifBodyTime(vakitDisplayName);
          // Ramazan günü (vaktin kendi gününe göre): imsak = sahur bitti, akşam = iftar
          if ((vakitLogicKey == "İmsak" || vakitLogicKey == "Akşam") &&
              _isRamadanDay(ramadan, vakitDate)) {
            if (vakitLogicKey == "İmsak") {
              title = loc.ramadanImsakTitle;
              body = exact
                  ? loc.ramadanImsakBody
                  : loc.ramadanImsakBodyAt(
                      formatClockTime(vakitDate, loc.localeName),
                    );
            } else {
              title = loc.ramadanIftarTitle;
              body = loc.ramadanIftarBody(vakitDisplayName);
            }
          }
          final onAlarmStream = alarmStream && soundToSend != null;
          plan.add(
            PlannedAlarm(
              id: alarmId(vakitDate, vakitIndex),
              title: title,
              body: body,
              time: vakitDate,
              sound: soundToSend,
              channelName: soundToSend == null
                  ? loc.channelSilentPrayers
                  : (onAlarmStream
                        ? loc.channelAlarmSound(soundToSend)
                        : loc.channelSoundPrefix(soundToSend)),
              payload: tracked
                  ? PrayerTracker.payload(vakitDate, vakitLogicKey)
                  : null,
              actionLabel: tracked ? loc.trackerPrayedAction : null,
              alarmStream: onAlarmStream,
            ),
          );
        }
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
                id: alarmId(vakitDate, vakitIndex, reminder: true),
                title: exact ? loc.notifTitleUpcoming : loc.reminderTitleAt,
                body: exact
                    ? loc.notifBodyUpcoming(vakitDisplayName, dakikaOnce)
                    : loc.notifBodyUpcomingAt(
                        vakitDisplayName,
                        formatClockTime(vakitDate, loc.localeName),
                      ),
                time: hatirlatmaZamani,
                sound: reminderSound,
                channelName: loc.channelSoundPrefix(reminderSound),
              ),
            );
          }
        }
      }
    }
    return plan;
  }

  /// Vakti son [lateWindow] içinde girmiş, açık farz ezanları (dün ve bugün): ID →
  /// bugünkü ayarlarla kurulacak hali. Gecikmeli kurulmuş ezan bu sürede henüz
  /// çalmamış olabilir; aynı yükle bekliyor ve kaydı ([alarmFingerprint]) aynıysa
  /// yeniden kurulumda iptal edilmez. Güneş ve hatırlatmalar korunmaz (yükleri yok;
  /// geç gelen hatırlatma da yanıltır).
  static Map<int, PlannedAlarm> recentlyDueEzans({
    required PrayerTimesModel previous,
    required PrayerTimesModel today,
    required DateTime now,
    required AppLocalizations loc,
    required Map<String, bool> onTimeAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, bool> silentModeSettings,
    RamadanCalendar? ramadan,
    bool alarmStream = false,
  }) {
    final from = now.subtract(lateWindow);
    // Dünün başından itibaren iki günün tüm ezanları (geçmiş olsalar da)
    final ezans = buildAlarmPlan(
      days: [previous, today],
      now: PrayerTracker.addDays(now, -1),
      loc: loc,
      onTimeAlarms: onTimeAlarms,
      reminderAlarms: const {},
      selectedSounds: selectedSounds,
      selectedReminderSounds: const {},
      silentModeSettings: silentModeSettings,
      ramadan: ramadan,
      alarmStream: alarmStream,
    );
    return {
      for (final a in ezans)
        if (a.payload != null && a.time.isBefore(now) && !a.time.isBefore(from))
          a.id: a,
    };
  }

  /// Kurulan ezanın kaydı: saat + ayarlar (ses, sessiz, alarm akışı, dil, gün).
  /// Gövde yok: tam zamanlı/gecikmeli kip sadece metni değiştirir, ezan aynıdır.
  static String alarmFingerprint(PlannedAlarm a) => [
    a.time.millisecondsSinceEpoch,
    a.title,
    a.sound,
    a.channelName,
    a.alarmStream,
    a.payload,
  ].join('|');

  // Okunamazsa boş: hiçbir geç ezan korunmaz (eski davranış, çift çalma olmaz)
  static Map<int, String> _loadPlanMeta(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(planMetaKey);
      if (raw == null) return {};
      return Map<String, dynamic>.from(
        jsonDecode(raw),
      ).map((k, v) => MapEntry(int.parse(k), v as String));
    } catch (e) {
      return {};
    }
  }

  static bool _isRamadanDay(RamadanCalendar? ramadan, DateTime date) {
    if (ramadan == null) return false;
    try {
      return ramadan.dayOf(date) != null;
    } catch (e) {
      return false;
    }
  }

  /// Diyanet Ramazan takvimi (bir kez okunur); okunamazsa hijri hesabı
  static Future<RamadanCalendar> _ramadanCalendar() async {
    try {
      return await loadRamadanCalendar().timeout(const Duration(seconds: 5));
    } catch (e) {
      return RamadanCalendar.hijriOnly;
    }
  }

  /// "Vakit çıkmadan hatırlat" planı (ID 100-124). [days][0] bugün, [previous] dünün
  /// vakitleri (dünkü yatsının süresi için). Hatırlatma günü d: dünkü yatsı (d'nin
  /// imsakında biter), sabah (güneşte), öğle (ikindide), ikindi (akşamda), akşam (yatsıda).
  /// Geçmiş, [minutes] >= vakit süresi veya kılındı işaretli vakitler atlanır.
  /// [exact] false: "çıkmasına X dakika kaldı" yerine çıkış saati ([buildAlarmPlan]).
  static List<PlannedAlarm> buildEndReminderPlan({
    required PrayerTimesModel previous,
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
    required int minutes,
    required Map<String, int> prayerLog,
    bool exact = true,
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
            title: exact ? loc.endReminderNotifTitle : loc.endReminderTitleAt,
            body: exact
                ? loc.endReminderNotifBody(names[key]!, minutes)
                : loc.endReminderNotifBodyAt(
                    names[key]!,
                    formatClockTime(end, loc.localeName),
                  ),
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
  /// Ayar kapalıysa hepsi iptal edilir. Hata fırlatmaz (Crashlytics'e bildirilir).
  Future<void> syncEndReminders({
    required PrayerTimesModel todayTimes,
    required AppLocalizations loc,
  }) => _serializeAlarms(() async {
    final now = _clock();
    try {
      final exact = await _exactMode();
      final planDays = await _planDays(todayTimes, now);
      await _syncEndReminders(
        previous: planDays.previous,
        days: planDays.reminderDays,
        now: now,
        loc: loc,
        exact: exact,
      );
    } catch (e, st) {
      await reportNonFatal(
        e,
        st,
        reason: 'vakit çıkış hatırlatmaları eşitlenemedi',
      );
    }
  });

  /// Plan boşsa ya da en az bir hatırlatma kurulduysa (ve iptaller yapılabildiyse) true
  Future<bool> _syncEndReminders({
    required PrayerTimesModel previous,
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AppLocalizations loc,
    required bool exact,
  }) => PrayerTrackerService.runExclusive(() async {
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
          exact: exact,
        );
      }
    } catch (e, st) {
      await reportNonFatal(e, st, reason: 'vakit çıkış planı okunamadı');
      return false;
    }
    final failures = _AlarmFailures();
    final cleanupOk = await _cancelUnplanned(
      PrayerTracker.isEndReminderId,
      plan.map((a) => a.id).toSet(),
      failures,
    );
    int succeeded = 0;
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
      } catch (e, st) {
        failures.add(e, st);
      }
    }
    // Bu arada bildirimden "Kıldım" denmiş olabilir (ayrı isolate): o vaktin
    // yeniden kurulan hatırlatması iptal edilir
    var recheckOk = true;
    if (plan.isNotEmpty) {
      try {
        final fresh = await _storageService.loadPrayerLog();
        for (final alarm in plan) {
          final target = PrayerTracker.parsePayload(alarm.payload);
          if (target != null &&
              PrayerTracker.isPrayed(fresh, target.date, target.key)) {
            await _notifications.cancel(alarm.id);
          }
        }
      } catch (e, st) {
        recheckOk = false;
        failures.add(e, st);
      }
    }
    await failures.report('vakit çıkış hatırlatması', plan.length);
    return cleanupOk && recheckOk && (plan.isEmpty || succeeded > 0);
  });

  // Plandan çıkan bekleyen (henüz çalmamış) bildirimler iptal edilir; çekmecedekilere
  // dokunulmaz. [keep]: aynı yükle bekleyen geç ezan (ID → yük) iptal edilmez.
  // false: temizlik tamamlanamadı (gün kaydedilmez, yeniden denenir).
  // Okuma hatası kurulumu engellemez.
  Future<bool> _cancelUnplanned(
    bool Function(int id) inRange,
    Set<int> plannedIds,
    _AlarmFailures failures, {
    Map<int, String> keep = const {},
  }) async {
    final Map<int, String?> pending;
    try {
      pending = await _notifications.pendingPayloads();
    } catch (e, st) {
      failures.add(e, st);
      return false;
    }
    var ok = true;
    for (final MapEntry(key: id, value: payload) in pending.entries) {
      if (!inRange(id) || plannedIds.contains(id)) continue;
      if (keep[id] != null && keep[id] == payload) continue;
      try {
        await _notifications.cancel(id);
      } catch (e, st) {
        ok = false;
        failures.add(e, st);
      }
    }
    return ok;
  }

  // Kurulumdan önce izin okunur (kip buna göre); okunamazsa son bilinen. false değilse
  // tam zamanlı kabul edilir (metinler göreli kalır)
  Future<bool> _exactMode() async =>
      (await _notifications.refreshExactAlarmPermission() ??
          await NotificationService.lastKnownExactAllowed()) !=
      false;

  // Uygulama içinde alarm kurma işleri üst üste binmez (iptal/kur sırası karışmasın).
  // Arka plan görevi ayrı isolate'tedir.
  static final SerialQueue _alarmQueue = SerialQueue();

  static Future<T> _serializeAlarms<T>(Future<T> Function() action) =>
      _alarmQueue.run(action);

  /// Ezan/hatırlatma alarmlarını kurar. Koordinat varsa 5 gün (uygulama açılmasa da ezan gelir),
  /// yoksa sadece [todayTimes] ile 1 gün.
  /// Toplu iptal yok: aynı ID'nin üzerine yazılır, sadece plandan çıkan bekleyen (henüz
  /// çalmamış) alarmlar iptal edilir → ekrandaki ezan bildirimi ve "Kıldım" butonu silinmez,
  /// alarmda boşluk olmaz. Tam zamanlı alarm izni yoksa gecikmeli kiple kurulur; vakti
  /// geçip henüz çalmamış (gecikmiş) ezan korunur ([recentlyDueEzans]).
  /// Kurulamayan alarm diğerlerini durdurmaz; tur sonunda Crashlytics'e bildirilir.
  Future<void> rescheduleAlarms({
    required PrayerTimesModel todayTimes,
    required AppLocalizations loc,
    required Map<String, bool> onTimeAlarms,
    required Map<String, bool> reminderAlarms,
    required Map<String, String> selectedSounds,
    required Map<String, String> selectedReminderSounds,
    required Map<String, bool> silentModeSettings,
    bool alarmStream = false,
  }) => _serializeAlarms(() async {
    final now = _clock();
    final exact = await _exactMode();
    final planDays = await _planDays(todayTimes, now);
    final ramadan = await _ramadanCalendar();
    final plan = buildAlarmPlan(
      days: planDays.days,
      now: now,
      loc: loc,
      onTimeAlarms: onTimeAlarms,
      reminderAlarms: reminderAlarms,
      selectedSounds: selectedSounds,
      selectedReminderSounds: selectedReminderSounds,
      silentModeSettings: silentModeSettings,
      ramadan: ramadan,
      alarmStream: alarmStream,
      exact: exact,
    );

    // Geç ezan sadece kurulduğu saat ve ayarlar bugün de aynıysa korunur (ince ayar,
    // konum, ses, dil değiştiyse eskisi geç çalmasın; kayıt yoksa korunmaz)
    final prefs = await SharedPreferences.getInstance();
    final savedMeta = _loadPlanMeta(prefs);
    final keep = <int, String>{
      for (final MapEntry(key: id, value: alarm) in recentlyDueEzans(
        previous: planDays.previous,
        today: planDays.days.first,
        now: now,
        loc: loc,
        onTimeAlarms: onTimeAlarms,
        selectedSounds: selectedSounds,
        silentModeSettings: silentModeSettings,
        ramadan: ramadan,
        alarmStream: alarmStream,
      ).entries)
        if (savedMeta[id] == alarmFingerprint(alarm)) id: alarm.payload!,
    };

    final failures = _AlarmFailures();
    final cleanupOk = await _cancelUnplanned(
      (id) => id >= 0 && id < alarmIdCount,
      plan.map((a) => a.id).toSet(),
      failures,
      keep: keep,
    );

    final meta = {for (final id in keep.keys) '$id': savedMeta[id]!};
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
          alarmStream: alarm.alarmStream,
        );
        succeeded++;
        if (alarm.payload != null) {
          meta['${alarm.id}'] = alarmFingerprint(alarm);
        }
      } catch (e, st) {
        failures.add(e, st);
      }
    }
    try {
      await prefs.setString(planMetaKey, jsonEncode(meta));
    } catch (e, st) {
      failures.add(e, st);
    }
    await failures.report('ezan alarmı', plan.length);

    final remindersOk = await _syncEndReminders(
      previous: planDays.previous,
      days: planDays.reminderDays,
      now: now,
      loc: loc,
      exact: exact,
    );

    // Hiçbiri kurulamadıysa (ya da iptaller yapılamadıysa) tarih yazılmaz: arka plan
    // görevi aynı gün yeniden dener
    if ((plan.isEmpty || succeeded > 0) && remindersOk && cleanupOk) {
      await prefs.setString(_alarmsDateKey, _dateKey(now));
    }
  });

  /// Günlük ayet (10:00, ID 1000) ve hadis (19:00, ID 1900) bildirimi.
  /// Biri kurulamazsa diğeri yine kurulur; hata Crashlytics'e bildirilir.
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
      try {
        await _notifications.scheduleDailyContent(
          id: 1000,
          title: title,
          body: content,
          hour: 10,
          minute: 0,
          channelId: 'daily_ayah_channel',
          channelName: 'Günlük Ayet',
        );
      } catch (e, st) {
        await reportNonFatal(e, st, reason: 'günün ayeti bildirimi kurulamadı');
      }
    }
    if (hadith != null && hadith.content != null) {
      String title = localeName.startsWith('tr')
          ? "Günün Hadisi"
          : "Hadith of the Day";
      try {
        await _notifications.scheduleDailyContent(
          id: 1900,
          title: title,
          body: hadith.content!,
          hour: 19,
          minute: 0,
          channelId: 'daily_hadith_channel',
          channelName: 'Günlük Hadis',
        );
      } catch (e, st) {
        await reportNonFatal(
          e,
          st,
          reason: 'günün hadisi bildirimi kurulamadı',
        );
      }
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
  /// beklenmeyen hatada false döner (WorkManager yeniden dener). [clock] sadece testte.
  static Future<bool> runHeadless({DateTime Function()? clock}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs
          .reload(); // uygulama süreci açıksa diğer isolate'in yazdıkları

      final service = PrayerRefreshService(NotificationService(), clock: clock);
      final now = service._clock();
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
      // Tam zamanlı alarm izni değiştiyse (açıldı/kapatıldı) alarmlar aynı gün de
      // yeni kiple yeniden kurulur (izin kapatılınca sistem kurulu alarmları siler)
      final exactBefore = prefs.getBool(
        NotificationService.exactAlarmsAllowedKey,
      );
      final exactNow = await service._notifications
          .refreshExactAlarmPermission();
      final permissionChanged =
          exactBefore != null && exactNow != null && exactBefore != exactNow;
      if (prefs.getString(_alarmsDateKey) != _dateKey(now) ||
          permissionChanged) {
        final settings = await service._storageService.loadSettings();
        await service.rescheduleAlarms(
          todayTimes: times,
          loc: loc,
          onTimeAlarms: settings['onTime'],
          reminderAlarms: settings['reminder'],
          selectedSounds: settings['sounds'],
          selectedReminderSounds: settings['reminderSounds'],
          silentModeSettings: settings['silentMode'],
          alarmStream: settings['alarmStream'] == true,
        );
      }
      await service._topUpDailyContent(loc);
      return true;
    } catch (e, st) {
      await reportNonFatal(e, st, reason: 'arka plan yenilemesi başarısız');
      return false;
    }
  }
}

/// Bir kurulum turundaki hatalar: tek tek yutulmaz, tur sonunda tek kayıtla
/// Crashlytics'e bildirilir (her alarm için ayrı kayıt gürültü olur)
class _AlarmFailures {
  int count = 0;
  Object? _first;
  StackTrace? _firstStack;

  void add(Object error, StackTrace stack) {
    count++;
    _first ??= error;
    _firstStack ??= stack;
  }

  Future<void> report(String what, int planned) async {
    final first = _first;
    if (first == null) return;
    await reportNonFatal(
      first,
      _firstStack,
      reason: '$what kurulumu: $count hata, $planned planlı',
    );
  }
}
