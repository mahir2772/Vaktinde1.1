// Zikirmatik: hedef halkası ve tur sayımı (saf hesap + ekran), "Hedefte
// sıfırdan devam et" ayarı (tur ve sayaç zikir başına kayıtlı), başlık
// kartında kaydırarak / oklarla önceki-sonraki zikir, üst çubukta onaylı
// Sıfırla, altta bugünkü toplam, sayacın çevresine dokunarak sayma ve "Ses
// tuşlarıyla say"ın Dart tarafı (yerel bayrak sadece sekme görünür + ayar
// açık + ön plandayken açık).
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/duas/dua_data.dart';
import 'package:ezan_saati/features/zikirmatik/view/dhikr_stats_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_settings_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/features/zikirmatik/zikir_logic.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

const _device = MethodChannel('vaktinde/device');
const _volumeKeys = EventChannel('vaktinde/volume_keys');

/// Titreşimler (HapticFeedback.vibrate argümanı; düz titreşimde null)
final List<Object?> _haptics = [];

/// Yerel tarafa gönderilen setVolumeKeyCounting değerleri
final List<Object?> _volumeFlags = [];

/// Ses tuşu akışı: dinlenirken dolu
MockStreamHandlerEventSink? _volumeSink;
int _volumeListens = 0;
int _volumeCancels = 0;

void _mockPlatform() {
  _haptics.clear();
  _volumeFlags.clear();
  _volumeSink = null;
  _volumeListens = 0;
  _volumeCancels = 0;
  _messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') _haptics.add(call.arguments);
    return null;
  });
  _messenger.setMockMethodCallHandler(_device, (call) async {
    if (call.method == 'setVolumeKeyCounting') _volumeFlags.add(call.arguments);
    return null;
  });
  _messenger.setMockStreamHandler(
    _volumeKeys,
    MockStreamHandler.inline(
      onListen: (args, sink) {
        _volumeListens++;
        _volumeSink = sink;
      },
      onCancel: (args) {
        _volumeCancels++;
        _volumeSink = null;
      },
    ),
  );
  // Diğer eklentiler (ses, ekran açık): "başarılı, null"
  _messenger.allMessagesHandler = (channel, handler, message) {
    if (handler != null) return handler(message);
    if (channel.startsWith('flutter/')) {
      return _messenger.delegate.send(channel, message);
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

void _clearPlatform() {
  _messenger.allMessagesHandler = null;
  _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  _messenger.setMockMethodCallHandler(_device, null);
  _messenger.setMockStreamHandler(_volumeKeys, null);
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Motorun gönderdiği gibi (ara durumlar dahil)
Future<void> _lifecycle(AppLifecycleState state) =>
    _messenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

Future<void> _settle(WidgetTester tester, {int steps = 6}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

AppLocalizations _loc(String lang) => lookupAppLocalizations(Locale(lang));

/// Alt menüdeki gibi IndexedStack: 0 = Zikir, 1 = başka sekme
Future<ValueNotifier<int>> _pumpZikir(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  String lang = 'tr',
  double width = 411,
  double height = 891,
  double textScale = 1,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'selected_dhikr': 'Sübhanallah',
    ...prefs,
  });
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final tab = ValueNotifier<int>(0);
  addTearDown(tab.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      key: UniqueKey(),
      create: (_) => ZikirViewModel(),
      child: MaterialApp(
        locale: Locale(lang),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: tab,
            builder: (context, index, _) => IndexedStack(
              index: index,
              children: const [
                ZikirView(),
                Center(child: Text('diğer sekme')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return tab;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

ZikirViewModel _vm(WidgetTester tester) =>
    tester.element(find.byType(ZikirView)).read<ZikirViewModel>();

/// Halkanın hedeflediği doluluk (TweenAnimationBuilder'ın son değeri)
double _ringFraction(WidgetTester tester) => tester
    .widget<TweenAnimationBuilder<double>>(find.byKey(ZikirView.ringKey))
    .tween
    .end!;

/// "27 / 33" (rakamlar eşit genişlikte çizilir)
Finder _progressText(String text) =>
    find.byWidgetPredicate((w) => w is TabularText && w.text == text);

/// Yerel taraftan ses tuşu olayı (+1 / -1); sahte eklenti olayları gerçek olay
/// döngüsüyle iletilir
Future<void> _volumeKey(WidgetTester tester, int delta) async {
  _volumeSink!.success(delta);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Hazır zikirler (duas.json): sahte zamanlı testlerden önce bir kez okunur
    await DuaLibrary.load();
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
  });

  setUp(_mockPlatform);
  tearDown(_clearPlatform);

  group('Tur ve halka (saf)', () {
    test('carryRounds: hedefi aşan sayaç turlara aktarılır', () {
      expect(carryRounds(0, 33, 1), (count: 0, round: 1));
      expect(carryRounds(32, 33, 1), (count: 32, round: 1));
      expect(carryRounds(33, 33, 1), (count: 0, round: 2));
      expect(carryRounds(98, 33, 1), (count: 32, round: 3));
      expect(carryRounds(99, 33, 2), (count: 0, round: 5));
      // Bozuk kayıt: sıfıra bölme yok, eksi yok
      expect(carryRounds(5, 0, 0), (count: 0, round: 6));
      expect(carryRounds(-3, 33, -1), (count: 0, round: 1));
    });

    test('kapalı kip: toplam sayaç, halka her hedefte dolar', () {
      final zero = ZikirProgress.of(count: 0, target: 33);
      expect(zero.fraction, 0);
      expect(zero.round, 1);
      expect(zero.showRound, isFalse);
      expect(zero.reached, isFalse);

      final p27 = ZikirProgress.of(count: 27, target: 33);
      expect(p27.count, 27);
      expect(p27.inRound, 27);
      expect(p27.fraction, closeTo(27 / 33, 1e-9));
      expect(p27.showRound, isFalse);

      final p33 = ZikirProgress.of(count: 33, target: 33);
      expect(p33.reached, isTrue);
      expect(p33.fraction, 1);
      expect(p33.round, 1);

      final p34 = ZikirProgress.of(count: 34, target: 33);
      expect(p34.count, 34);
      expect(p34.inRound, 1);
      expect(p34.round, 2);
      expect(p34.showRound, isTrue);
      expect(p34.reached, isFalse);

      final p66 = ZikirProgress.of(count: 66, target: 33, round: 9);
      expect(p66.reached, isTrue);
      expect(p66.round, 2); // kayıtlı tur kapalı kipte kullanılmaz
    });

    test('tur kipi: sayaç turun içinde, tur kayıtlı, yeni turda hedefte', () {
      final p = ZikirProgress.of(
        count: 27,
        target: 33,
        round: 2,
        roundMode: true,
      );
      expect(p.count, 27);
      expect(p.inRound, 27);
      expect(p.round, 2);
      expect(p.showRound, isTrue);
      expect(p.reached, isFalse);

      final first = ZikirProgress.of(count: 0, target: 33, roundMode: true);
      expect(first.showRound, isTrue);
      expect(first.reached, isFalse);

      final completed = ZikirProgress.of(
        count: 0,
        target: 33,
        round: 3,
        roundMode: true,
      );
      expect(completed.reached, isTrue);
      expect(completed.fraction, 0);

      // Kapalı kipten kalan toplam: turlara aktarılmış gösterilir
      final carried = ZikirProgress.of(count: 98, target: 33, roundMode: true);
      expect(carried.count, 32);
      expect(carried.round, 3);
    });

    test('önceki/sonraki zikir: liste içinde, uçlarda döner', () {
      const main = ['A', 'B', 'C', 'Özel'];
      const esma = ['Ya Allah', 'Ya Rahman', 'Ya Rahim'];
      String step(String current, int step) =>
          adjacentDhikr(current: current, main: main, esma: esma, step: step);
      expect(step('A', 1), 'B');
      expect(step('B', -1), 'A');
      expect(step('Özel', 1), 'A');
      expect(step('A', -1), 'Özel');
      // Esmâ-ül Hüsnâ kendi içinde
      expect(step('Ya Allah', 1), 'Ya Rahman');
      expect(step('Ya Allah', -1), 'Ya Rahim');
      // Hem özel hem Esma adı: kullanıcının listesi
      expect(
        adjacentDhikr(
          current: 'Ya Rahman',
          main: const ['A', 'Ya Rahman'],
          esma: esma,
          step: 1,
        ),
        'A',
      );
      // Silinmiş zikir: ileri ilk, geri son
      expect(step('Silinen', 1), 'A');
      expect(step('Silinen', -1), 'Özel');
      expect(
        adjacentDhikr(current: 'A', main: const [], esma: esma, step: 1),
        'A',
      );
    });
  });

  group('Görünüm modeli', () {
    Future<ZikirViewModel> model(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final vm = ZikirViewModel();
      await pumpEventQueue();
      return vm;
    }

    test('tur kipi: hedefte tur artar, sayaç sıfırlanır, çift titreşim; '
        'tur zikir başına kayıtlı', () async {
      final vm = await model({
        'selected_dhikr': 'Sübhanallah',
        'dhikr_count_Sübhanallah': 31,
        ZikirViewModel.roundModeKey: true,
        'dhikr_count_Elhamdülillah': 5,
        '${ZikirViewModel.roundPrefix}Elhamdülillah': 4,
      });
      expect(vm.isRoundModeEnabled, isTrue);
      expect(vm.round, 1);
      await vm.increment();
      expect((vm.count, vm.round), (32, 1));
      expect(_haptics, [null]);
      await vm.increment();
      expect((vm.count, vm.round), (0, 2));
      expect(vm.progress.reached, isTrue);
      // Hedefte ikinci titreşim 150 ms sonra
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(_haptics, [null, null, null]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('dhikr_count_Sübhanallah'), 0);
      expect(prefs.getInt('${ZikirViewModel.roundPrefix}Sübhanallah'), 2);

      // Başka zikrin turu ayrı
      await vm.changeDhikr('Elhamdülillah');
      expect((vm.count, vm.round), (5, 4));
      await vm.changeDhikr('Sübhanallah');
      expect((vm.count, vm.round), (0, 2));

      // Sıfırla: sayaç ve tur (1. tur kaydedilmez)
      await vm.reset();
      expect((vm.count, vm.round), (0, 1));
      expect(
        prefs.containsKey('${ZikirViewModel.roundPrefix}Sübhanallah'),
        isFalse,
      );
      vm.dispose();
      await pumpEventQueue();
    });

    test(
      'hedef: kayıt yoksa kaynaktaki sayı (yoksa 33), kayıt varsa o',
      () async {
        final vm = await model({
          'selected_dhikr': 'Estağfirullah',
          'dhikr_target_Kelime-i Tevhid': 99,
        });
        await pumpEventQueue();
        expect(vm.predefinedDhikrs, hasLength(35));
        expect(vm.target, 100);
        await vm.changeDhikr('adede_halkihi');
        expect(vm.target, 3);
        await vm.changeDhikr('Kelime-i Tevhid');
        expect(vm.target, 99);
        await vm.changeDhikr('Hz. Yunus');
        expect(vm.target, 33);
        expect(vm.getArabicForDhikr('Hz. Yunus'), startsWith('لَا إِلَهَ'));
        vm.dispose();
        await pumpEventQueue();
      },
    );

    test('kapalı kip (varsayılan): sayaç toplam, tur artmaz', () async {
      final vm = await model({
        'selected_dhikr': 'Sübhanallah',
        'dhikr_count_Sübhanallah': 32,
      });
      expect(vm.isRoundModeEnabled, isFalse);
      await vm.increment();
      expect((vm.count, vm.round), (33, 1));
      expect(vm.progress.reached, isTrue);
      await vm.increment();
      expect(vm.count, 34);
      expect(vm.progress.round, 2);
      expect(vm.progress.inRound, 1);
      // Tur kipi açılıp kapanınca sayaç değişmez
      await vm.toggleRoundMode(true);
      expect(vm.count, 34);
      expect(vm.progress.count, 1);
      expect(vm.progress.round, 2);
      await vm.toggleRoundMode(false);
      expect(vm.count, 34);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ZikirViewModel.roundModeKey), isFalse);
      vm.dispose();
      await pumpEventQueue();
    });

    test('-1: sıfırın altına inmez, tur kipinde önceki tura dönmez, '
        'günlük sayıdan düşer', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final vm = await model({
        'selected_dhikr': 'Sübhanallah',
        'dhikr_count_Sübhanallah': 1,
        'dhikr_daily_stats': '{"$today": 2}',
      });
      await vm.decrement();
      expect(vm.count, 0);
      expect(vm.dailyStats[today], 1);
      await vm.decrement();
      expect(vm.count, 0);
      expect(vm.dailyStats[today], 1);

      await vm.toggleRoundMode(true);
      await vm.setCount(33); // 1 tur + 0
      expect((vm.count, vm.round), (0, 2));
      await vm.decrement();
      expect((vm.count, vm.round), (0, 2));
      await vm.increment();
      await vm.decrement();
      expect((vm.count, vm.round), (0, 2));
      vm.dispose();
      await pumpEventQueue();
    });

    test('tur kipinde elle sayaç ve hedef: gösterilen tur korunur', () async {
      final vm = await model({
        'selected_dhikr': 'Sübhanallah',
        'dhikr_count_Sübhanallah': 98, // kapalı kipten kalan
        ZikirViewModel.roundModeKey: true,
      });
      expect((vm.progress.count, vm.progress.round), (32, 3));
      await vm.setCount(40);
      expect((vm.count, vm.round), (7, 4));
      await vm.setTarget(5);
      expect((vm.count, vm.round), (2, 5));
      expect(vm.target, 5);
      vm.dispose();
      await pumpEventQueue();
    });
  });

  group('Ekran', () {
    testWidgets('halka hedefe doğru dolar; "27 / 33", 2. turda "Tur 2"', (
      tester,
    ) async {
      final loc = _loc('tr');
      await _pumpZikir(
        tester,
        prefs: {'dhikr_count_Sübhanallah': 27, 'dhikr_target_Sübhanallah': 33},
      );
      expect(_ringFraction(tester), closeTo(27 / 33, 1e-9));
      // Üst çubukta tam ad sığıyor (411dp)
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(loc.zikirmatikTitle),
        ),
        findsOneWidget,
      );
      expect(_progressText('27 / 33'), findsOneWidget);
      expect(find.text(loc.zikirRound(1)), findsNothing);
      expect(find.text(loc.targetReached), findsNothing);

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(ZikirView.counterKey));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await _settle(tester);
      expect(_vm(tester).count, 33);
      expect(_ringFraction(tester), 1);
      expect(_progressText('33 / 33'), findsOneWidget);
      expect(find.text(loc.targetReached), findsOneWidget);

      await tester.tap(find.byKey(ZikirView.counterKey));
      await _settle(tester);
      expect(_progressText('1 / 33'), findsOneWidget);
      expect(find.text(loc.zikirRound(2)), findsOneWidget);
      expect(_ringFraction(tester), closeTo(1 / 33, 1e-9));
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('tur kipi: hedefte sıfırdan başlar, tur artar ve kalıcı', (
      tester,
    ) async {
      final loc = _loc('tr');
      await _pumpZikir(
        tester,
        prefs: {
          'dhikr_count_Sübhanallah': 32,
          ZikirViewModel.roundModeKey: true,
        },
      );
      expect(find.text(loc.zikirRound(1)), findsOneWidget);
      await tester.tap(find.byKey(ZikirView.counterKey));
      await _settle(tester);
      expect((_vm(tester).count, _vm(tester).round), (0, 2));
      expect(_progressText('0 / 33'), findsOneWidget);
      expect(find.text(loc.zikirRound(2)), findsOneWidget);
      // Hedefe ulaşma geri bildirimi (yeni turun başında)
      expect(find.text(loc.targetReached), findsOneWidget);
      expect(_ringFraction(tester), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('${ZikirViewModel.roundPrefix}Sübhanallah'), 2);
      // Çift titreşim
      expect(_haptics.where((h) => h == null), hasLength(2));

      await tester.tap(find.byKey(ZikirView.counterKey));
      await _settle(tester);
      expect(find.text(loc.targetReached), findsNothing);
      expect(_progressText('1 / 33'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('ayarlar: tur kipi ve ses tuşları (varsayılan kapalı)', (
      tester,
    ) async {
      final loc = _loc('tr');
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ZikirViewModel(),
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ZikirSettingsView(),
          ),
        ),
      );
      await _settle(tester);
      Switch switchOf(String title) => tester.widget<Switch>(
        find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(AppListTile),
          ),
          matching: find.byType(Switch),
        ),
      );
      await tester.scrollUntilVisible(find.text(loc.zikirVolumeKeys), 200);
      expect(find.text(loc.zikirCountingSection), findsOneWidget);
      expect(find.text(loc.zikirVolumeKeysDesc), findsOneWidget);
      expect(switchOf(loc.zikirRoundMode).value, isFalse);
      expect(switchOf(loc.zikirVolumeKeys).value, isFalse);

      await tester.tap(find.text(loc.zikirRoundMode));
      await tester.tap(find.text(loc.zikirVolumeKeys));
      await _settle(tester);
      expect(switchOf(loc.zikirRoundMode).value, isTrue);
      expect(switchOf(loc.zikirVolumeKeys).value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ZikirViewModel.roundModeKey), isTrue);
      expect(prefs.getBool(ZikirViewModel.volumeKeysKey), isTrue);
      // Ayar sayfası açıkken ses tuşları sayılmaz (Zikir ekranı yok)
      expect(_volumeFlags, isEmpty);
      await _finish(tester);
    });

    testWidgets('kaydırınca / oklarla önceki-sonraki zikir (uçlarda döner)', (
      tester,
    ) async {
      final loc = _loc('tr');
      await _pumpZikir(
        tester,
        prefs: {
          'custom_dhikrs_list': ['Ya Vedûd'],
        },
      );
      String selected() => _vm(tester).selectedDhikr;
      final header = find.byKey(ZikirView.headerKey);

      await tester.fling(header, const Offset(-300, 0), 1000);
      await _settle(tester);
      expect(selected(), 'Elhamdülillah');
      // Ad hazır zikir kitaplığından (duas.json)
      expect(find.text('Elhamdülillah'), findsOneWidget);
      await tester.fling(header, const Offset(300, 0), 1000);
      await _settle(tester);
      expect(selected(), 'Sübhanallah');
      // Yavaş sürükleme değiştirmez
      await tester.drag(header, const Offset(-40, 0));
      await _settle(tester);
      expect(selected(), 'Sübhanallah');

      // Oklar; baştan geri: listenin sonu (kullanıcının zikri)
      await tester.tap(find.byTooltip(loc.zikirPrevious));
      await _settle(tester);
      expect(selected(), 'Ya Vedûd');
      await tester.tap(find.byTooltip(loc.zikirNext));
      await _settle(tester);
      expect(selected(), 'Sübhanallah');
      // Hedef düğmesi kartın içinde çalışmaya devam eder
      await tester.tap(find.text(loc.targetCount(33)));
      await _settle(tester);
      expect(find.text(loc.setTarget), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('sağdan sola (ar): sağa kaydırmak sonraki', (tester) async {
      await _pumpZikir(tester, lang: 'ar');
      final header = find.byKey(ZikirView.headerKey);
      await tester.fling(header, const Offset(300, 0), 1000);
      await _settle(tester);
      expect(_vm(tester).selectedDhikr, 'Elhamdülillah');
      await tester.fling(header, const Offset(-300, 0), 1000);
      await _settle(tester);
      expect(_vm(tester).selectedDhikr, 'Sübhanallah');
      await _finish(tester);
    });

    testWidgets('Sıfırla üst çubukta (onaylı); altta Sıfırla yok', (
      tester,
    ) async {
      final loc = _loc('tr');
      await _pumpZikir(
        tester,
        prefs: {
          'dhikr_count_Sübhanallah': 20,
          ZikirViewModel.roundModeKey: true,
          '${ZikirViewModel.roundPrefix}Sübhanallah': 3,
        },
      );
      final reset = find.byTooltip(loc.resetCounter);
      expect(
        find.descendant(of: find.byType(AppBar), matching: reset),
        findsOneWidget,
      );
      // Altta görünür sıfırla düğmesi yok
      expect(find.text(loc.resetCounter), findsNothing);
      expect(find.text(loc.editCounterTitle), findsOneWidget);

      await tester.tap(reset);
      await _settle(tester);
      expect(find.text(loc.resetCounterConfirm), findsOneWidget);
      await tester.tap(find.text(loc.cancel));
      await _settle(tester);
      expect((_vm(tester).count, _vm(tester).round), (20, 3));

      await tester.tap(reset);
      await _settle(tester);
      await tester.tap(find.text(loc.resetCounter).last);
      await _settle(tester);
      expect((_vm(tester).count, _vm(tester).round), (0, 1));
      await _finish(tester);
    });

    testWidgets(
      'altta bugünkü toplam: sayınca artar, dokununca istatistikler',
      (tester) async {
        final loc = _loc('tr');
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await _pumpZikir(
          tester,
          prefs: {
            'dhikr_daily_stats': jsonEncode({today: 12}),
          },
        );
        expect(find.text(loc.zikirTodayCount(12)), findsOneWidget);
        await tester.tap(find.byKey(ZikirView.counterKey));
        await _settle(tester);
        expect(find.text(loc.zikirTodayCount(13)), findsOneWidget);

        await tester.tap(find.text(loc.zikirTodayCount(13)));
        await _settle(tester);
        expect(find.byType(DhikrStatsView), findsOneWidget);
        await _finish(tester);
      },
    );

    testWidgets('sayacın çevresindeki boş alana dokunmak sayar; başlık ve '
        'düğmeler saymaz', (tester) async {
      final loc = _loc('tr');
      await _pumpZikir(tester, prefs: {'dhikr_count_Sübhanallah': 5});
      final counter = tester.getRect(find.byKey(ZikirView.counterKey));
      final area = tester.getRect(
        find
            .ancestor(
              of: find.byKey(ZikirView.counterKey),
              matching: find.byType(LayoutBuilder),
            )
            .first,
      );
      // Dairenin dışı (sol kenar ve alt köşe)
      await tester.tapAt(Offset(area.left + 6, counter.center.dy));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(Offset(area.right - 6, area.bottom - 6));
      await _settle(tester);
      expect(_vm(tester).count, 7);

      // Başlık kartı (Arapça metin) ve alttaki düğme saymaz
      await tester.tap(find.text('سُبْحَانَ اللَّهِ'));
      await _settle(tester);
      expect(_vm(tester).count, 7);
      await tester.tap(find.text(loc.editCounterTitle));
      await _settle(tester);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text(loc.cancel));
      await _settle(tester);
      expect(_vm(tester).count, 7);
      await _finish(tester);
    });

    testWidgets('klasik tesbih: ilerleme ve tur, karta dokunmak da sayar', (
      tester,
    ) async {
      final loc = _loc('tr');
      await _pumpZikir(
        tester,
        prefs: {'zikir_view_mode': 1, 'dhikr_count_Sübhanallah': 40},
      );
      expect(_progressText('7 / 33'), findsOneWidget);
      expect(find.text(loc.zikirRound(2)), findsOneWidget);
      await tester.tap(find.byKey(ZikirView.counterKey));
      await _settle(tester);
      expect(_vm(tester).count, 41);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    for (final lang in ['tr', 'ar']) {
      for (final classic in [false, true]) {
        testWidgets(
          '$lang ${classic ? 'klasik' : 'modern'}: 320dp %130 yazı, tur ve '
          'hedefte taşma yok',
          (tester) async {
            final loc = _loc(lang);
            await _pumpZikir(
              tester,
              lang: lang,
              width: 320,
              height: 640,
              textScale: 1.3,
              prefs: {
                'zikir_view_mode': classic ? 1 : 0,
                'selected_dhikr': 'Hz. Yunus',
                'dhikr_count_Hz. Yunus': 0,
                '${ZikirViewModel.roundPrefix}Hz. Yunus': 12,
                ZikirViewModel.roundModeKey: true,
              },
            );
            expect(tester.takeException(), isNull);
            expect(find.text(loc.zikirRound(12)), findsOneWidget);
            // Dört düğmeli dar üst çubukta üç noktalı ad yerine kısa ad
            expect(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.text(loc.navZikir),
              ),
              findsOneWidget,
            );
            expect(find.text(loc.targetReached), findsOneWidget);
            for (final dark in [false, true]) {
              await _pumpZikir(
                tester,
                lang: lang,
                width: 320,
                height: 640,
                textScale: 1.3,
                dark: dark,
                prefs: {
                  'zikir_view_mode': classic ? 1 : 0,
                  'dhikr_count_Sübhanallah': 123456,
                  'dhikr_target_Sübhanallah': 1000,
                },
              );
              expect(tester.takeException(), isNull);
            }
            await _finish(tester);
          },
        );
      }
    }
  });

  group('Ses tuşlarıyla say (Dart tarafı)', () {
    testWidgets('ayar kapalıyken yerel tarafa hiç dokunulmaz', (tester) async {
      final tab = await _pumpZikir(tester);
      tab.value = 1;
      await _settle(tester, steps: 2);
      tab.value = 0;
      await _settle(tester, steps: 2);
      await _lifecycle(AppLifecycleState.paused);
      await _lifecycle(AppLifecycleState.resumed);
      await _settle(tester, steps: 2);
      expect(_volumeFlags, isEmpty);
      expect(_volumeListens, 0);
      await _finish(tester);
      expect(_volumeFlags, isEmpty);
    });

    testWidgets('sadece Zikir sekmesi görünür + ayar açık + ön planda: '
        'ses açma +1, ses kısma -1 (sıfırın altına inmez)', (tester) async {
      final tab = await _pumpZikir(
        tester,
        prefs: {
          'dhikr_count_Sübhanallah': 1,
          ZikirViewModel.volumeKeysKey: true,
        },
      );
      expect(_volumeFlags, [true]);
      expect(_volumeListens, 1);
      await _volumeKey(tester, 1);
      await _volumeKey(tester, 1);
      await _settle(tester, steps: 2);
      expect(_vm(tester).count, 3);
      for (var i = 0; i < 5; i++) {
        await _volumeKey(tester, -1);
      }
      await _settle(tester, steps: 2);
      expect(_vm(tester).count, 0);

      // Sekme değişince bırakılır
      tab.value = 1;
      await _settle(tester, steps: 2);
      expect(_volumeFlags, [true, false]);
      expect(_volumeCancels, 1);
      expect(_volumeSink, isNull);
      tab.value = 0;
      await _settle(tester, steps: 2);
      expect(_volumeFlags, [true, false, true]);
      expect(_volumeListens, 2);

      // Arka plan
      await _lifecycle(AppLifecycleState.inactive);
      await _lifecycle(AppLifecycleState.hidden);
      await _lifecycle(AppLifecycleState.paused);
      await _settle(tester, steps: 2);
      expect(_volumeFlags.last, false);
      expect(_volumeSink, isNull);
      await _lifecycle(AppLifecycleState.hidden);
      await _lifecycle(AppLifecycleState.inactive);
      await _lifecycle(AppLifecycleState.resumed);
      await _settle(tester, steps: 2);
      expect(_volumeFlags.last, true);
      expect(_volumeSink, isNotNull);

      // Üstüne açılan pencere (sıfırla onayı) ve sayfa
      await tester.tap(find.byTooltip(_loc('tr').resetCounter));
      await _settle(tester, steps: 3);
      expect(_volumeFlags.last, false);
      await tester.tap(find.text(_loc('tr').cancel));
      await _settle(tester, steps: 3);
      expect(_volumeFlags.last, true);
      await tester.tap(find.byTooltip(_loc('tr').zikirSettings));
      await _settle(tester);
      expect(_volumeFlags.last, false);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await _settle(tester);
      expect(_volumeFlags.last, true);

      // Ayar kapatılınca
      await _vm(tester).toggleVolumeKeys(false);
      await _settle(tester, steps: 2);
      expect(_volumeFlags.last, false);
      expect(_volumeSink, isNull);
      await _vm(tester).toggleVolumeKeys(true);
      await _settle(tester, steps: 2);
      expect(_volumeFlags.last, true);

      // Değerler ardışık tekrar etmez (her değişimde bir çağrı)
      for (var i = 1; i < _volumeFlags.length; i++) {
        expect(_volumeFlags[i], isNot(_volumeFlags[i - 1]));
      }
      expect(_volumeListens - _volumeCancels, 1);

      // Ekran kapanınca bırakılır
      await _finish(tester);
      expect(_volumeFlags.last, false);
      expect(_volumeSink, isNull);
    });

    testWidgets('tur kipinde ses tuşu: hedefte tur artar, -1 turun başında '
        'durur', (tester) async {
      await _pumpZikir(
        tester,
        prefs: {
          'dhikr_count_Sübhanallah': 32,
          ZikirViewModel.roundModeKey: true,
          ZikirViewModel.volumeKeysKey: true,
        },
      );
      await _volumeKey(tester, 1);
      await _settle(tester, steps: 2);
      expect((_vm(tester).count, _vm(tester).round), (0, 2));
      await _volumeKey(tester, -1);
      await _settle(tester, steps: 2);
      expect((_vm(tester).count, _vm(tester).round), (0, 2));
      await _finish(tester);
    });
  });
}
