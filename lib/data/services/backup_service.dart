import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/common/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import 'hatim.dart';
import 'hatim_service.dart';
import 'quran_service.dart';
import 'storage_service.dart';

/// Yedek dosyası neden okunamadı (kullanıcıya gösterilecek mesajı seçer)
enum BackupError {
  /// JSON değil, Vaktinde yedeği değil, çok büyük ya da bir değer beklenen
  /// türde/aralıkta değil
  invalid,

  /// Uygulamanın daha yeni bir sürümüyle alınmış (bilinmeyen biçim)
  newerVersion,
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.error, [this.detail]);

  final BackupError error;
  final String? detail;

  @override
  String toString() =>
      'BackupFormatException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// Okunmuş ve doğrulanmış yedek
class BackupData {
  const BackupData({required this.created, required this.values});

  /// Yedeğin alındığı an
  final DateTime created;

  /// Beyaz listedeki anahtarlar → SharedPreferences türündeki değer (bool, int,
  /// double, String, List<String>)
  final Map<String, Object> values;
}

enum _Kind { boolean, integer, decimal, text, textList }

class _Field {
  const _Field(this.kind, [this.check]);

  final _Kind kind;

  /// Türü doğru değerin anlamca da geçerli olup olmadığı (bozuk değer uygulamayı
  /// çökertmesin, ezanı susturmasın)
  final bool Function(Object value)? check;
}

/// Yedekle / geri yükle: kullanıcı verisi (SharedPreferences) beyaz listeyle bir
/// JSON dosyasına yazılır ve geri okunur. Biçim:
/// `{"app": "vaktinde", "version": 1, "created": ISO-8601 (UTC), "data": {...}}`;
/// `data` anahtarları SharedPreferences anahtarlarıdır, değerler kayıttaki
/// türleriyle (bool, int, double, String, List<String>) yazılır ve okurken
/// anahtarın beklenen türüne göre doğrulanır (JSON'da 41.0 → 41 olsa da double kalır).
///
/// Yedeğe girmeyenler: cihaza özgü bayraklar (InstallGuard.deviceKeys), vakit /
/// hadis / fitre / Kur'an önbellekleri, kalıcı bildirim metni, reklam rızası
/// (UMP/TCF ayrı dosyada), değerlendirme ve kullanım sayaçları, tanıtım turu.
abstract final class BackupService {
  static const String appId = 'vaktinde';
  static const int formatVersion = 1;

  /// Seçilen dosya en fazla bu kadar okunur (MainActivity ile aynı sınır)
  static const int maxBytes = 1024 * 1024;

  /// Vakit ince ayarı sınırı (dk; TimeAdjustView ile aynı)
  static const int maxTimeOffset = 30;

  // StorageService.loadSettings ve loadMissedPrayers ile aynı adlar
  static const List<String> _vakitler = [
    "İmsak",
    "Güneş",
    "Öğle",
    "İkindi",
    "Akşam",
    "Yatsı",
  ];
  static const List<String> _kazaKeys = [
    "Sabah",
    "Öğle",
    "İkindi",
    "Akşam",
    "Yatsı",
    "Vitir",
    "Oruç",
  ];

  static const String _languageKey = 'language_code';

  /// Konum birlikte geri yüklenir (il adı başka, koordinat başka yerin olmasın);
  /// yedekte hiçbiri yoksa telefondaki konum korunur
  static const Set<String> locationKeys = {
    'saved_city',
    'saved_district',
    'saved_lat',
    'saved_lng',
  };

  // Bugünün vakit önbelleği (StorageService.savePrayerTimesData): konum
  // değişince silinir, koordinatla hemen yeniden hesaplanır
  static const List<String> _prayerCacheKeys = [
    'cached_prayer_times',
    'cached_prayer_date',
  ];

  static final Map<String, _Field> _fields = {
    // Konum ve vakit ince ayarı
    'saved_city': const _Field(_Kind.text),
    'saved_district': const _Field(_Kind.text),
    'saved_lat': const _Field(_Kind.decimal, _isLatitude),
    'saved_lng': const _Field(_Kind.decimal, _isLongitude),
    'time_offsets': const _Field(_Kind.text, _isTimeOffsets),
    // Ezan, hatırlatma ve bildirim ayarları
    for (final vakit in _vakitler) ...{
      'onTime_$vakit': const _Field(_Kind.boolean),
      'reminder_$vakit': const _Field(_Kind.boolean),
      'silent_$vakit': const _Field(_Kind.boolean),
      'sound_$vakit': const _Field(_Kind.text, _isSoundId),
      'reminderSound_$vakit': const _Field(_Kind.text, _isSoundId),
    },
    StorageService.ezanAlarmStreamKey: const _Field(_Kind.boolean),
    'end_reminder_enabled': const _Field(_Kind.boolean),
    'end_reminder_minutes': const _Field(_Kind.integer, _isPositive),
    StorageService.dailyContentEnabledKey: const _Field(_Kind.boolean),
    StorageService.religiousDaysEnabledKey: const _Field(_Kind.boolean),
    StorageService.fridayNotifEnabledKey: const _Field(_Kind.boolean),
    StorageService.excusedSilentEzanKey: const _Field(_Kind.boolean),
    StorageService.persistentNotificationKey: const _Field(_Kind.boolean),
    // Namaz takibi, kaza sayaçları, Ramazan orucu
    'prayer_log': const _Field(_Kind.text, _isMaskMap),
    'prayer_log_since': const _Field(_Kind.text),
    'prayer_kaza_added': const _Field(_Kind.text, _isMaskMap),
    'tracker_excused': const _Field(_Kind.textList),
    'tracker_excused_open': const _Field(_Kind.text),
    'tracker_badges': const _Field(_Kind.text),
    for (final key in _kazaKeys)
      'kaza_$key': const _Field(_Kind.integer, _isNonNegative),
    'fast_log': const _Field(_Kind.textList),
    'fast_kaza_added': const _Field(_Kind.textList),
    // Zikirmatik (sayaç ve hedefler aşağıda, zikir adıyla)
    'selected_dhikr': const _Field(_Kind.text),
    'custom_dhikrs_list': const _Field(_Kind.textList),
    'dhikr_daily_stats': const _Field(_Kind.text, _isCountMap),
    'zikir_vibration': const _Field(_Kind.boolean),
    'zikir_sound': const _Field(_Kind.boolean),
    'zikir_awake': const _Field(_Kind.boolean),
    'zikir_view_mode': const _Field(_Kind.integer, _isNonNegative),
    'zikir_round_mode': const _Field(_Kind.boolean),
    'zikir_volume_keys': const _Field(_Kind.boolean),
    // Görünüm ve dil
    'theme_mode': const _Field(_Kind.integer, _isThemeMode),
    'background_image': const _Field(_Kind.text),
    ThemeProvider.textScaleKey: const _Field(_Kind.decimal, _isTextScale),
    _languageKey: const _Field(_Kind.text, _isLanguage),
    // Kur'an: kaldığın yer ve yazı boyutu (sure önbelleği değil), hatim
    QuranService.bookmarkKey: const _Field(_Kind.text),
    QuranService.fontScaleKey: const _Field(_Kind.decimal, _isFinite),
    HatimService.planKey: const _Field(_Kind.text, _isHatimPlan),
    HatimService.countKey: const _Field(_Kind.integer, _isNonNegative),
    HatimService.reminderKey: const _Field(_Kind.boolean),
    HatimService.reminderTimeKey: const _Field(_Kind.integer, _isMinuteOfDay),
  };

  // Zikir adına göre (hazır, Esmaü'l-Hüsna ya da kullanıcının eklediği)
  static const Map<String, _Field> _prefixed = {
    'dhikr_count_': _Field(_Kind.integer, _isNonNegative),
    // 0 hedef zikirde sıfıra bölme olurdu
    'dhikr_target_': _Field(_Kind.integer, _isPositive),
    // Tur kipinde tamamlanan tur + 1 (1. tur kaydedilmez)
    'dhikr_round_': _Field(_Kind.integer, _isPositive),
  };

  static _Field? _fieldOf(String key) {
    final exact = _fields[key];
    if (exact != null) return exact;
    for (final MapEntry(key: prefix, value: field) in _prefixed.entries) {
      if (key.length > prefix.length && key.startsWith(prefix)) return field;
    }
    return null;
  }

  /// Anahtar yedeğe girer mi
  static bool isBackedUp(String key) => _fieldOf(key) != null;

  // JSON'dan gelen değeri anahtarın SharedPreferences türüne çevirir; tür
  // uymuyorsa ya da değer geçersizse null
  static Object? _typed(_Field field, Object? value) {
    final Object? typed = switch (field.kind) {
      _Kind.boolean => value is bool ? value : null,
      _Kind.integer =>
        value is int
            ? value
            : (value is double &&
                      value.isFinite &&
                      value == value.roundToDouble()
                  ? value.toInt()
                  : null),
      _Kind.decimal => value is num ? value.toDouble() : null,
      _Kind.text => value is String ? value : null,
      _Kind.textList =>
        value is List && value.every((e) => e is String)
            ? List<String>.from(value)
            : null,
    };
    if (typed == null) return null;
    return (field.check?.call(typed) ?? true) ? typed : null;
  }

  /// Tüm kayıtlardan yedeklenecekler (anahtar sıralı). Beklenen türde olmayan
  /// ya da geçersiz kayıt atlanır: alınan her yedek geri yüklenebilir.
  static Map<String, Object> collect(Map<String, Object?> all) {
    final data = SplayTreeMap<String, Object>();
    all.forEach((key, value) {
      final field = _fieldOf(key);
      if (field == null) return;
      final typed = _typed(field, value);
      if (typed != null) data[key] = typed;
    });
    return data;
  }

  static String encode(Map<String, Object> data, {required DateTime created}) =>
      const JsonEncoder.withIndent('  ').convert({
        'app': appId,
        'version': formatVersion,
        'created': created.toUtc().toIso8601String(),
        'data': data,
      });

  /// Dosya metnini doğrular. Bilinmeyen anahtarlar atlanır; beyaz listedeki bir
  /// anahtarın türü ya da değeri geçersizse dosyanın tamamı reddedilir.
  static BackupData decode(String raw) {
    if (raw.length > maxBytes) {
      throw const BackupFormatException(BackupError.invalid, 'too large');
    }
    final Object? json;
    try {
      // Bazı düzenleyiciler dosya başına UTF-8 BOM ekler
      json = jsonDecode(raw.startsWith('\uFEFF') ? raw.substring(1) : raw);
    } on FormatException {
      throw const BackupFormatException(BackupError.invalid, 'not json');
    }
    if (json is! Map<String, dynamic> || json['app'] != appId) {
      throw const BackupFormatException(BackupError.invalid, 'not a backup');
    }
    final version = json['version'];
    if (version is! int || version < 1) {
      throw const BackupFormatException(BackupError.invalid, 'version');
    }
    if (version > formatVersion) {
      throw const BackupFormatException(BackupError.newerVersion);
    }
    final createdRaw = json['created'];
    final created = createdRaw is String ? DateTime.tryParse(createdRaw) : null;
    if (created == null) {
      throw const BackupFormatException(BackupError.invalid, 'created');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupFormatException(BackupError.invalid, 'data');
    }
    final values = <String, Object>{};
    for (final MapEntry(:key, :value) in data.entries) {
      final field = _fieldOf(key);
      if (field == null) continue;
      final typed = _typed(field, value);
      if (typed == null) throw BackupFormatException(BackupError.invalid, key);
      values[key] = typed;
    }
    return BackupData(created: created, values: values);
  }

  /// Paylaşılan dosyanın adı: vaktinde_yedek_yyyyMMdd.json (yerel tarih)
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'vaktinde_yedek_${now.year.toString().padLeft(4, '0')}'
        '${two(now.month)}${two(now.day)}.json';
  }

  /// Kayıtlı verinin yedek dosyası metni
  static Future<String> export(
    SharedPreferences prefs, {
    required DateTime now,
  }) async {
    // Bildirimdeki "Kıldım" ayrı isolate'te yazar: önbellek tazelenir
    await prefs.reload();
    return encode(
      collect({for (final key in prefs.getKeys()) key: prefs.get(key)}),
      created: now,
    );
  }

  /// Yedeği yazar: beyaz listedeki her anahtar yedektekiyle değiştirilir,
  /// yedekte olmayan silinir (varsayılana döner). Yedekte hiç konum yoksa
  /// telefondaki konum, dil yoksa seçili dil, kalıcı bildirim ayarı yoksa
  /// (ayardan önceki sürümün yedeği) telefondaki ayar korunur. Konum değiştiyse
  /// bugünün vakit önbelleği silinir (eski yerin vakitleri yeni adla görünmesin).
  /// Beyaz liste dışındaki kayıtlara dokunulmaz.
  static Future<void> restore(
    SharedPreferences prefs,
    BackupData backup,
  ) async {
    final values = backup.values;
    final replaceLocation = locationKeys.any(values.containsKey);
    await prefs.reload();
    for (final MapEntry(:key, :value) in values.entries) {
      await _write(prefs, key, value);
    }
    for (final key in prefs.getKeys().toList()) {
      if (!isBackedUp(key) || values.containsKey(key)) continue;
      if (!replaceLocation && locationKeys.contains(key)) continue;
      if (key == _languageKey ||
          key == StorageService.persistentNotificationKey) {
        continue;
      }
      await prefs.remove(key);
    }
    if (replaceLocation) {
      for (final key in _prayerCacheKeys) {
        await prefs.remove(key);
      }
    }
  }

  static Future<bool> _write(
    SharedPreferences prefs,
    String key,
    Object value,
  ) => switch (value) {
    bool v => prefs.setBool(key, v),
    int v => prefs.setInt(key, v),
    double v => prefs.setDouble(key, v),
    String v => prefs.setString(key, v),
    List<String> v => prefs.setStringList(key, v),
    _ => Future<bool>.value(false),
  };

  static const MethodChannel _device = MethodChannel('vaktinde/device');

  /// Sistem dosya seçicisi (MainActivity, ACTION_OPEN_DOCUMENT): seçilen
  /// dosyanın metni, vazgeçilirse null. [maxBytes]'tan büyük dosya
  /// [BackupFormatException]; seçici/okuma hatası PlatformException.
  static Future<String?> pickFile() async {
    try {
      return await _device.invokeMethod<String>('pickBackupFile');
    } on PlatformException catch (e) {
      if (e.code == 'too_large') {
        throw const BackupFormatException(BackupError.invalid, 'too large');
      }
      rethrow;
    }
  }
}

bool _isLatitude(Object v) => v is double && v.isFinite && v.abs() <= 90;

bool _isLongitude(Object v) => v is double && v.isFinite && v.abs() <= 180;

bool _isFinite(Object v) => v is double && v.isFinite;

bool _isNonNegative(Object v) => v is int && v >= 0;

bool _isPositive(Object v) => v is int && v > 0;

bool _isMinuteOfDay(Object v) => v is int && v >= 0 && v < 24 * 60;

bool _isHatimPlan(Object v) => v is String && HatimPlan.parse(v) != null;

bool _isThemeMode(Object v) =>
    v is int && v >= 0 && v < ThemeMode.values.length;

bool _isTextScale(Object v) => ThemeProvider.textScales.contains(v);

bool _isLanguage(Object v) =>
    v is String &&
    AppLocalizations.supportedLocales.any((l) => l.languageCode == v);

// Ezan (ezan1…) ve bildirim (bildirim1…) sesleri: res/raw adları
final RegExp _soundId = RegExp(r'^(ezan|bildirim)\d+$');

bool _isSoundId(Object v) => v is String && _soundId.hasMatch(v);

// JSON nesnesi: anahtar → tam sayı (kayıt biçimleri: takip maskeleri, zikir
// istatistikleri, vakit ince ayarı)
bool _isIntMap(Object v, bool Function(String key, int value) valid) {
  if (v is! String) return false;
  try {
    final decoded = jsonDecode(v);
    return decoded is Map<String, dynamic> &&
        decoded.entries.every((e) => e.value is int && valid(e.key, e.value));
  } on FormatException {
    return false;
  }
}

bool _isMaskMap(Object v) => _isIntMap(v, (_, mask) => mask >= 0);

bool _isCountMap(Object v) => _isIntMap(v, (_, count) => count >= 0);

bool _isTimeOffsets(Object v) => _isIntMap(
  v,
  (vakit, minutes) =>
      BackupService._vakitler.contains(vakit) &&
      minutes.abs() <= BackupService.maxTimeOffset,
);
