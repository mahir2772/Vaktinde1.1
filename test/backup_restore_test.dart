// Ayarlar > Yedekleme: satırlar, yedeği paylaşma (JSON dosyası), dosya seçip
// onayla geri yükleme (sahte "vaktinde/device" kanalı) ve geri yüklemeden
// sonra modellerin (ana model, tema, dil, zikir) kayıttan yenilenmesi
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/backup_service.dart';
import 'package:ezan_saati/data/services/notification_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/backup_setting.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeViewModel extends HomeViewModel {
  int reloads = 0;

  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> reloadFromStorage() async {
    reloads++;
    city = (await SharedPreferences.getInstance()).getString('saved_city');
    notifyListeners();
  }
}

// Telefondaki veri (geri yüklemeden önce)
const Map<String, Object> _deviceData = {
  'language_code': 'tr',
  'is_language_selected': true,
  'saved_city': 'İzmir',
  'saved_lat': 38.42,
  'saved_lng': 27.14,
  'theme_mode': 1,
  'kaza_Sabah': 40,
  'prayer_log': '{"2026-10-10":31}',
  'selected_dhikr': 'Sübhanallah',
  'dhikr_count_Sübhanallah': 33,
  'permissions_primed': true,
  'review_requested': true,
};

// Yedekteki veri
const Map<String, Object> _backupData = {
  'language_code': 'en',
  'saved_city': 'Ankara',
  'saved_district': 'Çankaya',
  'saved_lat': 39.93,
  'saved_lng': 32.85,
  'theme_mode': 2,
  'kaza_Sabah': 7,
  'onTime_Öğle': true,
  'prayer_log': '{"2026-10-09":31}',
  'fast_log': ['2026-03-01'],
  'selected_dhikr': 'Elhamdülillah',
  'dhikr_count_Elhamdülillah': 12,
};

String _backupFile(Map<String, Object> data, {int version = 1}) => jsonEncode({
  'app': 'vaktinde',
  'version': version,
  'created': '2026-10-11T08:30:00.000Z',
  'data': data,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const device = MethodChannel('vaktinde/device');
  const share = MethodChannel('dev.fluttercommunity.plus/share');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  final loc = lookupAppLocalizations(const Locale('tr'));

  // Dosya seçicinin cevabı: metin, null (vazgeçildi) ya da hata
  late Future<Object?> Function() pick;
  late List<MethodCall> picks;

  setUp(() {
    picks = [];
    pick = () async => null;
    messenger.setMockMethodCallHandler(device, (call) async {
      if (call.method != 'pickBackupFile') return null;
      picks.add(call);
      return pick();
    });
    // Diğer eklenti kanalları (zikir sesi, ekranı açık tutma, Firebase...)
    // "başarılı, null"
    messenger.allMessagesHandler = (channel, handler, message) {
      if (handler != null) return handler(message);
      if (channel.startsWith('flutter/')) {
        return messenger.delegate.send(channel, message);
      }
      if (channel.startsWith('dev.flutter.pigeon.')) {
        return Future.value(
          const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
      }
      return Future.value(
        const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    };
  });

  tearDown(() {
    messenger.allMessagesHandler = null;
    messenger.setMockMethodCallHandler(device, null);
    messenger.setMockMethodCallHandler(share, null);
    messenger.setMockMethodCallHandler(pathProvider, null);
  });

  Future<
    ({
      _FakeHomeViewModel home,
      LanguageProvider language,
      ThemeProvider theme,
      ZikirViewModel zikir,
    })
  >
  pumpSettings(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(_deviceData);
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final home = _FakeHomeViewModel();
    final language = LanguageProvider();
    final theme = ThemeProvider();
    final zikir = ZikirViewModel();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // lazy: false → ağaçla birlikte kapatılır (gece yarısı zamanlayıcısı)
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) => home,
            lazy: false,
          ),
          ChangeNotifierProvider(create: (_) => language, lazy: false),
          ChangeNotifierProvider(create: (_) => theme, lazy: false),
          ChangeNotifierProvider(create: (_) => zikir, lazy: false),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsView(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return (home: home, language: language, theme: theme, zikir: zikir);
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('Yedekleme bölümü: yedekle ve geri yükle satırları', (
    tester,
  ) async {
    await pumpSettings(tester);
    await scrollTo(tester, loc.backupImportTitle);
    expect(find.text(loc.sectionBackup), findsOneWidget);
    expect(find.text(loc.backupExportTitle), findsOneWidget);
    expect(find.text(loc.backupExportSub), findsOneWidget);
    expect(find.text(loc.backupImportSub), findsOneWidget);
    expect(find.byType(BackupSection), findsOneWidget);
    // Destek bölümünden önce
    expect(
      tester.getTopLeft(find.text(loc.backupImportTitle)).dy,
      lessThan(tester.getTopLeft(find.text(loc.sectionSupport)).dy),
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Verileri yedekle: tarihli JSON dosyası paylaşılır; konum '
      'dahil, cihaza özgü bayrak ve sayaç yok', (tester) async {
    final temp = Directory.systemTemp.createTempSync('vaktinde_backup');
    addTearDown(() => temp.deleteSync(recursive: true));
    messenger.setMockMethodCallHandler(pathProvider, (call) async => temp.path);
    MethodCall? shared;
    messenger.setMockMethodCallHandler(share, (call) async {
      shared = call;
      return 'dev.fluttercommunity.plus/share/success';
    });
    await pumpSettings(tester);
    await scrollTo(tester, loc.backupExportTitle);
    final today = DateTime.now();
    await tester.tap(find.text(loc.backupExportTitle));
    // Geçici dosya gerçek zaman ister
    for (var i = 0; i < 100 && shared == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(shared?.method, 'shareFiles');
    final args = shared!.arguments as Map;
    expect(args['mimeTypes'], ['application/json']);
    expect(args['subject'], loc.backupShareSubject);
    final path = (args['paths'] as List).single as String;
    expect(path.split('/').last, BackupService.fileName(today));
    final text = await tester.runAsync(() => File(path).readAsString());
    final backup = BackupService.decode(text!);
    expect(backup.values['saved_city'], 'İzmir');
    expect(backup.values['saved_lat'], 38.42);
    expect(backup.values['kaza_Sabah'], 40);
    expect(backup.values.containsKey('permissions_primed'), isFalse);
    expect(backup.values.containsKey('review_requested'), isFalse);
    expect(backup.values.containsKey('is_language_selected'), isFalse);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Geri yükle: dosya seçilir, tarihli onaydan sonra veriler '
      'değişir, modeller yenilenir', (tester) async {
    final models = await pumpSettings(tester);
    pick = () async => _backupFile(_backupData);
    final changes = PrayerTrackerService.changes.value;
    await scrollTo(tester, loc.backupImportTitle);
    await tester.tap(find.text(loc.backupImportTitle));
    await settle(tester);

    expect(picks, hasLength(1));
    expect(find.text(loc.backupRestoreConfirmTitle), findsOneWidget);
    // 08:30 UTC = 11:30 İstanbul
    expect(
      find.text(loc.backupRestoreConfirmMessage('11 Ekim 2026')),
      findsOneWidget,
    );
    await tester.tap(find.text(loc.backupRestoreConfirm));
    await settle(tester);

    final prefs = await SharedPreferences.getInstance();
    for (final MapEntry(:key, :value) in _backupData.entries) {
      expect(prefs.get(key), value, reason: key);
    }
    // Yedekte olmayan zikir sayacı silindi; cihaza özgü bayrak ve sayaç kaldı
    expect(prefs.containsKey('dhikr_count_Sübhanallah'), isFalse);
    expect(prefs.getBool('permissions_primed'), isTrue);
    expect(prefs.getBool('review_requested'), isTrue);
    expect(prefs.getBool('is_language_selected'), isTrue);

    expect(models.home.reloads, 1);
    expect(models.home.city, 'Ankara');
    expect(models.theme.themeMode, ThemeMode.dark);
    expect(models.language.locale, const Locale('en'));
    expect(models.zikir.selectedDhikr, 'Elhamdülillah');
    expect(models.zikir.count, 12);
    expect(PrayerTrackerService.changes.value, changes + 1);
    // Başarı mesajı yedekteki dilde
    expect(
      find.text(lookupAppLocalizations(const Locale('en')).backupRestored),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Geri yükle: seçmekten ya da onaydan vazgeçilirse hiçbir şey '
      'değişmez', (tester) async {
    final models = await pumpSettings(tester);
    await scrollTo(tester, loc.backupImportTitle);

    // Seçici kapatıldı
    await tester.tap(find.text(loc.backupImportTitle));
    await settle(tester);
    expect(picks, hasLength(1));
    expect(find.text(loc.backupRestoreConfirmTitle), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    // Onay penceresinde iptal
    pick = () async => _backupFile(_backupData);
    await tester.tap(find.text(loc.backupImportTitle));
    await settle(tester);
    expect(find.text(loc.backupRestoreConfirmTitle), findsOneWidget);
    await tester.tap(find.text(loc.cancel));
    await settle(tester);

    final prefs = await SharedPreferences.getInstance();
    for (final MapEntry(:key, :value) in _deviceData.entries) {
      expect(prefs.get(key), value, reason: key);
    }
    expect(prefs.containsKey('onTime_Öğle'), isFalse);
    expect(models.home.reloads, 0);
    expect(models.theme.themeMode, ThemeMode.light);
    expect(find.byType(SnackBar), findsNothing);
    // Satır yeniden kullanılabilir
    await tester.tap(find.text(loc.backupImportTitle));
    await settle(tester);
    expect(picks, hasLength(3));
    await tester.tap(find.text(loc.cancel));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Geri yükle: geçersiz, çok büyük ya da yeni sürüm dosyası '
      'uyarıyla reddedilir', (tester) async {
    final models = await pumpSettings(tester);
    await scrollTo(tester, loc.backupImportTitle);

    Future<void> expectSnack(String text) async {
      await tester.tap(find.text(loc.backupImportTitle));
      await settle(tester);
      expect(find.text(loc.backupRestoreConfirmTitle), findsNothing);
      expect(find.text(text), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(SettingsView)),
      ).removeCurrentSnackBar();
      await settle(tester);
    }

    pick = () async => '{"app": "başka"}';
    await expectSnack(loc.backupInvalidFile);
    pick = () async => _backupFile({'theme_mode': 'koyu'});
    await expectSnack(loc.backupInvalidFile);
    pick = () async => throw PlatformException(code: 'too_large');
    await expectSnack(loc.backupInvalidFile);
    pick = () async => _backupFile(_backupData, version: 2);
    await expectSnack(loc.backupNewerVersion);
    // Seçici açılamadı
    pick = () async => throw PlatformException(code: 'no_picker');
    await expectSnack(loc.shareFailed);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saved_city'), 'İzmir');
    expect(models.home.reloads, 0);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  test('restoreBackup: tema, dil ve zikir modelleri yeni kayıtla '
      'yenilenir (yedekte olmayan varsayılana döner)', () async {
    SharedPreferences.setMockInitialValues({
      ..._deviceData,
      'background_image': 'bg_kaaba1.webp',
      'app_text_scale': 1.3,
      'dhikr_daily_stats': '{"2026-10-01":5}',
      'zikir_vibration': false,
    });
    final language = LanguageProvider();
    final theme = ThemeProvider();
    final zikir = ZikirViewModel();
    await pumpEventQueue();
    expect(theme.backgroundImage, 'bg_kaaba1.webp');
    expect(theme.textScale, 1.3);
    expect(zikir.dailyStats, isNotEmpty);

    await restoreBackup(
      BackupData(
        created: DateTime.utc(2026, 10, 11),
        values: const {
          'language_code': 'de',
          'selected_dhikr': 'Elhamdülillah',
          'dhikr_count_Elhamdülillah': 10,
        },
      ),
      language: language,
      theme: theme,
      zikir: zikir,
    );
    expect(language.locale, const Locale('de'));
    expect(language.isLanguageSelected, isTrue);
    expect(theme.themeMode, ThemeMode.system);
    expect(theme.backgroundImage, isNull);
    expect(theme.textScale, 1.0);
    expect(zikir.selectedDhikr, 'Elhamdülillah');
    expect(zikir.count, 10);
    expect(zikir.dailyStats, isEmpty);
    expect(zikir.isVibrationEnabled, isTrue);
  });

  group('Ana model kayıttan yeniden okur', () {
    // Bekleyen alarmlar: ID → (Kıldım yükü "prayed|gün|vakit", kanal)
    late Map<int, ({String payload, String channel})> pending;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      pending = {};
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/Istanbul',
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'zonedSchedule':
              pending[call.arguments['id']] = (
                payload: call.arguments['payload'] as String? ?? '',
                channel: call.arguments['platformSpecifics']['channelId'],
              );
              return null;
            case 'cancel':
              pending.remove(call.arguments['id']);
              return null;
            case 'pendingNotificationRequests':
              return [
                for (final e in pending.entries)
                  {
                    'id': e.key,
                    'title': '',
                    'body': '',
                    'payload': e.value.payload,
                  },
              ];
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    Map<String, Set<String>> pendingEzans() {
      final result = <String, Set<String>>{};
      for (final p in pending.values) {
        final parts = p.payload.split('|');
        if (parts.length == 3) (result[parts[2]] ??= {}).add(parts[1]);
      }
      return result;
    }

    test('konum, ince ayarlı vakitler ve alarm ayarları yedekten; ezanlar '
        'yeni sesle kurulur', () async {
      SharedPreferences.setMockInitialValues({
        'saved_city': 'İzmir',
        'saved_lat': 38.42,
        'saved_lng': 27.14,
        'religious_days_enabled': false,
        'friday_notif_enabled': false,
        'daily_content_enabled': false,
      });
      await NotificationService().init();
      final vm = HomeViewModel();
      addTearDown(vm.dispose);
      vm.updateLocalization(lookupAppLocalizations(const Locale('tr')));
      vm.city = 'İzmir';
      vm.prayerTimes = await PrayerTimeService().forDate(DateTime.now());

      final prefs = await SharedPreferences.getInstance();
      await BackupService.restore(
        prefs,
        BackupData(
          created: DateTime.utc(2026, 10, 1),
          values: const {
            'saved_city': 'Ankara',
            'saved_district': 'Çankaya',
            'saved_lat': 39.93,
            'saved_lng': 32.85,
            'time_offsets': '{"Öğle":5}',
            'onTime_Öğle': true,
            'sound_Öğle': 'ezan2',
            'religious_days_enabled': false,
            'friday_notif_enabled': false,
            'daily_content_enabled': false,
          },
        ),
      );
      await vm.reloadFromStorage();

      expect(vm.city, 'Ankara');
      expect(vm.district, 'Çankaya');
      expect(vm.onTimeAlarms['Öğle'], isTrue);
      expect(vm.onTimeAlarms['Akşam'], isFalse);
      expect(vm.selectedSounds['Öğle'], 'ezan2');
      expect(vm.isLoading, isFalse);
      final expected = PrayerTimeService().calculate(
        39.93,
        32.85,
        offsets: const {'Öğle': 5},
      );
      expect(vm.prayerTimes!.ogle, expected.ogle);
      expect(vm.prayerTimes!.aksam, expected.aksam);
      // Bugünün önbelleği yeni yerin vakitleriyle yeniden yazıldı
      expect(prefs.getString('cached_prayer_times'), contains(expected.ogle!));

      expect(pendingEzans().keys, ['Öğle']);
      expect(pendingEzans()['Öğle']!.length, greaterThanOrEqualTo(4));
      expect(pending.values.map((p) => p.channel).toSet(), {'channel_ezan2'});
    });
  });
}
