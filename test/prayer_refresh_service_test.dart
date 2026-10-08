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
  // Vakit sırası: İmsak 0, Güneş 1, Öğle 2, İkindi 3, Akşam 4, Yatsı 5
  int id(DateTime date, int vakit, {bool reminder = false}) =>
      PrayerRefreshService.alarmId(date, vakit, reminder: reminder);
  final d0 = DateTime(2026, 3, 10);
  final d1 = DateTime(2026, 3, 11);

  List<PlannedAlarm> plan({
    required int dayCount,
    required DateTime now,
    bool reminders = true,
    bool silent = false,
    RamadanCalendar? ramadan,
    bool exact = true,
    AppLocalizations? l10n,
  }) => PrayerRefreshService.buildAlarmPlan(
    days: List.filled(dayCount, day),
    now: now,
    loc: l10n ?? loc,
    onTimeAlarms: all(true),
    reminderAlarms: all(reminders),
    selectedSounds: const {'Öğle': 'ezan3'},
    selectedReminderSounds: const {},
    silentModeSettings: all(silent),
    ramadan: ramadan,
    exact: exact,
  );

  test('Hicri tarih tüm uygulama dillerinde hata vermez', () {
    for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
      expect(PrayerRefreshService.hijriDateText(lang), isNotEmpty);
    }
  });

  test('5 günlük plan: gece yarısından sonra 60 alarm, ID tarihe bağlı', () {
    final alarms = plan(dayCount: 5, now: DateTime(2026, 3, 10, 0, 1));
    expect(alarms.map((a) => a.id).toList(), [
      for (int day = 0; day < 5; day++)
        for (int vakit = 0; vakit < 6; vakit++) ...[
          id(PrayerTracker.addDays(d0, day), vakit),
          id(PrayerTracker.addDays(d0, day), vakit, reminder: true),
        ],
    ]);
    expect(alarms.map((a) => a.id).toSet().length, 60);
    expect(
      alarms.every((a) => a.id < PrayerRefreshService.alarmIdCount),
      isTrue,
    );

    // 2. günün öğlesi
    final ogle = alarms.firstWhere((a) => a.id == id(d1, 2));
    expect(ogle.time, DateTime(2026, 3, 11, 13, 0));
    expect(ogle.sound, 'ezan3');
    expect(ogle.channelName, loc.channelSoundPrefix('ezan3'));
    expect(ogle.body, loc.notifBodyTime(loc.ogle));

    // Hatırlatma: İmsak/Güneş 30 dk, diğerleri 15 dk önce
    expect(
      alarms.firstWhere((a) => a.id == id(d0, 0, reminder: true)).time,
      DateTime(2026, 3, 10, 4, 30),
    );
    final ogleReminder = alarms.firstWhere(
      (a) => a.id == id(d0, 2, reminder: true),
    );
    expect(ogleReminder.time, DateTime(2026, 3, 10, 12, 45));
    expect(ogleReminder.sound, 'bildirim1');
    expect(ogleReminder.body, loc.notifBodyUpcoming(loc.ogle, 15));
  });

  test('Geçmiş vakit kurulmaz, ID yerleri sabit kalır', () {
    final alarms = plan(dayCount: 5, now: DateTime(2026, 3, 10, 12, 50));
    final ids = alarms.map((a) => a.id).toSet();
    // imsak, güneş ve öğle hatırlatması (12:45) geçti
    for (final past in [
      id(d0, 0),
      id(d0, 0, reminder: true),
      id(d0, 1),
      id(d0, 1, reminder: true),
      id(d0, 2, reminder: true),
    ]) {
      expect(ids.contains(past), isFalse, reason: 'ID $past');
    }
    expect(ids.contains(id(d0, 2)), isTrue); // öğle (13:00)
    expect(ids.contains(id(d1, 0)), isTrue); // yarının imsakı
    expect(alarms.length, 60 - 5);
  });

  test('Koordinatsız tek gün: geçmiş vakit yarına (yarının ID\'siyle) kayar', () {
    final alarms = plan(
      dayCount: 1,
      now: DateTime(2026, 3, 10, 12, 0),
      reminders: false,
    );
    expect(alarms.map((a) => a.id).toList(), [
      id(d1, 0),
      id(d1, 1),
      id(d0, 2),
      id(d0, 3),
      id(d0, 4),
      id(d0, 5),
    ]);
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
    expect(byId(id(d0, 0)).payload, 'prayed|2026-03-10|İmsak');
    expect(byId(id(d0, 0)).actionLabel, loc.trackerPrayedAction);
    // vakit yaklaşıyor hatırlatması
    expect(byId(id(d0, 0, reminder: true)).payload, isNull);
    expect(byId(id(d0, 1)).payload, isNull); // güneş
    expect(byId(id(d0, 1)).actionLabel, isNull);
    expect(byId(id(d1, 5)).payload, 'prayed|2026-03-11|Yatsı');

    // Tek gün modunda yarına kayan vakit yarının tarihini taşır
    final single = plan(
      dayCount: 1,
      now: DateTime(2026, 3, 10, 12, 0),
      reminders: false,
    );
    expect(single.first.payload, 'prayed|2026-03-11|İmsak');
    expect(single[2].payload, 'prayed|2026-03-10|Öğle');
  });

  test('ID tarihe bağlı: farklı günlerde kurulan planlar aynı vakte aynı ID '
      'verir; 6 gün çakışmasız', () {
    final first = plan(dayCount: 5, now: DateTime(2026, 3, 10, 0, 1));
    final second = plan(dayCount: 5, now: DateTime(2026, 3, 11, 0, 1));
    final byTime = {for (final a in first) (a.time, a.id.isOdd): a.id};
    int shared = 0;
    for (final a in second) {
      final previous = byTime[(a.time, a.id.isOdd)];
      if (previous != null) {
        expect(a.id, previous, reason: '${a.time}');
        shared++;
      }
    }
    expect(shared, 4 * 12);
    // Dün + 5 günlük plan: 72 ID'nin hepsi farklı
    final ids = {
      for (int day = -1; day < 5; day++)
        for (int vakit = 0; vakit < 6; vakit++)
          for (final reminder in [false, true])
            id(PrayerTracker.addDays(d0, day), vakit, reminder: reminder),
    };
    expect(ids.length, PrayerRefreshService.alarmIdCount);
  });

  group('Geç kalan ezan (gecikmeli kip): korunacaklar', () {
    final previous = PrayerTimesModel(
      imsak: '05:01',
      gunes: '06:31',
      ogle: '13:00',
      ikindi: '16:30',
      aksam: '18:59',
      yatsi: '23:30',
    );
    Map<int, String> due(DateTime now, {Map<String, bool>? onTime}) =>
        PrayerRefreshService.recentlyDueEzans(
          previous: previous,
          today: day,
          now: now,
          onTimeAlarms: onTime ?? all(true),
        );

    test('son 90 dk içinde vakti girmiş açık farz ezanı: ID → yük', () {
      expect(due(DateTime(2026, 3, 10, 13, 5)), {
        id(d0, 2): PrayerTracker.payload(d0, 'Öğle'),
      });
      // Pencere sınırları; vakit tam şimdi ise plandadır (korunacak değil)
      expect(due(DateTime(2026, 3, 10, 14, 30)).keys, [id(d0, 2)]);
      expect(due(DateTime(2026, 3, 10, 14, 31)), isEmpty);
      expect(due(DateTime(2026, 3, 10, 13, 0)), isEmpty);
    });

    test('gece yarısından sonra dünün yatsısı (dünün ID\'si)', () {
      final yesterday = DateTime(2026, 3, 9);
      expect(due(DateTime(2026, 3, 10, 0, 20)), {
        id(yesterday, 5): PrayerTracker.payload(yesterday, 'Yatsı'),
      });
    });

    test('kapalı vakit ve Güneş korunmaz', () {
      final now = DateTime(2026, 3, 10, 13, 5);
      expect(due(now, onTime: {...all(true), 'Öğle': false}), isEmpty);
      expect(due(DateTime(2026, 3, 10, 6, 45)), isEmpty); // güneş 06:30
    });
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
    String payload(DateTime date, String key) =>
        PrayerTracker.payload(date, key);

    List<PlannedAlarm> endPlan({
      required DateTime now,
      int minutes = 30,
      Map<String, int> log = const {},
      PrayerTimesModel? times,
      bool exact = true,
      AppLocalizations? l10n,
    }) => PrayerRefreshService.buildEndReminderPlan(
      previous: previous,
      days: List.filled(5, times ?? day),
      now: now,
      loc: l10n ?? loc,
      minutes: minutes,
      prayerLog: log,
      exact: exact,
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

    test('Gecikmeli kip: "çıkmasına X dk kaldı" yerine çıkış saati, nötr '
        'başlık; zaman, ID, Kıldım aynı', () {
      final now = DateTime(2026, 3, 10, 0, 1);
      final relative = endPlan(now: now);
      final absolute = endPlan(now: now, exact: false);
      expect(absolute.length, relative.length);
      for (int i = 0; i < relative.length; i++) {
        final a = relative[i];
        final b = absolute[i];
        expect(
          (b.id, b.time, b.payload, b.actionLabel, b.channelName),
          (a.id, a.time, a.payload, a.actionLabel, a.channelName),
        );
        expect(b.title, loc.endReminderTitleAt);
      }
      PlannedAlarm find(List<PlannedAlarm> p, String key) =>
          p.singleWhere((a) => a.payload == payload(d0, key));
      expect(
        find(absolute, 'Öğle').body,
        loc.endReminderNotifBodyAt(loc.ogle, '16:30'),
      );
      expect(
        find(absolute, 'İmsak').body,
        loc.endReminderNotifBodyAt(loc.sabah, '06:30'),
      );
      // Arapça: 12 saat
      final ar = lookupAppLocalizations(const Locale('ar'));
      expect(
        find(endPlan(now: now, exact: false, l10n: ar), 'Öğle').body,
        ar.endReminderNotifBodyAt(ar.ogle, '4:30 م'),
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
      PlannedAlarm byId(int day, int vakit) => alarms.firstWhere(
        (a) => a.id == id(PrayerTracker.addDays(now, day), vakit),
      );
      for (final day in [0, 1]) {
        final imsak = byId(day, 0);
        expect(imsak.title, loc.ramadanImsakTitle);
        expect(imsak.body, loc.ramadanImsakBody);
        final aksam = byId(day, 4);
        expect(aksam.title, loc.ramadanIftarTitle);
        expect(aksam.body, loc.ramadanIftarBody(loc.aksam));
        // Diğer vakitler değişmez
        expect(byId(day, 2).body, loc.notifBodyTime(loc.ogle));
        expect(byId(day, 5).body, loc.notifBodyTime(loc.yatsi));
      }
      for (final day in [2, 3, 4]) {
        expect(byId(day, 0).title, loc.notifTitleTime);
        expect(byId(day, 0).body, loc.notifBodyTime(loc.imsak));
        expect(byId(day, 4).body, loc.notifBodyTime(loc.aksam));
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
        normal.firstWhere((a) => a.id == id(now, 4)).body,
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
      final aksam = alarms.firstWhere(
        (a) => a.id == id(DateTime(2026, 3, 19), 4),
      );
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

  group('Gecikmeli kip (tam zamanlı izin yok) metinleri', () {
    final now = DateTime(2026, 3, 10, 0, 1);

    test('hatırlatma "X dakika kaldı" yerine vaktin saati, nötr başlık; '
        'ezanlar, zaman ve sesler aynı', () {
      final relative = plan(dayCount: 5, now: now);
      final absolute = plan(dayCount: 5, now: now, exact: false);
      expect(absolute.length, relative.length);
      for (int i = 0; i < relative.length; i++) {
        final a = relative[i];
        final b = absolute[i];
        expect(
          (b.id, b.time, b.sound, b.channelName, b.payload, b.alarmStream),
          (a.id, a.time, a.sound, a.channelName, a.payload, a.alarmStream),
        );
        if (a.id.isEven) {
          expect((b.title, b.body), (a.title, a.body)); // ezan
        } else {
          expect(b.title, loc.reminderTitleAt);
        }
      }
      PlannedAlarm byId(int id) => absolute.firstWhere((a) => a.id == id);
      expect(
        byId(id(d0, 0, reminder: true)).body,
        loc.notifBodyUpcomingAt(loc.imsak, '05:00'),
      );
      expect(
        byId(id(d0, 2, reminder: true)).body,
        loc.notifBodyUpcomingAt(loc.ogle, '13:00'),
      );
      // İngilizce: 12 saat
      final en = lookupAppLocalizations(const Locale('en'));
      final enPlan = plan(dayCount: 1, now: now, exact: false, l10n: en);
      expect(
        enPlan.firstWhere((a) => a.id == id(d0, 4, reminder: true)).body,
        en.notifBodyUpcomingAt(en.aksam, '7:00 PM'),
      );
    });

    test('Ramazan: sahur bitişi saatle; iftar metni aynı', () {
      final calendar = RamadanCalendar.fromReligiousDays([
        {'name': 'Ramazan Başlangıcı', 'date': '19 Şubat 2026'},
        {'name': 'Ramazan Bayramı 1. Gün', 'date': '20 Mart 2026'},
      ]);
      final alarms = plan(
        dayCount: 1,
        now: now,
        reminders: false,
        ramadan: calendar,
        exact: false,
      );
      final imsak = alarms.firstWhere((a) => a.id == id(d0, 0));
      expect(imsak.title, loc.ramadanImsakTitle);
      expect(imsak.body, loc.ramadanImsakBodyAt('05:00'));
      final aksam = alarms.firstWhere((a) => a.id == id(d0, 4));
      expect(aksam.body, loc.ramadanIftarBody(loc.aksam));
    });
  });
}
