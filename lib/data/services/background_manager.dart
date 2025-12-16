import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // --- 1. BİLDİRİM EKLENTİSİNİ BURADA DA HAZIRLIYORUZ ---
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // İkon ayarı (Hata almadığın launcher_icon)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // -----------------------------------------------------

  Map<String, String> vakitler = {};

  service.on('setPrayerTimes').listen((event) {
    if (event != null) {
      try {
        vakitler = Map<String, String>.from(event);
        // Güncelleme fonksiyonuna plugin'i de gönderiyoruz
        BackgroundManager._updateNotification(
          service,
          vakitler,
          flutterLocalNotificationsPlugin,
        );
      } catch (e) {
        print("Hata: $e");
      }
    }
  });

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (vakitler.isNotEmpty) {
      BackgroundManager._updateNotification(
        service,
        vakitler,
        flutterLocalNotificationsPlugin,
      );
    }
  });
}

class BackgroundManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vaktinde_sticky_channel',
      'Vakit Sayacı',
      description: 'Namaz vaktine kalan süreyi gösterir',
      importance: Importance.low, // Sessiz
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'vaktinde_sticky_channel',
        initialNotificationTitle: 'Vaktinde',
        initialNotificationContent: 'Başlatılıyor...',
        foregroundServiceNotificationId: 888, // Bu ID çok önemli
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }

  // --- GÜNCELLEME FONKSİYONU (ARTIK KENDİ BİLDİRİMİMİZİ BASIYORUZ) ---
  static void _updateNotification(
    ServiceInstance service,
    Map<String, String> vakitler,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final now = DateTime.now();
        String nextVakit = "İmsak";
        DateTime? nextTime;

        // Vakit bulma mantığı...
        for (var entry in vakitler.entries) {
          try {
            List<String> parts = entry.value.split(':');
            DateTime vTime = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            if (vTime.isAfter(now)) {
              nextVakit = entry.key;
              nextTime = vTime;
              break;
            }
          } catch (e) {
            continue;
          }
        }

        if (nextTime == null && vakitler.containsKey("İmsak")) {
          try {
            List<String> parts = vakitler["İmsak"]!.split(':');
            nextTime = DateTime(
              now.year,
              now.month,
              now.day + 1,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            nextVakit = "İmsak";
          } catch (e) {}
        }

        if (nextTime != null) {
          Duration diff = nextTime.difference(now);
          String kalanSure =
              "${diff.inHours} sa ${diff.inMinutes.remainder(60)} dk";

          String title = "Sıradaki: $nextVakit ($kalanSure)";
          String body = vakitler.entries
              .map((e) => "${e.key}:${e.value}")
              .join(" | ");

          // --- İŞTE SİHİRLİ DOKUNUŞ BURASI ---
          // Servisin kendi kısıtlı metodunu kullanmıyoruz.
          // Manuel olarak "Large Icon" (Büyük Renkli İkon) ekleyip basıyoruz.

          await flutterLocalNotificationsPlugin.show(
            888, // Servis ID'si ile aynı olmalı ki üzerine yazsın!
            title,
            body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'vaktinde_sticky_channel',
                'Vakit Sayacı',
                icon: '@mipmap/launcher_icon', // Küçük ikon (mecburen kalır)
                // >>> BU SATIR SENİN RENKLİ İKONUNU GERİ GETİRECEK <<<
                largeIcon: DrawableResourceAndroidBitmap(
                  '@mipmap/launcher_icon',
                ),

                // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                ongoing: true, // Silinemez yap
                importance: Importance.low,
                priority: Priority.low,
                showWhen: false,
              ),
            ),
          );
        }
      }
    }
  }
}
