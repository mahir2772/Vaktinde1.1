// Günün ayeti ve hadisi: güne bağlı seçim (ayet dilden bağımsız), gün + dil
// önbelleği (aynı gün ağa çıkmaz, internetsiz önbellekten), gün boyu kalan
// yerel yedek ve 10:00 / 19:00 bildiriminin çalacağı günün içeriğiyle kurulması.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/ayah_service.dart';
import 'package:ezan_saati/data/services/hadith_service.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _ayahNumberOf(Uri url) => int.parse(url.pathSegments[2]);

// alquran.cloud: /ayah/<no>/editions/quran-uthmani,<meal>
String _ayahJson(Uri url) {
  final number = _ayahNumberOf(url);
  final edition = url.pathSegments[4].split(',').last;
  return jsonEncode({
    'data': [
      {
        'number': number,
        'surah': {'name': 'sure'},
        'numberInSurah': 1,
        'text': 'ar $number',
      },
      {'number': number, 'text': '$edition $number'},
    ],
  });
}

// hadeethenc: liste (sayfa başına 20 kimlik) ve tek hadis
String _hadithJson(Uri url) {
  final query = url.queryParameters;
  if (url.path.endsWith('/list/')) {
    final page = int.parse(query['page']!);
    return jsonEncode({
      'data': [
        for (var i = 0; i < 20; i++) {'id': '${page * 100 + i}'},
      ],
    });
  }
  return jsonEncode({
    'hadeeth': '${query['language']} hadis ${query['id']}',
    'attribution': 'kaynak',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tr = Locale('tr');

  group('Günün ayeti', () {
    test('güne bağlı: 1..6236, saatten bağımsız, ardışık günler farklı, '
        '6236 gün boyunca tekrar yok', () {
      final start = DateTime(2026, 1, 1);
      final seen = <int>{};
      int? previous;
      for (var i = 0; i < AyahService.totalAyahs; i++) {
        final day = PrayerTracker.addDays(start, i);
        final number = AyahService.ayahNumberFor(day);
        expect(number, inInclusiveRange(1, AyahService.totalAyahs));
        expect(
          AyahService.ayahNumberFor(
            DateTime(day.year, day.month, day.day, 23, 59),
          ),
          number,
        );
        expect(number, isNot(previous));
        previous = number;
        seen.add(number);
      }
      expect(seen, hasLength(AyahService.totalAyahs));
    });

    test('gün + dil başına bir kez ağdan; dil değişince aynı ayetin meali, '
        'ertesi gün başka ayet', () async {
      SharedPreferences.setMockInitialValues({});
      final urls = <Uri>[];
      AyahService service() => AyahService(
        fetch: (url) async {
          urls.add(url);
          return _ayahJson(url);
        },
      );
      final day = DateTime(2026, 10, 13, 9);
      final number = AyahService.ayahNumberFor(day);
      final first = await service().getDailyAyah('tr', day: day);
      expect(first!.translatedText, 'tr.diyanet $number');

      // Uygulama yeniden açıldı (yeni servis), aynı gün başka saat → önbellek
      final again = await service().getDailyAyah(
        'tr',
        day: DateTime(2026, 10, 13, 23, 59),
      );
      expect(again!.translatedText, first.translatedText);
      expect(again.arabicText, first.arabicText);
      expect(urls, hasLength(1));

      final en = await service().getDailyAyah('en', day: day);
      expect(en!.translatedText, 'en.sahih $number');
      expect(urls.map(_ayahNumberOf), [number, number]);

      await service().getDailyAyah('tr', day: DateTime(2026, 10, 14));
      expect(_ayahNumberOf(urls.last), isNot(number));
    });

    test(
      'internetsiz: önbellek varsa o, yoksa null; hata yanıtı saklanmaz',
      () async {
        SharedPreferences.setMockInitialValues({});
        final day = DateTime(2026, 10, 13);
        final offline = AyahService(
          fetch: (_) async => throw const SocketException('yok'),
        );
        expect(await offline.getDailyAyah('tr', day: day), isNull);
        for (final bad in [null, '<html>404</html>']) {
          expect(
            await AyahService(
              fetch: (_) async => bad,
            ).getDailyAyah('tr', day: day),
            isNull,
          );
        }
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AyahService.cacheKey), isNull);

        final online = await AyahService(
          fetch: (url) async => _ayahJson(url),
        ).getDailyAyah('tr', day: day);
        final cached = await offline.getDailyAyah('tr', day: day);
        expect(cached!.translatedText, online!.translatedText);
      },
    );

    test(
      'önbellek: yarının kaydı bugününkini silmez, daha eskiler silinir',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = AyahService(fetch: (url) async => _ayahJson(url));
        for (final day in [11, 12, 13, 14]) {
          await service.getDailyAyah('tr', day: DateTime(2026, 10, day));
        }
        await service.getDailyAyah('en', day: DateTime(2026, 10, 14));
        final prefs = await SharedPreferences.getInstance();
        final entries =
            jsonDecode(prefs.getString(AyahService.cacheKey)!) as Map;
        expect(entries.keys, [
          '2026-10-13|tr',
          '2026-10-14|tr',
          '2026-10-14|en',
        ]);
      },
    );
  });

  group('Günün hadisi', () {
    test('seçim güne bağlı; gün + dil başına bir kez ağdan', () async {
      SharedPreferences.setMockInitialValues({});
      final urls = <Uri>[];
      HadithService service() => HadithService(
        fetch: (url) async {
          urls.add(url);
          return _hadithJson(url);
        },
      );
      final day = DateTime(2026, 10, 13, 9);
      final first = await service().getDailyHadith(tr, day: day);
      expect(first!.content, startsWith('tr hadis '));
      expect(urls, hasLength(2)); // liste + hadis

      final again = await service().getDailyHadith(
        tr,
        day: DateTime(2026, 10, 13, 22),
      );
      expect(again!.content, first.content);
      expect(again.source, 'kaynak');
      expect(urls, hasLength(2));

      // Önbellek silinse de aynı gün aynı hadis seçilir
      SharedPreferences.setMockInitialValues({});
      expect(
        (await service().getDailyHadith(tr, day: day))!.content,
        first.content,
      );
    });

    test('yerel yedek: bugün gösterilen gün boyu kalır (ağ gelse de); '
        'ileri günün yedeği saklanmaz', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final online = HadithService(fetch: (url) async => _hadithJson(url));
      for (final offline in [
        HadithService(fetch: (_) async => throw const SocketException('yok')),
        HadithService(fetch: (_) async => null), // HTTP hatası
        // Metinsiz hadis
        HadithService(
          fetch: (url) async => url.path.endsWith('/list/')
              ? _hadithJson(url)
              : jsonEncode({'hadeeth': ' '}),
        ),
      ]) {
        SharedPreferences.setMockInitialValues({});
        final fallback = await offline.getDailyHadith(tr);
        expect(fallback!.content, 'Ameller niyetlere göredir.');
        expect(
          (await online.getDailyHadith(tr, day: now))!.content,
          fallback.content,
        );

        final tomorrow = PrayerTracker.addDays(now, 1);
        expect(
          (await offline.getDailyHadith(tr, day: tomorrow))!.content,
          fallback.content,
        );
        expect(
          (await online.getDailyHadith(tr, day: tomorrow))!.content,
          startsWith('tr hadis '),
        );
      }
    });
  });

  group('Bildirim çalacağı günün içeriğiyle', () {
    test('çalacağı gün: saati geçmediyse bugün, geçtiyse yarın', () {
      DateTime day(int id, int hour, int minute) =>
          PrayerRefreshService.dailyContentDay(
            id,
            DateTime(2026, 10, 31, hour, minute),
          );
      const ayah = PrayerRefreshService.ayahNotificationId;
      const hadith = PrayerRefreshService.hadithNotificationId;
      final today = DateTime(2026, 10, 31);
      final tomorrow = DateTime(2026, 11, 1);
      expect(day(ayah, 9, 59), today);
      expect(day(ayah, 10, 1), tomorrow);
      expect(day(hadith, 10, 1), today);
      expect(day(hadith, 18, 59), today);
      expect(day(hadith, 19, 1), tomorrow);
      expect(day(ayah, 0, 0), today);
    });

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const notifChannel = MethodChannel(
      'dexterous.com/flutter/local_notifications',
    );
    late Map<int, String> bodies;

    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      bodies = {};
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/Istanbul',
      );
      messenger.setMockMethodCallHandler(notifChannel, (call) async {
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
            bodies[call.arguments['id'] as int] =
                call.arguments['body'] as String;
            return null;
          case 'pendingNotificationRequests':
            return const [];
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(notifChannel, null));

    // Yarın 08:00 ikisi de o gün (ana ekrandakiyle aynı); 12:00 ayet ertesi
    // gün (o günün ayeti), hadis o gün
    for (final hour in [8, 12]) {
      test('saat $hour:00 → ayet ve hadis çalacakları günün', () async {
        SharedPreferences.setMockInitialValues({});
        final now = DateTime.now();
        final at = DateTime(now.year, now.month, now.day + 1, hour);
        final today = PrayerTracker.day(at);
        final tomorrow = PrayerTracker.addDays(today, 1);
        final ayahDay = hour < 10 ? today : tomorrow;

        // Ana ekranın o günler göstereceği içerik (önbelleğe de yazılır)
        final ayahs = AyahService(fetch: (url) async => _ayahJson(url));
        final todayAyah = await ayahs.getDailyAyah('tr', day: today);
        final dayAyah = await ayahs.getDailyAyah('tr', day: ayahDay);
        final dayHadith = await HadithService(
          fetch: (url) async => _hadithJson(url),
        ).getDailyHadith(tr, day: today);

        final notifications = NotificationService();
        await notifications.init();
        await PrayerRefreshService(
          notifications,
          clock: () => at,
        ).scheduleDailyContent(localeName: 'tr');

        expect(
          bodies[PrayerRefreshService.ayahNotificationId],
          '${dayAyah!.arabicText}\n\n${dayAyah.translatedText}',
        );
        if (hour >= 10) {
          expect(dayAyah.translatedText, isNot(todayAyah!.translatedText));
        }
        expect(
          bodies[PrayerRefreshService.hadithNotificationId],
          dayHadith!.content,
        );
      });
    }
  });
}
