import '../../features/imsakiye/imsakiye_logic.dart';
import 'fast_tracker.dart';
import 'prayer_tracker.dart';
import 'serial_queue.dart';
import 'storage_service.dart';

/// Ramazan orucu kayıtları ve kaza orucu sayacı (Kaza Takibi 'Oruç').
/// Oku-değiştir-yaz işlemleri sırayla çalışır. [now] testler için.
class FastTrackerService {
  final StorageService _storage = StorageService();

  static final SerialQueue _queue = SerialQueue();

  Future<Set<String>> loadLog() => _storage.loadFastLog();

  Future<Set<String>> loadKazaAdded() => _storage.loadFastKazaAdded();

  Future<int> loadKazaCount() async =>
      (await _storage.loadMissedPrayers())[FastTracker.kazaKey] ?? 0;

  /// [date] gününü tutuldu / tutulmadı yapar. Kazaya eklenmiş gün tutuldu
  /// yapılmaz (sayaç zaten artırıldı; [removeFromKaza]); değiştiyse true.
  Future<bool> setFasted(DateTime date, bool fasted, {DateTime? now}) =>
      _queue.run(() async {
        final today = now ?? DateTime.now();
        final key = PrayerTracker.dateKey(date);
        if (fasted && (await _storage.loadFastKazaAdded()).contains(key)) {
          return false;
        }
        await _storage.saveFastLog(
          FastTracker.withDay(
            await _storage.loadFastLog(),
            date,
            fasted,
            today: today,
          ),
        );
        return true;
      });

  /// Kazaya eklenmiş günü tutuldu yapar ve kaza orucu sayacından bir düşer
  /// (sıfırın altına inmez; yarıda kalırsa iki kez düşülmez). Eklenmemişse false.
  Future<bool> removeFromKaza(DateTime date, {DateTime? now}) =>
      _queue.run(() async {
        final today = now ?? DateTime.now();
        final added = await _storage.loadFastKazaAdded();
        if (!added.contains(PrayerTracker.dateKey(date))) return false;
        await _storage.saveFastLog(
          FastTracker.withDay(
            await _storage.loadFastLog(),
            date,
            true,
            today: today,
          ),
        );
        await _storage.saveFastKazaAdded(
          FastTracker.withDay(added, date, false, today: today),
        );
        final count = await loadKazaCount();
        if (count > 0) {
          await _storage.updateMissedPrayer(FastTracker.kazaKey, count - 1);
        }
        return true;
      });

  /// [range] Ramazan'ının tutulmayan geçmiş günlerini kaza orucu sayacına
  /// ekler (her gün bir kez). Eklenen gün sayısını döner.
  Future<int> addMissedToKaza(RamadanRange range, {DateTime? now}) =>
      _queue.run(() async {
        final today = now ?? DateTime.now();
        final added = await _storage.loadFastKazaAdded();
        final candidates = FastTracker.kazaCandidates(
          range,
          await _storage.loadFastLog(),
          added,
          today,
        );
        if (candidates.isEmpty) return 0;
        // Önce "eklendi" kaydı: yarıda kalırsa en kötü ihtimalle eksik sayılır,
        // çift sayılmaz
        await _storage.saveFastKazaAdded(
          FastTracker.prune({
            ...added,
            for (final d in candidates) PrayerTracker.dateKey(d),
          }, today),
        );
        final count = await loadKazaCount();
        await _storage.updateMissedPrayer(
          FastTracker.kazaKey,
          count + candidates.length,
        );
        return candidates.length;
      });
}
