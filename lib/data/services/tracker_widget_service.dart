// ignore_for_file: empty_catches

import 'dart:ui';

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezan_saati/l10n/app_localizations.dart';
import 'notification_service.dart';
import 'prayer_refresh_service.dart';
import 'prayer_time_service.dart';
import 'prayer_tracker.dart';
import 'prayer_tracker_service.dart';
import 'serial_queue.dart';
import 'storage_service.dart';

/// home_widget etkileşim geri çağrısı: takip widget'ında vakit hücresine dokunuş.
/// Uygulama açılmadan ayrı bir isolate'te çalışır (HomeWidgetBackgroundService);
/// main.dart her açılışta kaydeder ([TrackerWidgetService.registerCallback]).
@pragma('vm:entry-point')
Future<void> trackerWidgetCallback(Uri? uri) async {
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {}
  await TrackerWidgetService.handleTap(uri);
}

/// Namaz takibi widget'ı (Kotlin: VaktindeWidgetTrackerProvider.kt): kayıt
/// PrayerTrackerService'te, widget bugünün işaret maskesini, özel günleri ve
/// metinleri HomeWidgetPreferences'tan okur. Gün dönümünde maskeyi Kotlin sıfırlar
/// (yazıldığı gün değilse), açık özel gün dönemini sonraki günlerin listesinden bilir.
/// Uygulama içi değişiklikte (HomeViewModel, PrayerTrackerService.changes), "Kıldım"
/// bildiriminde, dokunuşta ve widget verisi yazılırken (updateHomeWidget) yenilenir.
class TrackerWidgetService {
  TrackerWidgetService._();

  static const String providerName = 'VaktindeWidgetTrackerProvider';

  // Anahtarlar Kotlin'le sözleşme: değişirse VaktindeWidgetTrackerProvider da değişir
  static const String dateKey = 'tracker_date';
  static const String maskKey = 'tracker_mask';
  static const String excusedKey = 'tracker_excused_days';
  static const String titleKey = 'tracker_title';
  static const String labelsKey = 'tracker_labels';
  static const String statesKey = 'tracker_states';
  static const String cellTextKey = 'tracker_cell_text';

  /// Widget verisi (saf). Maske [now] gününün; özel günler bugünden açık dönemin
  /// son gününe kadar (virgüllü). Adlar [PrayerTracker.prayerKeys] sırasıyla, durum
  /// sözleri hücre durumlarının sırasıyla (kılındı, kılınmadı, vakti girmedi, özel
  /// gün); ikisi de satır satır. Hücre metni ekran okuyucu için: %1$s vakit, %2$s durum.
  static Map<String, Object> data({
    required Map<String, int> log,
    required Set<String> excused,
    required String? open,
    required DateTime now,
    required AppLocalizations loc,
  }) {
    final today = PrayerTracker.day(now);
    final todayKey = PrayerTracker.dateKey(today);
    final last = PrayerTracker.addDays(
      today,
      PrayerTracker.excusedPeriodDays - 1,
    );
    final days = PrayerTracker.excusedThrough(
      excused,
      open,
      last,
    ).where((d) => d.compareTo(todayKey) >= 0).toList()..sort();
    return {
      dateKey: todayKey,
      maskKey: PrayerTracker.maskOf(log, today),
      excusedKey: days.join(','),
      titleKey: loc.trackerToday,
      labelsKey: [
        loc.sabah,
        loc.ogle,
        loc.ikindi,
        loc.aksam,
        loc.yatsi,
      ].join('\n'),
      statesKey: [
        loc.trackerLegendPrayed,
        loc.a11yNotPrayed,
        loc.a11yNotDue,
        loc.a11yExcusedDay,
      ].join('\n'),
      cellTextKey: loc.a11yTrackerCell(loc.trackerToday, r'%1$s', r'%2$s'),
    };
  }

  /// Dokunuş adresi (Kotlin tapUri): vaktinde://tracker/toggle?date=yyyy-MM-dd&prayer=0..4
  static ({DateTime date, String key})? parseTap(Uri? uri) {
    if (uri == null ||
        uri.scheme != 'vaktinde' ||
        uri.host != 'tracker' ||
        uri.path != '/toggle') {
      return null;
    }
    final date = PrayerTracker.parseDateKey(uri.queryParameters['date'] ?? '');
    final index = int.tryParse(uri.queryParameters['prayer'] ?? '');
    if (date == null ||
        index == null ||
        index < 0 ||
        index >= PrayerTracker.prayerKeys.length) {
      return null;
    }
    return (date: date, key: PrayerTracker.prayerKeys[index]);
  }

  /// Dokunuş geri çağrısını kaydeder (her açılışta; tutamaç sürümle değişebilir)
  static Future<void> registerCallback() async {
    try {
      await HomeWidget.registerInteractivityCallback(trackerWidgetCallback);
    } catch (e) {}
  }

  // Yazımlar sırayla: üst üste gelen çağrılar anahtarları karıştırmasın
  static final SerialQueue _queue = SerialQueue();

  /// Kayıttan widget verisini yazar (widget'ı yenilemez: updateHomeWidget diğer
  /// widget'larla birlikte yeniler); [loc] yoksa kayıtlı dil. Başka isolate'in
  /// (bildirim, dokunuş) işaretleri de okunur. Hata fırlatmaz.
  static Future<void> write({AppLocalizations? loc}) => _queue.run(() async {
    try {
      final storage = StorageService();
      // Önce (reload ile) kayıt: diğer anahtarlar aynı tazelenmiş önbellekten
      final log = await storage.loadPrayerLog();
      final values = data(
        log: log,
        excused: await storage.loadTrackerExcused(),
        open: await storage.loadExcusedOpen(),
        now: DateTime.now(),
        loc: loc ?? await _localizations(),
      );
      for (final e in values.entries) {
        await HomeWidget.saveWidgetData<Object>(e.key, e.value);
      }
    } catch (e) {}
  });

  /// [write] ve widget'ı yeniler. Hata fırlatmaz.
  static Future<void> update({AppLocalizations? loc}) async {
    await write(loc: loc);
    try {
      await HomeWidget.updateWidget(
        name: providerName,
        androidName: providerName,
      );
    } catch (e) {}
  }

  // Aynı isolate'te art arda dokunuşlar sırayla: ikincisi birincinin sonucunu görür
  static final SerialQueue _taps = SerialQueue();

  /// Dokunuş: bugünün vakti kılındı ↔ kılınmadı ("Kıldım" bildirimiyle aynı kayıt
  /// kuralları: kazaya eklenmiş vakit işaretlenmez). Geri alınan vaktin "vakit
  /// çıkıyor" hatırlatması uygulamadaki gibi yeniden kurulur. Gece yarısından önce
  /// çizilmiş hücre ve özel gün işareti değiştirmez. Her durumda widget yeniden
  /// çizilir; işaret değiştiyse true.
  static Future<bool> handleTap(Uri? uri) => _taps.run(() async {
    var changed = false;
    try {
      final target = parseTap(uri);
      final now = DateTime.now();
      final today = PrayerTracker.day(now);
      if (target != null && PrayerTracker.daysBetween(target.date, now) == 0) {
        final service = PrayerTrackerService();
        if (!PrayerTracker.isExcused(await service.loadExcused(), today)) {
          final prayed = !PrayerTracker.isPrayed(
            await service.loadLog(),
            today,
            target.key,
          );
          changed = await service.setPrayed(today, target.key, prayed);
          if (changed && !prayed) await _resyncEndReminders(now);
        }
      }
    } catch (e) {}
    await update();
    return changed;
  });

  // Uygulamadaki HomeViewModel.refreshEndReminders'ın arka plan karşılığı
  static Future<void> _resyncEndReminders(DateTime now) async {
    try {
      final times = await PrayerTimeService().forDate(now);
      if (times == null) return;
      final notifications = NotificationService();
      await notifications.init();
      await PrayerRefreshService(
        notifications,
      ).syncEndReminders(todayTimes: times, loc: await _localizations());
    } catch (e) {}
  }

  static Future<AppLocalizations> _localizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return lookupAppLocalizations(
        Locale(prefs.getString('language_code') ?? 'tr'),
      );
    } catch (e) {
      return lookupAppLocalizations(const Locale('tr'));
    }
  }
}
