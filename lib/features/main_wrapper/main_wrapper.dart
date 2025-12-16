import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart'; // <--- Provider Eklendi (Veri çekmek için)
import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/missed_prayers/view/missed_prayers_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart'; // <--- ViewModel Eklendi

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
    const MissedPrayersView(),
    const ToolsView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAd();

    // --- EKLENEN KISIM ---
    // Uygulama açılır açılmaz veriyi çekmeye başla.
    // IndexedStack sayesinde sayfa değişse bile bu veri korunacak.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().initializeApp();
    });
    // ---------------------
  }

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
          print('Reklam yüklenemedi: ${err.message}');
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
    return Scaffold(
      // --- KRİTİK DEĞİŞİKLİK BURASI ---
      // IndexedStack: Sayfaları hafızada canlı tutar.
      // Sekme değiştirince HomeView kapanmaz, sadece gizlenir.
      // Böylece tekrar tekrar API isteği atmaz.
      body: IndexedStack(index: _currentIndex, children: _pages),
      // -------------------------------

      // Alt Menü + Reklam (Senin Kodun)
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Colors.teal),
                label: 'Vakitler',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: Colors.teal),
                label: 'Kıble',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_edu_outlined),
                selectedIcon: Icon(Icons.history_edu, color: Colors.teal),
                label: 'Kaza',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view),
                selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.teal),
                label: 'Diğer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
