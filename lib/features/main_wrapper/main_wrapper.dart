import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
// --- DİL DESTEĞİ İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// ---------------------------
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';

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

  final List<Widget> _pages = [
    const HomeView(),
    const QiblaView(),
    const ToolsView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAd();

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
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: Colors.teal.shade100,
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
