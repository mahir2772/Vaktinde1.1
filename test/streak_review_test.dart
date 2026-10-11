// Uygulama içi değerlendirme: namaz takibinde 7 günlük tam seri uygulamada
// tamamlanınca ömür boyu bir kez; Play değerlendirmesi yoksa, başka pencere
// açıkken, arka planda ya da bildirim aksiyonunda (ayrı isolate) istenmez.
import 'dart:convert';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/data/services/prayer_tracker_service.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/language_provider.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/prayer_tracker/streak_review.dart';
import 'package:ezan_saati/features/zikirmatik/view_model/zikir_view_model.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class _FakeHomeViewModel extends HomeViewModel {
  @override
  Future<void> initializeApp(AppLocalizations loc) async {}

  @override
  void updateLocalization(AppLocalizations loc) {}

  @override
  Future<void> getDailyHadith(Locale locale) async {}

  @override
  Future<void> getDailyAyah(Locale locale) async {}

  @override
  Future<void> refreshLocationAndTimes(BuildContext context) async {}

  @override
  Future<void> refreshEndReminders() async {}

  @override
  Future<void> requestBatteryOptimizationOnce() async {}
}

const _reviewChannel = MethodChannel('dev.britannio.in_app_review');
const _notifications = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);
const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');

/// Sahte zamanda [duration] boyunca 100 ms adımlarla ilerler
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < duration; t += step) {
    await tester.pump(step);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var available = true;
  var reviewRequests = 0;
  final today = PrayerTracker.day(DateTime.now());
  String dk(int daysAgo) =>
      PrayerTracker.dateKey(PrayerTracker.addDays(today, -daysAgo));
  // İmsak 00:00: dünün yatsısı "sürüyor" sayılmaz
  final times = PrayerTimesModel(
    imsak: '00:00',
    gunes: '06:00',
    ogle: '12:00',
    ikindi: '15:00',
    aksam: '18:00',
    yatsi: '20:00',
  );

  /// Bugünden önce [fullDays] tam gün; bugün [todayMask] (15 = yatsı hariç)
  Map<String, Object> streakPrefs(int fullDays, {int todayMask = 15}) => {
    'prayer_log': jsonEncode({
      for (var i = 1; i <= fullDays; i++) dk(i): PrayerTracker.fullMask,
      if (todayMask != 0) dk(0): todayMask,
    }),
    'prayer_log_since': dk(fullDays),
  };

  Future<void> lifecycle(AppLifecycleState state) =>
      messenger.handlePlatformMessage(
        SystemChannels.lifecycle.name,
        SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
        (_) {},
      );

  setUp(() {
    available = true;
    reviewRequests = 0;
    StreakReviewPrompt.debugReset();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(_notifications, (call) async => null);
    messenger.setMockMethodCallHandler(_reviewChannel, (call) async {
      switch (call.method) {
        case 'isAvailable':
          return available;
        case 'requestReview':
          reviewRequests++;
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_notifications, null);
    messenger.setMockMethodCallHandler(_reviewChannel, null);
  });

  group('Seri dinleyicisi', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    StreakReviewPrompt startPrompt({bool Function()? canPrompt}) {
      final prompt = StreakReviewPrompt(
        todayTimes: () => times,
        canPrompt: canPrompt,
        delay: Duration.zero,
      );
      addTearDown(prompt.dispose);
      prompt.start();
      return prompt;
    }

    test('hedef kuralı: seri bu işaretle 7\'ye ulaştı ya da 7+ iken arttı', () {
      bool reached(int? before, int after) =>
          StreakReviewPrompt.reachedGoal(before: before, after: after);
      expect(reached(6, 7), isTrue);
      expect(reached(9, 10), isTrue);
      expect(reached(7, 7), isFalse);
      expect(reached(5, 6), isFalse);
      expect(reached(8, 7), isFalse);
      expect(reached(null, 7), isFalse);
    });

    test('dünün yatsısı imsak girene kadar sürüyor sayılır', () {
      final at = DateTime(2026, 10, 8, 5, 30);
      bool ongoing(String? imsak) => StreakReviewPrompt.yesterdayYatsiOngoing(
        imsak == null
            ? null
            : PrayerTimesModel(
                imsak: imsak,
                gunes: '07:00',
                ogle: '13:00',
                ikindi: '16:00',
                aksam: '18:30',
                yatsi: '20:00',
              ),
        at,
      );
      expect(ongoing('05:45'), isTrue);
      expect(ongoing('05:30'), isFalse);
      expect(ongoing(null), isTrue);
      expect(ongoing('bozuk'), isTrue);
    });

    test('yedinci gün tamamlanınca bir kez istenir, sonra hiç', () async {
      SharedPreferences.setMockInitialValues(streakPrefs(6));
      final service = PrayerTrackerService();
      final prompt = startPrompt();
      await prompt.settled;
      expect(reviewRequests, 0);

      await service.setPrayed(today, 'Yatsı', true);
      await prompt.settled;
      expect(reviewRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReviewPrompt.requestedKey), isTrue);

      // Geri al + yeniden işaretle: seri yine 7 ama istenmez
      await service.setPrayed(today, 'Yatsı', false);
      await service.setPrayed(today, 'Yatsı', true);
      await prompt.settled;
      expect(reviewRequests, 1);

      // Sonraki oturumda da (kayıttan) istenmez
      prompt.dispose();
      StreakReviewPrompt.debugReset();
      final next = startPrompt();
      await service.setPrayed(today, 'Yatsı', false);
      await service.setPrayed(today, 'Yatsı', true);
      await next.settled;
      expect(reviewRequests, 1);
    });

    test('seri zaten 7+ iken açılış ve seriyi artırmayan işaret istemez; '
        'bugün tamamlanınca istenir', () async {
      SharedPreferences.setMockInitialValues(streakPrefs(8, todayMask: 1));
      final service = PrayerTrackerService();
      final prompt = startPrompt();
      await prompt.settled;
      await service.setPrayed(today, 'Öğle', true);
      await service.setPrayed(today, 'İkindi', true);
      await service.setPrayed(today, 'Akşam', true);
      await prompt.settled;
      expect(reviewRequests, 0);

      await service.setPrayed(today, 'Yatsı', true); // seri 8 → 9
      await prompt.settled;
      expect(reviewRequests, 1);
    });

    test('özel gün seriyi bozmaz: arada özel gün varken 7. gün istenir', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_log': jsonEncode({
          for (var i = 1; i <= 7; i++)
            if (i != 4) dk(i): PrayerTracker.fullMask,
          dk(0): 15,
        }),
        'prayer_log_since': dk(7),
        'tracker_excused': [dk(4)],
      });
      final prompt = startPrompt();
      await prompt.settled;
      expect(reviewRequests, 0);
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true); // 6 → 7
      await prompt.settled;
      expect(reviewRequests, 1);
    });

    test('özel gün işareti seriyi 7\'ye çıkarsa da istenmez; '
        'sonraki namazla istenir', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_log': jsonEncode({
          for (var i = 1; i <= 8; i++)
            if (i != 4) dk(i): PrayerTracker.fullMask,
          dk(0): 15,
        }),
        'prayer_log_since': dk(8),
      });
      final service = PrayerTrackerService();
      final prompt = startPrompt();
      await prompt.settled;
      // 4 gün önce özel gün: seri 3 → 7 (atlanan gün köprülenir)
      await service.setExcused(PrayerTracker.addDays(today, -4), true);
      await prompt.settled;
      expect(reviewRequests, 0);

      await service.setPrayed(today, 'Yatsı', true); // 7 → 8
      await prompt.settled;
      expect(reviewRequests, 1);
    });

    test('aynı anda iki dinleyici olsa da tek istek', () async {
      SharedPreferences.setMockInitialValues(streakPrefs(6));
      final a = startPrompt();
      final b = startPrompt();
      await Future.wait([a.settled, b.settled]);
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await Future.wait([a.settled, b.settled]);
      expect(reviewRequests, 1);
    });

    test('Play değerlendirmesi yoksa istenmez, kayıt da yazılmaz', () async {
      available = false;
      SharedPreferences.setMockInitialValues(streakPrefs(6));
      final prompt = startPrompt();
      await prompt.settled;
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await prompt.settled;
      expect(reviewRequests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReviewPrompt.requestedKey), isNull);
    });

    test(
      'başka pencere açıkken ya da uygulama arka plandayken istenmez',
      () async {
        var dialogOpen = true;
        SharedPreferences.setMockInitialValues(streakPrefs(6));
        final service = PrayerTrackerService();
        final prompt = startPrompt(canPrompt: () => !dialogOpen);
        await prompt.settled;
        await service.setPrayed(today, 'Yatsı', true);
        await prompt.settled;
        expect(reviewRequests, 0);

        dialogOpen = false;
        await service.setPrayed(today, 'Yatsı', false);
        await lifecycle(AppLifecycleState.inactive);
        await lifecycle(AppLifecycleState.hidden);
        await lifecycle(AppLifecycleState.paused);
        await service.setPrayed(today, 'Yatsı', true);
        await prompt.settled;
        expect(reviewRequests, 0);

        await lifecycle(AppLifecycleState.hidden);
        await lifecycle(AppLifecycleState.inactive);
        await lifecycle(AppLifecycleState.resumed);
        await service.setPrayed(today, 'Yatsı', false);
        await service.setPrayed(today, 'Yatsı', true);
        await prompt.settled;
        expect(reviewRequests, 1);
      },
    );

    test(
      'bildirimdeki "Kıldım" (ayrı isolate, dinleyici yok) istemez',
      () async {
        SharedPreferences.setMockInitialValues(streakPrefs(6));
        final marked = await PrayerTrackerService.handleNotificationAction(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: PrayerTracker.actionId,
            payload: PrayerTracker.payload(today, 'Yatsı'),
          ),
        );
        expect(marked, isTrue);
        expect(reviewRequests, 0);
      },
    );
  });

  group('Kullanım günü', () {
    // Saat enjekte edilir: gün dönümü elle ilerletilir
    var now = DateTime(2026, 10, 10, 9);
    const day = PrayerTracker.epochDay;

    setUp(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      now = DateTime(2026, 10, 10, 9);
      await lifecycle(AppLifecycleState.resumed);
    });
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    UsageReviewPrompt startUsage({bool Function()? canPrompt}) {
      final prompt = UsageReviewPrompt(
        canPrompt: canPrompt,
        delay: Duration.zero,
        clock: () => now,
      );
      addTearDown(prompt.dispose);
      prompt.start();
      return prompt;
    }

    /// Dördüncü gün dün sayılmış: bugünkü açılış beşinci gün
    Map<String, Object> fourDays() => {
      UsageReviewPrompt.countKey: 4,
      UsageReviewPrompt.lastDayKey: day(now) - 1,
    };

    Future<int?> storedCount() async => (await SharedPreferences.getInstance())
        .getInt(UsageReviewPrompt.countKey);

    // Ön plana dönüş (bildirim çekmecesi kapanınca da olur)
    Future<void> resume() async {
      await lifecycle(AppLifecycleState.inactive);
      await lifecycle(AppLifecycleState.resumed);
    }

    test('sayım kuralı: yeni gün bir sayılır, aynı gün tekrar sayılmaz; 5. '
        'günde açılışta ya da yeni günün ilk ön plana gelişinde istenir', () {
      ({int count, bool ask}) open(
        int count,
        int? last, {
        bool launch = false,
      }) => UsageReviewPrompt.onOpen(
        count: count,
        lastDay: last,
        today: 100,
        launch: launch,
      );
      expect(open(0, null, launch: true), (count: 1, ask: false));
      expect(open(3, 100), (count: 3, ask: false));
      expect(open(3, 100, launch: true), (count: 3, ask: false));
      expect(open(3, 99), (count: 4, ask: false));
      expect(open(4, 90), (count: 5, ask: true)); // aradaki boş günler sayılmaz
      expect(open(4, 100, launch: true), (count: 4, ask: false));
      // Hedefteyken aynı gün ön plana dönüş (reklam, ayarlar) istemez
      expect(open(5, 100), (count: 5, ask: false));
      expect(open(5, 100, launch: true), (count: 5, ask: true));
      expect(open(9, 99), (count: 10, ask: true));
    });

    test('5. gün açılışında bir kez istenir; kayıt seriyle ortak, sonra '
        'hiç istenmez', () async {
      SharedPreferences.setMockInitialValues(fourDays());
      final prompt = startUsage();
      await prompt.settled;
      expect(reviewRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReviewPrompt.requestedKey), isTrue);
      expect(prefs.getInt(UsageReviewPrompt.countKey), 5);
      expect(prefs.getInt(UsageReviewPrompt.lastDayKey), day(now));

      // Sonraki oturumda, yeni günde de (kayıttan) istenmez
      prompt.dispose();
      StreakReviewPrompt.debugReset();
      now = now.add(const Duration(days: 1));
      final next = startUsage();
      await next.settled;
      await resume();
      await next.settled;
      expect(reviewRequests, 1);
    });

    test('aynı gün tekrar açılış ve ön plana dönüş sayılmaz; uygulama '
        'açıkken gün dönünce ön plana gelişte sayılır', () async {
      SharedPreferences.setMockInitialValues({
        UsageReviewPrompt.countKey: 3,
        UsageReviewPrompt.lastDayKey: day(now),
      });
      final prompt = startUsage();
      await prompt.settled;
      await resume();
      await prompt.settled;
      expect(await storedCount(), 3);

      now = now.add(const Duration(days: 1));
      await resume();
      await prompt.settled;
      await resume();
      await prompt.settled;
      expect(await storedCount(), 4);
      expect(reviewRequests, 0);

      now = now.add(const Duration(days: 1));
      await resume();
      await prompt.settled;
      expect(await storedCount(), 5);
      expect(reviewRequests, 1);
    });

    test('arka plandayken sayılmaz ve istenmez; ön plana gelince sayılır ve '
        'istenir', () async {
      SharedPreferences.setMockInitialValues(fourDays());
      await lifecycle(AppLifecycleState.paused);
      final prompt = startUsage();
      await prompt.settled;
      expect(await storedCount(), 4);
      expect(reviewRequests, 0);

      await lifecycle(AppLifecycleState.hidden);
      await lifecycle(AppLifecycleState.inactive);
      await lifecycle(AppLifecycleState.resumed);
      await prompt.settled;
      expect(await storedCount(), 5);
      expect(reviewRequests, 1);
    });

    test('başka pencere açıkken istenmez; aynı gün ön plana dönüşte de '
        'istenmez, sonraki açılışta istenir', () async {
      var dialogOpen = true;
      SharedPreferences.setMockInitialValues(fourDays());
      final prompt = startUsage(canPrompt: () => !dialogOpen);
      await prompt.settled;
      expect(await storedCount(), 5);
      expect(reviewRequests, 0);

      dialogOpen = false;
      await resume();
      await prompt.settled;
      expect(reviewRequests, 0);

      prompt.dispose();
      final next = startUsage(canPrompt: () => !dialogOpen);
      await next.settled;
      expect(reviewRequests, 1);
    });

    test('Play değerlendirmesi yoksa istenmez, kayıt yazılmaz', () async {
      available = false;
      SharedPreferences.setMockInitialValues(fourDays());
      final prompt = startUsage();
      await prompt.settled;
      expect(reviewRequests, 0);
      expect(await storedCount(), 5);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StreakReviewPrompt.requestedKey), isNull);
    });

    test('seri tetiği istediyse kullanım günü istemez, saymaz', () async {
      SharedPreferences.setMockInitialValues({
        ...fourDays(),
        StreakReviewPrompt.requestedKey: true,
      });
      final prompt = startUsage();
      await prompt.settled;
      expect(reviewRequests, 0);
      expect(await storedCount(), 4);
    });

    test('iki tetik aynı oturumda: tek istek', () async {
      SharedPreferences.setMockInitialValues({
        ...streakPrefs(6),
        ...fourDays(),
      });
      final usage = startUsage();
      final streak = StreakReviewPrompt(
        todayTimes: () => times,
        delay: Duration.zero,
      );
      addTearDown(streak.dispose);
      streak.start();
      await Future.wait([usage.settled, streak.settled]);
      expect(reviewRequests, 1);
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await streak.settled;
      expect(reviewRequests, 1);
    });
  });

  group('Ana ekran (MainWrapper)', () {
    var locationPermission = 2; // kullanırken

    setUp(() {
      locationPermission = 2;
      debugResetPermissionPriming();
      AdConsent.debugReset();
      messenger.setMockMethodCallHandler(_geolocator, (call) async {
        switch (call.method) {
          case 'checkPermission':
          case 'requestPermission':
            return locationPermission;
          case 'isLocationServiceEnabled':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(_geolocator, null));

    Future<void> pumpMain(
      WidgetTester tester,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues({
        'language_code': 'tr',
        'is_language_selected': true,
        ...prefs,
      });
      tester.view.physicalSize = const Size(411 * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final vm = _FakeHomeViewModel()
        ..city = 'Ankara'
        ..district = 'Çankaya'
        ..isLoading = false
        ..prayerTimes = times;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeViewModel>(
              create: (_) => vm,
              lazy: false,
            ),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ZikirViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShowCaseWidget(
              onFinish: () {},
              builder: (context) => const MainWrapper(),
            ),
          ),
        ),
      );
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('açılış akışı bitince seri tamamlanırsa istenir', (
      tester,
    ) async {
      await pumpMain(tester, {
        ...streakPrefs(6),
        tourSeenKey: false,
        permissionsPrimedKey: true,
      });
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(reviewRequests, 1);
      await finish(tester);
    });

    testWidgets('tanıtım turu sürerken istenmez', (tester) async {
      // Tur görülmemiş (kayıt yedekten gelmiş olabilir: seri var)
      await pumpMain(tester, {...streakPrefs(6), permissionsPrimedKey: true});
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.showcaseLanguage), findsOneWidget);
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(reviewRequests, 0);
      await finish(tester);
    });

    testWidgets('izin penceresi açıkken istenmez', (tester) async {
      locationPermission = 0; // izin yok: açıklama penceresi açılır
      await pumpMain(tester, {...streakPrefs(6), tourSeenKey: false});
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.permissionPrimingTitle), findsOneWidget);
      await PrayerTrackerService().setPrayed(today, 'Yatsı', true);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(reviewRequests, 0);
      await finish(tester);
    });

    /// Dördüncü gün dün sayılmış: bu açılış beşinci gün
    Map<String, Object> fourUsageDays() => {
      UsageReviewPrompt.countKey: 4,
      UsageReviewPrompt.lastDayKey: PrayerTracker.epochDay(DateTime.now()) - 1,
    };

    testWidgets('5. kullanım günü: açılış akışından birkaç saniye sonra '
        'istenir', (tester) async {
      await pumpMain(tester, {
        ...fourUsageDays(),
        tourSeenKey: false,
        permissionsPrimedKey: true,
      });
      expect(reviewRequests, 0); // önce vakitler görünsün
      await _pumpFor(tester, const Duration(seconds: 3));
      expect(reviewRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(UsageReviewPrompt.countKey), 5);
      await finish(tester);
    });

    testWidgets('5. kullanım günü: tanıtım turu ya da izin penceresi '
        'sürerken istenmez', (tester) async {
      await pumpMain(tester, {...fourUsageDays(), permissionsPrimedKey: true});
      final loc = lookupAppLocalizations(const Locale('tr'));
      expect(find.text(loc.showcaseLanguage), findsOneWidget);
      await _pumpFor(tester, const Duration(seconds: 4));
      expect(reviewRequests, 0);
      await finish(tester);

      locationPermission = 0;
      await pumpMain(tester, {...fourUsageDays(), tourSeenKey: false});
      expect(find.text(loc.permissionPrimingTitle), findsOneWidget);
      await _pumpFor(tester, const Duration(seconds: 4));
      expect(reviewRequests, 0);
      await finish(tester);
    });
  });
}
