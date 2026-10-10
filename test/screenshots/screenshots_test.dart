// Ekran görüntüsü düzeneği: ana ekranları gerçek fontlarla PNG'ye çizer.
//
// Sadece SCREENSHOT_DIR verilince çalışır (normal `flutter test` atlar):
//   SCREENSHOT_DIR=/tmp/shots TZ=Europe/Istanbul flutter test test/screenshots/
//
// Eklenti kanalları sahte yanıt verir (reklam yüklenmez, konum İstanbul, pusula
// sabit yön); ana ekran durumu FakeHomeViewModel ile verilir (ağ/izin yok).
// Tek ekran: --plain-name "tr koyu tema" gibi test adıyla süzülür.
//
// Çıktı: <ekran>.png (411x891 dp, 1.5x) ve `_errors.txt` (ekran başına çerçeve
// hataları: taşma, yerleşim). Sınırlar: Arapça için DejaVu Sans yedek fontu
// kullanılır (cihazda sistem fontu); aile adı verilmemiş stiller (ör.
// DropdownButton.style) test motorunda siyah kutu olarak görünür.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ezan_saati/data/models/hadith_model.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/prayer_refresh_service.dart';
import 'package:ezan_saati/data/services/prayer_time_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/esmaul_husna/view/esmaul_husna_view.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/imsakiye/view/imsakiye_view.dart';
import 'package:ezan_saati/features/missed_prayers/view/missed_prayers_view.dart';
import 'package:ezan_saati/features/notification_health/view/notification_health_view.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/features/religious_days/view/religious_days_view.dart';
import 'package:ezan_saati/features/settings/view/settings_view.dart';
import 'package:ezan_saati/features/settings/view/time_adjust_view.dart';
import 'package:ezan_saati/features/zakat/view/zakat_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/dhikr_list_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/dhikr_stats_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_settings_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:ezan_saati/main.dart' show MyApp;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? _outDir = Platform.environment['SCREENSHOT_DIR'];

// Tipik telefon: 411x891 dp; PNG'ler küçük kalsın diye 1.5x çizilir
const double _deviceRatio = 2.625;
const double _outRatio = 1.5;

const double _istanbulLat = 41.0082;
const double _istanbulLng = 28.9784;

final GlobalKey _rootKey = GlobalKey();
final _android = TargetPlatformVariant.only(TargetPlatform.android);

/// Ağ/izin istemeyen ana ekran durumu
class FakeHomeViewModel extends HomeViewModel {
  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshLocationAndTimes(BuildContext context) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> applyTimeOffsets() async {}
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

DateTime _parse(DateTime day, String hhmm) {
  final p = hhmm.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(p[0]),
    int.parse(p[1]),
  );
}

PrayerTimesModel _istanbulTimes() =>
    PrayerTimeService().calculate(_istanbulLat, _istanbulLng);

/// Gerçek vakitler, akşam 50 dk sonra olacak şekilde kaydırılır: kerahat
/// ("yaklaşıyor") ve işaretlenebilir vakitler görünür. Gece yarısını aşarsa
/// sıkıştırılmış vakitler (güneş 10 dk önce doğmuş: kerahat sürüyor); o da
/// sığmazsa null.
PrayerTimesModel? _busyTimes() {
  final real = _istanbulTimes();
  final now = DateTime.now();
  final shift = now
      .add(const Duration(minutes: 50))
      .difference(_parse(now, real.aksam!));
  var out = <String>[];
  for (final v in [
    real.imsak!,
    real.gunes!,
    real.ogle!,
    real.ikindi!,
    real.aksam!,
    real.yatsi!,
  ]) {
    final t = _parse(now, v).add(shift);
    if (!DateUtils.isSameDay(t, now)) {
      out = [];
      break;
    }
    out.add(_hhmm(t));
  }
  if (out.isEmpty) {
    for (final minutes in [-30, -10, 20, 25, 30, 35]) {
      final t = now.add(Duration(minutes: minutes));
      if (!DateUtils.isSameDay(t, now)) return null;
      out.add(_hhmm(t));
    }
  }
  return PrayerTimesModel(
    imsak: out[0],
    gunes: out[1],
    ogle: out[2],
    ikindi: out[3],
    aksam: out[4],
    yatsi: out[5],
  );
}

FakeHomeViewModel _homeVm(String lang, {PrayerTimesModel? times}) {
  final vm = FakeHomeViewModel()
    ..prayerTimes = times ?? _istanbulTimes()
    ..city = 'İstanbul'
    ..district = 'Kadıköy'
    ..isLoading = false
    ..errorMessageKey = ''
    ..hijriDateText = PrayerRefreshService.hijriDateText(lang)
    ..dailyAyah = AyahModel(
      number: 293,
      surahName: 'Bakara',
      numberInSurah: 286,
      arabicText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      translatedText: 'Allah hiç kimseye gücünün yetmeyeceği bir yük yüklemez.',
    )
    ..dailyHadith = HadithModel(
      content: 'Ameller ancak niyetlere göredir.',
      source: 'Buhârî, Bed’ü’l-vahy 1',
    )
    ..onTimeAlarms = {'Öğle': true, 'Akşam': true, 'Yatsı': true}
    ..reminderAlarms = {'Akşam': true}
    ..selectedSounds = {'Öğle': 'ezan2'}
    ..selectedReminderSounds = {}
    ..silentModeSettings = {};
  return vm;
}

Map<String, Object> _prefs({
  required String lang,
  bool languageSelected = true,
  int themeMode = 1, // ThemeMode.light
  String? background,
}) {
  final today = DateTime.now();
  String dk(int daysAgo) =>
      PrayerTracker.dateKey(PrayerTracker.addDays(today, -daysAgo));
  int mask(List<String> keys) =>
      keys.fold(0, (m, k) => m | PrayerTracker.bit(k));
  final log = <String, int>{
    dk(0): mask(['İmsak', 'Öğle']),
    dk(1): PrayerTracker.fullMask,
    dk(2): mask(['İmsak', 'Öğle', 'İkindi', 'Akşam']),
    dk(3): PrayerTracker.fullMask,
    dk(4): mask(['Öğle', 'Akşam', 'Yatsı']),
    dk(5): PrayerTracker.fullMask,
    dk(6): mask(['İmsak', 'Akşam', 'Yatsı']),
  };
  final stats = <String, int>{
    for (var i = 0; i < 7; i++)
      PrayerTracker.addDays(today, -i).toIso8601String().substring(0, 10): [
        99,
        33,
        150,
        0,
        66,
        330,
        120,
      ][i],
  };
  return {
    'language_code': lang,
    'is_language_selected': languageSelected,
    'theme_mode': themeMode,
    'background_image': ?background,
    'is_first_launch_showcase_v3': false,
    // İzin açıklama penceresi ekran görüntülerini kapatmasın
    'permissions_primed': true,
    'saved_city': 'İstanbul',
    'saved_district': 'Kadıköy',
    'saved_lat': _istanbulLat,
    'saved_lng': _istanbulLng,
    'time_offsets': '{"Yatsı":2}',
    'prayer_log': jsonEncode(log),
    'prayer_log_since': dk(20),
    'kaza_Sabah': 12,
    'kaza_Öğle': 8,
    'kaza_İkindi': 5,
    'kaza_Akşam': 3,
    'kaza_Yatsı': 9,
    'kaza_Vitir': 4,
    'kaza_Oruç': 2,
    'selected_dhikr': 'Sübhanallah',
    'dhikr_count_Sübhanallah': 27,
    'dhikr_target_Sübhanallah': 33,
    'custom_dhikrs_list': ['Ya Vedûd'],
    'dhikr_daily_stats': jsonEncode(stats),
    // Bildirim Kontrolü: arka plan görevi 30 saattir çalışmadı (üretici rehberi öne çıkar)
    'last_headless_run': today
        .subtract(const Duration(hours: 50))
        .millisecondsSinceEpoch,
  };
}

/// Bildirim Kontrolü: kurulu ezanlar (bugün ve yarın öğle, akşam, yatsı)
List<Map<String, Object>> _pendingEzans() => [
  for (final day in [0, 1])
    for (final vakit in [2, 4, 5])
      {
        'id': PrayerRefreshService.alarmId(
          PrayerTracker.addDays(DateTime.now(), day),
          vakit,
        ),
        'title': '',
        'body': '',
        'payload': '',
      },
];

/// Tam zamanlı alarm izni (false: ana ekranda alarm izni uyarısı)
bool _exactAllowed = true;

String? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  // .../flutter/bin/cache/artifacts/engine/<platform>/flutter_tester
  final exe = File(Platform.resolvedExecutable).absolute.path;
  final idx = exe.indexOf(
    '${Platform.pathSeparator}bin${Platform.pathSeparator}cache',
  );
  return idx > 0 ? exe.substring(0, idx) : null;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var any = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    any = true;
  }
  if (any) await loader.load();
}

Future<void> _loadFonts() async {
  // Uygulama teması: pubspec'teki "Poppins" ailesi (400-900) ve Amiri
  await _loadFont('Poppins', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/google_fonts/Poppins-$w.ttf',
    for (final w in ['ExtraBold', 'Black'])
      'assets/google_fonts/Poppins-$w.ttf',
  ]);
  await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
  // Poppins'te Arapça yok: temadaki "sans-serif" yedeği cihazda sistem fontu,
  // testte DejaVu Sans
  await _loadFont('sans-serif', [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]);
  // google_fonts aile adları: Poppins_regular, Poppins_500 ...
  const poppins = {
    'regular': 'Regular',
    '500': 'Medium',
    '600': 'SemiBold',
    '700': 'Bold',
    '800': 'ExtraBold',
    '900': 'Black',
  };
  for (final e in poppins.entries) {
    await _loadFont('Poppins_${e.key}', [
      'assets/google_fonts/Poppins-${e.value}.ttf',
    ]);
  }
  final root = _flutterRoot();
  if (root == null) return;
  final material = '$root/bin/cache/artifacts/material_fonts';
  await _loadFont('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  final roboto = [
    for (final w in ['Regular', 'Medium', 'Bold', 'Light', 'Black', 'Italic'])
      '$material/Roboto-$w.ttf',
  ];
  // Android varsayılanı; pakette olmayan 'Courier' (geri sayım) cihazda Roboto'ya düşer
  await _loadFont('Roboto', roboto);
  await _loadFont('Courier', roboto);
  // Not: aile adı hiç verilmemiş stiller (ör. DropdownButton.style) test
  // motorunda siyah kutu olarak çizilir (cihazda Roboto; Poppins değil).
}

void _mockPlatform() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/geolocator'),
    (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
        case 'requestPermission':
          return 2; // whileInUse
        case 'getLastKnownPosition':
        case 'getCurrentPosition':
          return {
            'latitude': _istanbulLat,
            'longitude': _istanbulLng,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 10.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
          };
        default:
          return null;
      }
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async => {
      'appName': 'Vaktinde',
      'packageName': 'com.mmdigital.vaktinde',
      'version': '1.1.0',
      'buildNumber': '14',
    },
  );
  // MainActivity: İstanbul'un manyetik sapması ve beklenen alan şiddeti (µT);
  // Bildirim Kontrolü için Redmi, pil optimizasyonu açık, Rahatsız Etmeyin öncelikli
  messenger.setMockMethodCallHandler(
    const MethodChannel('vaktinde/device'),
    (call) async => switch (call.method) {
      'geomagnetic' => {'declination': 6.3, 'strength': 47.0},
      'deviceInfo' => {
        'manufacturer': 'Xiaomi',
        'brand': 'Redmi',
        'sdkInt': 34,
        'batteryOptimized': true,
        'interruptionFilter': 2,
        'notificationVolume': 5,
        'alarmVolume': 6,
        'ringerMode': 2,
      },
      'openSettings' => true,
      _ => null,
    },
  );
  // Bildirimler açık; alarm izni [_exactAllowed]; kurulu ezanlar
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  messenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async => switch (call.method) {
      'canScheduleExactNotifications' => _exactAllowed,
      'areNotificationsEnabled' => true,
      'pendingNotificationRequests' => _pendingEzans(),
      _ => null,
    },
  );
  // Bilinmeyen eklenti kanalları "başarılı, null" döner (reklam, ses, wakelock,
  // güncelleme...); motor kanalları (flutter/...) gerçek motora gider.
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
}

void _mockCompass({required double heading, required double accuracy}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        const EventChannel('hemanthraj/flutter_compass'),
        MockStreamHandler.inline(
          onListen: (args, sink) => sink.success([heading, heading, accuracy]),
        ),
      );
}

/// Manyetometre (MainActivity): [µT, doğruluk]; [microTesla] yoksa olay yok
void _mockMagnetic({double? microTesla, int accuracy = 3}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        const EventChannel('vaktinde/magnetic'),
        MockStreamHandler.inline(
          onListen: (args, sink) {
            if (microTesla != null) sink.success([microTesla, accuracy]);
          },
        ),
      );
}

/// Kıble sekmesinde "Doğru sonuç için" sayfası açılır, çekilir, kapanır
Future<void> _qiblaTipsShot(
  WidgetTester tester,
  String lang,
  String name,
) async {
  _currentScreen = name;
  final loc = lookupAppLocalizations(Locale(lang));
  final info = find.byTooltip(loc.qiblaTipsTitle);
  await tester.ensureVisible(info);
  await tester.tap(info);
  await _settle(tester, steps: 6);
  await _shot(tester, name);
  _navigator(tester).pop();
  await _settle(tester, steps: 6);
}

Future<void> _setViewport(
  WidgetTester tester, {
  double height = 891, // tipik telefon 411x891 dp
  double width = 411,
}) async {
  tester.view.physicalSize = Size(width * _deviceRatio, height * _deviceRatio);
  tester.view.devicePixelRatio = _deviceRatio;
}

/// Zamanlayıcılı/animasyonlu ekranlar yüzünden pumpAndSettle yerine sabit adımlar
Future<void> _settle(WidgetTester tester, {int steps = 8}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Varlık (json/görsel) yüklemeleri gerçek asenkron ister
  for (var round = 0; round < 2; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  _currentScreen = name;
  await tester.runAsync(() async {
    try {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        try {
          await precacheImage(image.image, element);
        } catch (_) {}
      }
    } catch (_) {
      // Bozuk düzen (yerleşim hatası) ağaç gezintisini de bozabilir
    }
  });
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: _outRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outDir/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
  if (_checkBars) _checkSystemBars(name);
}

// --- Uçtan uca: içerik sistem çubuklarının altına uzanır (Android 15+ ve
// MainActivity.enableEdgeToEdge), boşluğu MediaQuery.padding bırakır.
// Tipik değerler: durum çubuğu 24 dp, 3 tuşlu gezinme çubuğu 48 dp.
const double _statusBarDp = 24;
const double _navBarDp = 48;

/// Açıkken her görüntüde çubukların altında kalan içerik `_errors.txt`'ye yazılır
bool _checkBars = false;

void _setSystemBars(WidgetTester tester) {
  const bars = FakeViewPadding(
    top: _statusBarDp * _deviceRatio,
    bottom: _navBarDp * _deviceRatio,
  );
  tester.view.padding = bars;
  tester.view.viewPadding = bars;
}

/// Çubuk altında kalmaması gerekenler: yazı/simge ve dokunulan ögeler
/// (zemin, görsel, renk serbest)
bool _isBarSensitive(Widget w) =>
    w is RichText ||
    w is EditableText ||
    w is InkResponse ||
    w is Switch ||
    w is Checkbox ||
    w is Radio;

/// Ögenin görünen kısmı (kök kutuya göre, ata kırpmaları uygulanmış); yoksa null
Rect? _visibleRect(RenderBox box, RenderBox root) {
  var rect = MatrixUtils.transformRect(
    box.getTransformTo(root),
    Offset.zero & box.size,
  );
  RenderObject child = box;
  RenderObject? parent = box.parent;
  while (parent != null && child != root) {
    if (parent is RenderOpacity && parent.opacity == 0) return null;
    final clip = parent.describeApproximatePaintClip(child);
    if (clip != null) {
      rect = rect.intersect(
        MatrixUtils.transformRect(parent.getTransformTo(root), clip),
      );
    }
    if (rect.width <= 0 || rect.height <= 0) return null;
    child = parent;
    parent = parent.parent;
  }
  return rect;
}

/// Kaydırınca çubuğun altından çıkabilen liste içeriği serbest (uçtan uca olağan)
bool _canScrollOut(Element element, double overlap, {required bool bottom}) {
  var out = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor is! StatefulElement || ancestor.state is! ScrollableState) {
      return true;
    }
    final position = (ancestor.state as ScrollableState).position;
    if (position.axis != Axis.vertical) return true;
    out = (bottom ? position.extentAfter : position.extentBefore) >= overlap;
    return false;
  });
  return out;
}

String _describeContent(Element element) {
  final widget = element.widget;
  if (widget is RichText) {
    final text = widget.text.toPlainText().trim();
    final runes = text.runes.toList();
    // Material simgeleri Unicode özel kullanım alanlarında
    final rune = runes.length == 1 ? runes.first : 0;
    if ((rune >= 0xE000 && rune <= 0xF8FF) || rune >= 0xF0000) return 'simge';
    return '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}"';
  }
  String? inner;
  void visit(Element e) {
    if (inner != null) return;
    if (e.widget is RichText) {
      inner = _describeContent(e);
    } else {
      e.visitChildren(visit);
    }
  }

  element.visitChildren(visit);
  return '${widget.runtimeType}${inner == null ? '' : ' $inner'}';
}

/// Durum/gezinme çubuğunun altında kalan yazı, simge ve dokunulan ögeler
void _checkSystemBars(String name) {
  final root = _rootKey.currentContext!.findRenderObject()! as RenderBox;
  final size = root.size;
  final bands = <(String, Rect)>[
    ('durum çubuğu', Rect.fromLTRB(0, 0, size.width, _statusBarDp)),
    (
      'gezinme çubuğu',
      Rect.fromLTRB(0, size.height - _navBarDp, size.width, size.height),
    ),
  ];
  for (final element in find.byWidgetPredicate(_isBarSensitive).evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) continue;
    final rect = _visibleRect(box, root);
    if (rect == null) continue;
    for (final (label, band) in bands) {
      final overlap = rect.intersect(band);
      if (overlap.width < 1 || overlap.height < 1) continue;
      if (_canScrollOut(element, overlap.height, bottom: band.top > 0)) {
        continue;
      }
      _errors.add(
        '[$name] $label altında: ${_describeContent(element)} '
        '(${rect.top.toStringAsFixed(0)}-${rect.bottom.toStringAsFixed(0)} dp)',
      );
    }
  }
}

/// Ekranlardaki çerçeve hataları (taşma, yerleşim) düzeneği durdurmaz;
/// ekran adıyla `_errors.txt` dosyasına yazılır (denetim girdisi).
final List<String> _errors = [];
String _currentScreen = '';

Future<void> _run(WidgetTester tester, Future<void> Function() body) async {
  await _setViewport(tester);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString().trim().split('\n').first;
    final widget = details.informationCollector == null
        ? ''
        : details.informationCollector!()
              .map((n) => n.toString())
              .firstWhere((t) => t.contains('file:///'), orElse: () => '')
              .replaceAll(RegExp(r'.*/lib/'), 'lib/');
    _errors.add('[$_currentScreen] $text ${widget.trim()}');
  };
  // Testlerde gölgeler kalın siyah çerçeve olarak çizilir; gerçek gölge görünsün
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
    FlutterError.onError = original;
    tester.view.reset();
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String lang,
  required HomeViewModel homeVm,
  int themeMode = 1,
  bool languageSelected = true,
  String? background,
}) async {
  SharedPreferences.setMockInitialValues(
    _prefs(
      lang: lang,
      languageSelected: languageSelected,
      themeMode: themeMode,
      background: background,
    ),
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: _rootKey,
      child: MultiProvider(
        providers: [
          // lazy: false → okunmasa da (dil seçimi ekranı) dispose edilir, gece
          // yarısı zamanlayıcısı açık kalmaz
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) => homeVm,
            lazy: false,
          ),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ZikirViewModel()),
        ],
        child: const MyApp(),
      ),
    ),
  );
  await _settle(tester);
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

Future<void> _openRoute(
  WidgetTester tester,
  String name,
  Widget page, {
  double? tallHeight,
}) async {
  _currentScreen = name;
  _navigator(tester).push(MaterialPageRoute<void>(builder: (_) => page));
  await _settle(tester, steps: 10);
  await _shot(tester, name);
  if (tallHeight != null) {
    await _setViewport(tester, height: tallHeight);
    await _settle(tester, steps: 4);
    await _shot(tester, '${name}_full');
    await _setViewport(tester);
    await _settle(tester, steps: 2);
  }
  _navigator(tester).pop();
  await _settle(tester, steps: 6);
}

Future<void> _tapTab(WidgetTester tester, int index) async {
  _currentScreen = 'tab $index';
  await tester.tap(find.byType(NavigationDestination).at(index));
  await _settle(tester, steps: 6);
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final skip = _outDir == null || _outDir!.isEmpty;

  setUpAll(() async {
    if (skip) return;
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
    // Uygulama boyu önbelleklenen Future ilk testin sahte zaman bölgesinde
    // oluşursa sonraki testlerde hiç tamamlanmaz; gerçek bölgede önceden yüklenir
    await loadRamadanCalendar();
    await DiniGunlerService.loadResmiGunler();
    for (final lang in ['tr', 'ar']) {
      await rootBundle.loadString('assets/data/greetings_$lang.json');
    }
  });

  setUp(() {
    _mockPlatform();
    _mockCompass(heading: 120, accuracy: 5);
    _mockMagnetic();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
  });

  tearDownAll(() {
    if (skip) return;
    File(
      '$_outDir/_errors.txt',
    ).writeAsStringSync('${_errors.toSet().join('\n')}\n');
  });

  testWidgets('tr açık tema: tüm ekranlar', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      // Dil seçimi
      _currentScreen = 'tr_01_onboarding_language';
      await _pumpApp(
        tester,
        lang: 'tr',
        homeVm: _homeVm('tr'),
        languageSelected: false,
      );
      await _shot(tester, 'tr_01_onboarding_language');
      await _finish(tester);

      _currentScreen = 'tr_10_home';
      await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'));
      await _shot(tester, 'tr_10_home');
      await _setViewport(tester, height: 1500);
      await _settle(tester, steps: 4);
      await _shot(tester, 'tr_11_home_full');
      await _setViewport(tester);
      await _settle(tester, steps: 2);

      // Alarmlar sekmesi + açılmış Öğle kartı
      await tester.tap(find.text('Alarmlar'));
      await _settle(tester);
      await _shot(tester, 'tr_12_home_alarms');
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.text(loc.ogle).last);
      await _settle(tester);
      await _shot(tester, 'tr_13_home_alarms_expanded');
      await tester.tap(find.text('Vakitler'));
      await _settle(tester);

      await _tapTab(tester, 1);
      await _shot(tester, 'tr_20_qibla');
      await _qiblaTipsShot(tester, 'tr', 'tr_22_qibla_tips');
      await _tapTab(tester, 2);
      await _shot(tester, 'tr_30_zikirmatik');
      await _tapTab(tester, 3);
      await _shot(tester, 'tr_40_tools');

      await _openRoute(
        tester,
        'tr_50_settings',
        const SettingsView(),
        tallHeight: 1250,
      );
      await _openRoute(tester, 'tr_41_imsakiye', const ImsakiyeView());
      await _openRoute(
        tester,
        'tr_42_zakat',
        const ZakatView(),
        tallHeight: 2400,
      );
      await _openRoute(tester, 'tr_43_esmaul_husna', const EsmaulHusnaView());
      await _openRoute(
        tester,
        'tr_44_friday_messages',
        const FridayMessagesView(),
      );
      await _openRoute(
        tester,
        'tr_45_religious_days',
        const ReligiousDaysView(),
      );
      await _openRoute(
        tester,
        'tr_46_missed_prayers',
        const MissedPrayersView(),
        tallHeight: 1250,
      );
      await _openRoute(
        tester,
        'tr_47_prayer_tracker',
        const PrayerTrackerView(),
        tallHeight: 1400,
      );
      await _openRoute(tester, 'tr_51_time_adjust', const TimeAdjustView());
      await _openRoute(
        tester,
        'tr_53_notification_health',
        const NotificationHealthView(),
        tallHeight: 2300,
      );
      await _openRoute(
        tester,
        'tr_32_dhikr_stats',
        const DhikrStatsView(),
        tallHeight: 1300,
      );
      await _openRoute(
        tester,
        'tr_33_zikir_settings',
        const ZikirSettingsView(),
      );
      await _finish(tester);
    });
  });

  // Ayrı test: uzun Arapça zikirler ListTile yerleşimini bozabiliyor
  testWidgets('tr: zikir listesi', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'));
      await _openRoute(tester, 'tr_31_dhikr_list', const DhikrListView());
      await _finish(tester);
    });
  });

  // Dini günler: "Tebrik gönder" sayfası + paylaşılan resim kartı (1080x1350)
  for (final lang in ['tr', 'ar']) {
    testWidgets(
      '$lang: tebrik mesajları ve paylaşım kartı',
      skip: skip,
      variant: _android,
      (tester) async {
        await _run(tester, () async {
          await _pumpApp(tester, lang: lang, homeVm: _homeVm(lang));
          final loc = lookupAppLocalizations(Locale(lang));
          _currentScreen = '${lang}_45b_greetings';
          _navigator(tester).push(
            MaterialPageRoute<void>(builder: (_) => const ReligiousDaysView()),
          );
          await _settle(tester, steps: 10);
          // Yılın kalan günü yoksa (Aralık sonu) sıradaki gün sonraki yılda
          if (find.text(loc.sendGreeting).evaluate().isEmpty) {
            await tester.tap(find.byTooltip(loc.nextYear));
            await _settle(tester);
          }
          final button = find.text(loc.sendGreeting).first;
          await tester.ensureVisible(button);
          await tester.tap(button);
          await _settle(tester, steps: 10);
          await _shot(tester, '${lang}_45b_greetings');
          _navigator(tester).pop();
          await _settle(tester, steps: 6);
          _navigator(tester).pop();
          await _settle(tester, steps: 6);

          final greetings =
              jsonDecode(
                    File('assets/data/greetings_$lang.json').readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          await _openRoute(
            tester,
            '${lang}_45c_share_card',
            Scaffold(
              body: Center(
                child: ShareCard(
                  title: loc.regaipKandili,
                  message: (greetings['regaipKandili'] as List).first as String,
                  footer: loc.shareCardFooter,
                ),
              ),
            ),
          );
          await _finish(tester);
        });
      },
    );
  }

  testWidgets(
    'tr: dolu ana ekran (kerahat, takip) + büyük yazı',
    skip: skip,
    variant: _android,
    (tester) async {
      await _run(tester, () async {
        final busy = _busyTimes();
        if (busy != null) {
          _currentScreen = 'tr_14_home_busy_full';
          await _pumpApp(
            tester,
            lang: 'tr',
            homeVm: _homeVm('tr', times: busy),
          );
          await _setViewport(tester, height: 1500);
          await _settle(tester, steps: 4);
          await _shot(tester, 'tr_14_home_busy_full');
          await _setViewport(tester);
          await _finish(tester);
        }

        // Erişilebilirlik: sistem yazı boyutu %130
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        try {
          _currentScreen = 'tr_15_home_text130';
          await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'));
          await _shot(tester, 'tr_15_home_text130');
          await _tapTab(tester, 3);
          await _shot(tester, 'tr_48_tools_text130');
          await _openRoute(
            tester,
            'tr_52_settings_text130',
            const SettingsView(),
          );
          await _openRoute(
            tester,
            'tr_54_notification_health_text130',
            const NotificationHealthView(),
            tallHeight: 2800,
          );
          await _finish(tester);
        } finally {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        }
      });
    },
  );

  testWidgets('tr: kıble kalibrasyon uyarısı', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      _mockCompass(heading: 150, accuracy: -1);
      await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'));
      await _tapTab(tester, 1);
      // Uyarı 2 sn süren zayıf doğrulukta açılır
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester, steps: 2);
      await _shot(tester, 'tr_21_qibla_calibration');
      await _finish(tester);
    });
  });

  testWidgets('tr: kıble manyetik parazit', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      // Beklenen 47 µT, ölçülen 95 µT (mıknatıslı kılıf): 1,5 sn sonra uyarı
      _mockMagnetic(microTesla: 95);
      await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'));
      await _tapTab(tester, 1);
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester, steps: 2);
      await _shot(tester, 'tr_23_qibla_interference');
      await _finish(tester);
    });
  });

  testWidgets('tr koyu tema', skip: skip, variant: _android, (tester) async {
    await _run(tester, () async {
      _currentScreen = 'tr_dark_10_home';
      await _pumpApp(tester, lang: 'tr', homeVm: _homeVm('tr'), themeMode: 2);
      await _shot(tester, 'tr_dark_10_home');
      await _setViewport(tester, height: 1500);
      await _settle(tester, steps: 4);
      await _shot(tester, 'tr_dark_11_home_full');
      await _setViewport(tester);
      await _settle(tester, steps: 2);
      await tester.tap(find.text('Alarmlar'));
      await _settle(tester);
      await _shot(tester, 'tr_dark_12_home_alarms');
      await tester.tap(find.text('Vakitler'));
      await _settle(tester);
      await _tapTab(tester, 1);
      await _shot(tester, 'tr_dark_20_qibla');
      await _qiblaTipsShot(tester, 'tr', 'tr_dark_22_qibla_tips');
      await _tapTab(tester, 2);
      await _shot(tester, 'tr_dark_30_zikirmatik');
      await _tapTab(tester, 3);
      await _shot(tester, 'tr_dark_40_tools');
      await _openRoute(tester, 'tr_dark_50_settings', const SettingsView());
      await _openRoute(
        tester,
        'tr_dark_53_notification_health',
        const NotificationHealthView(),
        tallHeight: 2300,
      );
      await _openRoute(
        tester,
        'tr_dark_47_prayer_tracker',
        const PrayerTrackerView(),
      );
      await _openRoute(tester, 'tr_dark_41_imsakiye', const ImsakiyeView());
      await _openRoute(tester, 'tr_dark_42_zakat', const ZakatView());
      await _openRoute(
        tester,
        'tr_dark_46_missed_prayers',
        const MissedPrayersView(),
      );
      await _finish(tester);
    });
  });

  testWidgets('tr arka plan görseli', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      _currentScreen = 'tr_bg_10_home';
      await _pumpApp(
        tester,
        lang: 'tr',
        homeVm: _homeVm('tr'),
        background: 'bg_mosque2.webp',
      );
      await _shot(tester, 'tr_bg_10_home');
      await _setViewport(tester, height: 1500);
      await _settle(tester, steps: 4);
      await _shot(tester, 'tr_bg_11_home_full');
      await _setViewport(tester);
      await _settle(tester, steps: 2);
      await _tapTab(tester, 1);
      await _shot(tester, 'tr_bg_20_qibla');
      await _tapTab(tester, 2);
      await _shot(tester, 'tr_bg_30_zikirmatik');
      await _tapTab(tester, 3);
      await _shot(tester, 'tr_bg_40_tools');
      await _openRoute(tester, 'tr_bg_50_settings', const SettingsView());
      await _openRoute(
        tester,
        'tr_bg_53_notification_health',
        const NotificationHealthView(),
        tallHeight: 2300,
      );
      await _openRoute(tester, 'tr_bg_41_imsakiye', const ImsakiyeView());
      await _finish(tester);
    });
  });

  // Uçtan uca: durum çubuğu 24 dp + 3 tuşlu gezinme 48 dp. Çubuk altında kalan
  // yazı/simge/dokunulan öge `_errors.txt`'ye yazılır (zemin serbest)
  testWidgets('tr uçtan uca: sistem çubukları', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      _setSystemBars(tester);
      _checkBars = true;
      try {
        final loc = lookupAppLocalizations(const Locale('tr'));
        Future<void> closeSheet() async {
          _navigator(tester).pop();
          await _settle(tester, steps: 6);
        }

        _currentScreen = 'tr_edge_01_onboarding_language';
        await _pumpApp(
          tester,
          lang: 'tr',
          homeVm: _homeVm('tr'),
          languageSelected: false,
        );
        await _shot(tester, 'tr_edge_01_onboarding_language');
        await _finish(tester);

        // Uzun meal: okuma sayfası kayar, sondaki butonlar denetlenir
        final vm = _homeVm('tr')
          ..dailyAyah = AyahModel(
            number: 293,
            surahName: 'Bakara',
            numberInSurah: 286,
            arabicText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
            translatedText: List.filled(
              14,
              'Allah hiç kimseye gücünün yetmeyeceği bir yük yüklemez.',
            ).join(' '),
          );
        _currentScreen = 'tr_edge_10_home';
        await _pumpApp(tester, lang: 'tr', homeVm: vm);
        await _shot(tester, 'tr_edge_10_home');

        await tester.tap(find.byTooltip(loc.changeLocation));
        await _settle(tester, steps: 6);
        await _shot(tester, 'tr_edge_15_location_sheet');
        await closeSheet();

        await tester.ensureVisible(find.text(loc.dailyAyahTitle));
        await _settle(tester, steps: 2);
        await tester.tap(find.text(loc.dailyAyahTitle));
        await _settle(tester, steps: 6);
        await tester.scrollUntilVisible(
          find.text(loc.shareAsImage),
          300,
          scrollable: find
              .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await _settle(tester, steps: 4);
        await _shot(tester, 'tr_edge_16_reading_sheet_end');
        await closeSheet();

        await tester.tap(find.text('Alarmlar'));
        await _settle(tester);
        await _shot(tester, 'tr_edge_12_home_alarms');
        await tester.tap(find.text('Vakitler'));
        await _settle(tester);

        await _tapTab(tester, 1);
        await _shot(tester, 'tr_edge_20_qibla');
        await _qiblaTipsShot(tester, 'tr', 'tr_edge_22_qibla_tips');
        await _tapTab(tester, 2);
        await _shot(tester, 'tr_edge_30_zikirmatik');
        await _tapTab(tester, 3);
        await _shot(tester, 'tr_edge_40_tools');

        // Ayarlar + dil ve görünüm sayfaları
        _currentScreen = 'tr_edge_50_settings';
        _navigator(
          tester,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
        await _settle(tester, steps: 10);
        await _shot(tester, 'tr_edge_50_settings');
        for (final (title, name) in [
          (loc.changeLanguage, 'tr_edge_53_language_sheet'),
          (loc.appearanceSettings, 'tr_edge_54_appearance_sheet'),
        ]) {
          await tester.tap(find.text(title).first);
          await _settle(tester, steps: 6);
          await _shot(tester, name);
          await closeSheet();
        }
        await closeSheet();

        await _openRoute(tester, 'tr_edge_41_imsakiye', const ImsakiyeView());
        await _openRoute(
          tester,
          'tr_edge_47_prayer_tracker',
          const PrayerTrackerView(),
        );
        await _openRoute(tester, 'tr_edge_42_zakat', const ZakatView());
        await _openRoute(
          tester,
          'tr_edge_51_time_adjust',
          const TimeAdjustView(),
        );
        await _openRoute(
          tester,
          'tr_edge_31_dhikr_list',
          const DhikrListView(),
        );

        // Kaza: sayıya dokununca açılan elle giriş penceresi
        _currentScreen = 'tr_edge_46_missed_prayers';
        _navigator(tester).push(
          MaterialPageRoute<void>(builder: (_) => const MissedPrayersView()),
        );
        await _settle(tester, steps: 10);
        await _shot(tester, 'tr_edge_46_missed_prayers');
        await tester.tap(find.text('12').first);
        await _settle(tester, steps: 6);
        await _shot(tester, 'tr_edge_49_missed_dialog');
        await closeSheet();
        await closeSheet();
        await _finish(tester);
      } finally {
        _checkBars = false;
      }
    });
  });

  for (final lang in ['de', 'ar', 'fr']) {
    testWidgets(
      '$lang: ana ekran, araçlar, ayarlar',
      skip: skip,
      variant: _android,
      (tester) async {
        await _run(tester, () async {
          _currentScreen = '${lang}_10_home';
          await _pumpApp(tester, lang: lang, homeVm: _homeVm(lang));
          await _shot(tester, '${lang}_10_home');
          await _setViewport(tester, height: 1500);
          await _settle(tester, steps: 4);
          await _shot(tester, '${lang}_11_home_full');
          await _setViewport(tester);
          await _settle(tester, steps: 2);
          await _tapTab(tester, 1);
          await _shot(tester, '${lang}_20_qibla');
          await _qiblaTipsShot(tester, lang, '${lang}_22_qibla_tips');
          await _tapTab(tester, 2);
          await _shot(tester, '${lang}_30_zikirmatik');
          await _tapTab(tester, 3);
          await _shot(tester, '${lang}_40_tools');
          await _openRoute(
            tester,
            '${lang}_50_settings',
            const SettingsView(),
            tallHeight: 1250,
          );
          await _openRoute(
            tester,
            '${lang}_53_notification_health',
            const NotificationHealthView(),
            tallHeight: 2400,
          );
          await _openRoute(
            tester,
            '${lang}_47_prayer_tracker',
            const PrayerTrackerView(),
          );
          await _openRoute(tester, '${lang}_41_imsakiye', const ImsakiyeView());
          await _openRoute(tester, '${lang}_42_zakat', const ZakatView());
          await _openRoute(
            tester,
            '${lang}_33_zikir_settings',
            const ZikirSettingsView(),
          );
          await _finish(tester);
        });
      },
    );
  }

  // Küçük telefon (320dp) + %130 yazı: ana ekran, alt menü etiketleri, alarmlar
  testWidgets('320dp %130: ana ekran', skip: skip, variant: _android, (
    tester,
  ) async {
    await _run(tester, () async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      try {
        for (final lang in ['tr', 'de', 'fr', 'ar']) {
          _currentScreen = '${lang}_16_home_320_text130';
          await _setViewport(tester, width: 320, height: 640);
          await _pumpApp(tester, lang: lang, homeVm: _homeVm(lang));
          await _shot(tester, '${lang}_16_home_320_text130');
          await _tapTab(tester, 1);
          await _shot(tester, '${lang}_26_qibla_320_text130');
          // Kaydırınca görünen alt kısım (uyarı + doğruluk notu)
          await _setViewport(tester, width: 320, height: 1100);
          await _settle(tester, steps: 4);
          await _shot(tester, '${lang}_27_qibla_320_text130_full');
          await _finish(tester);
        }
      } finally {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }
    });
  });

  // 320dp + %130: alarm izni uyarısı (iki buton) ve Bildirim Kontrolü
  testWidgets(
    '320dp %130: alarm uyarısı, Bildirim Kontrolü',
    skip: skip,
    variant: _android,
    (tester) async {
      await _run(tester, () async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        _exactAllowed = false;
        try {
          for (final lang in ['tr', 'de', 'fr', 'ar']) {
            final loc = lookupAppLocalizations(Locale(lang));
            _currentScreen = '${lang}_17_alarms_banner_320_text130';
            await _setViewport(tester, width: 320, height: 640);
            final vm = _homeVm(lang);
            await _pumpApp(tester, lang: lang, homeVm: vm);
            await vm.alarmHealth.refresh();
            await tester.tap(find.text(loc.tabAlarms));
            await _settle(tester);
            await _shot(tester, '${lang}_17_alarms_banner_320_text130');

            final name = '${lang}_55_notification_health_320_text130';
            _currentScreen = name;
            _navigator(tester).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationHealthView(),
              ),
            );
            await _settle(tester, steps: 10);
            await _shot(tester, name);
            await _setViewport(tester, width: 320, height: 3600);
            await _settle(tester, steps: 4);
            await _shot(tester, '${name}_full');
            await _finish(tester);
          }
        } finally {
          _exactAllowed = true;
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        }
      });
    },
  );
}
