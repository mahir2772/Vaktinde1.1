// Ramazan orucu takibi: saf hesaplar (görünürlük, kaza adayları), kayıt
// (kazaya bir kez ekleme, kazadan çıkarma) ve Namaz Takibi'ndeki kart.
import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/fast_tracker.dart';
import 'package:ezan_saati/data/services/fast_tracker_service.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/features/prayer_tracker/view/prayer_tracker_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Diyanet 2027 Ramazanı: 8 Şubat – 8 Mart (29 gün), bayram 9 Mart
final RamadanRange _range = RamadanRange(
  hijriYear: 1448,
  start: DateTime(2027, 2, 8),
  length: 29,
);
final RamadanCalendar _calendar = RamadanCalendar({1448: _range});

/// Ramazan'ın [n]. günü
DateTime _day(int n) => PrayerTracker.addDays(_range.start, n - 1);
String _key(int n) => PrayerTracker.dateKey(_day(n));

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

  group('Saf hesaplar', () {
    test('kart Ramazan\'da ve bitişinden sonraki 30 gün görünür', () {
      RamadanRange? at(DateTime d) => FastTracker.visibleRamadan(_calendar, d);
      expect(at(DateTime(2026, 10, 10)), isNull);
      expect(at(DateTime(2027, 2, 7, 23, 59)), isNull);
      expect(at(DateTime(2027, 2, 8))?.start, DateTime(2027, 2, 8));
      expect(at(DateTime(2027, 3, 8, 22))?.length, 29);
      expect(at(DateTime(2027, 3, 9)), isNotNull); // bayram
      expect(at(DateTime(2027, 4, 7, 23, 59)), isNotNull); // bitiş + 30
      expect(at(DateTime(2027, 4, 8)), isNull);

      // Uygulamadaki Diyanet listesi: 2026 Ramazanı 19 Şubat – 19 Mart
      final official = RamadanCalendar.fromReligiousDays(
        jsonDecode(
              File('assets/data/religious_days.json').readAsStringSync(),
            )
            as List,
      );
      final r2026 = FastTracker.visibleRamadan(official, DateTime(2026, 4, 1))!;
      expect(r2026.start, DateTime(2026, 2, 19));
      expect(r2026.length, 29);
      expect(FastTracker.visibleRamadan(official, DateTime(2026, 4, 19)), isNull);
      expect(
        FastTracker.visibleRamadan(official, DateTime(2027, 2, 20))?.start,
        DateTime(2027, 2, 8),
      );
      // Resmî veri yoksa hijri hesap
      final hijri = ramadanOfHijriYear(1448);
      expect(
        FastTracker.visibleRamadan(RamadanCalendar.hijriOnly, hijri.start),
        isNotNull,
      );
    });

    test('kaza adayları: bugün, gelecek, tutulan ve eklenenler hariç', () {
      // 5. gün: 1-4 geçmiş; 1 ve 3 tutuldu, 2 kazaya eklendi
      final during = FastTracker.kazaCandidates(
        _range,
        {_key(1), _key(3)},
        {_key(2)},
        DateTime(2027, 2, 12, 20),
      );
      expect(during, [_day(4)]);

      // Bayramdan sonra: 29 günün 20'si tutuldu, 2'si eklendi → 7
      final fasted = {for (var n = 1; n <= 20; n++) _key(n)};
      final after = FastTracker.kazaCandidates(
        _range,
        fasted,
        {_key(21), _key(22)},
        DateTime(2027, 3, 20),
      );
      expect(after, [for (var n = 23; n <= 29; n++) _day(n)]);
      expect(FastTracker.fastedCount(_range, fasted), 20);
      // Aralık dışındaki kayıt sayılmaz
      expect(FastTracker.fastedCount(_range, {...fasted, '2027-03-09'}), 20);
    });

    test('günü ekle / çıkar; 400 günden eski ve bozuk kayıt budanır', () {
      final today = DateTime(2027, 3, 1);
      var days = FastTracker.withDay({}, _day(1), true, today: today);
      days = FastTracker.withDay(days, _day(2), true, today: today);
      expect(days, {_key(1), _key(2)});
      days = FastTracker.withDay(days, _day(1), false, today: today);
      expect(days, {_key(2)});
      // 22. gün = 1 Mart (bugün)
      expect(FastTracker.isFuture(_day(23), today), isTrue);
      expect(FastTracker.isFuture(_day(23), DateTime(2027, 3, 1, 23)), isTrue);
      expect(FastTracker.isFuture(_day(22), DateTime(2027, 3, 1, 23)), isFalse);
      expect(FastTracker.isFuture(_day(21), today), isFalse);

      final pruned = FastTracker.prune({
        '2026-01-30', // 395 gün önce
        '2026-01-20', // 405 gün önce
        'bozuk',
        '2027-02-30',
        _key(2),
      }, today);
      expect(pruned, {'2026-01-30', _key(2)});
    });
  });

  group('Kayıt (SharedPreferences)', () {
    final after = DateTime(2027, 3, 20); // bayramdan sonra

    test('tutuldu işaretle / geri al kalıcı', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FastTrackerService();
      expect(await service.setFasted(_day(2), true, now: after), isTrue);
      expect(await service.setFasted(_day(1), true, now: after), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('fast_log'), [_key(1), _key(2)]);
      await service.setFasted(_day(1), false, now: after);
      expect(await service.loadLog(), {_key(2)});
    });

    test('bozuk kayıt boş okunur', () async {
      SharedPreferences.setMockInitialValues({
        'fast_log': 'bozuk',
        'fast_kaza_added': 3,
      });
      final service = FastTrackerService();
      expect(await service.loadLog(), isEmpty);
      expect(await service.loadKazaAdded(), isEmpty);
      expect(await service.setFasted(_day(1), true, now: after), isTrue);
      expect(await service.loadLog(), {_key(1)});
    });

    test('kazaya ekleme: her gün bir kez, sayaç artar', () async {
      SharedPreferences.setMockInitialValues({'kaza_Oruç': 3, 'kaza_Sabah': 7});
      final service = FastTrackerService();
      for (final n in [1, 2, 3]) {
        await service.setFasted(_day(n), true, now: after);
      }
      expect(await service.addMissedToKaza(_range, now: after), 26);
      expect(await service.loadKazaCount(), 29);
      expect(await service.loadKazaAdded(), hasLength(26));
      // Namaz kazası etkilenmez
      expect((await StorageService().loadMissedPrayers())['Sabah'], 7);

      // İkinci kez: hiçbir şey eklenmez
      expect(await service.addMissedToKaza(_range, now: after), 0);
      expect(await service.loadKazaCount(), 29);

      // Kazaya eklenmiş gün doğrudan tutuldu yapılmaz (removeFromKaza)
      expect(await service.setFasted(_day(4), true, now: after), isFalse);
      expect((await service.loadLog()).contains(_key(4)), isFalse);

      // Sonradan tutulmadı yapılan gün eklenir, öncekiler tekrar sayılmaz
      await service.setFasted(_day(2), false, now: after);
      expect(await service.addMissedToKaza(_range, now: after), 1);
      expect(await service.loadKazaCount(), 30);

      // Ramazan sürerken bugün eklenmez
      SharedPreferences.setMockInitialValues({});
      expect(
        await service.addMissedToKaza(_range, now: DateTime(2027, 2, 10, 21)),
        2,
      );
      expect(await service.loadKazaAdded(), {_key(1), _key(2)});
    });

    test('kazadan çıkarma: tutuldu olur, sayaç bir azalır (0 altına inmez)', () async {
      SharedPreferences.setMockInitialValues({'kaza_Oruç': 1});
      final service = FastTrackerService();
      for (var n = 1; n <= 26; n++) {
        await service.setFasted(_day(n), true, now: after);
      }
      expect(await service.addMissedToKaza(_range, now: after), 3); // 27-29
      expect(await service.loadKazaCount(), 4);

      // Kazaya eklenmemiş gün değişmez
      expect(await service.removeFromKaza(_day(5), now: after), isFalse);

      expect(await service.removeFromKaza(_day(27), now: after), isTrue);
      expect(await service.loadKazaCount(), 3);
      expect((await service.loadLog()).contains(_key(27)), isTrue);
      expect((await service.loadKazaAdded()).contains(_key(27)), isFalse);
      // İkinci kez düşülmez, yeniden kazaya eklenmez
      expect(await service.removeFromKaza(_day(27), now: after), isFalse);
      expect(await service.addMissedToKaza(_range, now: after), 0);
      expect(await service.loadKazaCount(), 3);

      // Kaza Takibi'nde elle sıfırlanmışsa 0'da kalır, gün yine tutuldu olur
      await StorageService().updateMissedPrayer('Oruç', 0);
      expect(await service.removeFromKaza(_day(28), now: after), isTrue);
      expect(await service.loadKazaCount(), 0);
      expect((await service.loadLog()).contains(_key(28)), isTrue);

      // Sonradan tutulmadı yapılırsa yeniden kazaya eklenebilir
      await service.setFasted(_day(28), false, now: after);
      expect(await service.addMissedToKaza(_range, now: after), 1);
      expect(await service.loadKazaCount(), 1);
    });
  });

  group('Namaz Takibi: Ramazan orucu kartı', () {
    setUpAll(() async {
      await _loadFont('Poppins', [
        for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'assets/google_fonts/Poppins-$w.ttf',
      ]);
    });

    setUp(() {
      messenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads',
        (message) async =>
            const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    });

    Future<void> pumpTracker(
      WidgetTester tester,
      DateTime today, {
      String lang = 'tr',
      double width = 411,
      double height = 891,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PrayerTrackerView(
              fastClock: () => today,
              ramadanCalendar: _calendar,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> dispose(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    final loc = lookupAppLocalizations(const Locale('tr'));

    for (final (today, visible) in [
      (DateTime(2026, 10, 10), false),
      (DateTime(2027, 2, 7), false),
      (DateTime(2027, 2, 8), true),
      (DateTime(2027, 4, 7), true),
      (DateTime(2027, 4, 8), false),
    ]) {
      testWidgets('${PrayerTracker.dateKey(today)}: kart '
          '${visible ? 'görünür' : 'gizli'}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        await pumpTracker(tester, today);
        expect(find.text(loc.fastTitle), visible ? findsOneWidget : findsNothing);
        expect(find.text(loc.trackerLast7Days), findsOneWidget);
        await dispose(tester);
      });
    }

    testWidgets('güne dokun, tutulmayanları kazaya ekle, kazadan çıkar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'kaza_Oruç': 2});
      await pumpTracker(tester, DateTime(2027, 2, 12, 14)); // 5. gün
      final prefs = await SharedPreferences.getInstance();
      expect(find.text(loc.fastCount(0, 29)), findsOneWidget);

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastCount(1, 29)), findsOneWidget);
      expect(prefs.getStringList('fast_log'), [_key(1)]);
      // Gelecek gün işaretlenmez
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastCount(1, 29)), findsOneWidget);
      // Bugün işaretlenir, sonra geri alınır
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastCount(2, 29)), findsOneWidget);
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('fast_log'), [_key(1)]);

      // 2-4. günler (bugün hariç) kazaya
      await tester.tap(find.text(loc.fastKazaButton));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastKazaConfirm(3)), findsOneWidget);
      await tester.tap(find.text(loc.trackerKazaAdd));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastKazaDone(3)), findsOneWidget);
      expect(prefs.getInt('kaza_Oruç'), 5);
      expect(prefs.getStringList('fast_kaza_added'), [
        _key(2),
        _key(3),
        _key(4),
      ]);
      await tester.pump(const Duration(seconds: 5)); // SnackBar kapansın
      await tester.pumpAndSettle();

      // İkinci kez: eklenecek gün yok
      await tester.tap(find.text(loc.fastKazaButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(loc.fastKazaNone), findsOneWidget);

      // Kazaya eklenen gün: onayla tutuldu olur, sayaç bir azalır
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastKazaRemoveConfirm(5, 4)), findsOneWidget);
      await tester.tap(find.text(loc.fastFastedAction));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastCount(2, 29)), findsOneWidget);
      expect(prefs.getInt('kaza_Oruç'), 4);
      expect(prefs.getStringList('fast_kaza_added'), [_key(3), _key(4)]);

      // İptal edilirse değişmez
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.cancel));
      await tester.pumpAndSettle();
      expect(prefs.getInt('kaza_Oruç'), 4);
      expect(find.text(loc.fastCount(2, 29)), findsOneWidget);

      // Sayaç sıfırsa onay sorulmaz
      await prefs.setInt('kaza_Oruç', 0);
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(loc.fastCount(3, 29)), findsOneWidget);
      expect(prefs.getInt('kaza_Oruç'), 0);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    testWidgets('özel gün: kartta ayrı görünür ama kaza orucuna yine eklenir', (
      tester,
    ) async {
      // Namaz takibinde 2. ve 3. gün özel gün; 1. gün tutuldu
      SharedPreferences.setMockInitialValues({
        'fast_log': [_key(1)],
        'tracker_excused': [_key(2), _key(3)],
      });
      await pumpTracker(tester, DateTime(2027, 2, 12, 14)); // 5. gün
      final prefs = await SharedPreferences.getInstance();
      expect(find.text(loc.fastLegendExcused), findsOneWidget);
      expect(find.bySemanticsLabel(loc.ramadanDayLabel(2)), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(loc.ramadanDayLabel(2)))
            .value,
        loc.fastLegendExcused,
      );

      // Özel gün de tutuldu işaretlenebilir (ör. özel hal akşamdan sonra başladı)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastCount(2, 29)), findsOneWidget);
      expect(prefs.getStringList('fast_log'), [_key(1), _key(2)]);
      expect(find.text(loc.fastLegendExcused), findsOneWidget); // 3. gün

      // Tutulamayan oruç kaza edilir: özel gün (3.) de sayılır, 4. gün de
      await tester.tap(find.text(loc.fastKazaButton));
      await tester.pumpAndSettle();
      expect(find.text(loc.fastKazaConfirm(2)), findsOneWidget);
      await tester.tap(find.text(loc.trackerKazaAdd));
      await tester.pumpAndSettle();
      expect(prefs.getInt('kaza_Oruç'), 2);
      expect(prefs.getStringList('fast_kaza_added'), [_key(3), _key(4)]);
      // Kazaya eklenen gün artık "kazaya eklendi" görünür
      expect(find.text(loc.fastLegendExcused), findsNothing);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    });

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: 320dp, %130 yazı, kartta taşma yok', (tester) async {
        SharedPreferences.setMockInitialValues({
          'fast_log': [_key(1), _key(2)],
          'fast_kaza_added': [_key(3)],
          'tracker_excused': [_key(4)],
        });
        await pumpTracker(
          tester,
          DateTime(2027, 3, 20),
          lang: lang,
          width: 320,
          height: 640,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(Locale(lang));
        expect(find.text(l.fastTitle), findsOneWidget);
        expect(find.text(l.fastCount(2, 29)), findsOneWidget);
        expect(find.text(l.fastLegendExcused), findsOneWidget);
        for (var i = 0; i < 10; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        await dispose(tester);
      });
    }
  });
}
