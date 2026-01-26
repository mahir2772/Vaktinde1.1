import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- GLOBAL ALAN ---

class NextVakitInfo {
  final String name;
  final DateTime time;
  NextVakitInfo(this.name, this.time);
}

// 1. Sıradaki Vakti Bulan Fonksiyon (Düzeltilmiş)
NextVakitInfo? globalFindNextVakit(Map<String, String> vakitler) {
  final now = DateTime.now();

  // Vakit sıralaması
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

      // Şimdiki zamandan ilerideyse bu vakti seç
      if (time.isAfter(now)) {
        return NextVakitInfo(vakit, time);
      }
    } catch (e) {
      continue;
    }
  }

  // Eğer bugünkü tüm vakitler geçtiyse, yarının İmsak vaktini bul
  if (vakitler.containsKey("İmsak")) {
    try {
      final parts = vakitler["İmsak"]!.split(':');
      // now.day + 1 diyerek yarını veriyoruz (Dart tarihi otomatik düzeltir)
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

// 2. Bildirimi Güncelleyen Fonksiyon (YENİ SADE TASARIM)
Future<void> globalUpdateNotification(
  ServiceInstance service,
  Map<String, String> vakitler,
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  NextVakitInfo nextInfo,
) async {
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      // --- YENİ TASARIM: SADE VE ŞIK ---
      String title = "Sıradaki Vakit: ${nextInfo.name}";

      // Android chronometer kullanacağı için body'ye sadece etiketi yazıyoruz.
      // Sistem saati otomatik olarak yanına koyacak.
      String body = "Vaktin Çıkmasına:";

      await flutterLocalNotificationsPlugin.show(
        888,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vaktinde_sticky_channel',
            'Vaktin Çıkmasına',
            icon: '@mipmap/launcher_icon',
            // Büyük ikon olarak da uygulama logosunu kullanıyoruz, temiz durur.
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/launcher_icon',
            ),

            // --- SAYAÇ AYARLARI ---
            usesChronometer: true, // Sistem sayacını kullan
            chronometerCountDown: true, // Geri sayım modu
            when: nextInfo.time.millisecondsSinceEpoch, // Hedef zaman
            // --- DİĞER GÖRSEL AYARLAR ---
            showWhen: true,
            ongoing: true, // Bildirim silinemez (sabit)
            autoCancel: false,
            importance: Importance.low, // Ses çıkarmasın
            priority: Priority.low,
            showProgress: false,
            onlyAlertOnce: true, // Her güncellemede titremesin
            // Gereksiz "BigText" stillerini kaldırdık, standart görünüm kullandık.
            // Bu sayede o karmaşık tablo yerine sade bir satır görünecek.
          ),
        ),
      );
    }
  }
}

// --- SERVİS BAŞLANGIÇ NOKTASI ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  Map<String, String> vakitler = {};
  Timer? nextVakitTimer;

  service.on('setPrayerTimes').listen((event) {
    if (event == null) return;
    try {
      vakitler = Map<String, String>.from(event);

      // Mevcut sayacı iptal et
      nextVakitTimer?.cancel();

      // Yeni hedefi bul
      final nextInfo = globalFindNextVakit(vakitler);
      if (nextInfo == null) return;

      // Bildirimi güncelle
      globalUpdateNotification(service, vakitler, notifications, nextInfo);

      // Hedef zamana kadar bekle
      final now = DateTime.now();
      final duration = nextInfo.time.difference(now);

      // Eğer süre pozitifse timer kur (Eksiye düşmeyi engellemek için)
      if (duration.inSeconds > 0) {
        // Süre bitince (veya 1 saniye sonra) tekrar kontrol et
        // duration + 1 saniye ekliyoruz ki tam 00:00'da kalmasın, diğer vakte geçsin
        nextVakitTimer = Timer(duration + const Duration(seconds: 2), () {
          // Timer bittiğinde vakitleri tekrar kontrol et ve bildirimi güncelle
          final newNext = globalFindNextVakit(vakitler);
          if (newNext != null) {
            globalUpdateNotification(service, vakitler, notifications, newNext);
          }
        });
      } else {
        // Eğer süre zaten geçmişse hemen bir sonrakini bulmaya çalış
        final newNext = globalFindNextVakit(vakitler);
        if (newNext != null) {
          globalUpdateNotification(service, vakitler, notifications, newNext);
        }
      }
    } catch (e) {
      print("Background Hata: $e");
    }
  });
}

// --- YÖNETİCİ SINIF ---
class BackgroundManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    const channel = AndroidNotificationChannel(
      'vaktinde_sticky_channel',
      'Vaktin Çıkmasına',
      description: 'Namaz vaktine kalan süreyi gösterir',
      importance: Importance.low,
      showBadge: false,
    );
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: channel.id,
        initialNotificationTitle: 'Vaktin Çıkmasına',
        initialNotificationContent: 'Hesaplanıyor...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }
}
