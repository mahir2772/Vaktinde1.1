// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'prayer_tracker.dart';
import 'serial_queue.dart';
import 'storage_service.dart';
import 'tracker_widget_service.dart';

/// Bildirimdeki "Kıldım" ve "Durdur" aksiyonları: uygulamayı açmadan ayrı bir
/// isolate'te çalışır (flutter_local_notifications ActionBroadcastReceiver). Bildirim
/// eklentisinin her initialize çağrısı bu fonksiyonu verir (NotificationService.init,
/// background_manager). Her işleyici sadece kendi aksiyonunu işler.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {}
  // İşaretlendiyse takip widget'ı da (uygulama kapalıyken) yenilenir
  PrayerTrackerService.handleNotificationAction(response).then((marked) {
    if (marked) TrackerWidgetService.update();
  });
  NotificationService.showSilentCopy(response);
}

/// Namaz takibi kayıtları, seri hedefleri + kılınan vaktin "vakit çıkıyor"
/// hatırlatmasını iptal. Uygulama ve bildirim aksiyonu isolate'i ortak kullanır.
class PrayerTrackerService {
  final StorageService _storage = StorageService();

  /// Uygulama içi değişiklik sayacı (ana ekran satırı / takip ekranı dinler)
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Kayıt bütünüyle değiştirilirken ve değiştirildikten sonra artar (yedekten
  /// geri yükleme): bu yolla uzayan seri kullanıcının işareti değildir
  /// (StreakReviewPrompt değerlendirme istemez)
  static int replacements = 0;

  /// Kaydı bütünüyle değiştirir (yedekten geri yükleme): [write] diğer kayıt
  /// işleriyle sırayla çalışır, sonra dinleyiciler (ana ekran satırı, takip
  /// ekranı) yeniden okur
  static Future<void> replaceRecords(Future<void> Function() write) async {
    replacements++;
    try {
      await runExclusive(write);
    } finally {
      replacements++;
      changes.value++;
    }
  }

  static final SerialQueue _queue = SerialQueue();

  /// Oku-değiştir-yaz işlemleri ve hatırlatma senkronu sırayla çalışır.
  /// İç içe çağrılmamalı (kilitlenir).
  static Future<T> runExclusive<T>(Future<T> Function() action) =>
      _queue.run(action);

  /// Bildirim aksiyonunu işler; vakit işaretlendiyse true
  static Future<bool> handleNotificationAction(
    NotificationResponse response,
  ) async {
    try {
      if (response.actionId != PrayerTracker.actionId) return false;
      final target = PrayerTracker.parsePayload(response.payload);
      if (target == null) return false;
      return await PrayerTrackerService().setPrayed(
        target.date,
        target.key,
        true,
      );
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, int>> loadLog() => _storage.loadPrayerLog();

  Future<Map<String, int>> loadKazaAdded() => _storage.loadKazaAdded();

  Future<DateTime?> loadSince() async {
    final raw = await _storage.loadTrackerSince();
    return raw == null ? null : PrayerTracker.parseDateKey(raw);
  }

  /// Özel gün işareti alarm planını etkileyecek biçimde değişti (dün ve
  /// sonrası; özel günde ezan sessiz): HomeViewModel alarmları yeniden kurar
  static final ValueNotifier<int> excusedChanges = ValueNotifier<int>(0);

  static final StreamController<int> _badgeEarned =
      StreamController<int>.broadcast();

  /// Bu isolate'te yeni kazanılan seri hedefi (gün; aynı anda birkaçı
  /// kazanılırsa en büyüğü): uygulamada tebriki görünen takip yüzeyi gösterir.
  /// Arka plan isolate'inde (bildirim, widget) kazanılan sadece kayda yazılır.
  static Stream<int> get badgeEarned => _badgeEarned.stream;

  static void _announce(List<int> earned) {
    if (earned.isNotEmpty) _badgeEarned.add(earned.reduce(math.max));
  }

  /// Kazanılmış seri hedefleri (okuma; kaydetmez)
  Future<Map<int, String>> loadBadges() => _storage.loadTrackerBadges();

  /// Kazanılan seri hedefleri (gün → kazanıldığı gün). Önce güncel serinin
  /// ulaştığı hedefler kaydedilir: takip ekranı gösterdiği seriyle
  /// ([yesterdayYatsiOngoing] dahil) tutarlı kalır; eski sürümden ya da
  /// yedekten gelen seri de kazanılır.
  Future<Map<int, String>> earnBadges({
    bool yesterdayYatsiOngoing = false,
  }) async {
    final result = await runExclusive(
      () => _earnBadges(
        DateTime.now(),
        yesterdayYatsiOngoing: yesterdayYatsiOngoing,
      ),
    );
    _announce(result.earned);
    return result.badges;
  }

  // Kilitsiz (runExclusive içinden): serinin ulaştığı hedefler bugünün
  // tarihiyle kaydedilir. Seriyi uzatabilen her yazım (kılındı, kazadan
  // çıkarma, özel gün) çağırır: işaret nereden gelirse gelsin (ana ekran,
  // bildirim isolate'i, widget) hedef kaçmaz. Vakitler burada bilinmez: imsak
  // girmeden dünün eksik yatsısı seriyi bitirir (seri eksik sayılabilir, fazla
  // sayılmaz; takip ekranı [earnBadges] ile tamamlar). Özel günler sadece
  // okunur (kaydı uygulama yazar). Hata işaretlemeyi bozmaz.
  Future<({Map<int, String> badges, List<int> earned})> _earnBadges(
    DateTime now, {
    bool yesterdayYatsiOngoing = false,
  }) async {
    try {
      final badges = await _storage.loadTrackerBadges();
      final streak = PrayerTracker.streak(
        await _storage.loadPrayerLog(),
        now,
        excused: PrayerTracker.completeExcused(
          await _storage.loadTrackerExcused(),
          await _storage.loadExcusedOpen(),
          now,
        ).excused,
        yesterdayYatsiOngoing: yesterdayYatsiOngoing,
      );
      final next = PrayerTracker.withBadges(badges, streak, now);
      final earned = [
        for (final goal in next.keys)
          if (!badges.containsKey(goal)) goal,
      ];
      if (earned.isNotEmpty) await _storage.saveTrackerBadges(next);
      return (badges: next, earned: earned);
    } catch (e) {
      return (badges: const <int, String>{}, earned: const <int>[]);
    }
  }

  /// Özel gün (hayız/nifas) olarak işaretlenen günler. Açık dönem bugüne kadar
  /// tamamlanır ve kaydedilir (seri, kaza adayları ve yedek aynı günleri görür).
  Future<Set<String>> loadExcused() async =>
      (await runExclusive(() => _completedExcused(DateTime.now()))).excused;

  // Kilitsiz (runExclusive içinden): açık dönem bugüne kadar kümeye eklenir,
  // süresi dolduysa kapanır; değiştiyse kaydedilir (önce küme, sonra dönem)
  Future<({Set<String> excused, String? open})> _completedExcused(
    DateTime now,
  ) async {
    final days = await _storage.loadTrackerExcused();
    final open = await _storage.loadExcusedOpen();
    final result = PrayerTracker.completeExcused(days, open, now);
    if (!setEquals(days, result.excused)) {
      await _storage.saveTrackerExcused(result.excused);
    }
    if (open != result.open) await _storage.saveExcusedOpen(result.open);
    return result;
  }

  /// [date] gününü özel gün yapar ya da işareti kaldırır; değiştiyse true.
  /// Bugün işaretlenince açık dönem başlar, bugünün işareti kalkınca biter
  /// ([PrayerTracker.withExcusedPeriod]); geçmiş gün sadece kendisini etkiler.
  /// O günde kılındı işaretleri kayıtta kalır (işaret kalkınca yine sayılır).
  /// Özel gün yapılan günün kazaya eklenmiş vakitleri kazadan çıkar: kayıt
  /// silinir, kaza sayaçlarından düşülür (sıfırın altına inmez; sıra kayıt →
  /// sayaç, yarıda kalırsa sayaç en kötü ihtimalle fazla kalır, iki kez düşülmez).
  /// İşaret kalkınca o günün kılınmayan vakitleri yeniden kaza adayı olur.
  Future<bool> setExcused(DateTime date, bool excused) async {
    final now = DateTime.now();
    var earned = const <int>[];
    final result = await runExclusive(() async {
      final current = await _completedExcused(now);
      if (PrayerTracker.isExcused(current.excused, date) == excused) {
        return false;
      }
      final next = PrayerTracker.withExcusedPeriod(
        current.excused,
        current.open,
        date,
        excused,
        today: now,
      );
      await _storage.saveTrackerExcused(next.excused);
      if (next.open != current.open) {
        await _storage.saveExcusedOpen(next.open);
      }
      // Atlanan gün seriyi birleştirebilir (ya da kaldırılan işaret tam günü sayar)
      earned = (await _earnBadges(now)).earned;
      if (!excused) return true;
      final added = await _storage.loadKazaAdded();
      final mask = PrayerTracker.maskOf(added, date);
      if (mask == 0) return true;
      final key = PrayerTracker.dateKey(date);
      await _storage.saveKazaAdded(
        PrayerTracker.prune({...added}..remove(key), now),
      );
      final counters = await _storage.loadMissedPrayers();
      for (final e in PrayerTracker.kazaDeltas({key: mask}).entries) {
        final count = counters[e.key] ?? 0;
        if (count > 0) {
          await _storage.updateMissedPrayer(
            e.key,
            count > e.value ? count - e.value : 0,
          );
        }
      }
      return true;
    });
    changes.value++;
    _announce(earned);
    // Dün ve sonrası alarm planında (dünün geç kalan yatsısı dahil)
    if (result && PrayerTracker.daysBetween(date, now) <= 1) {
      excusedChanges.value++;
    }
    return result;
  }

  /// [date] günündeki [key] vaktini işaretler/kaldırır. Kılındıysa o vaktin bekleyen
  /// "vakit çıkıyor" hatırlatması iptal edilir ve serinin ulaştığı hedefler
  /// kazanılır. Kazaya eklenmiş vakit işaretlenmez (sayaç zaten artırıldı;
  /// [removeFromKaza]); değişiklik yapıldıysa true.
  Future<bool> setPrayed(DateTime date, String key, bool prayed) async {
    var earned = const <int>[];
    final result = await runExclusive(() async {
      final now = DateTime.now();
      if (prayed &&
          PrayerTracker.isPrayed(await _storage.loadKazaAdded(), date, key)) {
        return false;
      }
      final log = PrayerTracker.withPrayed(
        await _storage.loadPrayerLog(),
        date,
        key,
        prayed,
        today: now,
      );
      await _storage.savePrayerLog(log);
      if (prayed) {
        final since = await loadSince();
        if (since == null || PrayerTracker.daysBetween(since, date) < 0) {
          await _storage.saveTrackerSince(PrayerTracker.dateKey(date));
        }
        final id = PrayerTracker.endReminderIdToCancel(date, key, now);
        if (id != null) {
          try {
            await FlutterLocalNotificationsPlugin().cancel(id);
          } catch (e) {}
        }
        earned = (await _earnBadges(now)).earned;
      }
      return true;
    });
    changes.value++;
    _announce(earned);
    return result;
  }

  /// [key] vaktinin kaza sayacı (Kaza Takibi)
  Future<int> loadKazaCount(String key) async =>
      (await _storage.loadMissedPrayers())[PrayerTracker.kazaKeys[key]!] ?? 0;

  /// Kazaya eklenmiş vakti kılındı yapar ve kaza sayacından bir düşer (sıfırın
  /// altına inmez). Sıra: kılındı → kayıt silinir → sayaç; yarıda kalırsa sayaç en
  /// kötü ihtimalle fazla kalır, iki kez düşülmez. Kazaya eklenmemişse false.
  Future<bool> removeFromKaza(DateTime date, String key) async {
    var earned = const <int>[];
    final result = await runExclusive(() async {
      final added = await _storage.loadKazaAdded();
      if (!PrayerTracker.isPrayed(added, date, key)) return false;
      final now = DateTime.now();
      await _storage.savePrayerLog(
        PrayerTracker.withPrayed(
          await _storage.loadPrayerLog(),
          date,
          key,
          true,
          today: now,
        ),
      );
      await _storage.saveKazaAdded(
        PrayerTracker.withPrayed(added, date, key, false, today: now),
      );
      final kazaKey = PrayerTracker.kazaKeys[key]!;
      final count = (await _storage.loadMissedPrayers())[kazaKey] ?? 0;
      if (count > 0) await _storage.updateMissedPrayer(kazaKey, count - 1);
      earned = (await _earnBadges(now)).earned;
      return true;
    });
    changes.value++;
    _announce(earned);
    return result;
  }

  /// Kaza sayaçlarına [deltas] kadar ekler, üzerine yazmaz ("Kaza hesapla")
  Future<void> addToKazaCounters(Map<String, int> deltas) =>
      runExclusive(() async {
        final counters = await _storage.loadMissedPrayers();
        for (final e in deltas.entries) {
          await _storage.updateMissedPrayer(
            e.key,
            (counters[e.key] ?? 0) + e.value,
          );
        }
      });

  /// Kılınmayan geçmiş vakitleri kaza sayaçlarına ekler (her vakit bir kez;
  /// özel günler hariç). Eklenen vakit sayısını döner.
  Future<int> addMissedToKaza({bool yesterdayYatsiOngoing = false}) async {
    final added = await runExclusive(() async {
      final now = DateTime.now();
      final log = await _storage.loadPrayerLog();
      final already = await _storage.loadKazaAdded();
      final candidates = PrayerTracker.kazaCandidates(
        log,
        already,
        now,
        since: await loadSince(),
        excused: (await _completedExcused(now)).excused,
        yesterdayYatsiOngoing: yesterdayYatsiOngoing,
      );
      final count = PrayerTracker.totalCount(candidates);
      if (count == 0) return 0;
      // Önce "eklendi" kaydı: yarıda kalırsa en kötü ihtimalle eksik sayılır, çift sayılmaz
      await _storage.saveKazaAdded(
        PrayerTracker.prune(PrayerTracker.mergeMasks(already, candidates), now),
      );
      final counters = await _storage.loadMissedPrayers();
      for (final e in PrayerTracker.kazaDeltas(candidates).entries) {
        await _storage.updateMissedPrayer(
          e.key,
          (counters[e.key] ?? 0) + e.value,
        );
      }
      return count;
    });
    changes.value++;
    return added;
  }
}
