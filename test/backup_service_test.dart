// Yedekle / geri yükle: beyaz liste (cihaza özgü bayraklar, önbellekler, rıza
// ve sayaçlar girmez), türlerin korunması, dosya doğrulaması ve geri yüklemede
// kayıtların değiştirilmesi
import 'dart:convert';

import 'package:ezan_saati/data/services/ayah_service.dart';
import 'package:ezan_saati/data/services/backup_service.dart';
import 'package:ezan_saati/data/services/fitre_service.dart';
import 'package:ezan_saati/data/services/hadith_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/install_guard.dart';
import 'package:ezan_saati/features/prayer_tracker/streak_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Telefonda olabilecek kullanıcı verisi (her tür)
const Map<String, Object> _userData = {
  'saved_city': 'İstanbul',
  'saved_district': 'Üsküdar',
  'saved_lat': 41.0,
  'saved_lng': 29.03,
  'time_offsets': '{"İmsak":-2,"Öğle":3}',
  'onTime_Öğle': true,
  'reminder_Akşam': true,
  'silent_Yatsı': false,
  'sound_Öğle': 'ezan2',
  'reminderSound_Akşam': 'bildirim3',
  'ezan_alarm_stream': true,
  'end_reminder_enabled': true,
  'end_reminder_minutes': 45,
  'daily_content_enabled': false,
  'religious_days_enabled': true,
  'friday_notif_enabled': false,
  'prayer_log': '{"2026-10-09":31,"2026-10-10":5}',
  'prayer_log_since': '2026-09-01',
  'prayer_kaza_added': '{"2026-10-08":2}',
  'tracker_excused': ['2026-10-01', '2026-10-02'],
  'tracker_excused_open': '2026-10-02',
  'excused_silent_ezan': false,
  'persistent_notification_enabled': false,
  'kaza_Sabah': 12,
  'kaza_Oruç': 3,
  'fast_log': ['2026-03-01', '2026-03-02'],
  'fast_kaza_added': ['2026-03-05'],
  'selected_dhikr': 'Elhamdülillah',
  'custom_dhikrs_list': ['Ya Latif', 'Ya Vedud'],
  'dhikr_daily_stats': '{"2026-10-10":99}',
  'dhikr_count_Elhamdülillah': 17,
  'dhikr_target_Elhamdülillah': 99,
  'dhikr_count_Ya Latif': 129,
  'dhikr_round_Ya Latif': 4,
  'zikir_vibration': false,
  'zikir_sound': true,
  'zikir_awake': true,
  'zikir_view_mode': 1,
  'zikir_round_mode': true,
  'zikir_volume_keys': true,
  'theme_mode': 2,
  'background_image': 'bg_mosque2.webp',
  'language_code': 'de',
  'quran_bookmark': '{"surah":36,"ayah":12}',
  'quran_font_scale': 1.2,
};

// Yedeğe girmemesi gerekenler (cihaza özgü, önbellek, rıza, sayaç, tur)
final Map<String, Object> _notBackedUp = {
  for (final key in InstallGuard.deviceKeys) key: 'x',
  InstallGuard.markerKey: 1700000000000,
  'cached_prayer_times': '{"imsak":"05:00"}',
  'cached_prayer_date': '2026-10-11',
  'bg_display': 'Öğle 12:30',
  'daily_hadith_content': 'hadis',
  'daily_hadith_source': 'kaynak',
  'daily_hadith_date': '2026-10-11',
  'daily_hadith_lang': 'tr',
  AyahService.cacheKey: '{"2026-10-11|tr":"{}"}',
  HadithService.cacheKey: '{"2026-10-11|tr":{"content":"hadis"}}',
  FitreService.cacheKey: '{"x":1}',
  QuranService.cacheIndexKey: ['quran_surah_1'],
  '${QuranService.cachePrefix}1': 'metin',
  StreakReviewPrompt.requestedKey: true,
  UsageReviewPrompt.countKey: 4,
  UsageReviewPrompt.lastDayKey: 20000,
  tourSeenKey: false,
  'is_language_selected': true,
  'IABTCF_gdprApplies': 1,
  'IABTCF_PurposeConsents': '1111',
  'dhikr_count_': 5, // adsız zikir değil
  'dhikr_round_': 2,
};

String _backupJson(Map<String, Object?> data, {Object? version = 1}) =>
    jsonEncode({
      'app': 'vaktinde',
      'version': version,
      'created': '2026-10-11T08:30:00.000Z',
      'data': data,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('beyaz liste', () {
    test('kullanıcı verisi girer; cihaza özgü bayraklar, önbellekler, rıza '
        've sayaçlar girmez', () {
      final data = BackupService.collect({..._userData, ..._notBackedUp});
      expect(data.keys.toSet(), _userData.keys.toSet());
      for (final key in _notBackedUp.keys) {
        expect(BackupService.isBackedUp(key), isFalse, reason: key);
      }
      for (final key in InstallGuard.deviceKeys) {
        expect(data.containsKey(key), isFalse, reason: key);
      }
    });

    test('bütün vakitlerin alarm ayarları ve bütün kaza sayaçları girer', () {
      for (final vakit in [
        'İmsak',
        'Güneş',
        'Öğle',
        'İkindi',
        'Akşam',
        'Yatsı',
      ]) {
        for (final prefix in [
          'onTime_',
          'reminder_',
          'silent_',
          'sound_',
          'reminderSound_',
        ]) {
          expect(BackupService.isBackedUp('$prefix$vakit'), isTrue);
        }
      }
      for (final kaza in [
        'Sabah',
        'Öğle',
        'İkindi',
        'Akşam',
        'Yatsı',
        'Vitir',
        'Oruç',
      ]) {
        expect(BackupService.isBackedUp('kaza_$kaza'), isTrue);
      }
      expect(BackupService.isBackedUp('onTime_Öğlen'), isFalse);
      expect(BackupService.isBackedUp('kaza_Teheccüd'), isFalse);
    });

    test('telefondaki bozuk kayıt yedeğe girmez: alınan her yedek geri '
        'yüklenebilir', () {
      final data = BackupService.collect({
        ..._userData,
        'theme_mode': 7,
        'saved_lat': 'kırk bir',
        'dhikr_daily_stats': '{bozuk',
        'dhikr_target_Elhamdülillah': 0,
        'kaza_Vitir': -1,
      });
      expect(data.containsKey('theme_mode'), isFalse);
      expect(data.containsKey('saved_lat'), isFalse);
      expect(data.containsKey('dhikr_daily_stats'), isFalse);
      expect(data.containsKey('dhikr_target_Elhamdülillah'), isFalse);
      expect(data.containsKey('kaza_Vitir'), isFalse);
      final text = BackupService.encode(data, created: DateTime(2026, 10, 11));
      expect(BackupService.decode(text).values, data);
    });
  });

  group('dosya', () {
    test('biçim: app, version, UTC created, sıralı data', () {
      final created = DateTime(2026, 10, 11, 9, 30);
      final text = BackupService.encode(
        BackupService.collect(_userData),
        created: created,
      );
      final json = jsonDecode(text) as Map<String, dynamic>;
      expect(json['app'], 'vaktinde');
      expect(json['version'], 1);
      expect(json['created'], created.toUtc().toIso8601String());
      expect((json['created'] as String).endsWith('Z'), isTrue);
      final keys = (json['data'] as Map<String, dynamic>).keys.toList();
      expect(keys, [...keys]..sort());
      expect(BackupService.decode(text).created, created.toUtc());
    });

    test('türler aynen döner: bool, int, double (tam sayı da), String, '
        'List<String>', () {
      final values = BackupService.decode(
        BackupService.encode(
          BackupService.collect(_userData),
          created: DateTime(2026, 10, 11),
        ),
      ).values;
      expect(values, _userData);
      for (final MapEntry(:key, :value) in _userData.entries) {
        final restored = values[key]!;
        switch (value) {
          case bool _:
            expect(restored, isA<bool>(), reason: key);
          case int _:
            expect(restored, isA<int>(), reason: key);
          case double _:
            expect(restored, isA<double>(), reason: key);
          case String _:
            expect(restored, isA<String>(), reason: key);
          case List<String> _:
            expect(restored, isA<List<String>>(), reason: key);
        }
      }
      // 41.0 tam sayı görünümlü double: JSON'da 41 yazılsa da double kalır;
      // int anahtardaki 12.0 da int olur
      final edited = BackupService.decode(
        _backupJson({'saved_lat': 41, 'kaza_Sabah': 12.0}),
      ).values;
      expect(edited['saved_lat'], isA<double>());
      expect(edited['saved_lat'], 41.0);
      expect(edited['kaza_Sabah'], isA<int>());
      expect(edited['kaza_Sabah'], 12);
    });

    test('dosya adı: vaktinde_yedek_yyyyMMdd.json', () {
      expect(
        BackupService.fileName(DateTime(2026, 3, 5, 23, 59)),
        'vaktinde_yedek_20260305.json',
      );
      expect(
        BackupService.fileName(DateTime(2026, 12, 31)),
        'vaktinde_yedek_20261231.json',
      );
    });

    test('bilinmeyen anahtar atlanır, UTF-8 BOM kabul edilir', () {
      final backup = BackupService.decode(
        '\uFEFF${_backupJson({'saved_city': 'Ankara', 'gelecek_ozellik': 1, 'cached_prayer_times': 'x', 'permissions_primed': true})}',
      );
      expect(backup.values, {'saved_city': 'Ankara'});
    });

    BackupError? errorOf(String raw) {
      try {
        BackupService.decode(raw);
        return null;
      } on BackupFormatException catch (e) {
        return e.error;
      }
    }

    test('Vaktinde yedeği olmayan ya da bozuk dosya reddedilir', () {
      final invalid = <String>[
        '',
        'not json',
        '[]',
        '"vaktinde"',
        jsonEncode({'app': 'başka', 'version': 1, 'created': 'x', 'data': {}}),
        jsonEncode({'version': 1, 'created': '2026-10-11', 'data': {}}),
        _backupJson({}, version: null),
        _backupJson({}, version: '1'),
        _backupJson({}, version: 0),
        jsonEncode({'app': 'vaktinde', 'version': 1, 'data': {}}),
        jsonEncode({
          'app': 'vaktinde',
          'version': 1,
          'created': 'dün',
          'data': {},
        }),
        jsonEncode({
          'app': 'vaktinde',
          'version': 1,
          'created': '2026-10-11T08:30:00Z',
          'data': [],
        }),
        'x' * (BackupService.maxBytes + 1),
      ];
      for (final raw in invalid) {
        expect(
          errorOf(raw),
          BackupError.invalid,
          reason: raw.length > 80 ? raw.substring(0, 80) : raw,
        );
      }
    });

    test('daha yeni biçim (version 2) ayrı uyarı', () {
      expect(errorOf(_backupJson({}, version: 2)), BackupError.newerVersion);
      expect(errorOf(_backupJson({})), isNull);
    });

    test('beyaz listedeki anahtarın türü ya da değeri geçersizse dosya '
        'reddedilir', () {
      final bad = <String, Object?>{
        'onTime_Öğle': 'true',
        'kaza_Sabah': '12',
        'kaza_Öğle': 1.5,
        'kaza_Yatsı': -3,
        'saved_city': 34,
        'saved_lat': 91.0,
        'saved_lng': -181.0,
        'fast_log': ['2026-03-01', 5],
        'tracker_excused': '2026-10-01',
        'theme_mode': 3,
        'language_code': 'xx',
        'sound_Öğle': '../../ses',
        'reminderSound_Öğle': '',
        'dhikr_target_Sübhanallah': 0,
        'dhikr_count_Sübhanallah': -1,
        'dhikr_round_Sübhanallah': 0,
        'zikir_volume_keys': 'evet',
        'dhikr_daily_stats': '{"2026-10-10":"çok"}',
        'prayer_log': '{bozuk',
        'prayer_kaza_added': '[1,2]',
        'time_offsets': '{"Öğle":45}',
        'quran_font_scale': 'büyük',
        'end_reminder_minutes': 0,
        'daily_content_enabled': null,
      };
      for (final MapEntry(:key, :value) in bad.entries) {
        expect(
          errorOf(_backupJson({key: value})),
          BackupError.invalid,
          reason: '$key: $value',
        );
      }
      // Sınırdaki geçerli değerler
      expect(
        errorOf(
          _backupJson({
            'time_offsets': '{"Öğle":30,"İmsak":-30}',
            'theme_mode': 0,
            'saved_lat': -90.0,
            'saved_lng': 180,
            'language_code': 'ar',
            'sound_İmsak': 'ezan8',
            'dhikr_count_Ya Latif': 0,
          }),
        ),
        isNull,
      );
    });
  });

  group('geri yükleme', () {
    Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    BackupData backupOf(Map<String, Object> values) =>
        BackupData(created: DateTime.utc(2026, 10, 1), values: values);

    test('yedektekiler yazılır; beyaz listede olup yedekte olmayanlar '
        'silinir; diğer kayıtlara dokunulmaz', () async {
      final prefs = await prefsWith({
        'saved_city': 'İzmir',
        'saved_lat': 38.4,
        'saved_lng': 27.1,
        'kaza_Sabah': 40,
        'kaza_Vitir': 2,
        'onTime_Akşam': true,
        'prayer_log': '{"2026-10-10":31}',
        'dhikr_count_Sübhanallah': 33,
        'dhikr_count_Ya Hafız': 7,
        'language_code': 'tr',
        ..._notBackedUp,
      });
      await BackupService.restore(prefs, backupOf(_userData));

      for (final MapEntry(:key, :value) in _userData.entries) {
        expect(prefs.get(key), value, reason: key);
      }
      // Yedekte yok → varsayılana döner
      expect(prefs.containsKey('kaza_Vitir'), isFalse);
      expect(prefs.containsKey('onTime_Akşam'), isFalse);
      expect(prefs.containsKey('dhikr_count_Sübhanallah'), isFalse);
      expect(prefs.containsKey('dhikr_count_Ya Hafız'), isFalse);
      // Beyaz liste dışı (cihaza özgü, sayaç...) aynen kalır; vakit önbelleği
      // konum değiştiği için silinir
      for (final MapEntry(:key, :value) in _notBackedUp.entries) {
        if (key == 'cached_prayer_times' || key == 'cached_prayer_date') {
          expect(prefs.containsKey(key), isFalse, reason: key);
        } else {
          expect(prefs.get(key), value, reason: key);
        }
      }
      // Türler kayıtta da korunur
      expect(prefs.getDouble('saved_lat'), 41.0);
      expect(prefs.getStringList('fast_log'), ['2026-03-01', '2026-03-02']);
      expect(prefs.getInt('kaza_Sabah'), 12);
      expect(prefs.getBool('zikir_awake'), isTrue);
    });

    test('yedekte konum yoksa telefondaki konum ve vakit önbelleği, dil '
        'yoksa seçili dil, kalıcı bildirim ayarı yoksa (eski sürümün yedeği) '
        'telefondaki ayar korunur', () async {
      final prefs = await prefsWith({
        'saved_city': 'İzmir',
        'saved_district': 'Konak',
        'saved_lat': 38.4,
        'saved_lng': 27.1,
        'cached_prayer_times': '{"imsak":"05:10"}',
        'cached_prayer_date': '2026-10-11',
        'language_code': 'fr',
        'kaza_Sabah': 40,
        'persistent_notification_enabled': false,
      });
      await BackupService.restore(prefs, backupOf({'kaza_Sabah': 3}));
      expect(prefs.getString('saved_city'), 'İzmir');
      expect(prefs.getString('saved_district'), 'Konak');
      expect(prefs.getDouble('saved_lat'), 38.4);
      expect(prefs.getDouble('saved_lng'), 27.1);
      expect(prefs.getString('cached_prayer_times'), '{"imsak":"05:10"}');
      expect(prefs.getString('language_code'), 'fr');
      expect(prefs.getBool('persistent_notification_enabled'), isFalse);
      expect(prefs.getInt('kaza_Sabah'), 3);
    });

    test('konum birlikte değişir: koordinatsız yedekte eski koordinat '
        'kalmaz', () async {
      final prefs = await prefsWith({
        'saved_city': 'İzmir',
        'saved_district': 'Konak',
        'saved_lat': 38.4,
        'saved_lng': 27.1,
        'cached_prayer_times': '{"imsak":"05:10"}',
        'cached_prayer_date': '2026-10-11',
      });
      await BackupService.restore(prefs, backupOf({'saved_city': 'Ankara'}));
      expect(prefs.getString('saved_city'), 'Ankara');
      expect(prefs.containsKey('saved_district'), isFalse);
      expect(prefs.containsKey('saved_lat'), isFalse);
      expect(prefs.containsKey('saved_lng'), isFalse);
      expect(prefs.containsKey('cached_prayer_times'), isFalse);
      expect(prefs.containsKey('cached_prayer_date'), isFalse);
    });

    test('kayıt değişimi takip dinleyicilerine bildirilir', () async {
      final prefs = await prefsWith({'prayer_log': '{"2026-10-10":31}'});
      final before = PrayerTrackerService.changes.value;
      final replacements = PrayerTrackerService.replacements;
      // Dinleyici bildirildiğinde yeni kaydı okur
      final reads = <Future<Map<String, int>>>[];
      void listener() => reads.add(PrayerTrackerService().loadLog());

      PrayerTrackerService.changes.addListener(listener);
      addTearDown(() => PrayerTrackerService.changes.removeListener(listener));
      await PrayerTrackerService.replaceRecords(
        () => BackupService.restore(
          prefs,
          backupOf({'prayer_log': '{"2026-10-09":31}'}),
        ),
      );
      expect(PrayerTrackerService.changes.value, before + 1);
      expect(PrayerTrackerService.replacements, replacements + 2);
      expect(reads, hasLength(1));
      expect(await reads.single, {'2026-10-09': 31});
    });

    test('yedek alma: kayıtlardan dosya, geri okununca aynı veri', () async {
      final prefs = await prefsWith({..._userData, ..._notBackedUp});
      final text = await BackupService.export(
        prefs,
        now: DateTime(2026, 10, 11, 12),
      );
      expect(text, isNot(contains('permissions_primed')));
      expect(text, isNot(contains('cached_prayer_times')));
      expect(text, isNot(contains('IABTCF')));
      final backup = BackupService.decode(text);
      expect(backup.values, _userData);
      expect(backup.created, DateTime(2026, 10, 11, 12).toUtc());

      // Yedek başka bir telefona yüklenince aynı kayıtlar oluşur
      final other = await prefsWith({'language_code': 'tr'});
      await BackupService.restore(other, backup);
      for (final MapEntry(:key, :value) in _userData.entries) {
        expect(other.get(key), value, reason: key);
      }
    });
  });
}
