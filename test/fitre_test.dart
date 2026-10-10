// Fitre ve fidye: tutar seçimi (tarih, uzak dosya, bozuk uzak dosya → gömülü),
// önbellek, hesap ekranı (toplamlar, elle tutar) ve tr/ar %130 yazıda taşmama.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/fitre_service.dart';
import 'package:ezan_saati/features/fitre/view/fitre_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _json(List<Object?> amounts, {String currency = 'TRY'}) =>
    jsonEncode({'currency': currency, 'amounts': amounts});

final String _bundled = _json([
  {'validFrom': '2025-02-27', 'amount': 130, 'source': 'Diyanet'},
  {'validFrom': '2026-02-18', 'amount': 240, 'source': 'Diyanet'},
]);

final DateTime _today = DateTime(2026, 10, 10, 15, 30);

FitreService _service({Future<String?> Function(Uri url)? fetch}) =>
    FitreService(
      loadAsset: () async => _bundled,
      fetch: fetch ?? (_) async => null,
    );

double? _amountAt(List<FitreAmount> entries, DateTime day) =>
    FitreService.select(entries, day)?.amount;

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('Tutar seçimi', () {
    test('başlangıcı bugün ya da önce olan en yeni kayıt', () {
      final entries = FitreService.parse(_bundled);
      expect(entries, hasLength(2));
      expect(_amountAt(entries, DateTime(2025, 1, 1)), isNull);
      expect(_amountAt(entries, DateTime(2025, 2, 27)), 130);
      expect(_amountAt(entries, DateTime(2026, 2, 17, 23, 59)), 130);
      expect(_amountAt(entries, DateTime(2026, 2, 18)), 240);
      expect(_amountAt(entries, _today), 240);
      // Sıra değil tarih belirler
      expect(_amountAt(entries.reversed.toList(), _today), 240);

      final selected = FitreService.select(entries, _today)!;
      expect(selected.currency, 'TRY');
      expect(selected.source, 'Diyanet');
      expect(selected.validFrom, DateTime(2026, 2, 18));
    });

    test('bozuk kayıt atlanır, bozuk dosya boş liste', () {
      for (final raw in [
        null,
        '',
        'bozuk',
        '<html>404</html>',
        '[]',
        '{"amounts":[{"validFrom":"2026-02-18","amount":240}]}',
        '{"currency":"","amounts":[{"validFrom":"2026-02-18","amount":240}]}',
        '{"currency":"TRY","amounts":{}}',
        '{"currency":"TRY","amounts":[]}',
      ]) {
        expect(FitreService.parse(raw), isEmpty, reason: raw);
      }
      final entries = FitreService.parse(
        _json([
          {'validFrom': '2026-02-18', 'amount': -5},
          {'validFrom': '2026-02-18', 'amount': 0},
          {'validFrom': '2026-02-18', 'amount': '240'},
          {'validFrom': '2026-02-30', 'amount': 240},
          {'validFrom': '18.02.2026', 'amount': 240},
          {'amount': 240},
          'kayıt',
          {'validFrom': '2026-03-01', 'amount': 250.5},
        ]),
      );
      expect(entries, hasLength(1));
      expect(entries.single.amount, 250.5);
      expect(entries.single.source, 'Diyanet'); // kaynak yoksa
    });

    test('uzak dosya: aynı tarihte uzak kazanır, eskisi yeni gömülüyü ezmez', () {
      final bundled = FitreService.parse(_bundled);
      List<FitreAmount> withRemote(String remote) => [
        ...bundled,
        ...FitreService.parse(remote),
      ];

      // Düzeltme: aynı başlangıç tarihi
      final fix = _json([
        {'validFrom': '2026-02-18', 'amount': 250, 'source': 'Diyanet'},
      ]);
      expect(_amountAt(withRemote(fix), _today), 250);

      // Yeni yıl tutarı önceden yayımlandı: günü gelince geçerli
      final next = _json([
        {'validFrom': '2027-02-07', 'amount': 300, 'source': 'Diyanet'},
      ]);
      expect(_amountAt(withRemote(next), _today), 240);
      expect(_amountAt(withRemote(next), DateTime(2027, 2, 7)), 300);

      // Güncellenmemiş eski uzak dosya, uygulamadaki yeni tutarı ezmez
      final stale = _json([
        {'validFrom': '2025-02-27', 'amount': 130, 'source': 'Diyanet'},
      ]);
      expect(_amountAt(withRemote(stale), _today), 240);

      // Başka para birimi kaydıyla gelir
      final eur = _json([
        {'validFrom': '2026-03-01', 'amount': 10, 'source': 'DITIB'},
      ], currency: 'EUR');
      final selected = FitreService.select(withRemote(eur), _today)!;
      expect(selected.currency, 'EUR');
      expect(selected.source, 'DITIB');
    });

    test('gömülü dosya ve GitHub Pages kopyası (docs/site) aynı', () {
      final asset = File('assets/data/fitre.json').readAsStringSync();
      final site = File('docs/site/fitre.json').readAsStringSync();
      expect(jsonDecode(site), jsonDecode(asset));
      final selected = FitreService.select(FitreService.parse(asset), _today)!;
      expect(selected.amount, 240);
      expect(selected.currency, 'TRY');
      expect(selected.source, 'Diyanet');
      expect(selected.validFrom.year, 2026);
      expect(
        FitreService.remoteUrl.toString(),
        'https://mahir2772.github.io/fitre.json',
      );
    });
  });

  group('FitreService (önbellek, ağ)', () {
    final remote = _json([
      {'validFrom': '2026-09-01', 'amount': 260, 'source': 'Diyanet'},
    ]);

    test('geçerli uzak dosya saklanır, ağ yokken de kullanılır', () async {
      SharedPreferences.setMockInitialValues({});
      final urls = <Uri>[];
      final online = _service(
        fetch: (url) async {
          urls.add(url);
          return remote;
        },
      );
      expect((await online.loadLocal(_today))!.amount, 240);
      expect(urls, isEmpty); // yerel okuma ağa çıkmaz
      expect((await online.refresh(_today))!.amount, 260);
      expect(urls, [FitreService.remoteUrl]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(FitreService.cacheKey), remote);

      final offline = _service(fetch: (_) async => throw const SocketException('yok'));
      expect((await offline.loadLocal(_today))!.amount, 260);
      expect((await offline.refresh(_today))!.amount, 260);
      // Saklanan dosya da tarihe uyar
      expect((await offline.loadLocal(DateTime(2026, 8, 31)))!.amount, 240);
    });

    test('bozuk ya da boş uzak dosya → gömülü; saklanan iyi dosya korunur', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      for (final bad in ['<html>404</html>', '{"currency":"TRY","amounts":[]}']) {
        expect(
          (await _service(fetch: (_) async => bad).refresh(_today))!.amount,
          240,
        );
        expect(prefs.getString(FitreService.cacheKey), isNull);
      }
      // HTTP hata kodu (null) ve zaman aşımı
      expect((await _service().refresh(_today))!.amount, 240);
      expect(
        (await _service(
          fetch: (_) => Future<String?>.error(TimeoutException('zaman aşımı')),
        ).refresh(_today))!.amount,
        240,
      );

      await _service(fetch: (_) async => remote).refresh(_today);
      expect(prefs.getString(FitreService.cacheKey), remote);
      final broken = _service(fetch: (_) async => '{"currency":"TRY"');
      expect((await broken.refresh(_today))!.amount, 260);
      expect(prefs.getString(FitreService.cacheKey), remote);
    });

    test('gömülü dosya okunamazsa da çökmez', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FitreService(
        loadAsset: () => Future<String>.error(FlutterError('yok')),
        fetch: (_) async => null,
      );
      expect(await service.loadLocal(_today), isNull);
      expect(await service.refresh(_today), isNull);
    });
  });

  group('Ekran', () {
    setUpAll(() async {
      await _loadFont('Poppins', [
        for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'assets/google_fonts/Poppins-$w.ttf',
      ]);
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      messenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (message) async =>
            const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    });

    Future<void> pumpFitre(
      WidgetTester tester, {
      String lang = 'tr',
      bool dark = false,
      double width = 411,
      double height = 891,
      double textScale = 1,
      FitreService? service,
    }) async {
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FitreView(service: service ?? _service(), clock: () => _today),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> dispose(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> tapTimes(WidgetTester tester, Finder finder, int times) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      for (var i = 0; i < times; i++) {
        await tester.tap(finder);
        await tester.pump();
      }
    }

    testWidgets('kişi ve gün sayısıyla toplam; elle tutar ve varsayılana dönüş', (
      tester,
    ) async {
      await pumpFitre(tester);
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.fitreInfo), findsOneWidget);
      expect(find.text(loc.fitreSource('Diyanet', '2026')), findsOneWidget);
      expect(find.widgetWithText(TextField, '240'), findsOneWidget);
      expect(find.text('240 ₺'), findsNWidgets(2));
      expect(find.byTooltip(loc.fitreResetAmount), findsNothing);

      final addPeople = find.widgetWithIcon(IconButton, Icons.add).first;
      final addDays = find.widgetWithIcon(IconButton, Icons.add).last;
      await tapTimes(tester, addPeople, 2); // 3 kişi
      expect(find.text('720 ₺'), findsOneWidget);
      await tapTimes(tester, addDays, 40); // en çok 30 gün
      expect(find.text('7.200 ₺'), findsOneWidget);
      expect(tester.widget<IconButton>(addDays).onPressed, isNull);

      // Başka ülke / başka tutar: para birimi gösterilmez
      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();
      expect(find.text('900'), findsOneWidget);
      expect(find.text('9.000'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12,5');
      await tester.pump();
      expect(find.text('37,50'), findsOneWidget);
      expect(find.text('375,00'), findsOneWidget);

      await tester.tap(find.byTooltip(loc.fitreResetAmount));
      await tester.pump();
      expect(find.widgetWithText(TextField, '240'), findsOneWidget);
      expect(find.text('720 ₺'), findsOneWidget);
      expect(find.text('7.200 ₺'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('uzak dosyada yeni tutar: değiştirilmemiş alan güncellenir', (
      tester,
    ) async {
      final remote = _json([
        {'validFrom': '2026-09-01', 'amount': 260, 'source': 'Diyanet'},
      ]);
      await pumpFitre(tester, service: _service(fetch: (_) async => remote));
      expect(find.widgetWithText(TextField, '260'), findsOneWidget);
      expect(find.text('260 ₺'), findsNWidgets(2));
      await dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      for (final dark in [false, true]) {
        testWidgets('$lang ${dark ? 'koyu' : 'açık'}: 320dp, %130 yazı, '
            'taşma yok', (tester) async {
          await pumpFitre(
            tester,
            lang: lang,
            dark: dark,
            width: 320,
            height: 640,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          final loc = lookupAppLocalizations(Locale(lang));
          expect(find.text(loc.fitreTitle), findsOneWidget);
          // Uzun toplam da sığar (elle büyük tutar, 50 kişi)
          await tester.enterText(find.byType(TextField), '999999999');
          await tapTimes(
            tester,
            find.widgetWithIcon(IconButton, Icons.add).first,
            60,
          );
          for (var i = 0; i < 8; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -300));
            await tester.pump();
          }
          expect(find.text(loc.fidyeDaysLabel), findsOneWidget);
          expect(tester.takeException(), isNull);
          await dispose(tester);
        });
      }
    }
  });
}
