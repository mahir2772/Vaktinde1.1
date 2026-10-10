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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ramazan orucu kartı gizli: testler çalıştıkları tarihten bağımsız
PrayerTrackerView _trackerView() => PrayerTrackerView(
  fastClock: () => DateTime(2026, 10, 10),
  ramadanCalendar: RamadanCalendar.hijriOnly,
);

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
}
