// Kalıcı bildirim (888, sıradaki vakte kalan süre) isteğe bağlı: yeni
// kurulumda kapalı, ayardan önceki sürümü kullanmış kullanıcıda açık. Açıkken
// ön plan servisi başlar (telefon açılışında da), kapalıyken durur, açılışta
// başlamaz ve native taraf (HomeWidget bayrağı) 888'i çizmez. Eklenti
// kanalları sahte.
import 'dart:async';

import 'package:ezan_saati/data/services/background_manager.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/onboarding/install_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService implements ServiceInstance {
  int stops = 0;
  final _events = StreamController<Map<String, dynamic>>.broadcast(sync: true);

  void send(String method) => _events.add({'method': method});

  @override
  Stream<Map<String, dynamic>?> on(String method) =>
      _events.stream.where((e) => e['method'] == method).map((_) => null);

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}

  @override
  Future<void> stopSelf() async => stops++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const serviceChannel = MethodChannel(
    'id.flutter/background_service/android/method',
    JSONMethodCodec(),
  );
  const serviceEvents = EventChannel(
    'id.flutter/background_service/android/event',
    JSONMethodCodec(),
  );
  const homeWidget = MethodChannel('home_widget');
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  // Çağrı sırası ("eklenti.yöntem") ve ayrıntılar
  late List<String> order;
  late Map<String, dynamic> configured;
  late List<Object?> sent;
  late Map<String, Object?> widgetData;
  late List<Object?> widgetUpdates;

  setUp(() {
    FlutterBackgroundServiceAndroid.registerWith();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    order = [];
    configured = {};
    sent = [];
    widgetData = {};
    widgetUpdates = [];
    messenger.setMockMethodCallHandler(serviceChannel, (call) async {
      order.add('service.${call.method}');
      if (call.method == 'configure') {
        configured = Map<String, dynamic>.from(call.arguments as Map);
      }
      if (call.method == 'sendData') sent.add(call.arguments);
      return true;
    });
    messenger.setMockStreamHandler(
      serviceEvents,
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
    messenger.setMockMethodCallHandler(homeWidget, (call) async {
      order.add('widget.${call.method}');
      final args = call.arguments as Map;
      if (call.method == 'saveWidgetData') {
        widgetData[args['id'] as String] = args['data'];
      }
      if (call.method == 'updateWidget') widgetUpdates.add(args['android']);
      return true;
    });
    messenger.setMockMethodCallHandler(notifications, (call) async {
      order.add('notifications.${call.method}');
      return call.method == 'initialize' ? true : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(serviceChannel, null);
    messenger.setMockStreamHandler(serviceEvents, null);
    messenger.setMockMethodCallHandler(homeWidget, null);
    messenger.setMockMethodCallHandler(notifications, null);
  });

  const key = StorageService.persistentNotificationKey;

  group('varsayılan', () {
    test('yeni kurulum: kapalı yazılır; sonra dil ve konum seçilse de '
        'kapalı kalır', () async {
      // InstallGuard işareti ilk açılışta da yazılır: kullanım izi sayılmaz
      SharedPreferences.setMockInitialValues({InstallGuard.markerKey: 1});
      final prefs = await SharedPreferences.getInstance();
      expect(await StorageService.ensurePersistentNotification(prefs), isFalse);
      expect(prefs.getBool(key), isFalse);

      await prefs.setString('language_code', 'tr');
      await prefs.setBool('is_language_selected', true);
      await prefs.setString('saved_city', 'Konya');
      expect(StorageService.persistentNotificationOf(prefs), isFalse);
      expect(await StorageService.ensurePersistentNotification(prefs), isFalse);
    });

    test('güncelleyen kullanıcı (dil, konum ya da vakit önbelleği kayıtlı): '
        'açık yazılır', () async {
      for (final Map<String, Object> used in [
        {'is_language_selected': true},
        {'language_code': 'de'},
        {'saved_city': 'Berlin'},
        {'saved_lat': 52.5},
        {'cached_prayer_times': '{}'},
      ]) {
        SharedPreferences.setMockInitialValues(used);
        final prefs = await SharedPreferences.getInstance();
        expect(StorageService.persistentNotificationOf(prefs), isTrue);
        expect(
          await StorageService.ensurePersistentNotification(prefs),
          isTrue,
          reason: '$used',
        );
        expect(prefs.getBool(key), isTrue);
      }
    });

    test('kullanıcının seçimi korunur', () async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'tr',
        key: false,
      });
      var prefs = await SharedPreferences.getInstance();
      expect(await StorageService.ensurePersistentNotification(prefs), isFalse);

      SharedPreferences.setMockInitialValues({key: true});
      prefs = await SharedPreferences.getInstance();
      expect(await StorageService.ensurePersistentNotification(prefs), isTrue);
    });
  });

  group('servis', () {
    test('açık: önce bayrak, kanal; telefon açılışında da başlar; servis '
        'başlatılır', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'tr'});
      await BackgroundManager.initializeService();

      expect(widgetData[BackgroundManager.widgetFlagKey], isTrue);
      expect(order.first, 'widget.saveWidgetData');
      expect(order, contains('notifications.createNotificationChannel'));
      expect(order.where((m) => m.startsWith('service.')), [
        'service.configure',
        'service.start',
      ]);
      expect(configured['auto_start_on_boot'], isTrue);
      expect(configured['auto_start'], isFalse);
      expect(configured['is_foreground_mode'], isTrue);
      expect(configured['foreground_notification_id'], 888);
      expect(configured['notification_channel_id'], 'vaktinde_sticky_channel');
      expect(configured['foreground_service_types'], ['specialUse']);
      expect(sent, isEmpty);
      expect(widgetUpdates, isEmpty);
    });

    test('kapalı (yeni kurulum): başlatılmaz, telefon açılışında başlamaz, '
        'çalışıyorsa durdurulur, 888 kaldırılır', () async {
      SharedPreferences.setMockInitialValues({});
      await BackgroundManager.initializeService();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(key), isFalse);
      expect(widgetData[BackgroundManager.widgetFlagKey], isFalse);
      expect(order.first, 'widget.saveWidgetData');
      // Kullanılmayan kanal açılmaz
      expect(order, isNot(contains('notifications.createNotificationChannel')));
      expect(order, isNot(contains('service.start')));
      expect(configured['auto_start_on_boot'], isFalse);
      expect(configured['auto_start'], isFalse);
      expect(sent, [
        {'method': BackgroundManager.stopEvent, 'args': null},
      ]);
      expect(widgetUpdates, ['NotificationUpdater']);
    });

    test('servis isolate: kapalıyken başlatıldıysa (eski açılış kaydı) hemen '
        'durur; açıkken "dur" isteğiyle durur', () async {
      SharedPreferences.setMockInitialValues({key: false});
      final off = _FakeService();
      onStart(off);
      await pumpEventQueue();
      expect(off.stops, 1);
      expect(order, isNot(contains('notifications.initialize')));

      SharedPreferences.setMockInitialValues({key: true});
      final on = _FakeService();
      onStart(on);
      await pumpEventQueue();
      expect(on.stops, 0);
      // Hızlı kapat-aç: istek gelene kadar ayar yeniden açıldıysa durmaz
      on.send(BackgroundManager.stopEvent);
      await pumpEventQueue();
      expect(on.stops, 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, false);
      on.send(BackgroundManager.stopEvent);
      await pumpEventQueue();
      expect(on.stops, 1);
    });
  });

  test('Ayarlar anahtarı (HomeViewModel): kaydedilir, servis durur ya da '
      'başlar', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'tr', key: true});
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.persistentNotificationEnabled = true;
    final prefs = await SharedPreferences.getInstance();

    await vm.setPersistentNotificationEnabled(false);
    expect(vm.persistentNotificationEnabled, isFalse);
    expect(prefs.getBool(key), isFalse);
    expect(widgetData[BackgroundManager.widgetFlagKey], isFalse);
    expect(configured['auto_start_on_boot'], isFalse);
    expect(sent, hasLength(1));
    expect(order, isNot(contains('service.start')));

    order.clear();
    await vm.setPersistentNotificationEnabled(true);
    expect(prefs.getBool(key), isTrue);
    expect(widgetData[BackgroundManager.widgetFlagKey], isTrue);
    expect(configured['auto_start_on_boot'], isTrue);
    expect(order, contains('service.start'));

    // Aynı değer: hiçbir şey yapılmaz
    order.clear();
    await vm.setPersistentNotificationEnabled(true);
    expect(order, isEmpty);
  });
}
