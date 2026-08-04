import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  Map<String, String> display = {};
  SharedPreferences prefs = await SharedPreferences.getInstance();
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
}

class BackgroundManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const channel = AndroidNotificationChannel(
      'vaktinde_sticky_channel',
      'Prayer Times',
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
        initialNotificationTitle: '', //'Vaktinde',
        initialNotificationContent: '', //'Hesaplanıyor...',
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
