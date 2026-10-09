import 'package:flutter/services.dart';

import 'package:ezan_saati/l10n/app_localizations.dart';

/// Bildirim Kontrolü satırının durumu
enum HealthStatus { ok, warning, info }

/// Ezan sesini duyulmaz yapan durum
enum VolumeIssue { alarmMuted, silentMode, notificationMuted }

/// Arka plan ayarları rehberi için üretici ailesi
enum PhoneVendor { xiaomi, huawei, oppo, vivo, samsung, transsion, generic }

/// Açılabilen sistem ayar ekranları (MainActivity "openSettings")
enum SettingsTarget { app, notifications, battery, dnd, sound }

/// MainActivity "deviceInfo": ezanı etkileyen cihaz durumu (okunamayan alan null)
class DeviceStatus {
  const DeviceStatus({
    this.manufacturer = '',
    this.brand = '',
    this.sdkInt,
    this.batteryOptimized,
    this.interruptionFilter,
    this.notificationVolume,
    this.alarmVolume,
    this.ringerMode,
  });

  factory DeviceStatus.fromMap(Map<Object?, Object?> map) => DeviceStatus(
    manufacturer: map['manufacturer'] as String? ?? '',
    brand: map['brand'] as String? ?? '',
    sdkInt: map['sdkInt'] as int?,
    batteryOptimized: map['batteryOptimized'] as bool?,
    interruptionFilter: map['interruptionFilter'] as int?,
    notificationVolume: map['notificationVolume'] as int?,
    alarmVolume: map['alarmVolume'] as int?,
    ringerMode: map['ringerMode'] as int?,
  );

  final String manufacturer;
  final String brand;
  final int? sdkInt;

  /// Pil optimizasyonu açık (isIgnoringBatteryOptimizations false)
  final bool? batteryOptimized;

  /// NotificationManager.INTERRUPTION_FILTER_*: 0 bilinmiyor, 1 Rahatsız Etmeyin
  /// kapalı, 2 öncelikli, 3 tam sessizlik (alarm da çalmaz), 4 sadece alarmlar
  final int? interruptionFilter;
  final int? notificationVolume;
  final int? alarmVolume;

  /// AudioManager.RINGER_MODE_*: 0 sessiz, 1 titreşim, 2 normal
  final int? ringerMode;
}

/// Bildirim Kontrolü: cihaz durumu, sistem ayar ekranları ve saf durum kararları
abstract final class NotificationHealth {
  static const MethodChannel _device = MethodChannel('vaktinde/device');

  static const int filterAll = 1;
  static const int filterNone = 3;
  static const int ringerNormal = 2;

  /// Arka plan görevi (6 saatte bir) bundan uzun süre çalışmadıysa uyarı
  static const Duration backgroundStaleAfter = Duration(hours: 24);

  /// Üreticilerin arka plan kısıtlamaları için ayrıntılı rehber (dış tarayıcı)
  static const String guideUrl = 'https://dontkillmyapp.com';

  /// Rehber başlığındaki marka adları (çevrilmez)
  static const Map<PhoneVendor, String> vendorNames = {
    PhoneVendor.xiaomi: 'Xiaomi / Redmi / POCO',
    PhoneVendor.huawei: 'Huawei / Honor',
    PhoneVendor.oppo: 'OPPO / realme / OnePlus',
    PhoneVendor.vivo: 'vivo / iQOO',
    PhoneVendor.samsung: 'Samsung',
    PhoneVendor.transsion: 'Tecno / Infinix / itel',
  };

  /// Cihaz durumu; okunamazsa (Android değil, kanal hatası) null
  static Future<DeviceStatus?> readDevice() async {
    try {
      final map = await _device.invokeMapMethod<Object?, Object?>('deviceInfo');
      return map == null ? null : DeviceStatus.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// Sistem ayar ekranını açar (yoksa uygulama bilgisi); açılamazsa false
  static Future<bool> openSettings(SettingsTarget target) async {
    try {
      return await _device.invokeMethod<bool>('openSettings', {
            'target': target.name,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// Build.MANUFACTURER / BRAND kelimelerinden üretici ailesi
  static PhoneVendor vendorOf(String manufacturer, String brand) {
    final words = '$manufacturer $brand'
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .toSet();
    bool any(List<String> names) => names.any(words.contains);
    if (any(['xiaomi', 'redmi', 'poco'])) return PhoneVendor.xiaomi;
    if (any(['huawei', 'honor'])) return PhoneVendor.huawei;
    if (any(['oppo', 'realme', 'oneplus'])) return PhoneVendor.oppo;
    if (any(['vivo', 'iqoo'])) return PhoneVendor.vivo;
    if (any(['samsung'])) return PhoneVendor.samsung;
    if (any(['tecno', 'infinix', 'itel'])) return PhoneVendor.transsion;
    return PhoneVendor.generic;
  }

  /// Üreticiye göre arka plan adımları (otomatik başlatma, pil kısıtlaması, son
  /// uygulamalarda kilit). Uygulama adları (i Manager, Phone Master) çevrilmez.
  static List<String> guideSteps(PhoneVendor vendor, AppLocalizations loc) =>
      switch (vendor) {
        PhoneVendor.xiaomi => [
          loc.healthStepXiaomiAutostart,
          loc.healthStepXiaomiBattery,
          loc.healthStepLockRecents,
        ],
        PhoneVendor.huawei => [
          loc.healthStepHuaweiLaunch,
          loc.healthStepLockRecents,
        ],
        PhoneVendor.oppo => [
          loc.healthStepOppoBackground,
          loc.healthStepLockRecents,
        ],
        PhoneVendor.vivo => [
          loc.healthStepVivoBackground,
          loc.healthStepAutostartIn('i Manager'),
          loc.healthStepLockRecents,
        ],
        PhoneVendor.samsung => [
          loc.healthStepAppBattery,
          loc.healthStepSamsungSleeping,
        ],
        PhoneVendor.transsion => [
          loc.healthStepAutostartIn('Phone Master'),
          loc.healthStepAppBattery,
          loc.healthStepLockRecents,
        ],
        PhoneVendor.generic => [
          loc.healthStepAppBattery,
          loc.healthStepLockRecents,
        ],
      };

  /// Ezan alarm akışındaysa ("sessiz modda da çal") sadece alarm sesi önemlidir;
  /// bildirim akışında sessiz/titreşim modu ve bildirim sesi. Sorun yoksa null.
  static VolumeIssue? volumeIssue(DeviceStatus d, {required bool alarmStream}) {
    if (alarmStream) return d.alarmVolume == 0 ? VolumeIssue.alarmMuted : null;
    if (d.ringerMode != null && d.ringerMode != ringerNormal) {
      return VolumeIssue.silentMode;
    }
    if (d.notificationVolume == 0) return VolumeIssue.notificationMuted;
    return null;
  }

  /// Rahatsız Etmeyin: kapalıysa ok. Açıkken ezan alarm akışındaysa alarmlara izin
  /// verilir (tam sessizlik hariç): bilgi; diğer durumlarda uyarı. Bilinmiyorsa null.
  static HealthStatus? dndStatus(int? filter, {required bool alarmStream}) {
    if (filter == null || filter == 0) return null;
    if (filter == filterAll) return HealthStatus.ok;
    if (alarmStream && filter != filterNone) return HealthStatus.info;
    return HealthStatus.warning;
  }

  /// Arka planda çalışma: son koşu 24 saatten eskiyse uyarı. Kayıt hiç yoksa (1.2.0
  /// öncesi ya da hiç çalışmadı) kurulum/güncelleme 24 saatten eskiyse uyarı, değilse
  /// henüz bilinmiyor (null).
  static HealthStatus? backgroundStatus({
    required DateTime? lastRun,
    required DateTime? installedAt,
    required DateTime now,
  }) {
    if (lastRun != null) {
      return now.difference(lastRun) > backgroundStaleAfter
          ? HealthStatus.warning
          : HealthStatus.ok;
    }
    if (installedAt != null &&
        now.difference(installedAt) > backgroundStaleAfter) {
      return HealthStatus.warning;
    }
    return null;
  }
}
