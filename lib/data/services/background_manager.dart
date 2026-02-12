import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- YARDIMCI MODEL ---
class NextVakitInfo {
  final String internalName; // Hesaplama için (İmsak)
  final DateTime time;
  NextVakitInfo(this.internalName, this.time);
}

// --- HESAPLAMA MANTIĞI ---
NextVakitInfo? globalFindNextVakit(Map<String, String> vakitler) {
  final now = DateTime.now();
  // Bu sıra hesaplama için sabittir, dile göre değişmez.
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

  // Yarına sarkma (İmsak)
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

// Format: 02:45:12
String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String hours = twoDigits(d.inHours);
  String minutes = twoDigits(d.inMinutes.remainder(60));
  String seconds = twoDigits(d.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// --- SERVİS BAŞLANGIÇ ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  // İlk açılış bildirimi (Dil verisi gelene kadar İngilizce/Global)
  if (service is AndroidServiceInstance) {
    await notifications.show(
      888,
      'Vaktinde',
      'Loading...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaktinde_sticky_channel',
          'Prayer Times',
          icon: '@mipmap/launcher_icon',
          ongoing: true,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showWhen: false,
        ),
      ),
    );
  }

  Map<String, String> vakitler = {};
  Map<String, String> display = {}; // Çevirileri tutacak harita
  Timer? _timer;

  service.on('setPrayerTimes').listen((event) {
    if (event == null) return;
    try {
      // Gelen veri yapısı: { "times": {...}, "display": {...} }
      final data = Map<String, dynamic>.from(event);

      if (data.containsKey('times')) {
        vakitler = Map<String, String>.from(data['times']);
      }
      if (data.containsKey('display')) {
        display = Map<String, String>.from(data['display']);
      }

      _timer?.cancel();

      // Saniyelik döngü
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        final nextInfo = globalFindNextVakit(vakitler);

        if (nextInfo != null) {
          final now = DateTime.now();
          final difference = nextInfo.time.difference(now);

          // DİL DESTEĞİ BURADA DEVREYE GİRİYOR
          // nextInfo.internalName -> "İkindi" (sabit anahtar)
          // display[nextInfo.internalName] -> "Asr" (çevrilmiş isim)

          String localizedVakitName =
              display[nextInfo.internalName] ?? nextInfo.internalName;
          String nextTitleLabel = display['next'] ?? "Next";
          String remainingLabel = display['remaining'] ?? "Left";

          String title = "$nextTitleLabel: $localizedVakitName";
          String body = "$remainingLabel: ${_formatDuration(difference)}";

          // Tabloyu oluştururken çevirileri kullan
          // \u2003 = Geniş boşluk
          String bigText =
              "${display['İmsak']}\u2003${display['Güneş']}\u2003${display['Öğle']}\u2003${display['İkindi']}\u2003${display['Akşam']}\u2003${display['Yatsı']}\n"
              "${vakitler['İmsak']}\u2003${vakitler['Güneş']}\u2003${vakitler['Öğle']}\u2003${vakitler['İkindi']}\u2003${vakitler['Akşam']}\u2003${vakitler['Yatsı']}";

          final BigTextStyleInformation bigTextStyleInformation =
              BigTextStyleInformation(
                bigText,
                contentTitle: title,
                summaryText: body,
              );

          if (service is AndroidServiceInstance) {
            if (await service.isForegroundService()) {
              await notifications.show(
                888,
                title,
                body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    'vaktinde_sticky_channel',
                    'Prayer Times',
                    icon: '@mipmap/launcher_icon',
                    ongoing: true,
                    autoCancel: false,
                    importance: Importance.low,
                    priority: Priority.low,
                    onlyAlertOnce: true,
                    playSound: false,
                    enableVibration: false,
                    showWhen: false,
                    styleInformation: bigTextStyleInformation,
                  ),
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      print("Background Error: $e");
    }
  });
}

class BackgroundManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const channel = AndroidNotificationChannel(
      'vaktinde_sticky_channel',
      'Prayer Times',
      description: 'Shows prayer times and countdown',
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
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channel.id,
        initialNotificationTitle: 'Vaktinde',
        initialNotificationContent: 'Loading...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );

    await service.startService();
  }
}
