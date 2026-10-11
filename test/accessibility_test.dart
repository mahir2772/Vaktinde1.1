// Erişilebilirlik (TalkBack): geri sayım dakikalık tek etiket (saniyeler
// okunmaz), vakit ızgarası/satırı durumu sözle, takip hücreleri "gün, vakit:
// durum" düğmesi + gün adında basılı tutma ipucu, kıble pusulası yuvarlanmış
// dönüş yönergesi ve kıbleye girince tek canlı bölge, ikon düğmelerinde ipucu,
// %200 yazıda günün ayeti/hadisi başlığı kesilmez.
import 'dart:async';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/hadith_model.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/home/widgets/countdown_widget.dart';
import 'package:ezan_saati/features/home/widgets/daily_content.dart';
import 'package:ezan_saati/features/home/widgets/prayer_times_grid.dart';
import 'package:ezan_saati/features/home/widgets/ramadan_card.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/features/imsakiye/ramadan_calendar_loader.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/qibla/qibla_math.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _times = PrayerTimesModel(
  imsak: '05:00',
  gunes: '06:30',
  ogle: '13:00',
  ikindi: '16:00',
  aksam: '18:30',
  yatsi: '20:00',
);

const double _istanbulLat = 41.0082;
const double _istanbulLng = 28.9784;

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String lang = 'tr',
  double width = 411,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 891 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

/// Ana ekran hero'su gibi: koyu zemin, yanlarda 16dp
Widget _hero(Widget child) => Scaffold(
  backgroundColor: AppColors.brand,
  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Center(child: child),
  ),
);

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Gerçek yazı tipi: %200 yerleşim ölçüleri cihazdakine yakın olsun
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    // Önbelleklenen Future sahte zaman bölgesinde oluşmasın
    await loadRamadanCalendar();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Kalan süre metni (dakika hassasiyeti)', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    test('saat ve dakika; saniyeler atılır, 1 dakikanın altı "1 dakika"', () {
      String tr0(Duration d) => formatSpokenDuration(d, tr);
      expect(
        tr0(const Duration(hours: 1, minutes: 12, seconds: 59)),
        '1 saat 12 dakika',
      );
      expect(tr0(const Duration(hours: 1, minutes: 12)), '1 saat 12 dakika');
      expect(tr0(const Duration(hours: 2)), '2 saat');
      expect(tr0(const Duration(minutes: 45, seconds: 30)), '45 dakika');
      expect(tr0(const Duration(seconds: 30)), '1 dakika');
      expect(tr0(const Duration(seconds: -5)), '1 dakika');
      expect(
        formatSpokenDuration(const Duration(hours: 1, minutes: 1), en),
        '1 hour 1 minute',
      );
      expect(
        formatSpokenDuration(const Duration(hours: 3, minutes: 20), en),
        '3 hours 20 minutes',
      );
      expect(
        formatSpokenDuration(const Duration(hours: 2, minutes: 5), ar),
        'ساعتان و5 دقائق',
      );
    });
  });

  group('Geri sayım', () {
    testWidgets('tr: tek etiket dakikada bir değişir, saniyeler okunmaz', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 11, 11, 47, 10); // öğleye 1:12:50
      await _pump(
        tester,
        _hero(CountdownWidget(prayerTimes: _times, clock: () => now)),
      );
      String label() => tester.getSemantics(find.byType(CountdownWidget)).label;
      String digits() =>
          tester.widget<TabularText>(find.byType(TabularText)).text;

      const expected =
          'Sıradaki Vakit: Öğle, 13:00. Öğle vaktine 1 saat 12 dakika kaldı';
      expect(label(), expected);
      expect(digits(), '01:12:50');
      // Saniyeli sayaç ayrı bir düğüm değil
      expect(find.bySemanticsLabel(RegExp(r'\d\d:\d\d:\d\d')), findsNothing);

      // Aynı dakika içinde her saniye: rakamlar değişir, etiket değişmez
      for (var i = 0; i < 49; i++) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(label(), expected, reason: digits());
      }
      expect(digits(), '01:12:01');

      // Dakika dönünce bir kez değişir
      now = DateTime(2026, 10, 11, 11, 48, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(digits(), '01:11:59');
      expect(
        label(),
        'Sıradaki Vakit: Öğle, 13:00. Öğle vaktine 1 saat 11 dakika kaldı',
      );
      await _dispose(tester);
    });

    testWidgets('en: 12 saat biçimi ve İngilizce süre', (tester) async {
      final now = DateTime(2026, 10, 11, 15, 30, 40); // ikindiye 0:29:20
      await _pump(
        tester,
        _hero(CountdownWidget(prayerTimes: _times, clock: () => now)),
        lang: 'en',
      );
      expect(
        tester.getSemantics(find.byType(CountdownWidget)).label,
        'Next Prayer: Asr, 4:00 PM. 29 minutes left until Asr',
      );
      await _dispose(tester);
    });

    testWidgets('Ramazan kapsülü: iftara kalan süre dakikalık', (tester) async {
      var now = DateTime(2027, 2, 20, 15, 0, 10); // 13. gün, iftar 18:12
      final times = PrayerTimesModel(
        imsak: '05:52',
        gunes: '07:18',
        ogle: '13:22',
        ikindi: '16:17',
        aksam: '18:12',
        yatsi: '19:33',
      );
      await _pump(
        tester,
        _hero(RamadanCard(prayerTimes: times, clock: () => now)),
      );
      // Takvim geri çağrısı gerçek olay döngüsünde → ilk tik → çizim
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await tester.pump();
      const expected = "İftara Kalan 3 saat 11 dakika. Ramazan'ın 13. günü";
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'\d\d:\d\d:\d\d')), findsNothing);
      await _dispose(tester);
    });
  });

  group('Vakit ızgarası ve satırı', () {
    testWidgets('ızgara: ad, saat ve durum (sıradaki / geçti / şu an)', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 11, 11, 47);
      await _pump(
        tester,
        Scaffold(
          body: ListView(
            children: [PrayerTimesGrid(prayerTimes: _times, clock: () => now)],
          ),
        ),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      for (final label in [
        'İmsak, 05:00, ${loc.a11yPrayerPassed}',
        'Güneş, 06:30, ${loc.a11yPrayerPassed}, ${loc.sunriseNotPrayer}',
        'Öğle, 13:00, ${loc.nextPrayer}',
        'İkindi, 16:00',
        'Akşam, 18:30',
        'Yatsı, 20:00',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      expect(loc.a11yPrayerPassed, 'geçti');

      // Öğle girince: öğle "şu an", ikindi sıradaki (5 sn'de bir denetlenir)
      now = DateTime(2026, 10, 11, 13, 5);
      await tester.pump(const Duration(seconds: 5));
      expect(
        find.bySemanticsLabel('Öğle, 13:00, ${loc.currentPrayer}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('İkindi, 16:00, ${loc.nextPrayer}'),
        findsOneWidget,
      );
      await _dispose(tester);
    });

    testWidgets('PrayerTimeRow: durum sözle, düğme ve seçili', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: ListView(
            children: [
              PrayerTimeRow(
                name: 'Öğle',
                time: '13:00',
                state: PrayerRowState.next,
                trailing: const Icon(Icons.alarm_on),
                onTap: () {},
              ),
              const PrayerTimeRow(
                name: 'İmsak',
                time: '05:00',
                state: PrayerRowState.past,
              ),
            ],
          ),
        ),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Öğle, 13:00, ${loc.nextPrayer}'),
        ),
        containsSemantics(isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel('İmsak, 05:00, geçti'), findsOneWidget);
      await _dispose(tester);
    });
  });

  group('Namaz takibi ızgarası', () {
    String dk(int daysAgo) =>
        PrayerTracker.dateKey(PrayerTracker.addDays(DateTime.now(), -daysAgo));

    testWidgets('hücre: "gün, vakit: durum" düğmesi; gün adı basılı tutma '
        'ipucu', (tester) async {
      SharedPreferences.setMockInitialValues({
        'prayer_log_since': dk(6),
        'prayer_log':
            '{"${dk(1)}":${PrayerTracker.fullMask},'
            '"${dk(4)}":${PrayerTracker.bit('Öğle')}}',
        'prayer_kaza_added': '{"${dk(3)}":${PrayerTracker.fullMask}}',
        'tracker_excused': [dk(2)],
      });
      // Banner reklam kanalı
      _messenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (message) async =>
            const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
      addTearDown(
        () => _messenger.setMockMessageHandler(
          'plugins.flutter.io/google_mobile_ads',
          null,
        ),
      );
      await _pump(
        tester,
        PrayerTrackerView(
          fastClock: () => DateTime(2026, 10, 10),
          ramadanCalendar: RamadanCalendar.hijriOnly,
        ),
      );
      await tester.pumpAndSettle();
      final loc = lookupAppLocalizations(const Locale('tr'));
      String weekday(int daysAgo) => DateFormat(
        'EEEE',
        'tr',
      ).format(PrayerTracker.addDays(DateTime.now(), -daysAgo));

      final cells = {
        'Dün, Öğle: ${loc.trackerLegendPrayed}': true,
        '${weekday(2)}, Öğle: ${loc.a11yExcusedDay}': false,
        '${weekday(3)}, Sabah: ${loc.trackerLegendKaza}': true,
        '${weekday(4)}, Öğle: ${loc.trackerLegendPrayed}': true,
        '${weekday(4)}, İkindi: ${loc.a11yNotPrayed}': true,
        // Vakitler bilinmiyor: bugünün vakitleri henüz girmemiş sayılır
        'Bugün, Yatsı: ${loc.a11yNotDue}': true,
      };
      for (final MapEntry(key: label, value: enabled) in cells.entries) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node,
          containsSemantics(
            label: label,
            isButton: true,
            hasTapAction: true,
            hasEnabledState: !enabled,
            isEnabled: enabled ? null : false,
          ),
          reason: label,
        );
        // Durum işaretli/işaretsiz kutu olarak ikinci kez okunmaz
        expect(
          node.getSemanticsData().hasFlag(SemanticsFlag.hasCheckedState),
          isFalse,
          reason: label,
        );
      }
      expect(
        loc.a11yTrackerCell('Pazartesi', 'Öğle', 'Kılındı'),
        'Pazartesi, Öğle: Kılındı',
      );

      // Gün adı: kısaltma yerine tam ad; özel gün değeri ve basılı tutma ipucu
      final excusedDay = tester.getSemantics(find.bySemanticsLabel(weekday(2)));
      expect(excusedDay.value, loc.a11yExcusedDay);
      expect(excusedDay, containsSemantics(hasLongPressAction: true));
      expect(
        excusedDay.hintOverrides?.onLongPressHint,
        loc.trackerExcusedUnmark,
      );
      final yesterday = tester.getSemantics(
        find.bySemanticsLabel(loc.trackerYesterday),
      );
      expect(yesterday, containsSemantics(hasLongPressAction: true));
      expect(yesterday.hintOverrides?.onLongPressHint, loc.trackerExcusedMark);

      // Hücreye ekran okuyucuyla dokunma işareti değiştirir
      final prayedLabel = 'Dün, Akşam: ${loc.trackerLegendPrayed}';
      tester.semantics.tap(find.semantics.byLabel(prayedLabel));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(prayedLabel), findsNothing);
      expect(
        find.bySemanticsLabel('Dün, Akşam: ${loc.a11yNotPrayed}'),
        findsOneWidget,
      );
      await _dispose(tester);
    });

    test('fransızca: iki noktadan önce bölünmez boşluk', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(
        fr.a11yTrackerCell('Lundi', 'Dhuhr', fr.a11yNotPrayed),
        'Lundi, Dhuhr\u00a0: Non accomplie',
      );
    });
  });

  group('Kıble', () {
    test('dönüş açısı 5°\'lik adımlarla; hizadaysa 0', () {
      expect(spokenTurnDegrees(130, 151.6), 20);
      expect(spokenTurnDegrees(131.5, 151.6), 20);
      expect(spokenTurnDegrees(128, 151.6), 25);
      expect(spokenTurnDegrees(170, 151.6), -20);
      expect(spokenTurnDegrees(147, 151.6), 5); // 4,6° → en az 5
      expect(spokenTurnDegrees(150, 151.6), 0);
      // Arkası dönükken en kısa yön: 178,6° sağa / 178,4° sola
      expect(spokenTurnDegrees(333, 151.6), 180);
      expect(spokenTurnDegrees(330, 151.6), -180);
      final tr = lookupAppLocalizations(const Locale('tr'));
      expect(
        tr.a11yQiblaTurnRight(20),
        'Kıbleye dönmek için 20 derece sağa dönün',
      );
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        en.a11yQiblaTurnLeft(1),
        'Turn 1 degree to the left to face the qibla',
      );
      expect(
        en.a11yQiblaTurnLeft(15),
        'Turn 15 degrees to the left to face the qibla',
      );
    });

    group('pusula', () {
      setUp(() {
        _messenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (call) async => switch (call.method) {
            'isLocationServiceEnabled' => true,
            'checkPermission' => 2, // whileInUse
            'getLastKnownPosition' || 'getCurrentPosition' => {
              'latitude': _istanbulLat,
              'longitude': _istanbulLng,
              'timestamp': DateTime(2026).millisecondsSinceEpoch,
              'accuracy': 10.0,
              'altitude': 0.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
            },
            _ => null,
          },
        );
        // Sapma 0: yön olduğu gibi
        _messenger.setMockMethodCallHandler(
          const MethodChannel('vaktinde/device'),
          (call) async => call.method == 'geomagnetic'
              ? {'declination': 0.0, 'strength': 45.0}
              : null,
        );
        _messenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
      });

      tearDown(() {
        _messenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          null,
        );
        _messenger.setMockMethodCallHandler(
          const MethodChannel('vaktinde/device'),
          null,
        );
        _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      testWidgets('kadran yuvarlanmış yönerge okur (canlı bölge değil); '
          'kıbleye girilince tek canlı bölge', (tester) async {
        SharedPreferences.setMockInitialValues({
          'saved_lat': _istanbulLat,
          'saved_lng': _istanbulLng,
          'qibla_calibration_dialog_seen': true,
        });
        // Eşzamanlı: olay aynı pump'ta çizilir
        final compass = StreamController<CompassEvent>.broadcast(sync: true);
        addTearDown(compass.close);
        await _pump(
          tester,
          Scaffold(
            body: QiblaView(
              compassEvents: () => compass.stream,
              magneticEvents: () => null,
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final loc = lookupAppLocalizations(const Locale('tr'));
        Future<void> heading(double degrees) async {
          compass.add(CompassEvent.fromList([degrees, degrees, 15]));
          await tester.pump();
        }

        final turn20 = RegExp(RegExp.escape(loc.a11yQiblaTurnRight(20)));
        await heading(130); // kıble 151,6°: 21,6° sağa
        final dial = find.bySemanticsLabel(turn20);
        expect(dial, findsOneWidget);
        final dialNode = tester.getSemantics(dial);
        expect(dialNode.label, startsWith(loc.qiblaDirection));
        expect(
          dialNode.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion),
          isFalse,
        );
        // Küçük titreşim etiketi değiştirmez
        await heading(131);
        await heading(130.5);
        expect(find.bySemanticsLabel(turn20), findsOneWidget);
        expect(find.bySemanticsLabel(loc.a11yQiblaAligned), findsNothing);

        // Kıbleye dönülünce: canlı bölge "Kıble yönündesiniz" (bir kez)
        for (var i = 0; i < 40; i++) {
          await heading(151.6);
        }
        final aligned = find.bySemanticsLabel(loc.a11yQiblaAligned);
        expect(aligned, findsOneWidget);
        expect(
          tester.getSemantics(aligned),
          containsSemantics(isLiveRegion: true),
        );
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(loc.qiblaFound))),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel(
            RegExp('${RegExp.escape(loc.a11yQiblaAligned)}\$'),
          ),
          findsNWidgets(2), // canlı bölge + kadran
        );

        // Çıkınca canlı bölge kalkar
        for (var i = 0; i < 40; i++) {
          await heading(100);
        }
        expect(aligned, findsNothing);
        await _dispose(tester);
      });
    });
  });

  group('İkon düğmeleri ve büyük yazı', () {
    testWidgets('CounterStepper: −/+ ipucu; değere dokunma eylemi', (
      tester,
    ) async {
      var tapped = 0;
      await _pump(
        tester,
        Scaffold(
          body: Center(
            child: CounterStepper(
              value: 3,
              onChanged: (_) {},
              semanticLabel: 'Sabah',
              onValueTap: () => tapped++,
            ),
          ),
        ),
      );
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.byTooltip(loc.a11yDecrease), findsOneWidget);
      expect(find.byTooltip(loc.a11yIncrease), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Sabah'));
      expect(
        node,
        containsSemantics(
          value: '3',
          hasTapAction: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Sabah'));
      await tester.pump();
      expect(tapped, 1);
      await _dispose(tester);
    });

    testWidgets('de %200: ızgarada uzun vakit adı kesilmez, hücreler eşit', (
      tester,
    ) async {
      await _pump(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              PrayerTimesGrid(
                prayerTimes: _times,
                clock: () => DateTime(2026, 10, 11, 11, 47),
              ),
            ],
          ),
        ),
        lang: 'de',
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final de = lookupAppLocalizations(const Locale('de'));
      expect(de.gunes, 'Sonnenaufgang');
      expect(
        tester.renderObject<RenderParagraph>(find.text(de.gunes)),
        isA<RenderParagraph>().having(
          (p) => p.didExceedMaxLines,
          'didExceedMaxLines',
          isFalse,
        ),
      );
      Size cell(String name) => tester.getSize(
        find
            .ancestor(of: find.text(name), matching: find.byType(Container))
            .first,
      );
      expect(cell(de.gunes).height, cell(de.imsak).height);
      await _dispose(tester);
    });

    for (final (scale, stacked) in [(1.0, false), (1.3, false), (2.0, true)]) {
      testWidgets('de %${(scale * 100).round()}: günün ayeti/hadisi başlığı '
          'kesilmez${stacked ? ' (alt alta)' : ''}', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                DailyContentRow(
                  ayah: AyahModel(
                    number: 293,
                    surahName: 'Bakara',
                    numberInSurah: 286,
                    arabicText:
                        'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
                    translatedText:
                        'Allah verlangt von keiner Seele mehr, '
                        'als sie zu leisten vermag.',
                  ),
                  hadith: HadithModel(
                    content: 'Die Taten werden nach den Absichten bewertet.',
                    source: 'Buhari',
                  ),
                ),
              ],
            ),
          ),
          lang: 'de',
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final de = lookupAppLocalizations(const Locale('de'));
        for (final title in [de.dailyAyahTitle, de.hadithTitle]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(title),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: title);
        }
        expect(
          find.descendant(
            of: find.byType(DailyContentRow),
            matching: find.byType(IntrinsicHeight),
          ),
          stacked ? findsNothing : findsOneWidget,
        );
        await _dispose(tester);
      });
    }
  });
}
