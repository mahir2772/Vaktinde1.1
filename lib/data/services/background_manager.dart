import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'serial_queue.dart';
import 'storage_service.dart';

/// Kalıcı bildirim (888, sıradaki vakte kalan süre). Ön plan servisi yok:
/// bildirimi native NotificationUpdater çizer ve vakit gelince alarmla kendini
/// yeniler (telefon açılışında ve güncellemeden sonra da). Sistem bildirimi
/// çizemezse sadece o bildirim düşer, uygulama kapanmaz.
class BackgroundManager {
  /// Native taraf (NotificationUpdater, WidgetRefresher) ayarı HomeWidget
  /// verisinden okur; yoksa açık sayar (ayardan önceki sürümün verisi)
  static const String widgetFlagKey = 'persistent_notification';

  /// Kalıcı bildirimin kanalı (NotificationUpdater aynı kimlikle çizer)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'vaktinde_sticky_channel',
    'Prayer Times',
    importance: Importance.low,
    showBadge: false,
  );

  /// main(): kalıcı bildirim ayarı (yoksa karar burada yazılır) uygulanır
  static Future<void> initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    // 1.4.0 öncesi ön plan servisinin metin önbelleği
    await prefs.remove('bg_display');
    await apply(await StorageService.ensurePersistentNotification(prefs));
  }

  /// Açıkken 888 çizilir; kapalıyken 888 ve yenileme alarmı kaldırılır.
  /// Widget'lar, ezan alarmları, WorkManager etkilenmez.
  static Future<void> apply(bool enabled) =>
      _applyQueue.run(() => _apply(enabled));

  // Üst üste gelen aç/kapat sırayla uygulanır
  static final SerialQueue _applyQueue = SerialQueue();

  static Future<void> _apply(bool enabled) async {
    // Önce bayrak: NotificationUpdater ona bakarak çizer ya da kaldırır
    await HomeWidget.saveWidgetData<bool>(widgetFlagKey, enabled);
    if (enabled) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
    await HomeWidget.updateWidget(
      name: 'NotificationUpdater',
      androidName: 'NotificationUpdater',
    );
  }
}
