import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final loc = lookupAppLocalizations(const Locale('tr'));
  // Saat diliminden bağımsız olsun diye sabit vakitler
  final day = PrayerTimesModel(
    imsak: '05:00',
    gunes: '06:30',
    ogle: '13:00',
    ikindi: '16:30',
    aksam: '19:00',
    yatsi: '20:30',
  );
  Map<String, bool> all(bool value) => {
    for (final key in PrayerRefreshService.vakitKeys) key: value,
  };

  List<PlannedAlarm> plan({
    required int dayCount,
    required DateTime now,
    bool reminders = true,
    bool silent = false,
    RamadanCalendar? ramadan,
  }) => PrayerRefreshService.buildAlarmPlan(
    days: List.filled(dayCount, day),
    now: now,
    loc: loc,
    onTimeAlarms: all(true),
    reminderAlarms: all(reminders),
    selectedSounds: const {'Öğle': 'ezan3'},
    selectedReminderSounds: const {},
    silentModeSettings: all(silent),
    ramadan: ramadan,
  );

  test('Hicri tarih tüm uygulama dillerinde hata vermez', () {
    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      expect(PrayerRefreshService.hijriDateText(lang), isNotEmpty);
    }
  });

  test('5 günlük plan: gece yarısından sonra 60 alarm, ID 0-59', () {
    final alarms = plan(dayCount: 5, now: DateTime(2026, 3, 10, 0, 1));
    expect(alarms.map((a) => a.id).toList(), List.generate(60, (i) => i));

    // 2. günün öğlesi: 12 + 2*2 = 16
    final ogle = alarms.firstWhere((a) => a.id == 16);
    expect(ogle.time, DateTime(2026, 3, 11, 13, 0));
    expect(ogle.sound, 'ezan3');
    expect(ogle.channelName, loc.channelSoundPrefix('ezan3'));
    expect(ogle.body, loc.notifBodyTime(loc.ogle));

    // Hatırlatma: İmsak/Güneş 30 dk, diğerleri 15 dk önce
    expect(
      alarms.firstWhere((a) => a.id == 1).time,
      DateTime(2026, 3, 10, 4, 30),
    );
    final ogleReminder = alarms.firstWhere((a) => a.id == 5);
    expect(ogleReminder.time, DateTime(2026, 3, 10, 12, 45));
    expect(ogleReminder.sound, 'bildirim1');
    expect(ogleReminder.body, loc.notifBodyUpcoming(loc.ogle, 15));
  });

  test('Geçmiş vakit kurulmaz, ID yerleri sabit kalır', () {
    final alarms = plan(dayCount: 5, now: DateTime(2026, 3, 10, 12, 50));
    final ids = alarms.map((a) => a.id).toSet();
    // imsak, güneş ve öğle hatırlatması (12:45) geçti
    for (final id in [0, 1, 2, 3, 5]) {
      expect(ids.contains(id), isFalse, reason: 'ID $id');
    }
    expect(ids.contains(4), isTrue); // öğle (13:00)
    expect(ids.contains(12), isTrue); // yarının imsakı
    expect(alarms.length, 60 - 5);
  });

  test('Koordinatsız tek gün: geçmiş vakit yarına kayar', () {
    final alarms = plan(
      dayCount: 1,
      now: DateTime(2026, 3, 10, 12, 0),
      reminders: false,
    );
    expect(alarms.map((a) => a.id).toList(), [0, 2, 4, 6, 8, 10]);
    expect(alarms.first.time, DateTime(2026, 3, 11, 5, 0));
    expect(alarms[2].time, DateTime(2026, 3, 10, 13, 0));
  });

  test('Sessiz mod: ses yok, sessiz kanal', () {
    final alarms = plan(
      dayCount: 1,
      now: DateTime(2026, 3, 10, 0, 1),
      reminders: false,
      silent: true,
    );
    expect(alarms.every((a) => a.sound == null), isTrue);
    expect(alarms.first.channelName, loc.channelSilentPrayers);
  });

  test('Ezan bildiriminde "Kıldım" (Güneş ve hatırlatma hariç), doğru gün', () {
    final alarms = plan(dayCount: 5, now: DateTime(2026, 3, 10, 0, 1));
    PlannedAlarm byId(int id) => alarms.firstWhere((a) => a.id == id);
    expect(byId(0).payload, 'prayed|2026-03-10|İmsak');
    expect(byId(0).actionLabel, loc.trackerPrayedAction);
    expect(byId(1).payload, isNull); // vakit yaklaşıyor hatırlatması
    expect(byId(2).payload, isNull); // güneş
    expect(byId(2).actionLabel, isNull);
    expect(byId(12 + 10).payload, 'prayed|2026-03-11|Yatsı');

    // Tek gün modunda yarına kayan vakit yarının tarihini taşır
    final single = plan(
      dayCount: 1,
      now: DateTime(2026, 3, 10, 12, 0),
      reminders: false,
    );
    expect(single.first.payload, 'prayed|2026-03-11|İmsak');
    expect(single[2].payload, 'prayed|2026-03-10|Öğle');
  });

  group('Vakit çıkmadan hatırlatma planı', () {
    final previous = PrayerTimesModel(
      imsak: '05:01',
      gunes: '06:31',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: '18:59',
      yatsi: '20:28',
    );
    final d0 = DateTime(2026, 3, 10);
    String payload(DateTime date, String key) =>
        PrayerTracker.payload(date, key);

    List<PlannedAlarm> endPlan({
      required DateTime now,
      int minutes = 30,
      Map<String, int> log = const {},
      PrayerTimesModel? times,
    }) => PrayerRefreshService.buildEndReminderPlan(
      previous: previous,
      days: List.filled(5, times ?? day),
      now: now,
      loc: loc,
      minutes: minutes,
      prayerLog: log,
    );

    test('ID 100-124; bitiş: sabah→güneş, öğle→ikindi, ikindi→akşam, '
        'akşam→yatsı, yatsı→ertesi imsak', () {
      final now = DateTime(2026, 3, 10, 0, 1);
      final alarms = endPlan(now: now);
      expect(alarms.length, 25);
      expect(alarms.map((a) => a.id).toSet().length, 25);
      expect(alarms.every((a) => a.id >= 100 && a.id <= 124), isTrue);

      PlannedAlarm find(DateTime date, String key) =>
          alarms.singleWhere((a) => a.payload == payload(date, key));
      expect(find(d0, 'İmsak').time, DateTime(2026, 3, 10, 6, 0));
      expect(find(d0, 'Öğle').time, DateTime(2026, 3, 10, 16, 0));
      expect(find(d0, 'İkindi').time, DateTime(2026, 3, 10, 18, 30));
      expect(find(d0, 'Akşam').time, DateTime(2026, 3, 10, 20, 0));
      // Bugünün yatsısı yarın imsakta biter
      expect(find(d0, 'Yatsı').time, DateTime(2026, 3, 11, 4, 30));
      // Dünün yatsısı bugün imsakta biter
      expect(find(DateTime(2026, 3, 9), 'Yatsı').time, DateTime(2026, 3, 10, 4, 30));
      // 5. günün yatsısı 6. güne ait, sonraki planda kurulur
      expect(
        alarms.where((a) => a.payload == payload(DateTime(2026, 3, 14), 'Yatsı')),
        isEmpty,
      );

      // Kılındı işaretlenince iptal edilen ID, kurulan ID ile aynı
      for (final a in alarms) {
        final target = PrayerTracker.parsePayload(a.payload)!;
        expect(
          PrayerTracker.endReminderIdToCancel(target.date, target.key, now),
          a.id,
        );
      }

      final ogle = find(d0, 'Öğle');
      expect(ogle.title, loc.endReminderNotifTitle);
      expect(ogle.body, loc.endReminderNotifBody(loc.ogle, 30));
      expect(ogle.channelName, loc.endReminderChannel);
      expect(ogle.actionLabel, loc.trackerPrayedAction);
      expect(find(d0, 'İmsak').body, loc.endReminderNotifBody(loc.sabah, 30));
    });

    test('Geçmiş, kılınmış ve süreden uzun hatırlatmalar atlanır', () {
      final alarms = endPlan(
        now: DateTime(2026, 3, 10, 16, 5),
        log: {PrayerTracker.dateKey(d0): PrayerTracker.bit('İkindi')},
      );
      final payloads = alarms.map((a) => a.payload).toSet();
      expect(payloads.contains(payload(DateTime(2026, 3, 9), 'Yatsı')), isFalse);
      expect(payloads.contains(payload(d0, 'İmsak')), isFalse);
      expect(payloads.contains(payload(d0, 'Öğle')), isFalse); // 16:00 geçti
      expect(payloads.contains(payload(d0, 'İkindi')), isFalse); // kılındı
      expect(payloads.contains(payload(d0, 'Akşam')), isTrue);
      expect(alarms.length, 1 + 4 * 5);

      // Sabah 30 dk sürüyor: 30 dk önce hatırlatma kurulmaz, 15 dk kurulur
      final shortFajr = PrayerTimesModel(
        imsak: '06:00',
        gunes: '06:30',
        ogle: '13:00',
        ikindi: '16:30',
        aksam: '19:00',
        yatsi: '20:30',
      );
      final now = DateTime(2026, 3, 10, 0, 1);
      bool hasFajr(List<PlannedAlarm> p) =>
          p.any((a) => a.payload!.endsWith('|İmsak'));
      expect(hasFajr(endPlan(now: now, times: shortFajr)), isFalse);
      final fifteen = endPlan(now: now, times: shortFajr, minutes: 15);
      expect(fifteen.where((a) => a.payload!.endsWith('|İmsak')).length, 5);
      expect(
        fifteen.firstWhere((a) => a.payload == payload(d0, 'İmsak')).time,
        DateTime(2026, 3, 10, 6, 15),
      );
    });

    test('Farklı günlerde kurulan planlar aynı hatırlatmaya aynı ID verir', () {
      final first = {
        for (final a in endPlan(now: DateTime(2026, 3, 10, 0, 1)))
          a.payload: a.id,
      };
      int shared = 0;
      for (final a in endPlan(now: DateTime(2026, 3, 11, 0, 1))) {
        if (first.containsKey(a.payload)) {
          expect(a.id, first[a.payload], reason: a.payload);
          shared++;
        }
      }
      expect(shared, 4 * 5);
    });
  });

  group('Ramazan ezan metinleri', () {
    // Diyanet 1447: 19 Şubat - 19 Mart 2026, bayram 20 Mart
    final calendar = RamadanCalendar.fromReligiousDays([
      {'name': 'Ramazan Başlangıcı', 'date': '19 Şubat 2026'},
      {'name': 'Ramazan Bayramı 1. Gün', 'date': '20 Mart 2026'},
    ]);
    final now = DateTime(2026, 3, 18, 0, 1); // 18-19 Mart Ramazan, 20-22 değil

    test('Ramazan gününde imsak sahur, akşam iftar metni; diğer günler normal', () {
      final alarms = plan(dayCount: 5, now: now, ramadan: calendar);
      PlannedAlarm byId(int id) => alarms.firstWhere((a) => a.id == id);
      for (final day in [0, 1]) {
        final imsak = byId(12 * day);
        expect(imsak.title, loc.ramadanImsakTitle);
        expect(imsak.body, loc.ramadanImsakBody);
        final aksam = byId(12 * day + 8);
        expect(aksam.title, loc.ramadanIftarTitle);
        expect(aksam.body, loc.ramadanIftarBody(loc.aksam));
        // Diğer vakitler değişmez
        expect(byId(12 * day + 4).body, loc.notifBodyTime(loc.ogle));
        expect(byId(12 * day + 10).body, loc.notifBodyTime(loc.yatsi));
      }
      for (final day in [2, 3, 4]) {
        expect(byId(12 * day).title, loc.notifTitleTime);
        expect(byId(12 * day).body, loc.notifBodyTime(loc.imsak));
        expect(byId(12 * day + 8).body, loc.notifBodyTime(loc.aksam));
      }
    });

    test('Sadece başlık/metin değişir: ID, saat, ses, kanal, Kıldım aynı', () {
      final normal = plan(dayCount: 5, now: now);
      final ramadan = plan(dayCount: 5, now: now, ramadan: calendar);
      expect(ramadan.length, normal.length);
      int changed = 0;
      for (int i = 0; i < normal.length; i++) {
        final a = normal[i];
        final b = ramadan[i];
        expect(
          (b.id, b.time, b.sound, b.channelName, b.payload, b.actionLabel),
          (a.id, a.time, a.sound, a.channelName, a.payload, a.actionLabel),
        );
        if (a.title != b.title || a.body != b.body) changed++;
      }
      expect(changed, 4); // 2 gün x (imsak + akşam)
      // Takvim verilmezse (ya da Ramazan dışı) metinler normal
      expect(
        normal.firstWhere((a) => a.id == 8).body,
        loc.notifBodyTime(loc.aksam),
      );
    });

    test('Tek gün modunda yarına kayan imsak yarının gününe göre', () {
      // 19 Mart öğlen: yarının (20 Mart, bayram) imsakı normal, bugünün akşamı iftar
      final alarms = plan(
        dayCount: 1,
        now: DateTime(2026, 3, 19, 12, 0),
        reminders: false,
        ramadan: calendar,
      );
      expect(alarms.first.time, DateTime(2026, 3, 20, 5, 0));
      expect(alarms.first.body, loc.notifBodyTime(loc.imsak));
      final aksam = alarms.firstWhere((a) => a.id == 8);
      expect(aksam.time, DateTime(2026, 3, 19, 19, 0));
      expect(aksam.title, loc.ramadanIftarTitle);
    });

    test('Ramazan dışında hijri yedeği de normal metin verir', () {
      final alarms = plan(
        dayCount: 5,
        now: DateTime(2026, 6, 10, 0, 1),
        ramadan: RamadanCalendar.hijriOnly,
      );
      expect(alarms.where((a) => a.title != loc.notifTitleTime &&
          a.title != loc.notifTitleUpcoming), isEmpty);
    });
  });
}
