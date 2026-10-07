// Kıble pusulası pil kuralları: pusula aboneliği sadece sekme görünür ve
// uygulama ön plandayken açık (tek abonelik); kalibrasyon uyarısı 2 sn süren
// zayıf doğrulukta açılır, iyi okumada kapanır; küçük titreşim çizdirmez.
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

const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');
const _compassChannel = EventChannel('hemanthraj/flutter_compass');

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Her dinlemeyi ayrı abonelik sayan sahte pusula
class _FakeCompass {
  final List<MultiStreamController<CompassEvent>> _listeners = [];
  int listens = 0;
  int maxConcurrent = 0;

  int get active => _listeners.length;

  late final Stream<CompassEvent> stream = Stream<CompassEvent>.multi((c) {
    listens++;
    _listeners.add(c);
    if (_listeners.length > maxConcurrent) maxConcurrent = _listeners.length;
    c.onCancel = () {
      _listeners.remove(c);
    };
  });

  /// Android eklentisindeki gibi [yön, kamera yönü, doğruluk]; -1 = bilinmiyor
  void emit(double heading, {double accuracy = 15}) {
    final event = CompassEvent.fromList([heading, heading, accuracy]);
    for (final c in List.of(_listeners)) {
      c.addSync(event);
    }
  }
}

/// Motorun gönderdiği gibi (ara durumlar dahil: resumed → inactive → hidden → paused)
Future<void> _lifecycle(AppLifecycleState state) =>
    _messenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

/// Alt menüdeki gibi IndexedStack: 0 = Kıble, 1 = başka sekme.
/// [compass] yoksa gerçek eklenti akışı (FlutterCompass.events) kullanılır.
Future<ValueNotifier<int>> _pumpQibla(
  WidgetTester tester, {
  _FakeCompass? compass,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'saved_lat': 41.0082,
    'saved_lng': 28.9784,
    'qibla_calibration_dialog_seen': true,
    ...prefs,
  });
  final tab = ValueNotifier<int>(0);
  addTearDown(tab.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: tab,
          builder: (context, index, _) => IndexedStack(
            index: index,
            children: [
              compass == null
                  ? const QiblaView()
                  : QiblaView(compassEvents: () => compass.stream),
              const Center(child: Text('diğer sekme')),
            ],
          ),
        ),
      ),
    ),
  );
  // Konum (sahte kanal) → kıble açısı → pusula aboneliği
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return tab;
}

AppLocalizations get _loc => lookupAppLocalizations(const Locale('tr'));

void main() {
  setUp(() {
    _messenger.setMockMethodCallHandler(_geolocator, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 2; // whileInUse
        case 'getLastKnownPosition':
        case 'getCurrentPosition':
          return {
            'latitude': 41.0082,
            'longitude': 28.9784,
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
    // Kıble hizasında titreşim
    _messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    _messenger.setMockMethodCallHandler(_geolocator, null);
    _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('Pusula aboneliği', () {
    testWidgets('görünür + ön planda tek abonelik; olaylar yönü günceller', (
      tester,
    ) async {
      final compass = _FakeCompass();
      await _pumpQibla(tester, compass: compass);
      expect(compass.active, 1);
      expect(compass.listens, 1);

      compass.emit(120);
      await tester.pump();
      expect(find.textContaining('120°'), findsOneWidget);
      expect(find.text(_loc.qiblaTurnRight), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(compass.active, 0, reason: 'dispose aboneliği kapatır');
      expect(compass.maxConcurrent, 1);
    });

    testWidgets('inactive/hidden/paused kapatır, resumed yeniden açar', (
      tester,
    ) async {
      final compass = _FakeCompass();
      await _pumpQibla(tester, compass: compass);
      await _lifecycle(AppLifecycleState.resumed);
      expect(compass.active, 1);

      // Tam ekran reklam / bildirim perdesi
      await _lifecycle(AppLifecycleState.inactive);
      await tester.pump();
      expect(compass.active, 0);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(compass.active, 1);
      expect(compass.listens, 2);

      // Arka plan: resumed → inactive → hidden → paused
      await _lifecycle(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(compass.active, 0);
      compass.emit(10); // dinleyen yok
      await _lifecycle(AppLifecycleState.hidden);
      expect(compass.active, 0);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(compass.active, 1);
      expect(compass.listens, 3);

      compass.emit(200);
      await tester.pump();
      expect(find.textContaining('200°'), findsOneWidget);

      await _lifecycle(AppLifecycleState.detached);
      expect(compass.active, 0);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(compass.active, 1);
      expect(compass.maxConcurrent, 1);
      await tester.pumpWidget(const SizedBox());
      expect(compass.active, 0);
    });

    testWidgets('sekme gizlenince/üstüne sayfa açılınca kapanır; arka planda '
        'sekmeye dönmek açmaz', (tester) async {
      final compass = _FakeCompass();
      final tab = await _pumpQibla(tester, compass: compass);
      expect(compass.active, 1);
      compass.emit(120);
      await tester.pump();

      tab.value = 1;
      await tester.pump();
      expect(compass.active, 0);
      tab.value = 0;
      await tester.pump();
      expect(compass.active, 1);
      expect(compass.listens, 2);

      // Ön planda değilken sekmeye dönülse de açılmaz (inactive'de kareler
      // çizilmeye devam eder, sekme görünür olur)
      tab.value = 1;
      await tester.pump();
      await _lifecycle(AppLifecycleState.inactive);
      tab.value = 0;
      await tester.pump();
      expect(find.byType(QiblaView).hitTestable(), findsOneWidget);
      expect(compass.active, 0);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(compass.active, 1);

      // Gizli sekmedeyken ön plana dönmek de açmaz
      tab.value = 1;
      await tester.pump();
      await _lifecycle(AppLifecycleState.paused);
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(compass.active, 0);
      tab.value = 0;
      await tester.pump();
      expect(compass.active, 1);

      // Üstüne tam sayfa açılınca (TickerMode kapalı) durur, kapanınca döner
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('ayarlar')),
        ),
      );
      await tester.pumpAndSettle();
      expect(compass.active, 0);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(compass.active, 1);
      expect(compass.maxConcurrent, 1);
      await tester.pumpWidget(const SizedBox());
      expect(compass.active, 0);
    });

    testWidgets('hızlı geçişlerde hiçbir an iki abonelik olmaz', (
      tester,
    ) async {
      final compass = _FakeCompass();
      final tab = await _pumpQibla(tester, compass: compass);
      await _lifecycle(AppLifecycleState.resumed);
      for (var i = 0; i < 3; i++) {
        await _lifecycle(AppLifecycleState.inactive);
        await _lifecycle(AppLifecycleState.resumed);
        await _lifecycle(AppLifecycleState.resumed);
        tab.value = 1;
        await tester.pump();
        tab.value = 0;
        await tester.pump();
        compass.emit(100.0 + i * 10);
      }
      await tester.pump();
      expect(compass.active, 1);
      expect(compass.maxConcurrent, 1);
      expect(compass.listens, 7);
      await tester.pumpWidget(const SizedBox());
      expect(compass.active, 0);
    });

    testWidgets(
      'gerçek eklenti kanalı: arka planda "cancel", dönüşte "listen"',
      (tester) async {
        // Android eklentisi onCancel'da sensör dinleyicilerini kaldırır
        final calls = <String>[];
        _messenger.setMockStreamHandler(
          _compassChannel,
          MockStreamHandler.inline(
            onListen: (args, sink) => calls.add('listen'),
            onCancel: (args) => calls.add('cancel'),
          ),
        );
        addTearDown(
          () => _messenger.setMockStreamHandler(_compassChannel, null),
        );
        final tab = await _pumpQibla(tester);
        expect(calls, ['listen']);

        await _lifecycle(AppLifecycleState.paused);
        await tester.pump();
        expect(calls, ['listen', 'cancel']);
        await _lifecycle(AppLifecycleState.resumed);
        await tester.pump();
        expect(calls, ['listen', 'cancel', 'listen']);

        tab.value = 1;
        await tester.pump();
        expect(calls.last, 'cancel');
        tab.value = 0;
        await tester.pump();
        expect(calls.last, 'listen');

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(calls, [
          'listen',
          'cancel',
          'listen',
          'cancel',
          'listen',
          'cancel',
        ]);
      },
    );
  });

  group('Kalibrasyon uyarısı', () {
    test('doğruluk sınıfı: sadece yüksek (≤15°) yeterli', () {
      expect(compassAccuracyPoor(15), isFalse); // Android: yüksek
      expect(compassAccuracyPoor(5), isFalse); // iOS: ±5°
      expect(compassAccuracyPoor(30), isTrue); // orta
      expect(compassAccuracyPoor(45), isTrue); // düşük
      expect(compassAccuracyPoor(null), isTrue); // güvenilmez/bilinmiyor
      expect(compassAccuracyPoor(0), isTrue);
    });

    testWidgets('2 sn zayıf/bilinmiyorsa açılır, iyi okumada kapanır; kısa '
        'düşüş yanıp söndürmez', (tester) async {
      final compass = _FakeCompass();
      await _pumpQibla(tester, compass: compass);
      final warning = find.text(_loc.lowAccuracyWarning);
      final tip = find.text('${_loc.qiblaCalibration} ${_loc.keepAwayMetal}');

      compass.emit(120);
      await tester.pump();
      expect(tip, findsOneWidget);
      expect(warning, findsNothing);

      // Kısa düşüş: uyarı hiç görünmez
      compass.emit(120, accuracy: -1);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(warning, findsNothing);
      compass.emit(120);
      await tester.pump(const Duration(seconds: 3));
      expect(warning, findsNothing);

      // 2 sn'den uzun zayıf (orta → düşük): uyarı ipucunun yerine geçer
      compass.emit(120, accuracy: 30);
      await tester.pump(const Duration(seconds: 1));
      compass.emit(121, accuracy: 45);
      await tester.pump(const Duration(milliseconds: 900));
      expect(warning, findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(warning, findsOneWidget);
      expect(tip, findsNothing);

      // Zayıf olaylar sürerken sabit kalır
      for (var i = 0; i < 5; i++) {
        compass.emit(121, accuracy: -1);
        await tester.pump(const Duration(milliseconds: 300));
        expect(warning, findsOneWidget);
      }

      // İyi okuma: hemen kapanır
      compass.emit(121);
      await tester.pump();
      expect(warning, findsNothing);
      expect(tip, findsOneWidget);

      // Arka planda bekleyen sayaç düşmez; dönüşte yeniden 2 sn beklenir
      compass.emit(121, accuracy: -1);
      await tester.pump(const Duration(milliseconds: 1500));
      await _lifecycle(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      await _lifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(warning, findsNothing);
      compass.emit(121, accuracy: -1);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(warning, findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(warning, findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('0,5°den küçük yön değişimi yeniden çizim istemez', (
    tester,
  ) async {
    final compass = _FakeCompass();
    await _pumpQibla(tester, compass: compass);
    double dialTarget() => tester
        .widget<TweenAnimationBuilder<double>>(
          find.byType(TweenAnimationBuilder<double>),
        )
        .tween
        .end!;

    compass.emit(100);
    await tester.pumpAndSettle(); // kadran animasyonu biter
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(dialTarget(), 100);

    // setState yoksa kare de istenmez
    compass.emit(100.3);
    compass.emit(99.6);
    compass.emit(100.49);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump();
    expect(dialTarget(), 100);

    compass.emit(100.5);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(dialTarget(), closeTo(100.5, 1e-9));

    // 360/0 geçişi: kısa yol (359,8 → 0,1 = +0,3°) çizdirmez, kadran sarılmaz
    compass.emit(359.8);
    await tester.pumpAndSettle();
    final before = dialTarget();
    compass.emit(0.1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    compass.emit(0.4);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(dialTarget(), closeTo(before + 0.6, 1e-9));

    // Yön aynı kalsa da kalibrasyon değişimi çizdirir
    compass.emit(0.4, accuracy: -1);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(_loc.lowAccuracyWarning), findsOneWidget);
    compass.emit(0.4);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(find.text(_loc.lowAccuracyWarning), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
