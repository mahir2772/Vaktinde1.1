import 'package:flutter/material.dart';
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
import 'package:ezan_saati/features/common/widgets/ad_banner_widget.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';

import 'app_showcase.dart';

export 'app_showcase.dart'
    show homeLangKey, homeStoryKey, homeAlarmsKey, qiblaKey, zikirmatikKey;

/// Tanıtım turu görüldü mü (false = görüldü; tur başlarken yazılır)
const String tourSeenKey = 'is_first_launch_showcase_v3';

/// Alt menü (Ana Sayfa, Kıble, Zikirmatik, Araçlar) + banner + tanıtım turu.
/// Uygulama verisini (HomeViewModel.initializeApp) tek yerden burada başlatır.
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Sekmeler ilk ziyarette kurulur: pusula/konum açılışta başlamaz
  final Set<int> _visited = {0};

  // Tur birden fazla kez başlamasın
  bool _isTutorialChecked = false;

  @override
  void initState() {
    super.initState();
    AdHelper.instance.loadInterstitialAd();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      if (loc != null) {
        context.read<HomeViewModel>().initializeApp(loc);
      }
    });
  }

  /// Açılış sırası: ilk kez → tanıtım turu (izinler turun sonunda); sonraki
  /// açılışlarda tur yoksa → izin akışı hiç tamamlanmadıysa izinler (ör. tur
  /// yarıda kaldı), ardından pil optimizasyonu (en fazla bir kez). Pencereler
  /// üst üste binmez.
  Future<void> _runStartupFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(tourSeenKey) ?? true;
    if (!mounted) return;
    if (isFirstTime && _startTour()) {
      await prefs.setBool(tourSeenKey, false);
      return;
    }
    await primePermissionsIfNeeded(context);
    if (!mounted) return;
    await context.read<HomeViewModel>().requestBatteryOptimizationOnce();
  }

  /// Turu ekranda olan hedeflerle başlatır (5.x'te eksik hedef turu erken
  /// bitirir; günün ayeti/hadisi yüklenmediyse o adım atlanır)
  bool _startTour() {
    try {
      final view = ShowcaseView.get();
      final keys = [
        homeLangKey,
        homeStoryKey,
        homeAlarmsKey,
        qiblaKey,
        zikirmatikKey,
      ].where(view.isTargetRendered).toList();
      if (keys.isEmpty) return false;
      view.startShowCase(keys);
      return true;
    } catch (e) {
      debugPrint('Tanıtım turu başlatılamadı: $e');
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeViewModel>().updateLocalization(loc);
        }
      });
    }
  }

  Widget _page(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => const HomeView(),
      1 => const QiblaView(),
      2 => const ZikirView(),
      _ => const ToolsView(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final viewModel = context.watch<HomeViewModel>();

    // Yükleme bitince tur bir kez denenir
    if (!viewModel.isLoading && !_isTutorialChecked) {
      _isTutorialChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runStartupFlow();
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [for (var i = 0; i < 4; i++) _page(i)],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBannerWidget(adUnitId: AdIds.mainBanner),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              if (_currentIndex == index) return;
              setState(() {
                _visited.add(index);
                _currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: loc.navPrayer,
              ),
              AppShowcase(
                showcaseKey: qiblaKey,
                description: loc.showcaseQibla,
                child: NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore),
                  label: loc.navQibla,
                ),
              ),
              AppShowcase(
                showcaseKey: zikirmatikKey,
                description: loc.showcaseZikir,
                child: NavigationDestination(
                  icon: const Icon(Icons.touch_app_outlined),
                  selectedIcon: const Icon(Icons.touch_app),
                  label: loc.navZikir,
                ),
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view_rounded),
                label: loc.navTools,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
