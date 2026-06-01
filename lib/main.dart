import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'features/main_wrapper/main_wrapper.dart';
import 'features/home/view_model/home_view_model.dart';
import 'features/common/language_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_manager.dart';
import 'features/onboarding/view/onboarding_language_view.dart';
import 'features/common/theme_provider.dart';
import 'features/zikirmatik/view_model/zikir_view_model.dart';
// --- REKLAM HELPER İMPORTU EKLENDİ ---
import 'features/common/ad_helper.dart';

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase hatası: $e");
  }

  MobileAds.instance.initialize();

  // REKLAMI PUSUYA YATIRIYORUZ
  AdHelper.instance.loadInterstitialAd();

  // Background servisi başlatıyoruz
  try {
    await BackgroundManager.initializeService();
  } catch (e) {
    debugPrint("Background Service Başlatılamadı: $e");
  }

  GoogleFonts.config.allowRuntimeFetching = true;

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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: themeProvider.backgroundImage != null
            ? Colors.transparent
            : Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: themeProvider.backgroundImage != null
            ? Colors.transparent
            : const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E).withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
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
          ? const MainWrapper()
          : const OnboardingLanguageView(),
    );
  }
}
