import 'dart:convert';

import 'package:ezan_saati/core/ui/app_format.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/widget_service.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget/kalıcı bildirim verisi: gün dönümü için setin günü + yarının vakitleri.
// Anahtar adları Kotlin tarafıyla sözleşme (PrayerWidgetData.kt): değişirse orası da değişmeli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const homeWidget = MethodChannel('home_widget');
  const timeKeys = {
    'İmsak': 'imsak_time',
    'Güneş': 'gunes_time',
    'Öğle': 'ogle_time',
    'İkindi': 'ikindi_time',
    'Akşam': 'aksam_time',
    'Yatsı': 'yatsi_time',
  };
  const tomorrowKeys = {
    'İmsak': 'tomorrow_imsak_time',
    'Güneş': 'tomorrow_gunes_time',
    'Öğle': 'tomorrow_ogle_time',
    'İkindi': 'tomorrow_ikindi_time',
    'Akşam': 'tomorrow_aksam_time',
    'Yatsı': 'tomorrow_yatsi_time',
  };
  // Ekrandaki saat (Kotlin: PrayerWidgetData.displayTime): her vakit anahtarı + '_text'
  String textOf(String key) => '${key}_text';
  final tr = lookupAppLocalizations(const Locale('tr'));
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(homeWidget, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(homeWidget, null);
  });

  // Son yazılan değerler; null = anahtar silinir
  Map<String, Object?> saved() => {
    for (final c in calls.where((c) => c.method == 'saveWidgetData'))
      c.arguments['id'] as String: c.arguments['data'],
  };
  String two(int n) => n.toString().padLeft(2, '0');
  String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
  DateTime tomorrowOf(DateTime d) => DateTime(d.year, d.month, d.day + 1);
  final allMidnight = PrayerTimesModel(
    imsak: '00:00',
    gunes: '00:00',
    ogle: '00:00',
    ikindi: '00:00',
    aksam: '00:00',
    yatsi: '00:00',
  );

  Future<void> write(
    PrayerTimesModel times, {
    AppLocalizations? loc,
    String city = 'İstanbul',
  }) => PrayerRefreshService(NotificationService()).updateHomeWidget(
    times: times,
    loc: loc,
    city: city,
    district: 'Fatih',
    hijriDateText: 'bugün',
  );

  test(
    'Koordinat varsa setin günü, yarının vakitleri (ince ayarlı) ve hicri tarihi yazılır',
    () async {
      const offsets = {'İmsak': 2, 'Yatsı': -3};
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'time_offsets': jsonEncode(offsets),
      });
      final now = DateTime.now();
      final tomorrow = tomorrowOf(now);
      final service = PrayerTimeService();
      final today = service.calculate(41.0, 29.0, date: now, offsets: offsets);

      await write(today, loc: tr);

      final data = saved();
      expect(data['times_date'], dateKey(now));
      expect(data['imsak_time'], today.imsak);
      final expected = PrayerRefreshService.timesMap(
        service.calculate(41.0, 29.0, date: tomorrow, offsets: offsets),
      );
      for (final entry in tomorrowKeys.entries) {
        expect(data[entry.value], expected[entry.key], reason: entry.value);
        expect(data[entry.value], matches(RegExp(r'^\d\d:\d\d$')));
      }
      // İnce ayar yarına da uygulanır
      final raw = service.calculate(41.0, 29.0, date: tomorrow);
      expect(data['tomorrow_imsak_time'], isNot(raw.imsak));
      expect(
        data['tomorrow_hijri_date_text'],
        PrayerRefreshService.hijriDateText('tr', date: tomorrow),
      );
      expect(
        data['tomorrow_hijri_date_text'],
        isNot(PrayerRefreshService.hijriDateText('tr')),
      );
      expect(
        calls
            .where((c) => c.method == 'updateWidget')
            .map((c) => c.arguments['android'])
            .toSet(),
        {
          'VaktindeWidgetSmallProvider',
          'VaktindeWidgetLargeProvider',
          'VaktindeWidgetSmall2Provider',
          'VaktindeWidgetRamadanProvider',
          'VaktindeWidgetRingProvider',
          'VaktindeWidgetTrackerProvider',
          'NotificationUpdater',
        },
      );
    },
  );

  test('Ramazan widget\'ının tarihleri ve metinleri seçili dilde yazılır', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
    });
    final en = lookupAppLocalizations(const Locale('en'));
    await write(allMidnight, loc: en);

    final data = saved();
    final expected = WidgetService.ramadanData(
      now: DateTime.now(),
      calendar: await loadRamadanCalendar(),
      loc: en,
    );
    for (final entry in expected.entries) {
      expect(data[entry.key], entry.value, reason: entry.key);
    }
    for (final key in [
      'ramadan_start',
      'ramadan_end',
      'ramadan_next_start',
    ]) {
      expect(data[key], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')), reason: key);
    }
    // Tarih metni seçili dilde (intl tarih verisi yazmadan önce yüklenir)
    expect(data['ramadan_start_text'], isNot(contains('.')));
    expect(data['ramadan_title_iftar'], en.ramadanIftarLeft);
    expect(data['ramadan_day_text'], 'Ramadan · day %d');
    // Ramazan anahtarları widget'lar yenilenmeden önce yazılır
    final lastSave = calls.lastIndexWhere((c) => c.method == 'saveWidgetData');
    final firstUpdate = calls.indexWhere((c) => c.method == 'updateWidget');
    expect(lastSave, lessThan(firstUpdate));
  });

  test('Yatsıdan sonra hedef yarının gerçek imsakı', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
    });
    // Bugünün bütün vakitleri geçmiş
    await write(allMidnight, loc: tr);

    final data = saved();
    final imsak = (data['tomorrow_imsak_time'] as String).split(':');
    final tomorrow = tomorrowOf(DateTime.now());
    expect(
      data['target_time_ms'],
      DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        int.parse(imsak[0]),
        int.parse(imsak[1]),
      ).millisecondsSinceEpoch,
    );
    expect(data['title_text'], tr.toImsak);
  });

  test(
    'Koordinat yoksa yarının anahtarları silinir, gün yine yazılır',
    () async {
      SharedPreferences.setMockInitialValues({'saved_city': 'İstanbul'});
      await write(allMidnight, loc: tr);

      final data = saved();
      expect(data['times_date'], dateKey(DateTime.now()));
      for (final key in [
        ...tomorrowKeys.values,
        ...tomorrowKeys.values.map(textOf),
        'tomorrow_hijri_date_text',
      ]) {
        // Önceki konumdan kalan yarın verisi Kotlin'e ulaşmasın: açıkça silinir
        expect(data.containsKey(key), isTrue, reason: key);
        expect(data[key], isNull, reason: key);
      }
      // Eski davranış: bugünkü imsak saati, yarın
      final tomorrow = tomorrowOf(DateTime.now());
      expect(
        data['target_time_ms'],
        DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
        ).millisecondsSinceEpoch,
      );
    },
  );

  test(
    'Vakte kalan başlıkları yazılır (Kotlin sıradakini seçer); dil yoksa Türkçe',
    () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      Map<String, Object?> titles() => {
        for (final key in [
          'title_imsak',
          'title_gunes',
          'title_ogle',
          'title_ikindi',
          'title_aksam',
          'title_yatsi',
        ])
          key: saved()[key],
      };
      final de = lookupAppLocalizations(const Locale('de'));
      await write(allMidnight, loc: de);
      expect(titles(), {
        'title_imsak': de.toImsak,
        'title_gunes': de.toGunes,
        'title_ogle': de.toOgle,
        'title_ikindi': de.toIkindi,
        'title_aksam': de.toAksam,
        'title_yatsi': de.toYatsi,
      });
      // Eski anahtarlar da yazılmaya devam eder
      expect(saved()['title_text'], de.toImsak);
      expect(saved()['label_ogle'], de.ogle);

      calls.clear();
      await write(allMidnight);
      expect(titles(), {
        'title_imsak': 'İmsaka',
        'title_gunes': 'Güneşe',
        'title_ogle': 'Öğleye',
        'title_ikindi': 'İkindiye',
        'title_aksam': 'Akşama',
        'title_yatsi': 'Yatsıya',
      });
      expect(saved()['title_text'], 'İmsaka');
    },
  );

  test(
    'Saatin yazımı uygulama dilinde (en/ar 12 saat), hesap anahtarları "HH:mm"',
    () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      final now = DateTime.now();
      final service = PrayerTimeService();
      final today = service.calculate(41.0, 29.0, date: now);
      final todayMap = PrayerRefreshService.timesMap(today);
      final tomorrowMap = PrayerRefreshService.timesMap(
        service.calculate(41.0, 29.0, date: tomorrowOf(now)),
      );
      final patterns = {
        'en': RegExp(r'^([1-9]|1[0-2]):[0-5]\d (AM|PM)$'),
        'ar': RegExp(r'^([1-9]|1[0-2]):[0-5]\d (ص|م)$'),
        'tr': RegExp(r'^\d\d:\d\d$'),
        'de': RegExp(r'^\d\d:\d\d$'),
        'fr': RegExp(r'^\d\d:\d\d$'),
      };
      // Her dilde bütün yazımlar yazılır: dil değişince eski 12 saat metni kalmaz
      for (final MapEntry(key: dil, value: pattern) in patterns.entries) {
        calls.clear();
        await write(today, loc: lookupAppLocalizations(Locale(dil)));
        final data = saved();
        for (final MapEntry(key: vakit, value: key) in timeKeys.entries) {
          expect(data[key], todayMap[vakit], reason: '$dil $key');
          expect(data[key], matches(RegExp(r'^\d\d:\d\d$')), reason: key);
          expect(
            data[textOf(key)],
            formatPrayerTime(todayMap[vakit]!, dil),
            reason: '$dil $key',
          );
          expect(data[textOf(key)], matches(pattern), reason: '$dil $key');
        }
        for (final MapEntry(key: vakit, value: key) in tomorrowKeys.entries) {
          expect(data[key], tomorrowMap[vakit], reason: '$dil $key');
          expect(
            data[textOf(key)],
            formatPrayerTime(tomorrowMap[vakit]!, dil),
            reason: '$dil $key',
          );
        }
        // Yazımlar widget'lar yenilenmeden önce
        final lastSave = calls.lastIndexWhere(
          (c) => c.method == 'saveWidgetData',
        );
        final firstUpdate = calls.indexWhere((c) => c.method == 'updateWidget');
        expect(lastSave, lessThan(firstUpdate));
      }

      // Gece yarısı: 12 saatte "12:00 AM", 24 saatte "00:00"; dil yoksa 24 saat
      calls.clear();
      await write(allMidnight, loc: lookupAppLocalizations(const Locale('en')));
      expect(saved()['imsak_time_text'], '12:00 AM');
      expect(saved()['imsak_time'], '00:00');
      calls.clear();
      await write(allMidnight, loc: lookupAppLocalizations(const Locale('ar')));
      expect(saved()['yatsi_time_text'], '12:00 ص');
      calls.clear();
      await write(allMidnight);
      expect(saved()['imsak_time_text'], '00:00');
    },
  );

  test('Dil yoksa yarının hicri tarihi yazılmaz, vakitleri yazılır', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
    });
    await write(allMidnight);

    final data = saved();
    expect(data['tomorrow_yatsi_time'], matches(RegExp(r'^\d\d:\d\d$')));
    expect(data['tomorrow_hijri_date_text'], isNull);
  });

  test('Eksik vakit: hata fırlatmaz, yarım veri yazılmaz', () async {
    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
    });
    await write(PrayerTimesModel(imsak: '05:00'), loc: tr);
    expect(calls, isEmpty);
  });

  test(
    'Üst üste çağrılar karışmaz: yazımlar sırayla, son çağrı kalır',
    () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      final first = write(allMidnight, loc: tr, city: 'A');
      final second = write(allMidnight, loc: tr, city: 'B');
      await Future.wait([first, second]);

      final trace = calls
          .where(
            (c) =>
                c.method == 'updateWidget' ||
                (c.method == 'saveWidgetData' &&
                    c.arguments['id'] == 'location_text'),
          )
          .map((c) => c.method == 'updateWidget' ? 'U' : c.arguments['data'])
          .join();
      expect(trace, 'A, FatihUUUUUUUB, FatihUUUUUUU');
      expect(saved()['location_text'], 'B, Fatih');
    },
  );

  group('WorkManager görevi', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/Istanbul',
      );
      // Günlük ayet/hadis zaten kurulu (ağ isteği olmasın)
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async => switch (call.method) {
          'initialize' => true,
          'pendingNotificationRequests' => [
            for (final id in [1000, 1900])
              {'id': id, 'title': '', 'body': '', 'payload': ''},
          ],
          _ => null,
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('Arka planda da gün ve yarının vakitleri yazılır', () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'saved_city': 'İstanbul',
        'language_code': 'ar',
      });
      expect(await PrayerRefreshService.runHeadless(), isTrue);

      final data = saved();
      final now = DateTime.now();
      expect(data['times_date'], dateKey(now));
      expect(
        data['tomorrow_ogle_time'],
        PrayerTimeService().calculate(41.0, 29.0, date: tomorrowOf(now)).ogle,
      );
      expect(
        data['tomorrow_hijri_date_text'],
        PrayerRefreshService.hijriDateText('ar', date: tomorrowOf(now)),
      );
      // Vakte kalan başlıkları ve saatin yazımı arka planda da (uygulamanın dilinde)
      final ar = lookupAppLocalizations(const Locale('ar'));
      expect(data['title_ogle'], ar.toOgle);
      expect(data['title_yatsi'], ar.toYatsi);
      expect(
        data['ogle_time_text'],
        formatPrayerTime(data['ogle_time'] as String, 'ar'),
      );
      expect(data['ogle_time_text'], endsWith(' م'));
      expect(
        data['tomorrow_imsak_time_text'],
        formatPrayerTime(data['tomorrow_imsak_time'] as String, 'ar'),
      );
      // Ramazan widget'ı da (tarih metni Arapça: arka planda intl verisi yüklenir)
      expect(data['ramadan_title_iftar'], ar.ramadanIftarLeft);
      expect(data['ramadan_day_text'], ar.widgetRamadanDay('%d'));
      expect(data['ramadan_start'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(data['ramadan_start_text'], isNot(matches(RegExp(r'^\d\d\.'))));
    });
  });
}
