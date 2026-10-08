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
  });
}
