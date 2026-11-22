// Ramazan sayacı paylaşımı: kart metni ("Ramazan · 13. gün", "İftara 3 sa
// 12 dk", "İstanbul / Kadıköy · İftar 18:12"), düğme sadece Ramazan'da,
// paylaşım metni kampanyalı (iftar) Play bağlantısıyla biter.
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/home/widgets/ramadan_card.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _times = PrayerTimesModel(
  imsak: '05:52',
  gunes: '07:18',
  ogle: '13:22',
  ikindi: '16:17',
  aksam: '18:12',
  yatsi: '19:33',
);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// 320dp ekran; hero gibi yanlarda 16dp boşluk
Future<void> _pumpCard(
  WidgetTester tester,
  DateTime now, {
  String lang = 'tr',
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel()
        ..city = 'İstanbul'
        ..district = 'Kadıköy',
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: AppColors.brand,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: RamadanCard(prayerTimes: _times, clock: () => now),
            ),
          ),
        ),
      ),
    ),
  );
  // Takvim (önceden, gerçek bölgede yüklendi): geri çağrısı gerçek olay
  // döngüsünde çalışır → ilk tik → çizim
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() async {
    // Gerçek yazı tipleri: taşma denetimi cihazdaki ölçülere yakın olsun
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
    // Önbelleklenen Future sahte zaman bölgesinde oluşmasın
    await loadRamadanCalendar();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Paylaşım metni', () {
    final tr = lookupAppLocalizations(const Locale('tr'));

    test('iftar: gün, kalan süre (sa/dk), konum ve iftar saati', () {
      final content = ramadanShareContent(
        tr,
        countdown: RamadanCountdown(
          phase: RamadanPhase.iftar,
          target: DateTime(2027, 2, 20, 18, 12),
          fastDay: 13,
        ),
        remaining: const Duration(hours: 1, minutes: 11, seconds: 20),
        place: 'İstanbul',
      );
      expect(content.title, 'Ramazan · 13. gün');
      expect(content.message, 'İftara 1 sa 12 dk');
      expect(content.subtitle, 'İstanbul · İftar 18:12');
    });

    test('sahur: dakikaya yukarı yuvarlanır; konum yoksa sadece saat', () {
      final countdown = RamadanCountdown(
        phase: RamadanPhase.sahur,
        target: DateTime(2027, 2, 21, 5, 52),
        fastDay: 14,
      );
      final content = ramadanShareContent(
        tr,
        countdown: countdown,
        remaining: const Duration(seconds: 30),
      );
      expect(content.message, 'Sahura 1 dk');
      expect(content.subtitle, 'İmsak 05:52');

      final en = ramadanShareContent(
        lookupAppLocalizations(const Locale('en')),
        countdown: countdown,
        remaining: const Duration(hours: 2),
        place: 'Istanbul',
      );
      expect(en.title, 'Ramadan · Day 14');
      expect(en.message, 'Suhoor ends in 2 h');
      expect(en.subtitle, 'Istanbul · Imsak 5:52 AM');
    });
  });

  testWidgets('Ramazan dışında sayaç ve paylaş düğmesi yok', (tester) async {
    await _pumpCard(tester, DateTime(2026, 10, 10, 15));
    final loc = lookupAppLocalizations(const Locale('tr'));
    expect(find.byTooltip(loc.share), findsNothing);
    expect(find.text(loc.ramadanIftarLeft), findsNothing);
    await _dispose(tester);
  });

  for (final lang in ['tr', 'ar']) {
    testWidgets('$lang: Ramazan\'da paylaş düğmesi, %130 yazıda taşmaz', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        DateTime(2027, 2, 20, 15),
        lang: lang,
        textScale: 1.3,
      );
      final loc = lookupAppLocalizations(Locale(lang));
      expect(find.text(loc.ramadanIftarLeft), findsOneWidget);
      expect(find.text(loc.ramadanDayLabel(13)), findsOneWidget);
      expect(find.byTooltip(loc.share), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip(loc.share)).height,
        greaterThanOrEqualTo(AppSizes.minTouch),
      );
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });
  }

  testWidgets(
    'resimli paylaşım: metin "Ramazan · 13. gün" + iftar bağlantısı',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync('vaktinde_ramadan');
      addTearDown(() => temp.deleteSync(recursive: true));
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => temp.path,
      );
      MethodCall? shared;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          shared = call;
          return 'dev.fluttercommunity.plus/share/success';
        },
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          null,
        );
      });

      await _pumpCard(tester, DateTime(2027, 2, 20, 15));
      final loc = lookupAppLocalizations(const Locale('tr'));
      await tester.tap(find.byTooltip(loc.share));
      // Kart çizimi, PNG ve geçici dosya gerçek zaman ister; paylaşımdan sonra
      // birkaç tur daha: shareAsImage tamamlansın (tekrar paylaşım kilidi)
      for (var i = 0, after = 0; i < 100 && after < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        if (shared != null) after++;
      }
      expect(shared?.method, 'shareFiles');
      final text = (shared!.arguments as Map)['text'] as String;
      expect(text, shareCaption('Ramazan · 13. gün', 'iftar'));
      expect(text, endsWith(AppLinks.playStoreLink('iftar')));
      expect(find.byType(ShareCard), findsNothing);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );
}
