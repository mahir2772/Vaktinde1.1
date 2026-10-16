// Hatim: Medine mushafı sayfa tablosu (assets/data/quran_pages.json; API'nin
// sayfa bilgisiyle aynı), plan hesapları (günlük hedef, geride/önde, hedef
// günü geçmiş, sırayla ilerleme, "Sayfa Gir", kayıt budama, bitiş), Ramazan
// hedefi, hatırlatma kararı ve hatırlatmanın kurulması (ID 1100, 'open|hatim',
// her gün tekrarlayan gecikmeli kip).
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/hatim.dart';
import 'package:ezan_saati/data/services/hatim_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final QuranPages _pages = QuranPages.parse(
  File(QuranPages.asset).readAsStringSync(),
)!;

/// alquran.cloud fikstürünün Arapça baskısındaki ayet → sayfa
Map<int, int> _fixturePages(String path) => {
  for (final a
      in ((jsonDecode(File(path).readAsStringSync()) as Map)['data'] as List)
              .first['ayahs']
          as List)
    (a as Map)['numberInSurah'] as int: a['page'] as int,
};

final DateTime _today = DateTime(2026, 10, 16);

HatimPlan _plan({
  int position = 0,
  Map<String, int> log = const {},
  DateTime? target,
}) => HatimPlan(
  start: _today,
  target: target ?? PrayerTracker.addDays(_today, 30),
  position: position,
  log: log,
);

String _key(int daysAgo) =>
    PrayerTracker.dateKey(PrayerTracker.addDays(_today, -daysAgo));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sayfa tablosu', () {
    test('604 sayfa, sırayla artan; ilk ve son sayfalar', () {
      expect(_pages.starts, hasLength(604));
      for (var i = 1; i < _pages.starts.length; i++) {
        final a = _pages.starts[i - 1];
        final b = _pages.starts[i];
        expect(
          a.surah < b.surah || (a.surah == b.surah && a.ayah < b.ayah),
          isTrue,
          reason: 'sayfa ${i + 1}',
        );
      }
      expect(_pages.startOf(1), (surah: 1, ayah: 1));
      expect(_pages.startOf(2), (surah: 2, ayah: 1));
      expect(_pages.startOf(3), (surah: 2, ayah: 6));
      expect(_pages.startOf(49), (surah: 2, ayah: 283));
      expect(_pages.startOf(50), (surah: 3, ayah: 1));
      expect(_pages.startOf(604), (surah: 112, ayah: 1));
      // Aralık dışı sayfa sınıra çekilir (0: başlanmamış hatim)
      expect(_pages.startOf(0), (surah: 1, ayah: 1));
      expect(_pages.startOf(605), (surah: 112, ayah: 1));
      // Her sure tabloda bir sayfada başlar ve ayet sayısını aşmaz
      final surahs = QuranService.parseSurahs(
        File(QuranService.surahsAsset).readAsStringSync(),
      );
      for (final start in _pages.starts) {
        expect(
          start.ayah,
          lessThanOrEqualTo(surahs[start.surah - 1].ayahCount),
        );
      }
    });

    test(
      'ayetin sayfası: sayfa başı o sayfa, bir önceki ayet önceki sayfa',
      () {
        expect(_pages.pageOf(1, 1), 1);
        expect(_pages.pageOf(1, 7), 1);
        expect(_pages.pageOf(2, 1), 2);
        expect(_pages.pageOf(2, 255), 42);
        expect(_pages.pageOf(114, 6), 604);
        for (var page = 2; page <= 604; page++) {
          final start = _pages.startOf(page);
          expect(_pages.pageOf(start.surah, start.ayah), page);
          if (start.ayah > 1) {
            expect(_pages.pageOf(start.surah, start.ayah - 1), page - 1);
          }
        }
      },
    );

    test('cüz başları: 2. cüz 22. sayfa (2:142), 30. cüz 582. sayfa (78:1); '
        'Tanzil sınırlı 4 cüz sayfa ortasında başlar', () {
      final pages = [
        for (final s in QuranService.juzStarts) _pages.pageOf(s.surah, s.ayah),
      ];
      expect(pages, [
        1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, //
        302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562,
        582,
      ]);
      expect(_pages.startOf(22), (surah: 2, ayah: 142));
      expect(_pages.startOf(582), (surah: 78, ayah: 1));
      // Basılı mushafta bu cüzler bir önceki ayetle sayfa başında başlar;
      // QuranService.juzStarts (Tanzil / alquran.cloud) bir sonrakini verir
      final midPage = <int>[
        for (var juz = 1; juz <= 30; juz++)
          if (_pages.startOf(pages[juz - 1]) != QuranService.juzStarts[juz - 1])
            juz,
      ];
      expect(midPage, [4, 7, 11, 26]);
    });

    test("alquran.cloud yanıtlarının 'page' alanıyla aynı (Mülk, İhlâs)", () {
      for (final (path, surah) in [
        ('test/fixtures/quran_surah_67.json', 67),
        ('test/fixtures/quran_surah_112.json', 112),
      ]) {
        for (final MapEntry(key: ayah, value: page) in _fixturePages(
          path,
        ).entries) {
          expect(_pages.pageOf(surah, ayah), page, reason: '$surah:$ayah');
        }
      }
    });

    test('bozuk tablo okunmaz', () {
      final valid = File(QuranPages.asset).readAsStringSync();
      final list = jsonDecode(valid) as List;
      expect(QuranPages.parse(valid), isNotNull);
      expect(QuranPages.parse(jsonEncode(list.sublist(1))), isNull);
      expect(
        QuranPages.parse(jsonEncode([list[1], list[0], ...list.sublist(2)])),
        isNull,
      );
      expect(QuranPages.parse('{bozuk'), isNull);
    });
  });

  group('Plan', () {
    test('yeni hatim: seçeneklerin günlük hedefi 20 / 10 / 5 sayfa', () {
      expect(
        [
          for (final days in HatimPlan.optionDays)
            HatimPlan.begin(
              _today,
              PrayerTracker.addDays(_today, days),
            ).dailyGoal(_today),
        ],
        [20, 10, 5],
      );
      final plan = HatimPlan.begin(DateTime(2026, 10, 16, 21, 30), _today);
      expect(plan.start, _today);
      expect(plan.position, 0);
      expect(plan.progress, 0);
      expect(plan.isFinished, isFalse);
    });

    test('günlük hedef gün içinde okudukça değişmez; geride kalınca artar, '
        'öndeyken azalır (en az 1)', () {
      final fresh = _plan();
      expect(fresh.dailyGoal(_today), 20);
      // Bugün 12 sayfa: hedef yine 20 (bugünün başındaki kalan)
      final read = fresh.withPosition(12, _today);
      expect(read.readOn(_today), 12);
      expect(read.dailyGoal(_today), 20);
      // 10 gün sonra 100. sayfada (geride): 504 / 21 → 24
      final tenDays = PrayerTracker.addDays(_today, 10);
      expect(_plan(position: 100).dailyGoal(tenDays), 24);
      // 400. sayfada (önde): 204 / 21 → 10
      expect(_plan(position: 400).dailyGoal(tenDays), 10);
      // 600. sayfa, 21 gün: en az 1
      expect(_plan(position: 600).dailyGoal(tenDays), 1);
    });

    test('hedef günü geçtiyse günlük hedef kalanın tamamı', () {
      final late = _plan(position: 500, target: _today);
      expect(late.dailyGoal(_today), 104); // son gün
      final tomorrow = PrayerTracker.addDays(_today, 1);
      expect(late.dailyGoal(tomorrow), 104);
      final read = late.withPosition(510, tomorrow);
      expect(read.dailyGoal(tomorrow), 104);
      expect(read.remainingOn(tomorrow), 104);
    });

    test('okuyucu: sadece sırayla en çok 2 sayfa ilerler; geri ve uzak '
        'atlama sayılmaz', () {
      final plan = _plan(position: 10, log: {_key(0): 3});
      expect(plan.advancedTo(10, _today), isNull);
      expect(plan.advancedTo(9, _today), isNull);
      expect(plan.advancedTo(13, _today), isNull);
      expect(plan.advancedTo(300, _today), isNull);
      final next = plan.advancedTo(11, _today)!;
      expect(next.position, 11);
      expect(next.readOn(_today), 4);
      final twice = next.advancedTo(13, _today)!;
      expect(twice.position, 13);
      expect(twice.readOn(_today), 6);
      expect(twice.start, plan.start);
      expect(twice.target, plan.target);
    });

    test('son sayfada hatim biter (tarih), sonra ilerlemez', () {
      final plan = _plan(position: 603);
      final done = plan.advancedTo(604, _today)!;
      expect(done.isFinished, isTrue);
      expect(done.finished, _today);
      expect(done.progress, 1);
      expect(done.advancedTo(604, _today), isNull);
      expect(done.reminderStart(21 * 60, _today), isNull);
      // %100 bitmeden görünmez
      expect(plan.progress, 0.99);
      expect(_plan(position: 1).progress, 0);
      expect(_plan(position: 121).progress, 0.2);
    });

    test('Sayfa Gir: konum değişir, bugünün kaydı fark kadar (0 altına '
        'inmez), 1–604', () {
      final plan = _plan(position: 50, log: {_key(0): 5, _key(1): 20});
      final ahead = plan.withPosition(80, _today);
      expect(ahead.position, 80);
      expect(ahead.readOn(_today), 35);
      final back = ahead.withPosition(70, _today);
      expect(back.readOn(_today), 25);
      final far = back.withPosition(10, _today);
      expect(far.position, 10);
      expect(far.readOn(_today), 0);
      expect(far.log.containsKey(_key(0)), isFalse);
      expect(far.readOn(PrayerTracker.addDays(_today, -1)), 20);
      expect(plan.withPosition(0, _today).position, 1);
      final done = plan.withPosition(999, _today);
      expect(done.position, 604);
      expect(done.finished, _today);
      expect(done.withPosition(600, _today).finished, isNull);
    });

    test('kayıt son 60 günü tutar', () {
      final plan = _plan(
        position: 100,
        log: {_key(60): 4, _key(61): 7, _key(200): 9, _key(1): 2},
      );
      final next = plan.advancedTo(101, _today)!;
      expect(next.log.keys.toSet(), {_key(60), _key(1), _key(0)});
    });

    test('Planı Değiştir: konum ve kayıt korunur', () {
      final plan = _plan(position: 300, log: {_key(0): 4});
      final changed = plan.withTarget(PrayerTracker.addDays(_today, 60));
      expect(changed.position, 300);
      expect(changed.log, plan.log);
      expect(changed.start, plan.start);
      // 308 / 61 → 6
      expect(changed.dailyGoal(_today), 6);
    });

    test('kayıt: yazılıp okunur; bozuk ya da tutarsız kayıt okunmaz', () {
      final plan = _plan(position: 120, log: {_key(0): 8, _key(3): 20});
      final copy = HatimPlan.parse(plan.encode())!;
      expect(copy.encode(), plan.encode());
      expect(copy.position, 120);
      expect(copy.readOn(_today), 8);
      final done = plan.withPosition(604, _today);
      expect(HatimPlan.parse(done.encode())!.finished, _today);
      Map<String, Object?> json() =>
          jsonDecode(plan.encode()) as Map<String, Object?>;
      for (final bad in <Map<String, Object?>>[
        {...json(), 'position': 605},
        {...json(), 'position': -1},
        {...json(), 'position': '12'},
        {...json(), 'position': 604}, // bitiş günü yok
        {...json(), 'finished': '2026-10-16'}, // bitmemiş
        {...json(), 'target': '2026-13-01'},
        {...json(), 'start': null},
        {
          ...json(),
          'log': {'dün': 3},
        },
        {
          ...json(),
          'log': {'2026-10-16': -2},
        },
      ]) {
        expect(HatimPlan.parse(jsonEncode(bad)), isNull, reason: '$bad');
      }
      expect(HatimPlan.parse('{bozuk'), isNull);
      expect(HatimPlan.parse(null), isNull);
    });

    test("Ramazan'da hatim: Ramazan'da ya da en çok 15 gün önce, hedef "
        "Ramazan'ın son günü", () {
      final calendar = RamadanCalendar.fromReligiousDays(
        jsonDecode(File('assets/data/religious_days.json').readAsStringSync())
            as List,
      );
      final end = DateTime(2027, 3, 8);
      expect(HatimPlan.ramadanTarget(calendar, DateTime(2027, 1, 23)), isNull);
      expect(HatimPlan.ramadanTarget(calendar, DateTime(2027, 1, 24)), end);
      expect(HatimPlan.ramadanTarget(calendar, DateTime(2027, 2, 8)), end);
      expect(HatimPlan.ramadanTarget(calendar, DateTime(2027, 3, 8)), end);
      expect(HatimPlan.ramadanTarget(calendar, DateTime(2027, 3, 9)), isNull);
      expect(HatimPlan.ramadanTarget(calendar, _today), isNull);
      // Ramazan'ın 1. günü başlanırsa 29 günde: günde 21 sayfa
      expect(
        HatimPlan.begin(
          DateTime(2027, 2, 8),
          end,
        ).dailyGoal(DateTime(2027, 2, 8)),
        21,
      );
    });
  });

  group('Hatırlatma kararı', () {
    const nine = 21 * 60;

    test(
      'bugünün hedefi bitmediyse ve saati geçmediyse bugün, yoksa yarın',
      () {
        final tomorrowAt9 = DateTime(2026, 10, 17, 21);
        final plan = _plan(position: 10, log: {_key(0): 10});
        expect(
          plan.reminderStart(nine, DateTime(2026, 10, 16, 8)),
          DateTime(2026, 10, 16, 21),
        );
        expect(
          plan.reminderStart(nine, DateTime(2026, 10, 16, 21)),
          tomorrowAt9,
        );
        expect(
          plan.reminderStart(nine, DateTime(2026, 10, 16, 22)),
          tomorrowAt9,
        );
        // Hedef (20) tamamlandı: bugün çalmaz
        final met = plan.withPosition(20, _today);
        expect(met.reminderStart(nine, DateTime(2026, 10, 16, 8)), tomorrowAt9);
        // Saat 06:30
        expect(
          plan.reminderStart(6 * 60 + 30, DateTime(2026, 10, 16, 5)),
          DateTime(2026, 10, 16, 6, 30),
        );
      },
    );
  });

  group('Hatırlatma kurulumu', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    late Map<int, Map<Object?, Object?>> pending;
    late List<String> methods;
    final now = DateTime(2026, 10, 16, 9);

    setUp(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      pending = {};
      methods = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        switch (call.method) {
          case 'zonedSchedule':
            final args = call.arguments as Map<Object?, Object?>;
            pending[args['id'] as int] = args;
            return null;
          case 'cancel':
            pending.remove(call.arguments['id']);
            return null;
          case 'pendingNotificationRequests':
            return [
              for (final id in pending.keys)
                {'id': id, 'title': '', 'body': '', 'payload': ''},
            ];
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    HatimService service() => HatimService(clock: () => now);

    test('kapalıyken kurulmaz; açılınca her gün 21:00, gecikmeli kip, ID '
        "1100, yük 'open|hatim', kayıtlı dilde metin", () async {
      SharedPreferences.setMockInitialValues({'language_code': 'de'});
      final hatim = service();
      await hatim.begin(PrayerTracker.addDays(now, 30));
      expect(methods, isEmpty); // hatırlatma varsayılan kapalı
      final state = await hatim.load();
      expect(state.plan!.position, 0);
      expect(state.reminder, isFalse);
      expect(state.reminderTime, 21 * 60);

      await hatim.setReminder(enabled: true);
      final args = pending[HatimService.reminderId]!;
      expect(args['payload'], 'open|hatim');
      expect(args['title'], 'Khatm');
      expect(args['body'], 'Vergessen Sie Ihre heutige Khatm-Lesung nicht.');
      expect(args['scheduledDateTime'], '2026-10-16T21:00:00');
      expect(args['matchDateTimeComponents'], DateTimeComponents.time.index);
      final android = args['platformSpecifics'] as Map;
      expect(android['scheduleMode'], 'inexactAllowWhileIdle');
      expect(android['channelId'], 'hatim_reminder_channel');

      // Saat değişince yeniden kurulur
      await hatim.setReminder(time: 7 * 60 + 15);
      expect(
        pending[HatimService.reminderId]!['scheduledDateTime'],
        '2026-10-17T07:15:00',
      );
    });

    test('bugünün hedefi tamamlanınca yarından başlar; hatim bitince ya da '
        'silinince iptal edilir, sayaç artar', () async {
      SharedPreferences.setMockInitialValues({
        HatimService.reminderKey: true,
        HatimService.countKey: 2,
      });
      final hatim = service();
      final changes = HatimService.changes.value;
      await hatim.begin(PrayerTracker.addDays(now, 30));
      expect(HatimService.changes.value, greaterThan(changes));
      expect(
        pending[HatimService.reminderId]!['scheduledDateTime'],
        '2026-10-16T21:00:00',
      );
      expect(await hatim.advanceTo(1), isFalse);
      expect(await hatim.advanceTo(5), isFalse); // uzak: sayılmaz
      expect((await hatim.load()).plan!.position, 1);
      expect(await hatim.setPosition(20), isFalse);
      expect(
        pending[HatimService.reminderId]!['scheduledDateTime'],
        '2026-10-17T21:00:00',
      );

      expect(await hatim.setPosition(603), isFalse);
      expect(await hatim.advanceTo(604), isTrue);
      final state = await hatim.load();
      expect(state.plan!.isFinished, isTrue);
      expect(state.count, 3);
      expect(pending, isEmpty);
      // Bitmiş hatimde ilerleme yok, sayaç bir kez artar
      expect(await hatim.advanceTo(604), isFalse);
      expect((await hatim.load()).count, 3);

      await hatim.begin(PrayerTracker.addDays(now, 60));
      expect(pending.keys, [HatimService.reminderId]);
      await hatim.delete();
      final deleted = await hatim.load();
      expect(deleted.plan, isNull);
      expect(deleted.count, 3);
      expect(pending, isEmpty);
    });

    test(
      'kapatılınca ve dışarıdan eşitlemede (yedekten dönüş) plan yoksa '
      'kurulu hatırlatma iptal edilir; kurulu değilse iptal çağrılmaz',
      () async {
        SharedPreferences.setMockInitialValues({
          HatimService.reminderKey: true,
        });
        final hatim = service();
        await hatim.begin(PrayerTracker.addDays(now, 30));
        expect(pending, isNotEmpty);
        await hatim.setReminder(enabled: false);
        expect(pending, isEmpty);

        await hatim.setReminder(enabled: true);
        expect(pending, isNotEmpty);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(HatimService.planKey);
        await hatim.syncReminder();
        expect(pending, isEmpty);
        methods.clear();
        await hatim.syncReminder();
        expect(methods, ['pendingNotificationRequests']);
      },
    );
  });
}
