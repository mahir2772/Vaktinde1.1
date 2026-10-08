// Kıble pusulası doğruluğu: manyetik sapma düzeltmesi (eklenti manyetik kuzeyi
// verir, kıble açısı coğrafi kuzeye göre), titreşim süzgeci, manyetik parazit
// ve kalibrasyon kararları (saf); görünümde sapmanın uygulanması (konum başına
// tek sorgu), parazit uyarısı (1,5 sn, histerezis), manyetometre doğruluğu,
// doğruluk notu ve "Doğru sonuç için" sayfası (RTL, %130, arka plan resmi).
import 'dart:async';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/qibla/qibla_math.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _istanbulLat = 41.0082;
const double _istanbulLng = 28.9784;

const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');
const _device = MethodChannel('vaktinde/device');
const _magneticChannel = EventChannel('vaktinde/magnetic');

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// MainActivity 'geomagnetic' yanıtı (null: kanal hatası) ve gelen istekler
Map<String, Object>? _geomagneticReply;
final List<Object?> _geomagneticCalls = [];

/// Her dinlemeyi ayrı abonelik sayan sahte sensör akışı
class _FakeSensor<T> {
  final List<MultiStreamController<T>> _listeners = [];
  int listens = 0;

  int get active => _listeners.length;

  late final Stream<T> stream = Stream<T>.multi((c) {
    listens++;
    _listeners.add(c);
    c.onCancel = () {
      _listeners.remove(c);
    };
  });

  void add(T event) {
    for (final c in List.of(_listeners)) {
      c.addSync(event);
    }
  }
}

extension on _FakeSensor<CompassEvent> {
  /// Android eklentisindeki gibi [manyetik yön, kamera yönü, doğruluk]
  void heading(double degrees, {double accuracy = 15}) =>
      add(CompassEvent.fromList([degrees, degrees, accuracy]));
}

extension on _FakeSensor<MagneticReading> {
  void field(double microTesla, {int? accuracy = 3}) =>
      add((magnitude: microTesla, accuracy: accuracy));
}

/// Ekrandaki gibi: derece sağdan sola metinde yalıtılmış
String _iso(String text, String value) =>
    text.replaceFirst('$value°', '\u2066$value°\u2069');

AppLocalizations get _loc => lookupAppLocalizations(const Locale('tr'));

/// Motorun gönderdiği gibi (ara durumlar dahil)
Future<void> _lifecycle(AppLifecycleState state) =>
    _messenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

/// Alt menüdeki gibi IndexedStack: 0 = Kıble, 1 = başka sekme.
/// [magnetometer] yoksa gerçek kanal ('vaktinde/magnetic') kullanılır.
Future<ValueNotifier<int>> _pumpQibla(
  WidgetTester tester, {
  required _FakeSensor<CompassEvent> compass,
  _FakeSensor<MagneticReading>? magnetometer,
  String lang = 'tr',
  ThemeData? theme,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'saved_lat': _istanbulLat,
    'saved_lng': _istanbulLng,
    'qibla_calibration_dialog_seen': true,
    ...prefs,
  });
  final tab = ValueNotifier<int>(0);
  addTearDown(tab.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      theme: theme ?? AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: tab,
          builder: (context, index, _) => IndexedStack(
            index: index,
            children: [
              magnetometer == null
                  ? QiblaView(compassEvents: () => compass.stream)
                  : QiblaView(
                      compassEvents: () => compass.stream,
                      magneticEvents: () => magnetometer.stream,
                    ),
              const Center(child: Text('diğer sekme')),
            ],
          ),
        ),
      ),
    ),
  );
  // Konum → kıble açısı → pusula aboneliği + manyetik model sorgusu
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return tab;
}

/// ~5 olay/sn manyetometre akışı
Future<void> _field(
  WidgetTester tester,
  _FakeSensor<MagneticReading> magnetometer,
  double microTesla,
  Duration duration, {
  int? accuracy = 3,
}) async {
  const step = Duration(milliseconds: 200);
  for (var t = Duration.zero; t < duration; t += step) {
    magnetometer.field(microTesla, accuracy: accuracy);
    await tester.pump(step);
  }
}

Future<void> _openTips(WidgetTester tester, AppLocalizations loc) async {
  final info = find.byTooltip(loc.qiblaTipsTitle);
  await tester.ensureVisible(info);
  await tester.pump();
  await tester.tap(info);
  await tester.pumpAndSettle();
}

void main() {
  group('Manyetik sapma (coğrafi kuzey)', () {
    test('yön sapma kadar döner; bilinmiyorsa düzeltme yok', () {
      expect(trueHeading(0, 6), closeTo(6, 1e-9));
      expect(trueHeading(358, 6), closeTo(4, 1e-9));
      expect(trueHeading(2, -6), closeTo(356, 1e-9));
      expect(trueHeading(-170, 5), closeTo(195, 1e-9)); // eklenti -180..180
      expect(trueHeading(120, null), 120);
    });

    test('İstanbul: düzeltmesiz pusula kıbleyi sapma kadar kaçırır', () {
      final bearing = qiblaBearing(_istanbulLat, _istanbulLng); // coğrafi
      const declination = 6.0;
      // Telefon tam kıbleye bakarken manyetik pusula ~6° eksik gösterir
      final magnetic = bearing - declination;
      expect(qiblaTurnFor(magnetic, bearing), QiblaTurn.slightRight);
      expect(
        qiblaTurnFor(trueHeading(magnetic, declination), bearing),
        QiblaTurn.aligned,
      );
    });

    test('kanal yanıtı okunur; eksik/bozuk yanıtta düzeltme yapılmaz', () {
      final info = Geomagnetic.tryParse({'declination': 6.2, 'strength': 45.1});
      expect(info!.declination, 6.2);
      expect(info.strength, 45.1);
      final ints = Geomagnetic.tryParse({'declination': -3, 'strength': 50});
      expect(ints!.declination, -3.0);
      expect(ints.strength, 50.0);
      // Şiddet okunamazsa sapma yine uygulanır, parazit denetimi yapılmaz
      for (final strength in <Object?>[null, 0, -5.0, double.nan, 'x']) {
        final partial = Geomagnetic.tryParse({
          'declination': 4.0,
          'strength': strength,
        });
        expect(partial!.declination, 4.0);
        expect(partial.strength, isNull, reason: '$strength');
      }
      for (final bad in <Object?>[
        null,
        'x',
        33,
        <String, Object>{},
        {'strength': 45.0},
        {'declination': 'a'},
        {'declination': double.nan},
        {'declination': double.infinity},
        {'declination': 200.0},
      ]) {
        expect(Geomagnetic.tryParse(bad), isNull, reason: '$bad');
      }
    });

    test('önbellek hücresi 0,1°: yakın konum aynı, uzak konum farklı', () {
      expect(
        geomagneticCell(_istanbulLat, _istanbulLng),
        geomagneticCell(41.04, 28.96),
      );
      expect(
        geomagneticCell(_istanbulLat, _istanbulLng),
        isNot(geomagneticCell(41.06, _istanbulLng)),
      );
      expect(geomagneticCell(-6.2088, 106.8456), '-62:1068');
    });

    test('sapma metni: tam derece, işaretli', () {
      expect(formatDeclination(6.2), '+6');
      expect(formatDeclination(5.5), '+6');
      expect(formatDeclination(-5.6), '-6');
      expect(formatDeclination(0.4), '0');
      expect(formatDeclination(-0.4), '0');
    });
  });

  group('Titreşim süzgeci', () {
    /// [start]'tan başlayıp [readings]'i süzer; ara yönler [trace]'e yazılır
    double run(double start, List<double> readings, [List<double>? trace]) {
      var state = smoothHeading(null, start);
      for (final reading in readings) {
        state = smoothHeading(state, reading);
        trace?.add(filteredHeading(state));
      }
      return filteredHeading(state);
    }

    test('ilk okuma olduğu gibi', () {
      expect(filteredHeading(smoothHeading(null, 123.4)), closeTo(123.4, 1e-9));
      expect(filteredHeading(smoothHeading(null, -10)), closeTo(350, 1e-9));
    });

    test('30 Hz: 30°lik dönüş ~0,3 sn\'de 3°, ~0,5 sn\'de 0,5° içinde', () {
      expect(
        signedDelta(run(100, List.filled(9, 130)), 130).abs(),
        lessThan(3),
      );
      expect(
        signedDelta(run(100, List.filled(15, 130)), 130).abs(),
        lessThan(0.5),
      );
      // Tepkisiz de değil: ilk okumada dönüşün en az beşte biri
      expect(signedDelta(100, run(100, [130])), greaterThan(6));
    });

    test('359° ↔ 1°: kısa yoldan, uzun yola (180°) hiç savrulmaz', () {
      final up = <double>[];
      expect(run(359, List.filled(30, 1), up), closeTo(1, 0.01));
      for (final heading in up) {
        expect(signedDelta(359, heading), inInclusiveRange(0, 2.0001));
      }
      final down = <double>[];
      expect(run(1, List.filled(30, 359), down), closeTo(359, 0.01));
      for (final heading in down) {
        expect(signedDelta(1, heading), inInclusiveRange(-2.0001, 0));
      }
      // 350° → 10°: kuzeyden geçer, adım adım ilerler
      final wide = <double>[];
      run(350, List.filled(30, 10), wide);
      var previous = 0.0;
      for (final heading in wide) {
        final progress = signedDelta(350, heading);
        expect(progress, inInclusiveRange(previous - 1e-9, 20.0001));
        previous = progress;
      }
      expect(previous, closeTo(20, 0.01));
    });

    test('titreşimi bastırır: ±2° oynama ±0,3° altına iner', () {
      final trace = <double>[];
      run(100, [for (var i = 0; i < 60; i++) i.isEven ? 102 : 98], trace);
      for (final heading in trace) {
        expect(signedDelta(100, heading).abs(), lessThanOrEqualTo(0.5 + 1e-9));
      }
      for (final heading in trace.skip(10)) {
        expect(signedDelta(100, heading).abs(), lessThan(0.3));
      }
    });

    test('ters yöne (180°) takılmadan döner', () {
      expect(run(0, List.filled(30, 180)), closeTo(180, 0.5));
    });

    test('ortalama sıfırlanırsa (yön tanımsız) yeni okumadan başlar', () {
      final state = smoothHeading((sin: 0.0, cos: -1 / 3), 0);
      expect(filteredHeading(state), closeTo(0, 1e-9));
      expect(state.cos, closeTo(1, 1e-9));
    });
  });

  group('Manyetik parazit', () {
    test('sapma: |ölçülen/beklenen − 1|', () {
      expect(fieldDeviation(45, 45), 0);
      expect(fieldDeviation(56.25, 45), closeTo(0.25, 1e-12));
      expect(fieldDeviation(90, 45), closeTo(1, 1e-12));
      expect(fieldDeviation(30, 45), closeTo(1 / 3, 1e-12));
      // Beklenen bilinmiyor / geçersiz ölçüm: denetim yok
      expect(fieldDeviation(45, null), isNull);
      expect(fieldDeviation(45, 0), isNull);
      expect(fieldDeviation(double.nan, 45), isNull);
      expect(fieldDeviation(-1, 45), isNull);
    });

    test('histerezis: %25 aşılınca açılır, %15 altına inmeden kapanmaz', () {
      var warning = false;
      for (final (deviation, expected) in [
        (0.10, false),
        (0.25, false), // eşiğin kendisi açmaz
        (0.30, true),
        (0.20, true), // açıkken %15'e kadar sürer
        (0.15, true),
        (0.14, false),
        (0.20, false), // kapalıyken %25 aşılmadan açılmaz
        (0.25, false),
        (0.26, true),
      ]) {
        warning = magneticInterference(deviation, warning: warning);
        expect(warning, expected, reason: '$deviation');
      }
    });

    test('olay okunur: [µT, doğruluk]', () {
      expect(parseMagneticReading([48.5, 3]), (magnitude: 48.5, accuracy: 3));
      expect(parseMagneticReading([48, 2]), (magnitude: 48.0, accuracy: 2));
      expect(parseMagneticReading([50.0, 1.0]), (magnitude: 50.0, accuracy: 1));
      for (final unknown in <Object?>[-1, 7, null, 'x']) {
        expect(parseMagneticReading([50.0, unknown]), (
          magnitude: 50.0,
          accuracy: null,
        ), reason: '$unknown');
      }
      for (final bad in <Object?>[
        null,
        'x',
        <Object?>[],
        [50.0],
        ['a', 3],
        [double.nan, 3],
        [-1.0, 3],
      ]) {
        expect(parseMagneticReading(bad), isNull, reason: '$bad');
      }
    });
  });

  test('kalibrasyon kararı: manyetometre 0/1 zayıf, pusula kuralı aynen', () {
    // (pusula ±°, manyetometre durumu, zayıf mı)
    for (final (compass, magnetometer, poor) in [
      (15.0, null, false), // manyetometre bilinmiyor: eskisi gibi
      (15.0, 3, false), // yüksek
      (15.0, 2, false), // orta yeterli
      (15.0, 1, true), // düşük
      (15.0, 0, true), // güvenilmez
      (30.0, 3, true), // pusula orta: eskisi gibi zayıf
      (null, 3, true), // pusula bilinmiyor: eskisi gibi zayıf
    ]) {
      expect(
        calibrationPoor(
          compassAccuracy: compass,
          magnetometerAccuracy: magnetometer,
        ),
        poor,
        reason: '$compass / $magnetometer',
      );
      expect(
        magnetometerAccuracyPoor(magnetometer),
        magnetometer == 0 || magnetometer == 1,
      );
    }
  });

  group('Görünüm', () {
    setUp(() {
      _geomagneticReply = {'declination': 6.2, 'strength': 45.0};
      _geomagneticCalls.clear();
      _messenger.setMockMethodCallHandler(_geolocator, (call) async {
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return true;
          case 'checkPermission':
            return 2; // whileInUse
          case 'getLastKnownPosition':
          case 'getCurrentPosition':
            return {
              'latitude': _istanbulLat,
              'longitude': _istanbulLng,
              'timestamp': DateTime(2026).millisecondsSinceEpoch,
              'accuracy': 10.0,
              'altitude': 0.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
            };
          default:
            return null;
        }
      });
      _messenger.setMockMethodCallHandler(_device, (call) async {
        if (call.method != 'geomagnetic') return null;
        _geomagneticCalls.add(call.arguments);
        final reply = _geomagneticReply;
        if (reply == null) throw PlatformException(code: 'error');
        return reply;
      });
      // Kıble hizasında titreşim
      _messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
    });

    tearDown(() {
      _messenger.setMockMethodCallHandler(_geolocator, null);
      _messenger.setMockMethodCallHandler(_device, null);
      _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('sapma yöne uygulanır; konum başına bir kez sorulur', (
      tester,
    ) async {
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      final tab = await _pumpQibla(
        tester,
        compass: compass,
        magnetometer: magnetometer,
      );
      expect(_geomagneticCalls, [
        {'lat': _istanbulLat, 'lng': _istanbulLng},
      ]);

      // Manyetik 146° + 6,2° = coğrafi 152°: kıble (151,6°) bulundu
      compass.heading(146);
      await tester.pump();
      expect(find.text(_iso(_loc.phoneHeading('152'), '152')), findsOneWidget);
      expect(find.text(_loc.qiblaFound), findsOneWidget);

      // Arka plan/ön plan ve sekme geçişi: aynı konum yeniden sorulmaz
      await _lifecycle(AppLifecycleState.paused);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      tab.value = 1;
      await tester.pump();
      tab.value = 0;
      await tester.pump();
      expect(compass.listens, 3);
      expect(_geomagneticCalls, hasLength(1));

      // Dönüşte süzgeç ilk okumayla başlar (eski yönden kaymaz)
      compass.heading(300);
      await tester.pump();
      expect(find.text(_iso(_loc.phoneHeading('306'), '306')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sapma alınamazsa düzeltmesiz çalışır, parazit denetlenmez; '
        'sonraki açılışta yeniden sorulur', (tester) async {
      _geomagneticReply = null;
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      await _pumpQibla(tester, compass: compass, magnetometer: magnetometer);
      compass.heading(146);
      await tester.pump();
      expect(find.text(_iso(_loc.phoneHeading('146'), '146')), findsOneWidget);
      expect(find.text(_loc.qiblaTurnSlightRight), findsOneWidget);
      // Beklenen şiddet bilinmiyor: güçlü alan uyarı açmaz
      await _field(tester, magnetometer, 120, const Duration(seconds: 3));
      expect(find.text(_loc.qiblaInterferenceWarning), findsNothing);
      expect(_geomagneticCalls, hasLength(1));

      _geomagneticReply = {'declination': 6.2, 'strength': 45.0};
      await _lifecycle(AppLifecycleState.paused);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(_geomagneticCalls, hasLength(2));
      compass.heading(146);
      await tester.pump();
      expect(find.text(_iso(_loc.phoneHeading('152'), '152')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('manyetik parazit: 1,5 sn sürerse uyarı; normale dönünce '
        'histerezisle kapanır', (tester) async {
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      await _pumpQibla(tester, compass: compass, magnetometer: magnetometer);
      final warning = find.text(_loc.qiblaInterferenceWarning);
      final tip = find.text('${_loc.qiblaCalibration} ${_loc.keepAwayMetal}');
      compass.heading(146);
      await tester.pump();

      await _field(tester, magnetometer, 45, const Duration(seconds: 1));
      expect(warning, findsNothing);
      expect(tip, findsOneWidget);

      // Kısa sapma (metal yanından geçerken): uyarı yok
      await _field(tester, magnetometer, 60, const Duration(seconds: 1));
      await _field(tester, magnetometer, 45, const Duration(seconds: 2));
      expect(warning, findsNothing);

      // %33 sapma 1,5 sn sürünce uyarı ipucunun yerine geçer; not yerinde
      magnetometer.field(60);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(warning, findsNothing);
      magnetometer.field(60);
      await tester.pump(const Duration(milliseconds: 200));
      expect(warning, findsOneWidget);
      expect(tip, findsNothing);
      expect(find.text(_loc.qiblaAccuracyNote), findsOneWidget);

      // %15,6: açılma eşiğinin altında ama histerezis içinde, uyarı sürer;
      // tek normal okuma da kapatmaz
      await _field(tester, magnetometer, 52, const Duration(seconds: 2));
      magnetometer.field(45);
      await tester.pump(const Duration(milliseconds: 200));
      await _field(tester, magnetometer, 52, const Duration(seconds: 2));
      expect(warning, findsOneWidget);

      // Normale dönünce 1 sn sonra kapanır
      magnetometer.field(46);
      await tester.pump(const Duration(milliseconds: 900));
      expect(warning, findsOneWidget);
      magnetometer.field(46);
      await tester.pump(const Duration(milliseconds: 200));
      expect(warning, findsNothing);
      expect(tip, findsOneWidget);

      // Arka planda bekleyen sayaç düşmez
      magnetometer.field(80);
      await tester.pump(const Duration(seconds: 1));
      await _lifecycle(AppLifecycleState.paused);
      expect(magnetometer.active, 0);
      await tester.pump(const Duration(seconds: 3));
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(magnetometer.active, 1);
      expect(warning, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('manyetometre doğruluğu 0/1: 2 sn sonra kalibrasyon uyarısı, '
        'pencere bir kez', (tester) async {
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      await _pumpQibla(
        tester,
        compass: compass,
        magnetometer: magnetometer,
        prefs: {'qibla_calibration_dialog_seen': false},
      );
      final lowAccuracy = find.text(_loc.lowAccuracyWarning);
      final dialog = find.text(_loc.calibrationRequired);
      compass.heading(146); // pusula doğruluğu yüksek
      await tester.pump();
      await _field(tester, magnetometer, 45, const Duration(seconds: 3));
      await _field(
        tester,
        magnetometer,
        45,
        const Duration(seconds: 3),
        accuracy: 2,
      );
      expect(lowAccuracy, findsNothing);

      magnetometer.field(45, accuracy: 1);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(lowAccuracy, findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(dialog, findsOneWidget);
      await tester.tap(find.text(_loc.okUnderstood));
      await tester.pump();
      expect(dialog, findsNothing);
      expect(lowAccuracy, findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('qibla_calibration_dialog_seen'), isTrue);

      // Manyetometre düzelince (pusula da iyi) hemen kapanır
      magnetometer.field(45, accuracy: 3);
      await tester.pump();
      expect(lowAccuracy, findsNothing);

      // Yeniden zayıflarsa uyarı döner, pencere tekrar açılmaz
      magnetometer.field(45, accuracy: 0);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(lowAccuracy, findsOneWidget);
      expect(dialog, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pusula yön vermeden manyetometre pencere açmaz', (
      tester,
    ) async {
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      await _pumpQibla(
        tester,
        compass: compass,
        magnetometer: magnetometer,
        prefs: {'qibla_calibration_dialog_seen': false},
      );
      await _field(
        tester,
        magnetometer,
        45,
        const Duration(seconds: 5),
        accuracy: 0,
      );
      expect(find.text(_loc.noCompass), findsOneWidget);
      expect(find.text(_loc.calibrationRequired), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('qibla_calibration_dialog_seen'), isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('doğruluk notu her zaman görünür; bilgi düğmesi ipuçlarını, '
        'kıble açısını ve sapmayı gösterir', (tester) async {
      final compass = _FakeSensor<CompassEvent>();
      final magnetometer = _FakeSensor<MagneticReading>();
      await _pumpQibla(tester, compass: compass, magnetometer: magnetometer);
      // Yön gelmeden de görünür
      expect(find.text(_loc.qiblaAccuracyNote), findsOneWidget);
      compass.heading(146);
      await tester.pump();
      expect(find.text(_loc.qiblaAccuracyNote), findsOneWidget);

      await _openTips(tester, _loc);
      expect(find.text(_loc.qiblaTipsTitle), findsOneWidget);
      for (final tip in [
        _loc.qiblaTipFlat,
        _loc.qiblaTipCalibrate,
        _loc.qiblaTipMagneticCase,
        _loc.qiblaTipMetal,
        _loc.qiblaTipMosque,
      ]) {
        expect(find.text(tip), findsOneWidget);
      }
      expect(
        find.text(_iso(_loc.qiblaAngleTrueNorth('152'), '152')),
        findsOneWidget,
      );
      expect(
        find.text(_iso(_loc.qiblaDeclination('+6'), '+6')),
        findsOneWidget,
      );
      // Sayfa açıkken kıble sekmesi görünür kalır: pusula sürer
      expect(compass.active, 1);

      Navigator.of(tester.element(find.text(_loc.qiblaTipFlat))).pop();
      await tester.pumpAndSettle();
      expect(find.text(_loc.qiblaTipFlat), findsNothing);
      expect(compass.active, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sapma bilinmiyorsa sayfada sapma satırı yok', (tester) async {
      _geomagneticReply = null;
      final compass = _FakeSensor<CompassEvent>();
      await _pumpQibla(
        tester,
        compass: compass,
        magnetometer: _FakeSensor<MagneticReading>(),
      );
      compass.heading(146);
      await tester.pump();
      await _openTips(tester, _loc);
      expect(
        find.text(_iso(_loc.qiblaAngleTrueNorth('152'), '152')),
        findsOneWidget,
      );
      final declinationLabel = _loc.qiblaDeclination('0').split(':').first;
      expect(find.textContaining(declinationLabel), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('320dp %130: ar koyu, de arka plan resmi, tr uyarılarla '
        'taşmaz; değerler sağdan solada bozulmaz', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final (lang, theme) in [
        ('ar', AppTheme.dark()),
        ('de', AppTheme.light(hasBackgroundImage: true)),
        ('tr', AppTheme.light()),
      ]) {
        final loc = lookupAppLocalizations(Locale(lang));
        final compass = _FakeSensor<CompassEvent>();
        final magnetometer = _FakeSensor<MagneticReading>();
        await _pumpQibla(
          tester,
          compass: compass,
          magnetometer: magnetometer,
          lang: lang,
          theme: theme,
        );
        compass.heading(146);
        await tester.pump();
        if (lang == 'tr') {
          // En kalabalık hâl: parazit + kalibrasyon uyarısı birlikte
          await _field(
            tester,
            magnetometer,
            90,
            const Duration(seconds: 3),
            accuracy: 1,
          );
          expect(find.text(loc.qiblaInterferenceWarning), findsOneWidget);
          expect(find.text(loc.lowAccuracyWarning), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: lang);
        expect(find.text(loc.qiblaAccuracyNote), findsOneWidget);

        if (lang == 'de') {
          // Fotoğraf üstünde koyu zemin + beyaz yazı: not, yönerge, açılar
          for (final text in [
            find.text(loc.qiblaAccuracyNote),
            find.text(loc.qiblaFound),
            find.text(_iso(loc.qiblaAngle('152'), '152')),
          ]) {
            expect(
              tester.widget<Text>(text).style!.color,
              PrayerColors.light.onHero,
            );
            final box = tester.widget<DecoratedBox>(
              find
                  .ancestor(of: text, matching: find.byType(DecoratedBox))
                  .first,
            );
            expect(
              (box.decoration as BoxDecoration).color,
              PrayerColors.light.heroImageScrim,
            );
          }
        }

        await _openTips(tester, loc);
        expect(tester.takeException(), isNull, reason: '$lang sayfa');
        expect(find.text(loc.qiblaTipMosque), findsOneWidget);
        if (lang == 'ar') {
          // Rakamlar uygulamanın geri kalanı gibi; işaret ve ° yerinde kalır
          expect(find.textContaining('\u2066152°\u2069'), findsWidgets);
          expect(find.textContaining('\u2066+6°\u2069'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('MainActivity kanalları: [µT, doğruluk] olayları okunur, '
        '"no_sensor" hatası sessizce yutulur', (tester) async {
      MockStreamHandlerEventSink? sink;
      final calls = <String>[];
      _messenger.setMockStreamHandler(
        _magneticChannel,
        MockStreamHandler.inline(
          onListen: (args, events) {
            calls.add('listen');
            sink = events;
          },
          onCancel: (args) => calls.add('cancel'),
        ),
      );
      addTearDown(
        () => _messenger.setMockStreamHandler(_magneticChannel, null),
      );
      final compass = _FakeSensor<CompassEvent>();
      await _pumpQibla(tester, compass: compass);
      expect(calls, ['listen']);
      compass.heading(146);
      await tester.pump();

      for (var i = 0; i < 10; i++) {
        sink!.success([90.0, 3]);
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text(_loc.qiblaInterferenceWarning), findsOneWidget);

      sink!.error(code: 'no_sensor', message: 'Manyetometre yok');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(_loc.qiblaInterferenceWarning), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls, ['listen', 'cancel']);
    });
  });
}
