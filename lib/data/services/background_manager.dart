import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
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

  Map<String, String> vakitler = {};
  Map<String, String> display = {};

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedTimes = prefs.getString('bg_vakitler');
  String? savedDisplay = prefs.getString('bg_display');

  if (savedTimes != null) {
    vakitler = Map<String, String>.from(jsonDecode(savedTimes));
  }
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

  int? lastTargetTimeMs;

  service.on('setPrayerTimes').listen((event) async {
    if (event == null) return;
    try {
      final data = Map<String, dynamic>.from(event);
      if (data.containsKey('times')) {
        vakitler = Map<String, String>.from(data['times']);
        await prefs.setString('bg_vakitler', jsonEncode(vakitler));
      }
      if (data.containsKey('display')) {
        display = Map<String, String>.from(data['display']);
        await prefs.setString('bg_display', jsonEncode(display));
      }

      // İŞTE İNADI KIRAN SİHİRLİ SATIR BURASI!
      // Yeni dil paketi geldiği an, eski zaman hafızasını sıfırlıyoruz
      // Böylece aşağıdaki Timer saniyeler içinde "Aaa zaman değişmiş (null olmuş)" diyerek bildirimi zorla yeniden çiziyor.
      lastTargetTimeMs = null;
    } catch (e) {
      print(e.toString());
    }
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (vakitler.isEmpty) return;

    final nextInfo = globalFindNextVakit(vakitler);

    if (nextInfo != null) {
      final currentTargetMs = nextInfo.time.millisecondsSinceEpoch;

      if (lastTargetTimeMs != currentTargetMs) {
        lastTargetTimeMs = currentTargetMs;

        String dinamikBaslik =
            display['to_${nextInfo.internalName}'] ??
            display['remaining'] ??
            "Kalan";

        await HomeWidget.saveWidgetData<int>('target_time_ms', currentTargetMs);
        await HomeWidget.saveWidgetData<String>('title_text', dinamikBaslik);
        await HomeWidget.updateWidget(
          name: 'VaktindeWidgetSmallProvider',
          androidName: 'VaktindeWidgetSmallProvider',
        );
        await HomeWidget.updateWidget(
          name: 'VaktindeWidgetLargeProvider',
          androidName: 'VaktindeWidgetLargeProvider',
        );

        String localizedVakitName =
            display[nextInfo.internalName] ?? nextInfo.internalName;
        String nextTitleLabel = display['next'] ?? "Next";

        String targetHour = nextInfo.time.hour.toString().padLeft(2, '0');
        String targetMinute = nextInfo.time.minute.toString().padLeft(2, '0');

        String title = "$nextTitleLabel: $localizedVakitName";
        String body = "$localizedVakitName -> $targetHour:$targetMinute";

        String bigText =
            "${display['İmsak'] ?? 'İmsak'}\u2003${display['Güneş'] ?? 'Güneş'}\u2003${display['Öğle'] ?? 'Öğle'}\u2003${display['İkindi'] ?? 'İkindi'}\u2003${display['Akşam'] ?? 'Akşam'}\u2003${display['Yatsı'] ?? 'Yatsı'}\n${vakitler['İmsak'] ?? '--:--'}\u2003${vakitler['Güneş'] ?? '--:--'}\u2003${vakitler['Öğle'] ?? '--:--'}\u2003${vakitler['İkindi'] ?? '--:--'}\u2003${vakitler['Akşam'] ?? '--:--'}\u2003${vakitler['Yatsı'] ?? '--:--'}";

        final BigTextStyleInformation bigTextStyleInformation =
            BigTextStyleInformation(
              bigText,
              contentTitle: title,
              summaryText: body,
            );

        if (service is AndroidServiceInstance) {
          await notifications.show(
            888,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'vaktinde_sticky_channel',
                'Prayer Times',
                ongoing: true,
                autoCancel: false,
                importance: Importance.low,
                priority: Priority.low,
                onlyAlertOnce: true,
                playSound: false,
                enableVibration: false,
                showWhen: true,
                usesChronometer: true,
                chronometerCountDown: true,
                when: currentTargetMs,
                styleInformation: bigTextStyleInformation,
              ),
            ),
          );
        }
      }
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
        initialNotificationTitle: 'Vaktinde',
        initialNotificationContent: 'Hesaplanıyor...',
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
