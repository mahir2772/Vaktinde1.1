import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
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
  }) => PrayerRefreshService.buildAlarmPlan(
    days: List.filled(dayCount, day),
    now: now,
    loc: loc,
    onTimeAlarms: all(true),
    reminderAlarms: all(reminders),
    selectedSounds: const {'Öğle': 'ezan3'},
    selectedReminderSounds: const {},
    silentModeSettings: all(silent),
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
}
