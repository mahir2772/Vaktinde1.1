import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'prayer_tracker.dart';
import 'prayer_tracker_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Son bilinen tam zamanlı alarm izni (arayüz uyarısı ve arka plan görevi okur)
  static const String exactAlarmsAllowedKey = 'exact_alarms_allowed';

  /// İzin yokken alarmClock kurulumunda eklentinin döndürdüğü hata kodu
  static const String exactAlarmsDeniedCode = 'exact_alarms_not_permitted';

  // Bu nesnede bilinen izin durumu; null: bilinmiyor (önce tam zamanlı denenir)
  bool? _exactAllowed;

  AndroidFlutterLocalNotificationsPlugin? get _android => _notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// İzin varsa (ya da bilinmiyorsa) alarmClock: tam vaktinde. Yoksa
  /// inexactAllowWhileIdle: gecikebilir ama yine çalar (alarmClock hiç kurulmaz).
  static AndroidScheduleMode scheduleModeFor(bool? exactAllowed) =>
      exactAllowed == false
      ? AndroidScheduleMode.inexactAllowWhileIdle
      : AndroidScheduleMode.alarmClock;

  /// Ezan/hatırlatma kanalı. Android'de kanalın sesi ve ses türü sonradan
  /// değişmez: "sessiz modda da çal" için ayrı "alarm_" kanalları (alarm ses
  /// akışı); eski kanallar kapalı hali için kalır. Sesi olmayan bildirim etkilenmez.
  static ({String id, AudioAttributesUsage usage}) prayerChannel(
    String? soundName, {
    bool alarmStream = false,
  }) {
    if (soundName == null) {
      return (
        id: 'channel_silent_prayer',
        usage: AudioAttributesUsage.notification,
      );
    }
    if (alarmStream) {
      return (
        id: 'alarm_channel_$soundName',
        usage: AudioAttributesUsage.alarm,
      );
    }
    return (id: 'channel_$soundName', usage: AudioAttributesUsage.notification);
  }

  /// "Sessiz modda da çal" sadece Android 8+ (API 26) çalışır: alarm ses türü
  /// bildirim kanalıyla verilir, 7.x'te kanal yok. Sürüm MainActivity kanalından
  /// okunur; okunamazsa (başka platform / test) true.
  static Future<bool> alarmStreamSupported() async {
    try {
      final sdk = await const MethodChannel(
        'vaktinde/device',
      ).invokeMethod<int>('sdkInt');
      return sdk == null || sdk >= 26;
    } catch (e) {
      return true;
    }
  }

  /// Android 12+ "Alarmlar ve hatırlatıcılar" izni (11 ve altında eklenti hep
  /// true döner). Belirlenemezse (Android değil / kanal hatası) null.
  Future<bool?> canScheduleExactAlarms() async {
    try {
      return await _android?.canScheduleExactNotifications();
    } catch (e) {
      return null;
    }
  }

  /// Kurulumdan önce: izin okunur, bu nesnede ve kalıcı olarak saklanır.
  /// Okunamazsa önceki bilgi korunur.
  Future<bool?> refreshExactAlarmPermission() async {
    final allowed = await canScheduleExactAlarms();
    if (allowed != null) {
      _exactAllowed = allowed;
      await _saveExactAllowed(allowed);
    }
    return allowed;
  }

  static Future<void> _saveExactAllowed(bool allowed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(exactAlarmsAllowedKey, allowed);
    } catch (e) {
      // Kayıt sadece uyarı içindir; kurulumu durdurmaz
    }
  }

  /// Son kurulumda görülen izin (canlı sorgu yapılamazsa arayüz bunu kullanır)
  static Future<bool?> lastKnownExactAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(exactAlarmsAllowedKey);
    } catch (e) {
      return null;
    }
  }

  /// Uygulama bildirimleri açık mı (Android 13+ bildirim izni dahil); bilinmiyorsa null
  Future<bool?> notificationsEnabled() async {
    try {
      return await _android?.areNotificationsEnabled();
    } catch (e) {
      return null;
    }
  }

  /// Android 12+: sistemin "Alarmlar ve hatırlatıcılar" ekranı açılır; dönünce
  /// izin durumu gelir. Hata/başka platformda null.
  Future<bool?> requestExactAlarmPermission() async {
    try {
      return await _android?.requestExactAlarmsPermission();
    } catch (e) {
      return null;
    }
  }

  /// Android 13+ bildirim izni penceresi (12 ve altında pencere yok, mevcut
  /// durum döner). Hata/başka platformda null.
  Future<bool?> requestNotificationPermission() async {
    try {
      return await _android?.requestNotificationsPermission();
    } catch (e) {
      return null;
    }
  }

  // Tam zamanlı izin yoksa gecikmeli kip. İzin sorgulanamadıysa ya da kurulum
  // sırasında geri alındıysa alarmClock reddedilir: aynı bildirim gecikmeli kurulur.
  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    NotificationDetails details, {
    String? payload,
  }) async {
    final mode = scheduleModeFor(_exactAllowed);
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: mode,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code != exactAlarmsDeniedCode ||
          mode != AndroidScheduleMode.alarmClock) {
        rethrow;
      }
      _exactAllowed = false;
      await _saveExactAllowed(false);
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

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
    bool alarmStream = false, // "sessiz modda da çal": alarm ses akışı (ezan)
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    final channel = prayerChannel(soundName, alarmStream: alarmStream);

    bool playSound = soundName != null;
    RawResourceAndroidNotificationSound? soundSource = soundName != null
        ? RawResourceAndroidNotificationSound(soundName)
        : null;

    await _zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          localizedChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          ticker: localizedTicker,
          icon: '@mipmap/launcher_icon',
          sound: soundSource,
          enableVibration: true,
          audioAttributesUsage: channel.usage,
          actions: actionLabel != null ? [prayedAction(actionLabel)] : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: playSound,
          sound: soundName != null ? '$soundName.mp3' : null,
        ),
      ),
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
    await _zonedSchedule(
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

    await _zonedSchedule(
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
    );
  }

  /// Kurulu (henüz çalmamış) bildirimlerin ID'leri
  Future<Set<int>> pendingIds() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toSet();
  }

  /// Kurulu (henüz çalmamış) bildirimler: ID → yük ("Kıldım" verisi; yoksa boş)
  Future<Map<int, String?>> pendingPayloads() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return {for (final p in pending) p.id: p.payload};
  }

  Future<void> cancel(int id) => _notificationsPlugin.cancel(id);
}
