// Yedekten / başka telefondan (cihazdan cihaza aktarım) gelen kayıtlarda
// cihaza özgü bayraklar silinir; aynı kurulumda ve bu sürüme güncellenen
// mevcut kurulumda hiçbir şey yeniden sorulmaz.
import 'dart:io';

import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/install_guard.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const install = 1760000000000;
  const day = Duration.millisecondsPerDay;
  final deviceFlags = <String, Object>{
    permissionsPrimedKey: true,
    'battery_optimization_asked': true,
    'alarms_scheduled_date': '2026-10-08',
    'qibla_calibration_dialog_seen': true,
    'exact_alarms_allowed': false,
  };
  final userData = <String, Object>{
    'language_code': 'tr',
    'is_language_selected': true,
    tourSeenKey: false,
    'saved_city': 'Ankara',
    'saved_lat': 39.92,
    'prayer_log': '{"2026-10-07":31}',
    'kaza_Sabah': 3,
    'onTime_Öğle': true,
  };

  PackageInfo info({int? installTime = install, int? updateTime}) {
    DateTime? at(int? ms) =>
        ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    return PackageInfo(
      appName: 'Vaktinde',
      packageName: 'com.mmdigital.vaktinde',
      version: '1.1.0',
      buildNumber: '15',
      installTime: at(installTime),
      // Yeni kurulumda ilk kurulum = son güncelleme
      updateTime: at(updateTime ?? installTime),
    );
  }

  Future<(InstallCheck, SharedPreferences)> check(
    Map<String, Object> stored,
    PackageInfo packageInfo,
  ) async {
    SharedPreferences.setMockInitialValues(stored);
    final result = await InstallGuard.run(packageInfo: () async => packageInfo);
    return (result, await SharedPreferences.getInstance());
  }

  void expectUserDataKept(SharedPreferences prefs) {
    for (final MapEntry(:key, :value) in userData.entries) {
      expect(prefs.get(key), value, reason: key);
    }
  }

  setUp(() => InstallGuard.isSupported = () => true);
  tearDown(() => InstallGuard.isSupported = () => Platform.isAndroid);

  test('aynı kurulum: hiçbir bayrağa dokunulmaz', () async {
    final (result, prefs) = await check({
      ...deviceFlags,
      ...userData,
      InstallGuard.markerKey: install,
    }, info(updateTime: install + 30 * day));
    expect(result, InstallCheck.sameInstall);
    for (final MapEntry(:key, :value) in deviceFlags.entries) {
      expect(prefs.get(key), value, reason: key);
    }
    expectUserDataKept(prefs);
  });

  test('başka kurulumun kaydı: cihaz bayrakları silinir, kullanıcı verisi '
      'kalır, yeni işaret yazılır', () async {
    final (result, prefs) = await check({
      ...deviceFlags,
      ...userData,
      InstallGuard.markerKey: install - 400 * day,
    }, info());
    expect(result, InstallCheck.restored);
    // Fikstür koddaki listeyle aynı: listeden düşen bayrak testte yakalanır
    expect(deviceFlags.keys.toSet(), InstallGuard.deviceKeys.toSet());
    for (final key in deviceFlags.keys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expectUserDataKept(prefs);
    expect(prefs.getInt(InstallGuard.markerKey), install);

    // Sonraki açılış aynı kurulum: izin akışında yazılan bayrak kalır
    await prefs.setBool(permissionsPrimedKey, true);
    expect(
      await InstallGuard.run(packageInfo: () async => info()),
      InstallCheck.sameInstall,
    );
    expect(prefs.getBool(permissionsPrimedKey), isTrue);
  });

  test('bu sürüme güncellenen mevcut kurulum: sessizce işaretlenir, '
      'tekrar sorulmaz', () async {
    final (result, prefs) = await check({
      ...deviceFlags,
      ...userData,
    }, info(updateTime: install + 30 * day));
    expect(result, InstallCheck.adopted);
    for (final MapEntry(:key, :value) in deviceFlags.entries) {
      expect(prefs.get(key), value, reason: key);
    }
    expect(prefs.getInt(InstallGuard.markerKey), install);
    expect(
      await InstallGuard.run(
        packageInfo: () async => info(updateTime: install + 31 * day),
      ),
      InstallCheck.sameInstall,
    );
  });

  test('işaretsiz eski yedek, hiç güncellenmemiş yeni kuruluma gelirse '
      'bayraklar silinir', () async {
    final (result, prefs) = await check({...deviceFlags, ...userData}, info());
    expect(result, InstallCheck.restored);
    for (final key in deviceFlags.keys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expectUserDataKept(prefs);
    expect(prefs.getInt(InstallGuard.markerKey), install);
  });

  test('ilk açılış: işaret yazılır, sonraki açılış aynı kurulum', () async {
    final (result, prefs) = await check({}, info());
    expect(result, InstallCheck.firstRun);
    expect(prefs.getInt(InstallGuard.markerKey), install);
    expect(
      await InstallGuard.run(packageInfo: () async => info()),
      InstallCheck.sameInstall,
    );
  });

  test('denetlenemezse hiçbir şeye dokunulmaz', () async {
    final stored = {...deviceFlags, InstallGuard.markerKey: 1};
    final cases = <Future<PackageInfo> Function()>[
      () async => info(installTime: null),
      () async => info(installTime: 0),
      () async => throw PlatformException(code: 'x'),
    ];
    for (final packageInfo in cases) {
      SharedPreferences.setMockInitialValues(stored);
      expect(
        await InstallGuard.run(packageInfo: packageInfo),
        InstallCheck.skipped,
      );
      final prefs = await SharedPreferences.getInstance();
      for (final MapEntry(:key, :value) in stored.entries) {
        expect(prefs.get(key), value, reason: key);
      }
    }
    // Android dışı
    InstallGuard.isSupported = () => false;
    SharedPreferences.setMockInitialValues(stored);
    expect(
      await InstallGuard.run(packageInfo: () async => info()),
      InstallCheck.skipped,
    );
    expect(
      (await SharedPreferences.getInstance()).getInt(InstallGuard.markerKey),
      1,
    );
  });

  test('karar tablosu', () {
    InstallCheck decide(int? marker, int? update, bool flags) =>
        InstallGuard.decide(
          marker: marker,
          installTime: install,
          updateTime: update,
          hasDeviceFlags: flags,
        );
    expect(decide(install, install, true), InstallCheck.sameInstall);
    expect(decide(install + 1, install, false), InstallCheck.restored);
    expect(decide(null, install, false), InstallCheck.firstRun);
    expect(decide(null, install + day, true), InstallCheck.adopted);
    expect(decide(null, null, true), InstallCheck.adopted);
    expect(decide(null, install, true), InstallCheck.restored);
  });
}
