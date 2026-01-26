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
      await androidImplementation?.requestNotificationsPermission();
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
    String channelId = soundName != null
        ? 'channel_$soundName'
        : 'channel_silent_prayer';
    String channelName = soundName != null
        ? 'Ses: $soundName'
        : 'Sessiz Ezan Bildirimleri';
    bool playSound = soundName != null;
    RawResourceAndroidNotificationSound? soundSource = soundName != null
        ? RawResourceAndroidNotificationSound(soundName)
        : null;

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

  // --- 🔥 PRO TASARIM GÜNCELLEMESİ BURADA ---
  Future<void> showStickyNotification({
    required String title, // Kapalıyken görünen başlık (Örn: Sıradaki: İmsak)
    required String body, // Kapalıyken görünen metin (Örn: Kalan Süre...)
    required String bigContent, // AÇILINCA görünen tablo metni
    DateTime? endTime,
  }) async {
    // Pro Tasarım: BigTextStyle
    final BigTextStyleInformation
    bigTextStyleInformation = BigTextStyleInformation(
      bigContent, // Genişleyince çıkacak olan o tablo yapısı
      htmlFormatBigText: false,

      contentTitle: title, // Genişleyince üstte kalan başlık
      htmlFormatContentTitle: false,

      summaryText:
          "Vaktin Çıkmasına: ", // Sağ üstte uygulama adının yanındaki küçük yazı
      htmlFormatSummaryText: false,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'vaktinde_sticky_channel',
          'Kalıcı Sayaç',
          channelDescription: 'Vakte kalan süreyi gösterir',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigTextStyleInformation, // <-- Özel tasarım stili
          // KRONOMETRE AYARLARI (Sağ üstte saniye sayar)
          usesChronometer: endTime != null,
          chronometerCountDown: endTime != null,
          when: endTime?.millisecondsSinceEpoch,
          showWhen: true,
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
