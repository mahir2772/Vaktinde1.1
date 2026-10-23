// Kalıcı bildirim (888, sıradaki vakte kalan süre) isteğe bağlı: yeni
// kurulumda kapalı, ayardan önceki sürümü kullanmış kullanıcıda açık. Ön plan
// servisi yok: ayar HomeWidget bayrağına yazılır, NotificationUpdater çizer
// (açık) ya da kaldırır (kapalı). Eklenti kanalları sahte.
import 'package:ezan_saati/data/services/background_manager.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/onboarding/install_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const homeWidget = MethodChannel('home_widget');
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  // Çağrı sırası ("eklenti.yöntem") ve ayrıntılar
  late List<String> order;
  late Map<String, Object?> widgetData;
  late List<Object?> widgetUpdates;
  late List<Object?> channels;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    order = [];
    widgetData = {};
    widgetUpdates = [];
    channels = [];
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
      if (call.method == 'createNotificationChannel') {
        channels.add((call.arguments as Map)['id']);
      }
      return call.method == 'initialize' ? true : null;
    });
  });

  tearDown(() {
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

  group('uygulama', () {
    test('açık: önce bayrak, kanal, sonra 888 çizilir; eski servis metni '
        'silinir', () async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'tr',
        'bg_display': '{}',
      });
      await BackgroundManager.initializeService();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('bg_display'), isFalse);
      expect(widgetData[BackgroundManager.widgetFlagKey], isTrue);
      expect(order, [
        'widget.saveWidgetData',
        'notifications.createNotificationChannel',
        'widget.updateWidget',
      ]);
      expect(channels, ['vaktinde_sticky_channel']);
      expect(widgetUpdates, ['NotificationUpdater']);
    });

    test('kapalı (yeni kurulum): kanal açılmaz, 888 kaldırılır', () async {
      SharedPreferences.setMockInitialValues({});
      await BackgroundManager.initializeService();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(key), isFalse);
      expect(widgetData[BackgroundManager.widgetFlagKey], isFalse);
      expect(order, ['widget.saveWidgetData', 'widget.updateWidget']);
      expect(widgetUpdates, ['NotificationUpdater']);
    });
  });

  test('Ayarlar anahtarı (HomeViewModel): kaydedilir, bayrak yazılır, 888 '
      'yenilenir', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'tr', key: true});
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.persistentNotificationEnabled = true;
    final prefs = await SharedPreferences.getInstance();

    await vm.setPersistentNotificationEnabled(false);
    expect(vm.persistentNotificationEnabled, isFalse);
    expect(prefs.getBool(key), isFalse);
    expect(widgetData[BackgroundManager.widgetFlagKey], isFalse);
    expect(channels, isEmpty);
    expect(widgetUpdates, ['NotificationUpdater']);

    order.clear();
    await vm.setPersistentNotificationEnabled(true);
    expect(prefs.getBool(key), isTrue);
    expect(widgetData[BackgroundManager.widgetFlagKey], isTrue);
    expect(channels, ['vaktinde_sticky_channel']);
    expect(order.last, 'widget.updateWidget');

    // Aynı değer: hiçbir şey yapılmaz
    order.clear();
    await vm.setPersistentNotificationEnabled(true);
    expect(order, isEmpty);
  });
}
