import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:geolocator/geolocator.dart'; // YENİ EKLENDİ
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // YENİ EKLENDİ
import 'package:workmanager/workmanager.dart';

import 'features/main_wrapper/main_wrapper.dart';
import 'features/home/view_model/home_view_model.dart';
import 'features/common/language_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_manager.dart';
import 'data/services/prayer_refresh_service.dart';
import 'features/onboarding/view/onboarding_language_view.dart';
import 'features/common/theme_provider.dart';
import 'features/zikirmatik/view_model/zikir_view_model.dart';
import 'features/common/ad_helper.dart';
import 'features/common/ad_consent.dart';
import 'core/ui/app_theme.dart';

final NotificationService notificationService = NotificationService();

const String _refreshTaskName = 'vaktinde_daily_refresh';

// WorkManager arka plan görevi: uygulama günlerce açılmasa da widget'lar,
// kalıcı bildirim ve 5 günlük ezan alarmları güncel kalır
@pragma('vm:entry-point')
void callbackDispatcher() {
  DartPluginRegistrant.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    return PrayerRefreshService.runHeadless();
  });
}

Future<void> _registerBackgroundRefresh() async {
  if (!Platform.isAndroid) return;
  try {
    await Workmanager().initialize(callbackDispatcher);
    // keep: her açılışta yeniden kaydetmek periyodu sıfırlamaz; ilk kayıtta hemen bir kez çalışır
    await Workmanager().registerPeriodicTask(
      _refreshTaskName,
      _refreshTaskName,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint("Workmanager başlatılamadı: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    // Sahadaki hatalar Crashlytics'e raporlanır (debug'da kapalı)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Firebase hatası: $e");
  }

  // Reklamlar AdMob rızası (UMP) alındıktan sonra başlar; açılışı bekletmez
  AdHelper.instance.loadInterstitialAd();

  try {
    await BackgroundManager.initializeService();
  } catch (e) {
    debugPrint("Background Service Başlatılamadı: $e");
  }

  await _registerBackgroundRefresh();

  // Poppins ve Amiri pubspec'te gömülü (internetsiz ilk açılış)
  LicenseRegistry.addLicense(() async* {
    final poppins = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Poppins'], poppins);
    final amiri = await rootBundle.loadString('assets/fonts/amiri/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Amiri'], amiri);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ZikirViewModel()),
      ],
      child: const MyApp(),
    ),
  );

  // AB'de rıza formu gerekiyorsa ilk kare çizildikten sonra gösterilir
  unawaited(AdConsent.gatherAndStartAds());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint("Güncelleme kontrol hatası: $e");
    }
  }

  // --- YENİ: TANITIM TURU BİTER BİTMEZ İZİNLERİ İSTEYEN ZEKİ FONKSİYON ---
  Future<void> _requestPermissionsAfterTutorial() async {
    // 1. Önce Bildirim İznini İster
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      if (Platform.isAndroid) {
        await notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint("Bildirim izni hatası: $e");
    }

    // 2. Kullanıcı bildirim iznini geçer geçmez Konum İznini İster
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint("Konum izni hatası: $e");
    }
  }
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hasBackground = themeProvider.backgroundImage != null;

    return MaterialApp(
      title: 'Vaktinde',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('ar'),
      ],
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(hasBackgroundImage: hasBackground),
      darkTheme: AppTheme.dark(hasBackgroundImage: hasBackground),
      builder: (context, child) {
        return Stack(
          children: [
            if (themeProvider.backgroundImage != null)
              Positioned.fill(
                child: Image.asset(
                  "assets/images/backgrounds/${themeProvider.backgroundImage}",
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: Directionality(
                textDirection: languageProvider.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
          ],
        );
      },
      home: languageProvider.isLanguageSelected
          ? ShowCaseWidget(
              onFinish:
                  _requestPermissionsAfterTutorial, // TUR BİTİNCE İZİNLERİ TETİKLER
              builder: (context) => const MainWrapper(),
            )
          : const OnboardingLanguageView(),
    );
  }
}
