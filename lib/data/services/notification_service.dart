import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'prayer_tracker.dart';
import 'prayer_tracker_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      // IDE hatasını ve sürüm farklarını %100 çözen dinamik yapı:
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      String tzName = '';
      if (tzInfo is String) {
        tzName = tzInfo;
      } else {
        tzName = tzInfo.name ?? tzInfo.identifier ?? tzInfo.toString();
      }
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 🔥 İŞTE ÇÖZÜM BURADA: Otomatik izin istemeyi (true olanları false yaparak) kapattık!
    // Artık izinleri sadece main.dart'taki Showcase turu bittikten sonra isteyeceğiz.
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    // "Kıldım" aksiyonu için arka plan işleyicisi (her initialize'da aynı)
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground,
    );
  }

  static AndroidNotificationAction prayedAction(String label) =>
      AndroidNotificationAction(
        PrayerTracker.actionId,
        label,
        showsUserInterface: false,
        cancelNotification: true,
      );

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
    required String localizedChannelName,
    required String localizedTicker,
    String? payload,
    String? actionLabel, // verilirse "Kıldım" butonu eklenir
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    String channelId = soundName != null
        ? 'channel_$soundName'
        : 'channel_silent_prayer';

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
          localizedChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          ticker: localizedTicker,
          icon: '@mipmap/launcher_icon',
          sound: soundSource,
          enableVibration: true,
          actions: actionLabel != null ? [prayedAction(actionLabel)] : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: playSound,
          sound: soundName != null ? '$soundName.mp3' : null,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );
  }

  /// "Vakit çıkıyor" hatırlatması (ID 100-124): ayrı kanal, normal önem, varsayılan ses
  Future<void> scheduleEndReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String localizedChannelName,
    required String actionLabel,
    required String payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_end_reminder',
          localizedChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
          actions: [prayedAction(actionLabel)],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );
  }

  Future<void> showStickyNotification({
    required String title,
    required String body,
    required String bigContent,
    required String localizedSummaryText,
    required String localizedChannelName,
    required String localizedChannelDesc,
    DateTime? endTime,
  }) async {
    final BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
          bigContent,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: localizedSummaryText,
          htmlFormatSummaryText: false,
        );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'vaktinde_sticky_channel',
          localizedChannelName,
          channelDescription: localizedChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigTextStyleInformation,
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

  Future<void> scheduleDailyContent({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
  }) async {
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      String tzName = '';
      if (tzInfo is String) {
        tzName = tzInfo;
      } else {
        tzName = tzInfo.name ?? tzInfo.identifier ?? tzInfo.toString();
      }
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
        );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: bigTextStyleInformation,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Kurulu (henüz çalmamış) bildirimlerin ID'leri
  Future<Set<int>> pendingIds() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toSet();
  }

  Future<void> cancel(int id) => _notificationsPlugin.cancel(id);

  // 🔥 İŞTE HAYAT KURTARAN YENİ FONKSİYONUMUZ
  Future<void> cancelSpecificAlarms() async {
    // Sadece namaz (0-59 arası, 5 gün x 12), vakit çıkış hatırlatması (100-124) ve
    // günlük (1000, 1900) alarmları siler.
    // 888 ID'Lİ ARKA PLAN YAPIŞKAN BİLDİRİMİNE ASLA DOKUNMAZ!
    for (int i = 0; i < 60; i++) {
      await _notificationsPlugin.cancel(i);
    }
    for (int i = 100; i < 125; i++) {
      await _notificationsPlugin.cancel(i);
    }
    await _notificationsPlugin.cancel(1000);
    await _notificationsPlugin.cancel(1900);
  }
}
