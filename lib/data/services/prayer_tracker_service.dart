// ignore_for_file: empty_catches

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prayer_tracker.dart';
import 'serial_queue.dart';
import 'storage_service.dart';

/// Bildirimdeki "Kıldım" aksiyonu: uygulamayı açmadan ayrı bir isolate'te çalışır
/// (flutter_local_notifications ActionBroadcastReceiver). Bildirim eklentisinin her
/// initialize çağrısı bu fonksiyonu verir (NotificationService.init, background_manager).
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {}
  PrayerTrackerService.handleNotificationAction(response);
}

/// Namaz takibi kayıtları + kılınan vaktin "vakit çıkıyor" hatırlatmasını iptal.
/// Uygulama ve bildirim aksiyonu isolate'i ortak kullanır.
class PrayerTrackerService {
  final StorageService _storage = StorageService();

  /// Uygulama içi değişiklik sayacı (ana ekran satırı / takip ekranı dinler)
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

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

  /// Özel gün (hayız/nifas) olarak işaretlenen günler
  Future<Set<String>> loadExcused() => _storage.loadTrackerExcused();

  /// [date] gününü özel gün yapar ya da işareti kaldırır; değiştiyse true.
  /// O günde kılındı işaretleri kayıtta kalır (işaret kalkınca yine sayılır).
  /// Özel gün yapılan günün kazaya eklenmiş vakitleri kazadan çıkar: kayıt
  /// silinir, kaza sayaçlarından düşülür (sıfırın altına inmez; sıra kayıt →
  /// sayaç, yarıda kalırsa sayaç en kötü ihtimalle fazla kalır, iki kez düşülmez).
  /// İşaret kalkınca o günün kılınmayan vakitleri yeniden kaza adayı olur.
  Future<bool> setExcused(DateTime date, bool excused) async {
    final result = await runExclusive(() async {
      final now = DateTime.now();
      final days = await _storage.loadTrackerExcused();
      if (PrayerTracker.isExcused(days, date) == excused) return false;
      await _storage.saveTrackerExcused(
        PrayerTracker.withExcused(days, date, excused, today: now),
      );
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
    return result;
  }

  /// [date] günündeki [key] vaktini işaretler/kaldırır. Kılındıysa o vaktin bekleyen
  /// "vakit çıkıyor" hatırlatması iptal edilir. Kazaya eklenmiş vakit işaretlenmez
  /// (sayaç zaten artırıldı; [removeFromKaza]); değişiklik yapıldıysa true.
  Future<bool> setPrayed(DateTime date, String key, bool prayed) async {
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
      }
      return true;
    });
    changes.value++;
    return result;
  }

  /// [key] vaktinin kaza sayacı (Kaza Takibi)
  Future<int> loadKazaCount(String key) async =>
      (await _storage.loadMissedPrayers())[PrayerTracker.kazaKeys[key]!] ?? 0;

  /// Kazaya eklenmiş vakti kılındı yapar ve kaza sayacından bir düşer (sıfırın
  /// altına inmez). Sıra: kılındı → kayıt silinir → sayaç; yarıda kalırsa sayaç en
  /// kötü ihtimalle fazla kalır, iki kez düşülmez. Kazaya eklenmemişse false.
  Future<bool> removeFromKaza(DateTime date, String key) async {
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
      return true;
    });
    changes.value++;
    return result;
  }

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
        excused: await _storage.loadTrackerExcused(),
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
