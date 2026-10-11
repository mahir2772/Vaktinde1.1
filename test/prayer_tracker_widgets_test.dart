import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/home/widgets/kerahat_card.dart';
import 'package:ezan_saati/features/home/widgets/prayer_tracker_row.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/features/settings/view/end_reminder_setting.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ramazan orucu kartı gizli: testler çalıştıkları tarihten bağımsız
PrayerTrackerView _trackerView() => PrayerTrackerView(
  fastClock: () => DateTime(2026, 10, 10),
  ramadanCalendar: RamadanCalendar.hijriOnly,
);

Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/google_fonts/Poppins-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  String hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String dk(int daysAgo) =>
      PrayerTracker.dateKey(PrayerTracker.addDays(DateTime.now(), -daysAgo));

  Future<void> pumpApp(WidgetTester tester, String lang, Widget home) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Banner reklam kanalı
    messenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async =>
          const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
    testWidgets('Ana ekran: kerahat ve "Bugün" satırı $lang taşmadan', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      // Güneş şu an doğdu: kerahat sürüyor; imsak gece yarısı (işaretlenebilir)
      final times = PrayerTimesModel(
        imsak: '00:00',
        gunes: hhmm(DateTime.now()),
        ogle: '23:59',
        ikindi: '23:59',
        aksam: '23:59',
        yatsi: '23:59',
      );
      await pumpApp(
        tester,
        lang,
        Scaffold(
          body: ListView(
            children: [
              KerahatCard(prayerTimes: times),
              PrayerTrackerRow(prayerTimes: times),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final loc = lookupAppLocalizations(Locale(lang));
      expect(find.textContaining(loc.kerahatActive('').trim()), findsOneWidget);
      expect(find.text(loc.trackerToday), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);

      // Sabah işaretlenir; vakti girmemiş öğle işaretlenmez
      await tester.tap(find.text(loc.sabah));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.ogle));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text(loc.trackerNotYet), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('prayer_log'),
        '{"${dk(0)}":${PrayerTracker.bit('İmsak')}}',
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Takip ekranı $lang: ızgara, istatistik, kazaya ekleme', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'prayer_log_since': dk(3),
        'prayer_log': '{"${dk(1)}":31,"${dk(2)}":1}',
        'prayer_kaza_added': '{"${dk(3)}":31}',
      });
      await pumpApp(tester, lang, _trackerView());
      expect(tester.takeException(), isNull);
      final loc = lookupAppLocalizations(Locale(lang));
      expect(find.text(loc.trackerLast7Days), findsOneWidget);
      expect(find.text(loc.trackerStreakDays(1)), findsOneWidget);
      // 3 gün önce: 5 kaza hücresi + açıklama
      expect(find.byIcon(Icons.history), findsNWidgets(6));

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.trackerKazaButton));
      await tester.pumpAndSettle();
      // 2 gün önce sadece sabah kılındı → 4 vakit
      expect(find.text(loc.trackerKazaConfirm(4)), findsOneWidget);
      await tester.tap(find.text(loc.trackerKazaAdd));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerKazaDone(4)), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // SnackBar kapansın
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.history), findsNWidgets(10));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('kaza_Öğle'), 1);
      expect(prefs.getInt('kaza_Sabah'), isNull);
      expect(tester.takeException(), isNull);

      // Kaza hücresi: sayaç varsa onayla kılındı olur ve sayaç bir azalır
      await tester.tap(find.byIcon(Icons.history).first); // 2 gün önce öğle
      await tester.pumpAndSettle();
      expect(
        find.text(loc.trackerKazaRemoveConfirm(loc.ogle, 1, 0)),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, loc.trackerPrayedAction),
      );
      await tester.pumpAndSettle();
      expect(prefs.getInt('kaza_Öğle'), 0);
      expect(find.byIcon(Icons.history), findsNWidgets(9));
      // Sayaç sıfırsa onay sorulmaz (3 gün önce sabah)
      await tester.tap(find.byIcon(Icons.history).at(3));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byIcon(Icons.history), findsNWidgets(8));
      expect(prefs.getInt('kaza_Sabah'), isNull);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Ayarlar: vakit çıkış hatırlatması $lang', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(
        tester,
        lang,
        Scaffold(body: ListView(children: const [EndReminderSetting()])),
      );
      final loc = lookupAppLocalizations(Locale(lang));
      expect(find.text(loc.endReminderTitle), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      await tester.tap(find.text(loc.timeAdjustMinutes('45')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('end_reminder_enabled'), isTrue);
      expect(prefs.getInt('end_reminder_minutes'), 45);
    });
  }

  testWidgets(
    'Başka isolate\'te (bildirim) işaretlenen vakit 30 sn içinde yansır',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final times = PrayerTimesModel(
        imsak: '00:00',
        gunes: '00:00',
        ogle: '00:00',
        ikindi: '00:00',
        aksam: '00:00',
        yatsi: '00:00',
      );
      await pumpApp(
        tester,
        'tr',
        Scaffold(
          body: ListView(
            children: [PrayerTrackerRow(prayerTimes: times)],
          ),
        ),
      );
      expect(find.text('0/5'), findsOneWidget);

      // Bildirim aksiyonu isolate'i kayda yazdı; bu isolate'e haber gelmez
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_log', '{"${dk(0)}":3}');
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.text('2/5'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Takip ekranı da kaydı düzenli yeniden okur', (tester) async {
    SharedPreferences.setMockInitialValues({'prayer_log_since': dk(3)});
    await pumpApp(tester, 'tr', _trackerView());
    expect(find.byIcon(Icons.check), findsNWidgets(1)); // açıklama
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_log', '{"${dk(1)}":31}');
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNWidgets(6));
    await tester.pumpWidget(const SizedBox());
  });

  group('Özel gün (hayız/nifas)', () {
    final loc = lookupAppLocalizations(const Locale('tr'));
    // Takip ızgarasındaki gün adı (bugün/dün dışındakiler)
    String dayLabel(int daysAgo) => DateFormat(
      'EEE d',
      'tr',
    ).format(PrayerTracker.addDays(DateTime.now(), -daysAgo));
    String pct(double value) => NumberFormat.percentPattern('tr').format(value);

    testWidgets('gün adına basılı tutunca işaretlenir; hücreler kapalı, '
        'seri, oran ve kazaya girmez', (tester) async {
      SharedPreferences.setMockInitialValues({
        'prayer_log_since': dk(3),
        'prayer_log': '{"${dk(1)}":31,"${dk(2)}":1}',
      });
      await pumpApp(tester, 'tr', _trackerView());
      final prefs = await SharedPreferences.getInstance();
      // Bugünün vakitleri bilinmiyor: 3 gün önce 0/5, 2 gün önce 1/5, dün 5/5
      expect(find.text(pct(6 / 15)), findsOneWidget);
      expect(find.text(loc.trackerStreakDays(1)), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(7)); // 6 hücre + açıklama
      // Keşif: başlıktaki düğme + açıklamada tek satır
      expect(find.byIcon(kExcusedIcon), findsNWidgets(2));
      expect(find.text(loc.trackerLegendExcused), findsOneWidget);

      await tester.longPress(find.text(dayLabel(2)));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedMarked), findsOneWidget);
      expect(prefs.getStringList('tracker_excused'), [dk(2)]);
      // Satırın 5 hücresi soluk; o günün sabah işareti gizli ama kayıtta
      expect(find.byIcon(kExcusedIcon), findsNWidgets(7));
      expect(find.byIcon(Icons.check), findsNWidgets(6));
      expect(find.text(pct(5 / 10)), findsOneWidget);
      expect(find.text(loc.trackerStreakDays(1)), findsOneWidget);

      // Hücre kapalı: dokununca açıklama, kayıt değişmez
      await tester.pump(const Duration(seconds: 5)); // SnackBar kapansın
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(kExcusedIcon).at(2)); // 2 gün önce öğle
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedCellSnack), findsOneWidget);
      expect(prefs.getString('prayer_log'), '{"${dk(1)}":31,"${dk(2)}":1}');

      // Kazaya ekleme: özel günün 4 vakti sayılmaz, sadece 3 gün önce
      await tester.pump(const Duration(seconds: 5));
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.trackerKazaButton));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerKazaConfirm(5)), findsOneWidget);
      await tester.tap(find.text(loc.trackerKazaAdd));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerKazaDone(5)), findsOneWidget);
      expect(prefs.getInt('kaza_Öğle'), 1);
      expect(prefs.getString('prayer_kaza_added'), '{"${dk(3)}":31}');

      // Basılı tutunca işaret kalkar, sabah işareti geri gelir
      await tester.pump(const Duration(seconds: 5));
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.longPress(find.text(dayLabel(2)));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedUnmarked), findsOneWidget);
      expect(prefs.getStringList('tracker_excused'), isEmpty);
      expect(find.byIcon(kExcusedIcon), findsNWidgets(2));
      expect(find.byIcon(Icons.check), findsNWidgets(7));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('kazaya eklenmiş gün özel gün olunca onayla sayaçtan düşülür', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'prayer_log_since': dk(3),
        'prayer_log': '{"${dk(3)}":1}',
        'prayer_kaza_added': '{"${dk(3)}":30}',
        'kaza_Öğle': 2,
      });
      await pumpApp(tester, 'tr', _trackerView());
      final prefs = await SharedPreferences.getInstance();
      await tester.longPress(find.text(dayLabel(3)));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedKazaConfirm(4)), findsOneWidget);
      // Vazgeçilirse değişmez
      await tester.tap(find.text(loc.cancel));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('tracker_excused'), isNull);
      expect(prefs.getInt('kaza_Öğle'), 2);

      await tester.longPress(find.text(dayLabel(3)));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, loc.trackerExcusedMark));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('tracker_excused'), [dk(3)]);
      expect(prefs.getInt('kaza_Öğle'), 1);
      expect(prefs.getInt('kaza_Yatsı'), isNull); // 0 iken düşülmez
      expect(prefs.getString('prayer_kaza_added'), '{}');
      expect(find.byIcon(Icons.history), findsNWidgets(1)); // açıklama
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('başlık düğmesi: açıklama ve "bugünü işaretle" anahtarı', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester, 'tr', _trackerView());
      final prefs = await SharedPreferences.getInstance();
      bool switchValue() =>
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

      await tester.tap(find.byTooltip(loc.trackerExcusedTitle));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedInfo), findsOneWidget);
      expect(switchValue(), isFalse);
      await tester.tap(find.text(loc.trackerExcusedToday));
      await tester.pumpAndSettle();
      expect(switchValue(), isTrue);
      expect(prefs.getStringList('tracker_excused'), [dk(0)]);

      // Sayfa kapanınca bugünün satırı soluk
      Navigator.of(tester.element(find.text(loc.trackerExcusedInfo))).pop();
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedInfo), findsNothing);
      expect(find.byIcon(kExcusedIcon), findsNWidgets(7));

      // Yeniden açılınca anahtar açık; kapatınca işaret kalkar
      await tester.tap(find.byTooltip(loc.trackerExcusedTitle));
      await tester.pumpAndSettle();
      expect(switchValue(), isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(switchValue(), isFalse);
      expect(prefs.getStringList('tracker_excused'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ana ekran "Bugün": basılı tutunca özel gün, işaretler kapalı', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'prayer_log': '{"${dk(0)}":1}'});
      final times = PrayerTimesModel(
        imsak: '00:00',
        gunes: '00:00',
        ogle: '00:00',
        ikindi: '00:00',
        aksam: '00:00',
        yatsi: '00:00',
      );
      await pumpApp(
        tester,
        'tr',
        Scaffold(
          body: ListView(children: [PrayerTrackerRow(prayerTimes: times)]),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(find.text('1/5'), findsOneWidget);

      await tester.longPress(find.text(loc.trackerToday));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedMarked), findsOneWidget);
      expect(prefs.getStringList('tracker_excused'), [dk(0)]);
      expect(find.text('1/5'), findsNothing);
      expect(find.byIcon(kExcusedIcon), findsNWidgets(6)); // başlık + 5 vakit
      expect(find.byIcon(Icons.check), findsNothing);

      // Vakitler kapalı: dokununca açıklama, kayıt değişmez
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.ogle));
      await tester.pumpAndSettle();
      expect(find.text(loc.trackerExcusedCellSnack), findsOneWidget);
      expect(prefs.getString('prayer_log'), '{"${dk(0)}":1}');

      await tester.longPress(find.text(loc.trackerToday));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
      expect(prefs.getStringList('tracker_excused'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: 320dp, %130 yazı, özel gün satırları ve açıklama '
          'taşmadan', (tester) async {
        await _loadPoppins();
        SharedPreferences.setMockInitialValues({
          'prayer_log_since': dk(5),
          'prayer_log': '{"${dk(1)}":31,"${dk(4)}":3}',
          'prayer_kaza_added': '{"${dk(5)}":31}',
          'tracker_excused': [dk(2), dk(3)],
        });
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        messenger.setMockMessageHandler(
          'plugins.flutter.io/google_mobile_ads',
          (message) async =>
              const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(),
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _trackerView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(Locale(lang));
        // 2 özel gün satırı (10 hücre) + başlık düğmesi + açıklama
        expect(find.byIcon(kExcusedIcon), findsNWidgets(12));
        expect(find.text(l.trackerLegendExcused), findsOneWidget);

        await tester.tap(find.byTooltip(l.trackerExcusedTitle));
        await tester.pumpAndSettle();
        expect(find.text(l.trackerExcusedInfo), findsOneWidget);
        expect(find.text(l.trackerExcusedToday), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.text(l.trackerExcusedInfo))).pop();
        await tester.pumpAndSettle();

        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
