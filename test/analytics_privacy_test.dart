// Analitik olaylarında konum (il/ilçe, koordinat) ve ibadet bilgisi (vakit)
// gönderilmez; Firebase Analytics'e tek kapı AppAnalytics'tir.
import 'dart:io';

import 'package:ezan_saati/features/common/app_analytics.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final events = <(String, Map<String, Object>?)>[];
  final original = AppAnalytics.sink;

  setUp(() {
    events.clear();
    AppAnalytics.sink = (name, parameters) async =>
        events.add((name, parameters));
  });
  tearDown(() => AppAnalytics.sink = original);

  test('izinli olmayan parametreler atılır', () async {
    await AppAnalytics.logEvent(
      name: 'deneme',
      parameters: {
        'sehir': 'Ankara',
        'ilce': 'Çankaya',
        'vakit': 'Öğle',
        'lat': 39.92,
        'tip': 'tam_vakit',
      },
    );
    await AppAnalytics.logEvent(name: 'bos', parameters: {'sehir': 'Ankara'});
    expect(events.map((e) => e.$1), ['deneme', 'bos']);
    expect(events[0].$2, {'tip': 'tam_vakit'});
    expect(events[1].$2, isNull);
  });

  test('gönderim hatası uygulamayı etkilemez', () async {
    AppAnalytics.sink = (name, parameters) => throw StateError('firebase');
    await AppAnalytics.logEvent(name: 'deneme');
  });

  test('şehir değişince olayda il/ilçe yok', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    await vm.changeCityAndDistrict('Ankara', 'Çankaya', lat: 39.92, lng: 32.85);
    expect(vm.city, 'Ankara');
    expect(events.map((e) => e.$1), ['sehir_secildi']);
    expect(events.single.$2, isNull);
  });

  test('alarm açılınca olayda vakit yok', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = HomeViewModel();
    addTearDown(vm.dispose);
    vm.toggleAlarm('Öğle', true, true);
    vm.toggleAlarm('Akşam', false, true);
    vm.toggleAlarm('Akşam', false, false); // kapatma olay göndermez
    await Future<void>.delayed(Duration.zero);
    expect(events.map((e) => e.$1), ['alarm_acildi', 'alarm_acildi']);
    expect(events[0].$2, {'tip': 'tam_vakit'});
    expect(events[1].$2, {'tip': 'hatirlatma'});
  });

  test('Firebase Analytics sadece AppAnalytics üzerinden çağrılır', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !file.path.endsWith('app_analytics.dart') &&
            file.readAsStringSync().contains('FirebaseAnalytics'))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
