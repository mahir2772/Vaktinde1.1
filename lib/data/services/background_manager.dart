import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_tracker_service.dart';
import 'serial_queue.dart';
import 'storage_service.dart';

class NextVakitInfo {
  final String internalName;
  final DateTime time;
  NextVakitInfo(this.internalName, this.time);
}

NextVakitInfo? globalFindNextVakit(Map<String, String> vakitler) {
  final now = DateTime.now();
  final List<String> vakitSirasi = [
    "İmsak",
    "Güneş",
    "Öğle",
    "İkindi",
    "Akşam",
    "Yatsı",
  ];

  for (final vakit in vakitSirasi) {
    if (!vakitler.containsKey(vakit)) continue;
    try {
      final parts = vakitler[vakit]!.split(':');
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (time.isAfter(now)) return NextVakitInfo(vakit, time);
    } catch (e) {
      continue;
    }
  }

  if (vakitler.containsKey("İmsak")) {
    try {
      final parts = vakitler["İmsak"]!.split(':');
      final time = DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return NextVakitInfo("İmsak", time);
    } catch (e) {
      return null;
    }
  }
  return null;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Kalıcı bildirim kapalıyken başlatıldıysa (eski açılış ayarı, yedekten
  // dönen eklenti kaydı, bekçi alarmı) hemen durur; açılışta bir daha başlamaz
  if (!StorageService.persistentNotificationOf(prefs)) {
    if (service is AndroidServiceInstance) {
      await service.setAutoStartOnBootMode(false);
    }
    await service.stopSelf();
    return;
  }
  // Ayar kapatılınca (BackgroundManager.apply): eklentinin "elle durduruldu"
  // kaydıyla durur, bekçi alarmı yeniden başlatmaz. İstek gelene kadar ayar
  // yeniden açıldıysa (hızlı kapat-aç) durmaz
  service.on(BackgroundManager.stopEvent).listen((_) async {
    await prefs.reload();
    if (!StorageService.persistentNotificationOf(prefs)) {
      await service.stopSelf();
    }
  });

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  // NotificationService.init ile aynı işleyici: "Kıldım" aksiyonu kaybolmasın
  await notifications.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground,
  );

  Map<String, String> display = {};
  String? savedDisplay = prefs.getString('bg_display');

  if (savedDisplay != null) {
    display = Map<String, String>.from(jsonDecode(savedDisplay));
  }

  if (service is AndroidServiceInstance) {
    await notifications.show(
      888,
      display['next'] ?? 'Vaktinde',
      display['loading'] ?? 'Hesaplanıyor...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaktinde_sticky_channel',
          'Prayer Times',
          ongoing: true,
          importance: Importance.low,
          priority: Priority.low,
          showWhen: false,
        ),
      ),
    );
  }

  // Sadece başlık gibi temel metinleri dinlemeye devam ederiz, matematiksel hesaplar artık Native'de!
  service.on('setPrayerTimes').listen((event) async {
    if (event == null) return;
    try {
      final data = Map<String, dynamic>.from(event);
      if (data.containsKey('display')) {
        display = Map<String, String>.from(data['display']);
        await prefs.setString('bg_display', jsonEncode(display));
      }
    } catch (e) {
      debugPrint("Arka plan dinleme hatası: $e");
    }
  });

  // Yer tutucu bildirim gerçek sayacı ezmesin (soğuk başlangıç, yeniden başlatma, güncelleme):
  // kayıtlı vakit varsa NotificationUpdater 888'i hemen asıl içerikle yeniden çizer
  if (service is AndroidServiceInstance) {
    try {
      final imsak = await HomeWidget.getWidgetData<String>('imsak_time');
      if (imsak != null && imsak.isNotEmpty) {
        await HomeWidget.updateWidget(
          name: 'NotificationUpdater',
          androidName: 'NotificationUpdater',
        );
      }
    } catch (e) {
      debugPrint("Kalıcı bildirim yenilenemedi: $e");
    }
  }
}

class BackgroundManager {
  /// Native taraf (NotificationUpdater, WidgetRefresher) ayarı HomeWidget
  /// verisinden okur; yoksa açık sayar (ayardan önceki sürümün verisi)
  static const String widgetFlagKey = 'persistent_notification';

  /// Servis isolate'ine "dur" isteği (onStart dinler)
  static const String stopEvent = 'stopService';

  /// main(): kalıcı bildirim ayarı (yoksa karar burada yazılır) uygulanır
  static Future<void> initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    await apply(await StorageService.ensurePersistentNotification(prefs));
  }

  /// Kalıcı bildirim açıkken ön plan servisi başlar (telefon açılışında da)
  /// ve 888 çizilir; kapalıyken servis durur, açılışta başlamaz, 888 ve
  /// yenileme alarmı kaldırılır. Widget'lar, ezan alarmları, WorkManager
  /// etkilenmez.
  static Future<void> apply(bool enabled) =>
      _applyQueue.run(() => _apply(enabled));

  // Üst üste gelen aç/kapat sırayla uygulanır
  static final SerialQueue _applyQueue = SerialQueue();

  static Future<void> _apply(bool enabled) async {
    // Önce bayrak: başlayan servis 888'i çizebilsin, durunca geri gelmesin
    await HomeWidget.saveWidgetData<bool>(widgetFlagKey, enabled);
    final service = FlutterBackgroundService();

    const channel = AndroidNotificationChannel(
      'vaktinde_sticky_channel',
      'Prayer Times',
      importance: Importance.low,
      showBadge: false,
    );

    // Ön plan bildirimi kanalsız başlatılamaz (yeni kurulumda ilk açılış)
    if (enabled) {
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // Eklenti telefon açılışında başlatma ayarını (auto_start_on_boot) kendi
    // kaydına sadece configure'da yazar: kapatırken de çağrılır
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: enabled,
        isForegroundMode: true,
        notificationChannelId: channel.id,
        initialNotificationTitle: '', //'Vaktinde',
        initialNotificationContent: '', //'Hesaplanıyor...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.specialUse],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );

    if (enabled) {
      await service.startService();
      return;
    }
    service.invoke(stopEvent);
    // Servis dışında çizilmiş 888 (NotificationUpdater bayrağa bakıp kaldırır)
    await HomeWidget.updateWidget(
      name: 'NotificationUpdater',
      androidName: 'NotificationUpdater',
    );
  }
}
