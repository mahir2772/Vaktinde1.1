import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:ezan_saati/core/notification_routes.dart';
import 'package:ezan_saati/core/ui/feature_tip.dart';

import 'package:ezan_saati/features/home/view/home_view.dart';
import 'package:ezan_saati/features/qibla/view/qibla_view.dart';
import 'package:ezan_saati/features/quran/view/quran_view.dart';
import 'package:ezan_saati/features/zikirmatik/view/zikir_view.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/ad_helper.dart';
import 'package:ezan_saati/features/common/app_analytics.dart';
import 'package:ezan_saati/features/common/widgets/ad_banner_widget.dart';
import 'package:ezan_saati/features/common/open_surah.dart';
import 'package:ezan_saati/features/friday_messages/view/friday_messages_view.dart';
import 'package:ezan_saati/features/onboarding/view/onboarding_language_view.dart';
import 'package:ezan_saati/features/prayer_tracker/streak_review.dart';
import 'package:ezan_saati/features/quran/widgets/hatim_card.dart';
import 'package:ezan_saati/features/app_guide/whats_new.dart';

import 'app_showcase.dart';
import 'main_tabs.dart';

export 'main_tabs.dart';

export 'app_showcase.dart'
    show
        homeLangKey,
        homeTrackerKey,
        homeStoryKey,
        homeAlarmsKey,
        quranKey,
        qiblaKey,
        zikirmatikKey,
        toolsKey,
        TourRequests;

/// Tanıtım turu görüldü mü (false = görüldü; tur başlarken yazılır)
const String tourSeenKey = 'is_first_launch_showcase_v3';

/// Alt menü (Ana Sayfa, Kur'an, Kıble, Zikir, Araçlar) + banner + tanıtım turu.
/// Sekme değişiminde reklam yok; geçiş reklamı yerleri AdHelper'da. Uygulama verisini (HomeViewModel.initializeApp) tek yerden burada
/// başlatır.
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Sekmeler ilk ziyarette kurulur: pusula/konum ve Kur'an listesi açılışta
  // başlamaz
  final Set<int> _visited = {MainTab.home.index};

  // Tur birden fazla kez başlamasın
  bool _isTutorialChecked = false;

  // Açılış akışı (tur/izinler/Yenilikler) bitti: ipuçları ondan sonra
  bool _startupDone = false;

  // Bildirimden istenen ekran pencereler kapanana kadar bekler
  Timer? _routeRetry;

  // Değerlendirme isteği (açılış akışından sonra; ömür boyu tek istek ortak):
  // 7 günlük tam seride ya da uygulama 5 farklı günde açılınca
  late final StreakReviewPrompt _reviewPrompt;
  late final UsageReviewPrompt _usagePrompt;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<HomeViewModel>();
    _reviewPrompt = StreakReviewPrompt(
      todayTimes: () => viewModel.prayerTimes,
      canPrompt: _canPromptReview,
    );
    _usagePrompt = UsageReviewPrompt(canPrompt: _canPromptReview);
    AdHelper.instance.loadInterstitialAd();
    AdHelper.instance.startupWindowOpen = () => !_canPromptReview();
    HomeView.alarmsTabRequests.addListener(_showHomeTab);
    MainTabRequests.attach(_showTab);
    TourRequests.replays.addListener(_replayTour);
    FeatureTip.attachGate(_canShowTip);
    NotificationRoutes.pending.addListener(_openNotificationRoute);

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
  /// yarıda kaldı), ardından pil optimizasyonu (en fazla bir kez), sonra bu
  /// sürüme güncelleyene Yenilikler (bir kez; yeni kurulumda yok). Pencereler
  /// üst üste binmez.
  Future<void> _runStartupFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool(tourSeenKey) ?? true;
      if (!mounted) return;
      if (isFirstTime && _startTour()) {
        await prefs.setBool(tourSeenKey, false);
        // İlk açılış hunisi: tur kurulum başına bir kez başlar; 'tur_bitti'
        // gelmeyen tur yarıda kalmıştır
        AppAnalytics.logEvent(name: 'tur_basladi');
        if (mounted) await WhatsNew.showIfNeeded(context, updated: false);
        return;
      }
      await primePermissionsIfNeeded(context);
      if (!mounted) return;
      await context.read<HomeViewModel>().requestBatteryOptimizationOnce();
      if (!mounted) return;
      await WhatsNew.showIfNeeded(context, updated: !isFirstTime);
    } finally {
      // Değerlendirme isteği ve ipuçları açılış pencereleriyle çakışmaz
      if (mounted) {
        _startupDone = true;
        _reviewPrompt.start();
        _usagePrompt.start();
        _openNotificationRoute();
      }
    }
  }

  // İpucu: açılış akışı bittiyse ve değerlendirmeyle aynı pencereler kapalıysa
  bool _canShowTip() => _startupDone && _canPromptReview();

  // İzin, rıza formu ya da tanıtım turu açıkken değerlendirme istenmez (ilk
  // reklam fırsatındaki "Reklamlar hakkında" açıklaması da gösterilmez)
  bool _canPromptReview() =>
      !permissionPrimingActive &&
      !AdConsent.isGatheringConsent &&
      !_isTourRunning();

  bool _isTourRunning() {
    try {
      return ShowcaseView.get().isShowcaseRunning;
    } catch (e) {
      return false;
    }
  }

  /// Bildirimden istenen ekran (NotificationRoutes): açılış akışı bittikten
  /// sonra, tur/izin/rıza pencereleri kapalıyken (ipuçlarıyla aynı kapı)
  /// açılır; o zamana kadar saniyede bir yeniden denenir. Geçiş reklamı yok
  /// (AdMob: bildirimden açılan ekranda geçiş reklamı gösterilmez).
  void _openNotificationRoute() {
    _routeRetry?.cancel();
    final target = NotificationRoutes.pending.value;
    if (target == null || !mounted) return;
    if (!_canShowTip()) {
      _routeRetry = Timer(const Duration(seconds: 1), _openNotificationRoute);
      return;
    }
    NotificationRoutes.pending.value = null;
    switch (target.split(':')) {
      case [NotificationRoutes.friday]:
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const FridayMessagesView()),
        );
      case [NotificationRoutes.surah, final number]:
        final surah = int.tryParse(number);
        if (surah != null) openSurahReader(context, surah);
      case [NotificationRoutes.hatim]:
        openHatimReading(context);
    }
  }

  @override
  void dispose() {
    HomeView.alarmsTabRequests.removeListener(_showHomeTab);
    MainTabRequests.detach(_showTab);
    TourRequests.replays.removeListener(_replayTour);
    FeatureTip.detachGate(_canShowTip);
    NotificationRoutes.pending.removeListener(_openNotificationRoute);
    _routeRetry?.cancel();
    _reviewPrompt.dispose();
    _usagePrompt.dispose();
    super.dispose();
  }

  // Sekme içinden istenen geçiş (ör. ana ekranın Kur'an kartı)
  bool _showTab(MainTab tab) {
    if (!mounted) return false;
    if (_currentIndex != tab.index) {
      setState(() {
        _visited.add(tab.index);
        _currentIndex = tab.index;
      });
    }
    return true;
  }

  // "Alarmlar" sekmesi istendi (Bildirim Kontrolü): ana sayfa sekmesi seçilir
  void _showHomeTab() {
    if (_currentIndex == MainTab.home.index) return;
    setState(() => _currentIndex = MainTab.home.index);
  }

  /// Uygulamayı Tanı'dan: ana sekmenin "Vakitler" görünümüne dönülür, üstteki
  /// sayfalar kapandıktan sonra tur yeniden başlar (izinler yeniden sorulmaz:
  /// main.dart)
  Future<void> _replayTour() async {
    if (!_showTab(MainTab.home)) return;
    HomeView.openTimesTab();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted && !_isTourRunning()) _startTour();
  }

  /// Turu ekranda olan hedeflerle başlatır (5.x'te eksik hedef turu erken
  /// bitirir; günün ayeti/hadisi yüklenmediyse o adım atlanır)
  bool _startTour() {
    try {
      final view = ShowcaseView.get();
      final keys = [
        homeLangKey,
        homeTrackerKey,
        homeStoryKey,
        homeAlarmsKey,
        quranKey,
        qiblaKey,
        zikirmatikKey,
        toolsKey,
      ].where(view.isTargetRendered).toList();
      if (keys.isEmpty) return false;
      view.addOnFinishCallback(_logTourFinished);
      view.startShowCase(keys);
      return true;
    } catch (e) {
      debugPrint('Tanıtım turu başlatılamadı: $e');
      return false;
    }
  }

  // Tur sonuna kadar gidildi (eksik hedefle erken biten tur dahil)
  static void _logTourFinished() => AppAnalytics.logEvent(name: 'tur_bitti');

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
    return switch (MainTab.values[index]) {
      MainTab.home => const HomeView(),
      // Sekme: banner alt menüde (tek banner); sure okuyucu üstüne açılır
      MainTab.quran => const QuranView(asTab: true),
      MainTab.qibla => const QiblaView(),
      MainTab.zikir => const ZikirView(),
      MainTab.tools => const ToolsView(),
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
        children: [for (var i = 0; i < MainTab.values.length; i++) _page(i)],
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
                showcaseKey: quranKey,
                description: loc.showcaseQuran,
                child: NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: loc.navQuran,
                ),
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
              AppShowcase(
                showcaseKey: toolsKey,
                description: loc.showcaseTools,
                child: NavigationDestination(
                  icon: const Icon(Icons.grid_view_outlined),
                  selectedIcon: const Icon(Icons.grid_view_rounded),
                  label: loc.navTools,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
