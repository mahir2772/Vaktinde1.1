import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // 1. Bildirim Gönderme İzni (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // 2. Tam Zamanlı Alarm İzni (Android 12+) - İŞTE BU EKLENDİ ✅
      // Bu komut, kullanıcıyı "Alarmlar ve Hatırlatıcılar" ekranına yönlendirir
      // veya izin istendiğini belirtir. Bu olmadan ezan vaktinde çalmaz.
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundName,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    String channelId;
    String channelName;
    bool playSound;
    RawResourceAndroidNotificationSound? soundSource;

    if (soundName != null) {
      channelId = 'channel_$soundName';
      channelName = 'Ses: $soundName';
      playSound = true;
      soundSource = RawResourceAndroidNotificationSound(soundName);
    } else {
      channelId = 'channel_silent_prayer';
      channelName = 'Sessiz Ezan Bildirimleri';
      playSound = false;
      soundSource = null;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          ticker: 'Ezan Vakti',
          icon: '@mipmap/launcher_icon',
          visibility: NotificationVisibility.public,
          sound: soundSource,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: playSound,
          sound: soundName != null ? '$soundName.mp3' : null,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  Future<void> showStickyNotification({
    required String title,
    required String body,
  }) async {
    // HTML formatı kapalı (false), düz metin
    final BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
        );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'sticky_channel_id_simple',
          'Kalıcı Sayaç',
          channelDescription: 'Vakte kalan süreyi gösterir',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          showWhen: false,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigTextStyleInformation,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(888, title, body, platformChannelSpecifics);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
