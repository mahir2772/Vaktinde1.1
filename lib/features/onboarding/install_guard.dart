import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'view/onboarding_language_view.dart' show permissionsPrimedKey;

/// [InstallGuard.run] sonucu
enum InstallCheck {
  /// Kayıtlar bu kurulumun
  sameInstall,

  /// İlk açılış (ya da sıfırlanacak bayrak yok): işaret yazıldı
  firstRun,

  /// İşaretten önceki sürümle aynı cihazda güncellenmiş kurulum: sessizce işaretlendi
  adopted,

  /// Kayıtlar başka bir kurulumdan (yedek / cihazdan cihaza aktarım): bayraklar silindi
  restored,

  /// Denetlenemedi (Android değil, kurulum zamanı yok, hata)
  skipped,
}

/// Android yedeği ve cihazdan cihaza aktarım SharedPreferences'ı yeni bir
/// kuruluma taşır. Cihaza özgü bayraklar da taşınırsa yeni telefonda bildirim
/// izni hiç istenmez (ezan sessiz kalır), pil muafiyeti sorulmaz, alarm günü
/// "kuruldu" görünür. Kurulum kimliği: PackageInfo.installTime (Android
/// PackageManager.firstInstallTime) güncellemede değişmez, yeni kurulumda değişir.
class InstallGuard {
  InstallGuard._();

  /// Kayıtları yazan kurulumun ilk kurulum zamanı (ms)
  static const String markerKey = 'install_marker';

  /// Yeni cihaza / yeniden kuruluma taşınmaması gereken bayraklar
  static const List<String> deviceKeys = [
    permissionsPrimedKey, // bildirim/konum izni akışı
    'battery_optimization_asked', // HomeViewModel: pil optimizasyonu muafiyeti
    'alarms_scheduled_date', // PrayerRefreshService: alarmların kurulduğu gün
    'qibla_calibration_dialog_seen', // QiblaView: pusula kalibrasyon penceresi
    'exact_alarms_allowed', // NotificationService: tam zamanlı alarm izni durumu
    'alarm_plan_meta', // PrayerRefreshService: kurulu ezanların saat/ayar kaydı
  ];

  /// Testte platform kontrolünü aşmak için
  @visibleForTesting
  static bool Function() isSupported = () => Platform.isAndroid;

  /// Saf karar; zamanlar ms. [hasDeviceFlags]: [deviceKeys]'ten biri kayıtlı mı.
  static InstallCheck decide({
    required int? marker,
    required int installTime,
    required int? updateTime,
    required bool hasDeviceFlags,
  }) {
    if (marker == installTime) return InstallCheck.sameInstall;
    if (marker != null) return InstallCheck.restored;
    if (!hasDeviceFlags) return InstallCheck.firstRun;
    // İşaretsiz eski veri: uygulama bu cihazda kurulduktan sonra güncellendiyse
    // aynı kurulumdur (mevcut kullanıcı rahatsız edilmez). Hiç güncellenmemiş
    // kurulumda bayrak varsa (yeni kurulumda ilk + son güncelleme zamanı eşit)
    // kayıtlar yedekten gelmiştir.
    if (updateTime == null || updateTime > installTime) {
      return InstallCheck.adopted;
    }
    return InstallCheck.restored;
  }

  /// main() başında, bayrakları okuyan her şeyden önce bir kez çağrılır.
  /// Hata fırlatmaz; denetlenemezse hiçbir şeye dokunmaz.
  static Future<InstallCheck> run({
    Future<PackageInfo> Function() packageInfo = PackageInfo.fromPlatform,
  }) async {
    if (!isSupported()) return InstallCheck.skipped;
    try {
      final info = await packageInfo();
      final installTime = info.installTime?.millisecondsSinceEpoch;
      if (installTime == null || installTime <= 0) return InstallCheck.skipped;
      final prefs = await SharedPreferences.getInstance();
      final result = decide(
        marker: prefs.getInt(markerKey),
        installTime: installTime,
        updateTime: info.updateTime?.millisecondsSinceEpoch,
        hasDeviceFlags: deviceKeys.any(prefs.containsKey),
      );
      if (result == InstallCheck.restored) {
        for (final key in deviceKeys) {
          await prefs.remove(key);
        }
      }
      if (result != InstallCheck.sameInstall) {
        await prefs.setInt(markerKey, installTime);
        debugPrint('Kurulum denetimi: ${result.name}');
      }
      return result;
    } catch (e) {
      debugPrint('Kurulum denetimi yapılamadı: $e');
      return InstallCheck.skipped;
    }
  }
}
