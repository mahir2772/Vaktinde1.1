import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 3, 10, 14, 0);
  DateTime d(int offset) => PrayerTracker.addDays(today, offset);
  String dk(DateTime date) => PrayerTracker.dateKey(date);
  int bit(String key) => PrayerTracker.bit(key);
  const all = PrayerTracker.fullMask;

  group('Saf hesaplar', () {
    test('tarih anahtarı ve bildirim aksiyonu yükü', () {
      expect(dk(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
      expect(PrayerTracker.parseDateKey('2026-03-05'), DateTime(2026, 3, 5));
      expect(PrayerTracker.parseDateKey('2026-02-30'), isNull);
      expect(PrayerTracker.parseDateKey('bozuk'), isNull);

      final payload = PrayerTracker.payload(DateTime(2026, 3, 5, 20, 30), 'Yatsı');
      expect(payload, 'prayed|2026-03-05|Yatsı');
      final parsed = PrayerTracker.parsePayload(payload)!;
      expect(parsed.date, DateTime(2026, 3, 5));
      expect(parsed.key, 'Yatsı');
      expect(PrayerTracker.parsePayload('prayed|2026-03-05|Güneş'), isNull);
      expect(PrayerTracker.parsePayload('x|2026-03-05|Öğle'), isNull);
      expect(PrayerTracker.parsePayload(''), isNull);
      expect(PrayerTracker.parsePayload(null), isNull);
      expect(() => PrayerTracker.bit('Güneş'), throwsArgumentError);
    });

    test('işaretle / geri al; boş gün silinir, 400 günden eskisi budanır', () {
      var log = <String, int>{};
      log = PrayerTracker.withPrayed(log, d(0), 'Öğle', true, today: today);
      log = PrayerTracker.withPrayed(log, d(0), 'İmsak', true, today: today);
      expect(PrayerTracker.isPrayed(log, d(0), 'Öğle'), isTrue);
      expect(PrayerTracker.isPrayed(log, d(0), 'İkindi'), isFalse);
      expect(log, {'2026-03-10': 3});
      log = PrayerTracker.withPrayed(log, d(0), 'Öğle', false, today: today);
      expect(log, {'2026-03-10': 1});
      log = PrayerTracker.withPrayed(log, d(0), 'İmsak', false, today: today);
      expect(log, isEmpty);

      final old = {dk(d(-401)): all, dk(d(-400)): all};
      final pruned = PrayerTracker.withPrayed(
        old,
        d(0),
        'Yatsı',
        true,
        today: today,
      );
      expect(pruned, {dk(d(-400)): all, '2026-03-10': bit('Yatsı')});
    });

    test('seri: bugün sadece tamamsa sayılır, eksik gün seriyi bitirir', () {
      expect(PrayerTracker.streak({}, today), 0);
      final log = {dk(d(-1)): all, dk(d(-2)): all, dk(d(-3)): all, dk(d(-5)): all};
      expect(PrayerTracker.streak(log, today), 3);
      log[dk(d(0))] = 15; // 4 vakit: bugün sayılmaz ama seriyi bozmaz
      expect(PrayerTracker.streak(log, today), 3);
      log[dk(d(0))] = all;
      expect(PrayerTracker.streak(log, today), 4);
      log[dk(d(-2))] = all & ~bit('Akşam');
      expect(PrayerTracker.streak(log, today), 2);
    });

    test('İmsak girmeden dünün yatsısı seriyi bozmaz, orana eksik yazılmaz', () {
      final log = {
        dk(d(-1)): all & ~bit('Yatsı'),
        dk(d(-2)): all,
        dk(d(-3)): all,
      };
      expect(PrayerTracker.streak(log, today), 0);
      expect(
        PrayerTracker.streak(log, today, yesterdayYatsiOngoing: true),
        2,
      );
      // Dün yatsı da kılındıysa dün sayılır
      final full = {...log, dk(d(-1)): all};
      expect(PrayerTracker.streak(full, today, yesterdayYatsiOngoing: true), 3);
      // Dün başka vakit eksikse seri biter
      final missing = {...log, dk(d(-1)): all & ~bit('Öğle') & ~bit('Yatsı')};
      expect(
        PrayerTracker.streak(missing, today, yesterdayYatsiOngoing: true),
        0,
      );

      // Oran: dün 4/4 (yatsı henüz paydada değil), bugün imsak öncesi 0/0
      expect(
        PrayerTracker.completionRate(
          log,
          today,
          todayDue: 0,
          since: d(-1),
          yesterdayYatsiOngoing: true,
        ),
        1.0,
      );
      expect(
        PrayerTracker.completionRate(log, today, todayDue: 0, since: d(-1)),
        closeTo(4 / 5, 1e-9),
      );
      expect(
        PrayerTracker.completionRate(
          full,
          today,
          todayDue: 0,
          since: d(-1),
          yesterdayYatsiOngoing: true,
        ),
        1.0,
      );
    });

    test('30 günlük oran: takip başlangıcı ve bugün vakti girmiş farzlar', () {
      final log = {dk(d(-2)): all, dk(d(-1)): 7, dk(d(0)): 3};
      expect(
        PrayerTracker.completionRate(log, today, todayDue: 3, since: null),
        isNull,
      );
      expect(
        PrayerTracker.completionRate(log, today, todayDue: 3, since: d(-2)),
        closeTo((5 + 3 + 2) / (5 + 5 + 3), 1e-9),
      );
      // Pencere 30 gün: 29 geçmiş gün + bugün
      expect(
        PrayerTracker.completionRate(log, today, todayDue: 3, since: d(-100)),
        closeTo(10 / (29 * 5 + 3), 1e-9),
      );
      // İmsaktan önce bugün değerlendirilecek vakit yok
      expect(
        PrayerTracker.completionRate({}, today, todayDue: 0, since: d(0)),
        isNull,
      );
    });

    test('kaza adayları: başlangıç öncesi, bugün, kılınan ve eklenenler hariç', () {
      final log = {dk(d(-1)): bit('Öğle'), dk(d(-3)): all};
      final added = {dk(d(-2)): bit('İmsak') | bit('Yatsı')};
      expect(
        PrayerTracker.kazaCandidates(log, added, today, since: null),
        isEmpty,
      );

      final c = PrayerTracker.kazaCandidates(log, added, today, since: d(-4));
      expect(c, {
        dk(d(-1)): all & ~bit('Öğle'),
        dk(d(-2)): bit('Öğle') | bit('İkindi') | bit('Akşam'),
        dk(d(-4)): all,
      });
      expect(PrayerTracker.totalCount(c), 12);
      expect(PrayerTracker.kazaDeltas(c), {
        'Sabah': 2,
        'Öğle': 2,
        'İkindi': 3,
        'Akşam': 3,
        'Yatsı': 2,
      });

      // Eklenenlerle birleşince bir daha aday olmaz
      final merged = PrayerTracker.mergeMasks(added, c);
      expect(
        PrayerTracker.kazaCandidates(log, merged, today, since: d(-4)),
        isEmpty,
      );

      // İmsak girmediyse dünün yatsısı henüz kaza değil
      expect(
        PrayerTracker.kazaCandidates(
          log,
          added,
          today,
          since: d(-1),
          yesterdayYatsiOngoing: true,
        ),
        {dk(d(-1)): all & ~bit('Öğle') & ~bit('Yatsı')},
      );

      // En fazla 30 geçmiş gün
      final wide = PrayerTracker.kazaCandidates({}, {}, today, since: d(-100));
      expect(wide.length, 30);
      expect(wide.containsKey(dk(d(-30))), isTrue);
      expect(wide.containsKey(dk(d(-31))), isFalse);
      expect(wide.containsKey(dk(d(0))), isFalse);
    });

    test('özel gün kaydı: ekle / çıkar; bozuk ve 400 günden eskisi budanır', () {
      var days = PrayerTracker.withExcused({}, d(-1), true, today: today);
      days = PrayerTracker.withExcused(days, d(-2), true, today: today);
      expect(days, {dk(d(-1)), dk(d(-2))});
      expect(PrayerTracker.isExcused(days, DateTime(2026, 3, 9, 23, 59)), isTrue);
      expect(PrayerTracker.isExcused(days, d(0)), isFalse);
      days = PrayerTracker.withExcused(days, d(-1), false, today: today);
      expect(days, {dk(d(-2))});

      final pruned = PrayerTracker.withExcused(
        {dk(d(-401)), dk(d(-400)), 'bozuk', '2026-02-30'},
        d(0),
        true,
        today: today,
      );
      expect(pruned, {dk(d(-400)), dk(d(0))});
      expect(PrayerTracker.pruneExcused({dk(d(-401))}, today), isEmpty);
    });

    test('özel gün seriyi bozmaz, seriye de sayılmaz', () {
      // Dün tam, 2 gün önce boş (özel), 3-4 gün önce tam, 5 gün önce boş
      final log = {dk(d(-1)): all, dk(d(-3)): all, dk(d(-4)): all};
      expect(PrayerTracker.streak(log, today), 1);
      expect(PrayerTracker.streak(log, today, excused: {dk(d(-2))}), 3);
      // Özel günün işaretleri sayılmaz (tam gün de olsa)
      expect(
        PrayerTracker.streak(log, today, excused: {dk(d(-2)), dk(d(-3))}),
        2,
      );
      final withToday = {...log, dk(d(0)): all};
      expect(PrayerTracker.streak(withToday, today), 2);
      expect(
        PrayerTracker.streak(
          withToday,
          today,
          excused: {dk(d(0)), dk(d(-2))},
        ),
        3,
      );

      // Arka arkaya bir haftalık özel gün arayı köprüler
      final week = {
        dk(d(-1)): all,
        for (int i = 9; i <= 10; i++) dk(d(-i)): all,
      };
      final period = {for (int i = 2; i <= 8; i++) dk(d(-i))};
      expect(PrayerTracker.streak(week, today), 1);
      expect(PrayerTracker.streak(week, today, excused: period), 3);
      // Sadece özel gün: seri yok
      expect(PrayerTracker.streak({}, today, excused: period), 0);

      // İmsak girmeden: dün özel ise atlanır
      final ongoing = {dk(d(-2)): all, dk(d(-3)): all};
      expect(
        PrayerTracker.streak(ongoing, today, yesterdayYatsiOngoing: true),
        0,
      );
      expect(
        PrayerTracker.streak(
          ongoing,
          today,
          excused: {dk(d(-1))},
          yesterdayYatsiOngoing: true,
        ),
        2,
      );
    });

    test('özel gün orana girmez (ne pay ne payda)', () {
      final log = {dk(d(-2)): all, dk(d(-1)): 7, dk(d(0)): 3};
      double? rate(Set<String> excused) => PrayerTracker.completionRate(
        log,
        today,
        todayDue: 3,
        since: d(-2),
        excused: excused,
      );
      expect(rate({}), closeTo((5 + 3 + 2) / (5 + 5 + 3), 1e-9));
      expect(rate({dk(d(-1))}), closeTo((5 + 2) / (5 + 3), 1e-9));
      expect(rate({dk(d(0))}), closeTo((5 + 3) / (5 + 5), 1e-9));
      // Değerlendirilecek gün kalmadı
      expect(rate({dk(d(-2)), dk(d(-1)), dk(d(0))}), isNull);
      // Takip başlangıcından önceki özel gün etkisiz
      expect(rate({dk(d(-5))}), rate({}));
    });

    test('özel günün vakitleri kaza adayı olmaz', () {
      final log = {dk(d(-1)): bit('Öğle'), dk(d(-3)): all};
      final c = PrayerTracker.kazaCandidates(
        log,
        {},
        today,
        since: d(-4),
        excused: {dk(d(-2)), dk(d(-4))},
      );
      expect(c, {dk(d(-1)): all & ~bit('Öğle')});
      expect(PrayerTracker.totalCount(c), 4);
      // Dün özel: imsak girmemiş olsa da hiçbiri aday değil
      expect(
        PrayerTracker.kazaCandidates(
          log,
          {},
          today,
          since: d(-1),
          excused: {dk(d(-1))},
          yesterdayYatsiOngoing: true,
        ),
        isEmpty,
      );
    });

    test('vakit çıkış hatırlatma ID: 100-124, ardışık 5 günde çakışmaz', () {
      final ids = <int>{
        for (int day = 0; day < 5; day++)
          for (final key in PrayerTracker.prayerKeys)
            PrayerTracker.endReminderId(d(day), key),
      };
      expect(ids.length, 25);
      expect(ids.every((id) => id >= 100 && id <= 124), isTrue);
      expect(ids.every(PrayerTracker.isEndReminderId), isTrue);
      expect(PrayerTracker.isEndReminderId(99), isFalse);
      expect(PrayerTracker.isEndReminderId(125), isFalse);
      // Takvim gününe bağlı: saatten bağımsız, 5 günde bir tekrar
      expect(
        PrayerTracker.endReminderId(DateTime(2026, 3, 10, 23, 59), 'İkindi'),
        PrayerTracker.endReminderId(DateTime(2026, 3, 10), 'İkindi'),
      );
      expect(
        PrayerTracker.endReminderId(d(5), 'Öğle'),
        PrayerTracker.endReminderId(d(0), 'Öğle'),
      );
    });

    test('kılınan vaktin iptal edilecek hatırlatması: yatsı ertesi güne ait', () {
      expect(
        PrayerTracker.endReminderIdToCancel(d(0), 'Yatsı', today),
        PrayerTracker.endReminderId(d(1), 'Yatsı'),
      );
      expect(
        PrayerTracker.endReminderIdToCancel(d(-1), 'Yatsı', today),
        PrayerTracker.endReminderId(d(0), 'Yatsı'),
      );
      expect(
        PrayerTracker.endReminderIdToCancel(d(0), 'Öğle', today),
        PrayerTracker.endReminderId(d(0), 'Öğle'),
      );
      // Pencere dışı: aynı ID başka günün hatırlatması olabilir
      expect(PrayerTracker.endReminderIdToCancel(d(-1), 'Öğle', today), isNull);
      expect(PrayerTracker.endReminderIdToCancel(d(-5), 'Öğle', today), isNull);
      expect(PrayerTracker.endReminderIdToCancel(d(4), 'Yatsı', today), isNull);
    });
  });

  group('Kayıt ve bildirim aksiyonu (SharedPreferences)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<int> cancelled;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      cancelled = [];
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          if (call.method == 'cancel') cancelled.add(call.arguments['id']);
          return null;
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    DateTime now() => PrayerTracker.day(DateTime.now());

    test('işaretle / geri al kalıcı; takip başlangıcı; hatırlatma iptali', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PrayerTrackerService();
      final day = now();
      final changes = PrayerTrackerService.changes.value;

      await service.setPrayed(day, 'Öğle', true);
      expect(PrayerTrackerService.changes.value, changes + 1);
      expect(PrayerTracker.isPrayed(await service.loadLog(), day, 'Öğle'), isTrue);
      expect(await service.loadSince(), day);
      expect(cancelled, [PrayerTracker.endReminderId(day, 'Öğle')]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prayer_log'), '{"${dk(day)}":2}');

      // Daha eski gün işaretlenince başlangıç geri çekilir; pencere dışı iptal yok
      final older = PrayerTracker.addDays(day, -3);
      await service.setPrayed(older, 'Akşam', true);
      expect(await service.loadSince(), older);
      expect(cancelled.length, 1);

      // Geri alma hatırlatmaya ve başlangıca dokunmaz
      await service.setPrayed(day, 'Öğle', false);
      expect(PrayerTracker.isPrayed(await service.loadLog(), day, 'Öğle'), isFalse);
      expect(await service.loadSince(), older);
      expect(cancelled.length, 1);
    });

    test('bildirimdeki "Kıldım": yükteki gün işaretlenir, diğerleri yok sayılır', () async {
      SharedPreferences.setMockInitialValues({});
      final yesterday = PrayerTracker.addDays(now(), -1);
      NotificationResponse response(String? actionId, String? payload) =>
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: 10,
            actionId: actionId,
            payload: payload,
          );

      expect(
        await PrayerTrackerService.handleNotificationAction(
          response(null, PrayerTracker.payload(yesterday, 'Yatsı')),
        ),
        isFalse,
      );
      expect(
        await PrayerTrackerService.handleNotificationAction(
          response(PrayerTracker.actionId, 'bozuk'),
        ),
        isFalse,
      );
      expect(await PrayerTrackerService().loadLog(), isEmpty);

      expect(
        await PrayerTrackerService.handleNotificationAction(
          response(
            PrayerTracker.actionId,
            PrayerTracker.payload(yesterday, 'Yatsı'),
          ),
        ),
        isTrue,
      );
      final log = await PrayerTrackerService().loadLog();
      expect(log, {dk(yesterday): bit('Yatsı')});
      // Dünün yatsı hatırlatması bugüne aittir
      expect(cancelled, [PrayerTracker.endReminderId(now(), 'Yatsı')]);
    });

    test('Kazaya eklenmiş vakit sonradan "Kıldım" ile işaretlenmez', () async {
      final yesterday = PrayerTracker.addDays(now(), -1);
      SharedPreferences.setMockInitialValues({
        'prayer_kaza_added': '{"${dk(yesterday)}":${bit('Yatsı')}}',
      });
      final service = PrayerTrackerService();
      expect(await service.setPrayed(yesterday, 'Yatsı', true), isFalse);
      expect(
        await PrayerTrackerService.handleNotificationAction(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: PrayerTracker.actionId,
            payload: PrayerTracker.payload(yesterday, 'Yatsı'),
          ),
        ),
        isFalse,
      );
      expect(await service.loadLog(), isEmpty);
      expect(cancelled, isEmpty);
      // Aynı günün diğer vakitleri işaretlenebilir
      expect(await service.setPrayed(yesterday, 'Akşam', true), isTrue);
      expect(await service.loadLog(), {dk(yesterday): bit('Akşam')});
    });

    test('kazaya ekleme: her vakit bir kez, sayaçlar artar', () async {
      SharedPreferences.setMockInitialValues({'kaza_Öğle': 4});
      final service = PrayerTrackerService();
      DateTime day(int offset) => PrayerTracker.addDays(now(), offset);

      // Takip 3 gün önce başladı; dün tamam
      await service.setPrayed(day(-3), 'Öğle', true);
      for (final key in PrayerTracker.prayerKeys) {
        await service.setPrayed(day(-1), key, true);
      }

      expect(await service.addMissedToKaza(), 4 + 5);
      final expected = {
        'Sabah': 2,
        'Öğle': 5,
        'İkindi': 2,
        'Akşam': 2,
        'Yatsı': 2,
        'Vitir': 0,
        'Oruç': 0,
      };
      expect(await StorageService().loadMissedPrayers(), expected);

      // İkinci kez: hiçbir şey eklenmez
      expect(await service.addMissedToKaza(), 0);
      expect(await StorageService().loadMissedPrayers(), expected);

      // Sonradan oluşan boşluk eklenir, öncekiler tekrar sayılmaz
      await service.setPrayed(day(-1), 'Akşam', false);
      expect(await service.addMissedToKaza(), 1);
      expect((await StorageService().loadMissedPrayers())['Akşam'], 3);

      // Dünün yatsısı imsak girmeden eklenmez
      await service.setPrayed(day(-1), 'Yatsı', false);
      expect(await service.addMissedToKaza(yesterdayYatsiOngoing: true), 0);
      expect(await service.addMissedToKaza(), 1);
      expect((await StorageService().loadMissedPrayers())['Yatsı'], 3);
    });

    test('kazadan çıkarma: kılındı olur, sayaç bir azalır (0 altına inmez)', () async {
      SharedPreferences.setMockInitialValues({'kaza_Sabah': 4});
      final service = PrayerTrackerService();
      DateTime day(int offset) => PrayerTracker.addDays(now(), offset);
      bool prayed(Map<String, int> m, int offset, String key) =>
          PrayerTracker.isPrayed(m, day(offset), key);

      await service.setPrayed(day(-2), 'Öğle', true);
      expect(await service.addMissedToKaza(), 9);
      expect(await service.loadKazaCount('İmsak'), 6);

      // Kazaya eklenmemiş vakit değişmez
      expect(await service.removeFromKaza(day(-2), 'Öğle'), isFalse);

      expect(await service.removeFromKaza(day(-1), 'İmsak'), isTrue);
      expect(await service.loadKazaCount('İmsak'), 5);
      expect(prayed(await service.loadLog(), -1, 'İmsak'), isTrue);
      expect(prayed(await service.loadKazaAdded(), -1, 'İmsak'), isFalse);
      // İkinci kez düşülmez, yeniden kazaya eklenmez
      expect(await service.removeFromKaza(day(-1), 'İmsak'), isFalse);
      expect(await service.addMissedToKaza(), 0);
      expect(await service.loadKazaCount('İmsak'), 5);

      // Kaza Takibi'nde elle sıfırlanmışsa 0'da kalır, vakit yine kılındı olur
      await StorageService().updateMissedPrayer('Akşam', 0);
      expect(await service.removeFromKaza(day(-1), 'Akşam'), isTrue);
      expect(await service.loadKazaCount('Akşam'), 0);
      expect(prayed(await service.loadLog(), -1, 'Akşam'), isTrue);

      // Sonradan kılınmadı yapılırsa yeniden kazaya eklenebilir
      await service.setPrayed(day(-1), 'Akşam', false);
      expect(await service.addMissedToKaza(), 1);
      expect(await service.loadKazaCount('Akşam'), 1);
    });

    test('özel gün: kalıcı, budanır; kazaya eklenmez, işaret kalkınca eklenir', () async {
      DateTime day(int offset) => PrayerTracker.addDays(now(), offset);
      SharedPreferences.setMockInitialValues({
        'tracker_excused': ['bozuk', dk(day(-401))],
      });
      final service = PrayerTrackerService();
      final prefs = await SharedPreferences.getInstance();
      final changes = PrayerTrackerService.changes.value;

      expect(await service.setExcused(day(-2), true), isTrue);
      expect(PrayerTrackerService.changes.value, changes + 1);
      expect(prefs.getStringList('tracker_excused'), [dk(day(-2))]);
      expect(await service.loadExcused(), {dk(day(-2))});
      // Zaten özel gün: değişiklik yok
      expect(await service.setExcused(day(-2), true), isFalse);

      // Takip 3 gün önce başladı (öğle kılındı); 2 gün önce özel gün
      await service.setPrayed(day(-3), 'Öğle', true);
      expect(await service.addMissedToKaza(), 4 + 5);
      expect(await StorageService().loadMissedPrayers(), {
        'Sabah': 2,
        'Öğle': 1,
        'İkindi': 2,
        'Akşam': 2,
        'Yatsı': 2,
        'Vitir': 0,
        'Oruç': 0,
      });
      expect(
        PrayerTracker.maskOf(await service.loadKazaAdded(), day(-2)),
        0,
      );

      // İşaret kalkınca o günün kılınmayan vakitleri yeniden aday olur
      expect(await service.setExcused(day(-2), false), isTrue);
      expect(prefs.getStringList('tracker_excused'), isEmpty);
      expect(await service.addMissedToKaza(), 5);
      expect((await StorageService().loadMissedPrayers())['Sabah'], 3);
    });

    test('özel gün yapılan günün kazaya eklenmiş vakitleri sayaçtan düşülür', () async {
      SharedPreferences.setMockInitialValues({'kaza_Sabah': 4});
      final service = PrayerTrackerService();
      DateTime day(int offset) => PrayerTracker.addDays(now(), offset);

      await service.setPrayed(day(-2), 'Öğle', true);
      expect(await service.addMissedToKaza(), 9);
      expect(await service.loadKazaCount('İmsak'), 6);
      expect(await service.loadKazaCount('Öğle'), 1);

      // Dün özel gün: dünün 5 vakti kazadan çıkar
      expect(await service.setExcused(day(-1), true), isTrue);
      expect(await StorageService().loadMissedPrayers(), {
        'Sabah': 5,
        'Öğle': 0,
        'İkindi': 1,
        'Akşam': 1,
        'Yatsı': 1,
        'Vitir': 0,
        'Oruç': 0,
      });
      expect(await service.loadKazaAdded(), {
        dk(day(-2)): all & ~bit('Öğle'),
      });
      // Özel günde işaretlenen vakit kayıtta kalır, kaza sayacına dokunmaz
      expect(await service.setPrayed(day(-1), 'İmsak', true), isTrue);
      expect(PrayerTracker.isPrayed(await service.loadLog(), day(-1), 'İmsak'), isTrue);
      expect(await service.loadKazaCount('İmsak'), 5);

      // Elle sıfırlanmış sayaç 0'da kalır
      await StorageService().updateMissedPrayer('Akşam', 0);
      expect(await service.setExcused(day(-2), true), isTrue);
      expect(await service.loadKazaCount('Akşam'), 0);
      expect(await service.loadKazaCount('İmsak'), 4);
      expect(await service.loadKazaCount('Öğle'), 0);
      expect(await service.loadKazaAdded(), isEmpty);
      expect(await service.addMissedToKaza(), 0);
    });

    test('vakit çıkış hatırlatması ayarı: varsayılan kapalı/30, geçersiz dakika 30', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      var s = await storage.loadEndReminderSettings();
      expect((s.enabled, s.minutes), (false, 30));
      await storage.saveEndReminderSettings(enabled: true, minutes: 45);
      s = await storage.loadEndReminderSettings();
      expect((s.enabled, s.minutes), (true, 45));
      SharedPreferences.setMockInitialValues({'end_reminder_minutes': 7});
      expect((await storage.loadEndReminderSettings()).minutes, 30);
    });
  });
}
