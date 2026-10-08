import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/features/home/alarm_health.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// İzin durumu (AlarmHealth): ne zaman uyarı, ne zaman yeniden kurulum, butonlar
// neyi açar; "sessiz modda da çal" ayarının kaydı ve yeniden kurulumu
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  late List<MethodCall> notifCalls;
  // Eklentinin yanıtları: bool, null ya da fırlatılacak hata
  late Object? canScheduleExact;
  late Object? notificationsEnabled;
  late Future<Object?> Function() onRequestExact;
  late Future<Object?> Function() onRequestNotifications;

  Object? answer(Object? value) {
    if (value is Exception) throw value;
    return value;
  }

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    notifCalls = [];
    canScheduleExact = true;
    notificationsEnabled = true;
    onRequestExact = () async => true;
    onRequestNotifications = () async => true;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'Europe/Istanbul',
    );
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      notifCalls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return answer(canScheduleExact);
        case 'areNotificationsEnabled':
          return answer(notificationsEnabled);
        case 'requestExactAlarmsPermission':
          return onRequestExact();
        case 'requestNotificationsPermission':
          return onRequestNotifications();
        case 'pendingNotificationRequests':
          return <Object?>[];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(notifChannel, null);
  });

  test('uyarı seçimi: alarm yoksa yok, bildirim kapalıysa önce o', () {
    AlarmHealthIssue? issue(bool? exact, bool? notif, bool any) =>
        AlarmHealth.issueFor(
          exactAllowed: exact,
          notificationsEnabled: notif,
          anyAlarmEnabled: any,
        );
    expect(issue(false, false, false), isNull);
    expect(issue(true, true, true), isNull);
    expect(issue(null, null, true), isNull);
    expect(issue(false, true, true), AlarmHealthIssue.exactAlarmsOff);
    expect(issue(false, null, true), AlarmHealthIssue.exactAlarmsOff);
    expect(issue(true, false, true), AlarmHealthIssue.notificationsOff);
    expect(issue(false, false, true), AlarmHealthIssue.notificationsOff);
  });

  late int changes;
  late int settingsOpened;
  AlarmHealth health() {
    changes = 0;
    settingsOpened = 0;
    final h = AlarmHealth(
      NotificationService(),
      onChanged: () async => changes++,
      openSettings: () async {
        settingsOpened++;
        return true;
      },
    );
    addTearDown(h.dispose);
    return h;
  }

  test(
    'ilk okuma yeniden kurmaz; izin değişince / bildirim açılıp kapanınca kurar',
    () async {
      SharedPreferences.setMockInitialValues({});
      final h = health();
      canScheduleExact = false;
      notificationsEnabled = false;
      await h.refresh();
      expect(h.exactAllowed, isFalse);
      expect(h.notificationsEnabled, isFalse);
      expect(changes, 0);

      notificationsEnabled = true; // ayarlardan açıldı
      await h.refresh();
      expect(changes, 1);
      canScheduleExact = true; // tam zamanlı izin verildi: kip değişir
      await h.refresh();
      expect(changes, 2);
      await h.refresh(); // değişiklik yok
      expect(changes, 2);
      // Kapatıldı: uyarı çıkar, ezan alarm simgesi olmadan (alarmClock'suz) yeniden
      notificationsEnabled = false;
      await h.refresh();
      expect(changes, 3);
      expect(h.issue(anyAlarmEnabled: true), AlarmHealthIssue.notificationsOff);
      canScheduleExact = false; // izin geri alındı: gecikmeli kiple yeniden
      await h.refresh();
      expect(changes, 4);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(NotificationService.exactAlarmsAllowedKey), isFalse);
    },
  );

  test('üst üste okumalar tek koşuda birleşir, sonuncusu kaybolmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    canScheduleExact = false;
    await h.refresh();
    final first = h.refresh();
    canScheduleExact = true; // ilk okuma sürerken değişti
    final second = h.refresh();
    await Future.wait([first, second]);
    expect(h.exactAllowed, isTrue);
    expect(changes, 1);
  });

  test('canlı okunamazsa son kurulumda görülen izin kullanılır', () async {
    SharedPreferences.setMockInitialValues({
      NotificationService.exactAlarmsAllowedKey: false,
    });
    final h = health();
    canScheduleExact = PlatformException(code: 'error');
    await h.refresh();
    expect(h.exactAllowed, isFalse);
  });

  test(
    '"İzin ver": sistem ekranı, dönünce uyarı kalkar ve alarmlar kurulur',
    () async {
      SharedPreferences.setMockInitialValues({});
      final h = health();
      canScheduleExact = false;
      await h.refresh();
      onRequestExact = () async {
        canScheduleExact = true;
        return true;
      };
      await h.fixExactAlarms();
      expect(h.exactAllowed, isTrue);
      expect(h.issue(anyAlarmEnabled: true), isNull);
      expect(changes, 1);
      expect(settingsOpened, 0);
    },
  );

  test('"İzin ver": ekran açılamazsa uygulama ayarları', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    onRequestExact = () async => throw PlatformException(code: 'error');
    await h.fixExactAlarms();
    expect(settingsOpened, 1);
  });

  test('"Aç": pencere izin verirse ayarlar açılmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    notificationsEnabled = false;
    await h.refresh();
    onRequestNotifications = () async {
      notificationsEnabled = true;
      return true;
    };
    await h.fixNotifications();
    expect(settingsOpened, 0);
    expect(h.notificationsEnabled, isTrue);
    expect(changes, 1);
  });

  test('"Aç": pencere hiç çıkmadıysa (anında ret) uygulama ayarları', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    notificationsEnabled = false;
    await h.refresh();
    onRequestNotifications = () async => false;
    await h.fixNotifications();
    expect(settingsOpened, 1);
    expect(h.notificationsEnabled, isFalse);
  });

  test('"Aç": kullanıcı pencerede reddederse ayarlar açılmaz; ikinci '
      'dokunuşta ayarlar', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    notificationsEnabled = false;
    await h.refresh();
    var requests = 0;
    onRequestNotifications = () async {
      requests++;
      // Kullanıcı pencereyi okuyup reddetti
      await Future<void>.delayed(
        AlarmHealth.noDialogThreshold + const Duration(milliseconds: 200),
      );
      return false;
    };
    await h.fixNotifications();
    expect(requests, 1);
    expect(settingsOpened, 0);
    await h.fixNotifications();
    expect(requests, 1);
    expect(settingsOpened, 1);
  });

  test('Android dışı / eklenti yok: uyarı yok', () async {
    SharedPreferences.setMockInitialValues({});
    final h = health();
    canScheduleExact = null;
    notificationsEnabled = null;
    await h.refresh();
    expect(h.issue(anyAlarmEnabled: true), isNull);
  });

  test(
    '"Sessiz modda da çal" kaydedilir, alarmlar yeni kanalla kurulur',
    () async {
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
      });
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(lookupAppLocalizations(const Locale('tr')));
      vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());
      vm.onTimeAlarms = {
        for (final k in PrayerRefreshService.vakitKeys) k: k == 'Öğle',
      };
      String? channelOf(int id) => notifCalls
          .lastWhere(
            (c) => c.method == 'zonedSchedule' && c.arguments['id'] == id,
          )
          .arguments['platformSpecifics']['channelId'];

      await vm.setEzanAlarmStream(true);
      await vm.alarmsSettled;
      expect(vm.ezanAlarmStream, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ezan_alarm_stream'), isTrue);
      // Yarının öğle ezanı (ID 16)
      expect(channelOf(16), 'alarm_channel_ezan1');

      await vm.setEzanAlarmStream(false);
      await vm.alarmsSettled;
      expect(prefs.getBool('ezan_alarm_stream'), isFalse);
      expect(channelOf(16), 'channel_ezan1');
    },
  );
}
