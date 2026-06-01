import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
// --- DİL DESTEĞİ İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// ---------------------------
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
// --- ZİKİRMATİK İMPORTU EKLENDİ ---
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  final String _adUnitId = 'ca-app-pub-4975388193054410/3285554173';

  // --- SAYFALAR GÜNCELLENDİ (Sıralama: Home -> Qibla -> Zikirmatik -> Tools) ---
  final List<Widget> _pages = [
    const HomeView(),
    const QiblaView(),
    const ZikirView(), // 3. Sıraya Zikirmatik eklendi
    const ToolsView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAd();
    AdHelper.instance.loadInterstitialAd();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context);
      if (loc != null) {
        // Uygulama ilk açıldığında verileri yükle
        context.read<HomeViewModel>().initializeApp(loc);
      }
    });
  }

  // --- EKLENEN KISIM: DİL DEĞİŞİKLİĞİNİ YAKALAR ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Uygulamanın dili her değiştiğinde burası çalışır
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      // ViewModel'e "Dil değişti, alarmları yeni dile göre ayarla" diyoruz
      context.read<HomeViewModel>().updateLocalization(loc);
    }
  }
  // ------------------------------------------------

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('Reklam yüklenemedi: ${err.message}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),

          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              if (_currentIndex != index) {
                // Sadece başka bir sekmeye geçiyorsa çalışsın

                // REKLAMI ÇAĞIR (Süre dolmadıysa kendi içinde iptal olur zaten)
                AdHelper.instance.showInterstitialAd();

                setState(() {
                  _currentIndex = index;
                });
              }
            },
            // Karanlık temaya uygun renk atamaları
            backgroundColor:
                theme.bottomNavigationBarTheme.backgroundColor ??
                (isDark ? Colors.grey.shade900 : Colors.white),
            indicatorColor: Colors.teal.withOpacity(isDark ? 0.3 : 0.2),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: Colors.teal),
                label: loc.navPrayer,
              ),
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore, color: Colors.teal),
                label: loc.navQibla,
              ),
              // --- ZİKİRMATİK İKONU BURAYA EKLENDİ ---
              NavigationDestination(
                icon: const Icon(
                  Icons.touch_app_outlined,
                ), // Dokunma/Zikir ikonu
                selectedIcon: const Icon(Icons.touch_app, color: Colors.teal),
                label: loc.zikirmatikTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard, color: Colors.teal),
                label: loc.navMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
