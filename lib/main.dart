import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'features/main_wrapper/main_wrapper.dart';
import 'features/home/view_model/home_view_model.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_manager.dart'; // <--- YENİ YOL BURASI

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reklamları Başlat
  await MobileAds.instance.initialize();

  // ARKA PLAN SERVİSİNİ BAŞLAT (Burayı ekledik)
  await BackgroundManager.initializeService();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HomeViewModel())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaktinde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const MainWrapper(),
    );
  }
}
