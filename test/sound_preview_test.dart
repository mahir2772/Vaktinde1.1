// Alarm ayarlarındaki ses önizlemesi: res/raw'daki bildirim sesi "vaktinde/device"
// kanalıyla çalınır (assets'te kopyası yok). Kotlin playSound'u ses susunca
// (bitti / durduruldu / yeni ses başladı) yanıtlar; aynı anda tek ses.
import 'dart:async';

import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const device = MethodChannel('vaktinde/device');
  late List<String> calls;
  // Çalan sesin bekleyen yanıtı (sahte Kotlin tarafı)
  Completer<void>? playing;

  void silence() {
    final current = playing;
    playing = null;
    if (current != null && !current.isCompleted) current.complete();
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    playing = null;
    messenger.setMockMethodCallHandler(device, (call) async {
      calls.add('${call.method}:${call.arguments}');
      switch (call.method) {
        case 'playSound':
          silence(); // yeni ses öncekini keser
          final done = playing = Completer<void>();
          await done.future;
        case 'stopSound':
          silence();
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(device, null));

  test('res/raw sesi adıyla çalınır; ses bitince simge kapanır', () async {
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    unawaited(vm.playPreview('ezan3'));
    await settle();
    expect(calls, ['playSound:ezan3']);
    expect(vm.currentlyPlayingSound, 'ezan3');

    silence(); // ses sonuna kadar çaldı
    await settle();
    expect(vm.currentlyPlayingSound, isNull);
  });

  test('aynı sese dokunmak durdurur, başka ses öncekini keser', () async {
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    unawaited(vm.playPreview('ezan1'));
    await settle();
    unawaited(vm.playPreview('bildirim2'));
    await settle();
    // Kesilen sesin yanıtı yeni sesin simgesini kapatmaz
    expect(vm.currentlyPlayingSound, 'bildirim2');

    await vm.playPreview('bildirim2');
    await settle();
    expect(vm.currentlyPlayingSound, isNull);
    expect(calls, ['playSound:ezan1', 'playSound:bildirim2', 'stopSound:null']);

    // Durdur → hemen yeniden çal: eski turun yanıtı yeni turu kapatmaz
    unawaited(vm.playPreview('ezan1'));
    unawaited(vm.playPreview('ezan1'));
    unawaited(vm.playPreview('ezan1'));
    await settle();
    expect(vm.currentlyPlayingSound, 'ezan1');
    expect(playing, isNotNull);
  });

  test('alt sayfa kapanınca ve ayar değişince susar', () async {
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    unawaited(vm.playPreview('ezan5'));
    await settle();
    await vm.stopPreview();
    await settle();
    expect(vm.currentlyPlayingSound, isNull);
    expect(playing, isNull);
    expect(calls.last, 'stopSound:null');

    // Çalan yokken kanal çağrılmaz
    await vm.stopPreview();
    vm.toggleAlarm('Öğle', true, false);
    await settle();
    expect(calls.where((c) => c.startsWith('stopSound')), hasLength(1));

    unawaited(vm.playPreview('bildirim1'));
    await settle();
    vm.toggleSilentMode('Öğle', true);
    await settle();
    expect(vm.currentlyPlayingSound, isNull);
    expect(playing, isNull);
  });

  test('kapanan ekranda çalan ses susar', () async {
    final vm = HomeViewModel();
    unawaited(vm.playPreview('ezan8'));
    await settle();
    vm.dispose();
    await settle();
    expect(calls, ['playSound:ezan8', 'stopSound:null']);
  });

  test('kanal yoksa (Android dışı) simge hemen kapanır', () async {
    messenger.setMockMethodCallHandler(device, null);
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    await vm.playPreview('ezan1');
    expect(vm.currentlyPlayingSound, isNull);
  });
}
