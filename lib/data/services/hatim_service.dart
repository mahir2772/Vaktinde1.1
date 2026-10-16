import 'dart:math' as math;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notification_routes.dart';
import '../../l10n/app_localizations.dart';
import 'error_reporter.dart';
import 'hatim.dart';
import 'notification_service.dart';
import 'prayer_tracker.dart';
import 'serial_queue.dart';

/// Kur'an listesinin ve ana ekranın gösterdiği hatim durumu
typedef HatimState = ({
  HatimPlan? plan,
  int count,
  bool reminder,
  int reminderTime,
});

/// Hatim planı ('hatim_plan'), tamamlanan hatim sayısı ('hatim_count') ve
/// günlük hatırlatma ('hatim_reminder_enabled' varsayılan kapalı,
/// 'hatim_reminder_time' günün dakikası, varsayılan 21:00). Değişiklikler
/// sırayla yazılır; [changes] artar (Kur'an listesi ve ana ekran hemen
/// yenilenir), hatırlatma açıksa yeniden kurulur.
class HatimService {
  static const String planKey = 'hatim_plan';
  static const String countKey = 'hatim_count';
  static const String reminderKey = 'hatim_reminder_enabled';
  static const String reminderTimeKey = 'hatim_reminder_time';
  static const int defaultReminderTime = 21 * 60;

  /// Hatırlatma bildirimi: ID (diğer aralıklarla çakışmaz) ve dokununca
  /// açılacak yer (hatim okuması)
  static const int reminderId = 1100;
  static final String reminderPayload = NotificationRoutes.route(
    NotificationRoutes.hatim,
  );

  /// Plan, sayaç ya da hatırlatma değişti
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final SerialQueue _queue = SerialQueue();
  static Future<QuranPages>? _pages;

  final NotificationService _notifications = NotificationService();
  final DateTime Function() _clock;

  /// [clock]: test için
  HatimService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Sayfa tablosu uygulama boyunca bir kez okunur
  static Future<QuranPages> loadPages() => _pages ??= rootBundle
      .loadString(QuranPages.asset)
      .then(
        (raw) =>
            QuranPages.parse(raw) ?? (throw StateError('sayfa tablosu bozuk')),
      );

  static int _reminderTime(SharedPreferences prefs) =>
      (prefs.getInt(reminderTimeKey) ?? defaultReminderTime).clamp(0, 1439);

  Future<HatimState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        plan: HatimPlan.parse(prefs.getString(planKey)),
        count: math.max(0, prefs.getInt(countKey) ?? 0),
        reminder: prefs.getBool(reminderKey) ?? false,
        reminderTime: _reminderTime(prefs),
      );
    } catch (_) {
      return (
        plan: null,
        count: 0,
        reminder: false,
        reminderTime: defaultReminderTime,
      );
    }
  }

  /// Yeni hatim: bugün başlar, [target] gününe kadar
  Future<void> begin(DateTime target) =>
      _update((_, today) => HatimPlan.begin(today, target));

  /// "Planı Değiştir": konum ve kayıt korunur
  Future<void> changeTarget(DateTime target) =>
      _update((plan, _) => plan?.withTarget(target));

  /// "Sayfa Gir"; hatim bu girişle tamamlandıysa true
  Future<bool> setPosition(int page) =>
      _update((plan, today) => plan?.withPosition(page, today));

  /// Okuyucuda görünen sayfa: sırayla ilerlediyse hatim konumu ilerler.
  /// Hatim bu adımda tamamlandıysa true.
  Future<bool> advanceTo(int page) =>
      _update((plan, today) => plan?.advancedTo(page, today) ?? plan);

  /// "Hatmi Sil": tamamlanan hatim sayısı kalır
  Future<void> delete() => _update((_, _) => null);

  /// Değişmeyen plan ([change] aynı nesneyi döner) yazılmaz. Hatim bu
  /// değişiklikle bittiyse sayaç artar ve true döner.
  Future<bool> _update(
    HatimPlan? Function(HatimPlan? plan, DateTime today) change,
  ) => _queue.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final before = HatimPlan.parse(prefs.getString(planKey));
    final after = change(before, PrayerTracker.day(_clock()));
    if (identical(after, before)) return false;
    if (after == null) {
      await prefs.remove(planKey);
    } else {
      await prefs.setString(planKey, after.encode());
    }
    final completed =
        (after?.isFinished ?? false) && !(before?.isFinished ?? false);
    if (completed) {
      await prefs.setInt(countKey, (prefs.getInt(countKey) ?? 0) + 1);
    }
    changes.value++;
    if (prefs.getBool(reminderKey) ?? false) await _syncReminder();
    return completed;
  });

  /// Hatırlatma ayarı ([time]: günün dakikası)
  Future<void> setReminder({bool? enabled, int? time}) => _queue.run(() async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) await prefs.setBool(reminderKey, enabled);
    if (time != null) await prefs.setInt(reminderTimeKey, time);
    changes.value++;
    await _syncReminder();
  });

  /// Açılışta, dil değişince ve yedekten dönüşte: hatırlatma yeniden kurulur,
  /// ekranlar kayıttan yenilenir (geri yüklenen plan hemen görünür)
  Future<void> syncReminder() => _queue.run(() {
    changes.value++;
    return _syncReminder();
  });

  /// Açıksa ve hatim sürüyorsa her gün seçilen saatte ([HatimPlan.reminderStart]
  /// gününden başlar), değilse kurulu olan iptal edilir. Metin kayıtlı dilde
  /// (eski sayı içermez); kurulamazsa Crashlytics'e bildirilir.
  Future<void> _syncReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final start = (prefs.getBool(reminderKey) ?? false)
          ? HatimPlan.parse(
              prefs.getString(planKey),
            )?.reminderStart(_reminderTime(prefs), _clock())
          : null;
      if (start == null) {
        if ((await _notifications.pendingIds()).contains(reminderId)) {
          await _notifications.cancel(reminderId);
        }
        return;
      }
      final loc = lookupAppLocalizations(
        Locale(prefs.getString('language_code') ?? 'tr'),
      );
      await _notifications.scheduleDailyReminder(
        id: reminderId,
        title: loc.hatimTitle,
        body: loc.hatimReminderBody,
        time: start,
        channelId: 'hatim_reminder_channel',
        channelName: loc.hatimReminderChannel,
        payload: reminderPayload,
      );
    } catch (e, st) {
      await reportNonFatal(e, st, reason: 'hatim hatırlatması kurulamadı');
    }
  }
}
