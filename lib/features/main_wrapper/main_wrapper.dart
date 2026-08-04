import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';

// --- 5 ADIMLIK TANITIM İÇİN GLOBAL ANAHTARLAR ---
final GlobalKey homeLangKey = GlobalKey();
final GlobalKey homeStoryKey = GlobalKey();
final GlobalKey homeAlarmsKey = GlobalKey();
final GlobalKey qiblaKey = GlobalKey();
final GlobalKey zikirmatikKey = GlobalKey();

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 🔥 YENİ: Turun birden fazla kez başlamasını engellemek için güvenlik kilidi
  bool _isTutorialChecked = false;

  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  final List<Widget> _pages = [
    const HomeView(),
    const QiblaView(),
    const ZikirView(),
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
        context.read<HomeViewModel>().initializeApp(loc);
      }
    });
  }

  // --- ÇEVİRİ YARDIMCI FONKSİYONU ---
  String _t(AppLocalizations loc, String trText, String enText) {
    return loc.localeName.startsWith('tr') ? trText : enText;
  }

  Future<void> _checkAndStartShowcase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Testleri temiz yapmak için versiyonu v3 yaptık, sen test ettikçe silecek
    bool isFirstTime = prefs.getBool('is_first_launch_showcase_v3') ?? true;

    if (isFirstTime && mounted) {
      // 5 adımlı turu sırayla başlatır
      ShowCaseWidget.of(context).startShowCase([
        homeLangKey,
        homeStoryKey,
        homeAlarmsKey,
        qiblaKey,
        zikirmatikKey,
      ]);
      await prefs.setBool('is_first_launch_showcase_v3', false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      // 🔥 KESİN ÇÖZÜM: Build işlemi bittikten hemen sonra state güncellenecek
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeViewModel>().updateLocalization(loc);
        }
      });
    }
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

    // 🔥 YENİ KUSURSUZ MİMARİ: View Model'i dinliyoruz.
    final viewModel = context.watch<HomeViewModel>();

    // Eğer yükleme bittiyse ve tur henüz başlamadıysa tetikle!
    if (!viewModel.isLoading && !_isTutorialChecked) {
      _isTutorialChecked = true; // Sadece 1 kez çalışması için kilidi kapat

      // Çizim işlemlerinin tam bitmesi için çok ufak bir süre tanıyıp başlatıyoruz
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartShowcase();
      });
    }

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
                AdHelper.instance.showInterstitialAd();
                setState(() {
                  _currentIndex = index;
                });
              }
            },
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

              // ADIM 4: KIBLE SEKMESİ
              Showcase(
                key: qiblaKey,
                description: _t(
                  loc,
                  "Kıble yönünü pusula ile bulabilirsiniz.",
                  "You can find the Qibla direction using the compass.",
                ),
                overlayColor: Colors.black.withOpacity(0.8),
                tooltipBackgroundColor: Colors.teal.shade800,
                textColor: Colors.white,
                child: NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore, color: Colors.teal),
                  label: loc.navQibla,
                ),
              ),

              // ADIM 5: ZİKİRMATİK SEKMESİ
              Showcase(
                key: zikirmatikKey,
                description: _t(
                  loc,
                  "Zikirlerinizi buradan takip edebilirsiniz.",
                  "You can track your dhikrs from here.",
                ),
                overlayColor: Colors.black.withOpacity(0.8),
                tooltipBackgroundColor: Colors.teal.shade800,
                textColor: Colors.white,
                child: NavigationDestination(
                  icon: const Icon(Icons.touch_app_outlined),
                  selectedIcon: const Icon(Icons.touch_app, color: Colors.teal),
                  label: loc.zikirmatikTitle,
                ),
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
