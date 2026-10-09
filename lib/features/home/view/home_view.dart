import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../core/ui/app_theme.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../../core/ui/state_views.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
import '../../location_search_dialog/location_search_dialog.dart';
import '../../main_wrapper/app_showcase.dart';
import '../prayer_schedule.dart';
import '../view_model/home_view_model.dart';
import '../widgets/alarm_health_banner.dart';
import '../widgets/alarm_settings_list.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/daily_content.dart';
import '../widgets/kerahat_card.dart';
import '../widgets/prayer_times_grid.dart';
import '../widgets/prayer_tracker_row.dart';
import '../widgets/ramadan_card.dart';

/// Ana ekran: hero (konum, tarih, sıradaki vakit + sayaç, kerahat/Ramazan),
/// 2×3 vakit ızgarası, "Bugün" takibi, günün ayeti/hadisi; "Alarmlar" sekmesi.
/// Veriyi MainWrapper'ın başlattığı HomeViewModel verir.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  /// "Alarmlar" sekmesini açma istekleri (Bildirim Kontrolü): MainWrapper ana sayfa
  /// sekmesine, HomeView "Alarmlar" sekmesine geçer
  static final ValueNotifier<int> alarmsTabRequests = ValueNotifier(0);

  static void openAlarmsTab() => alarmsTabRequests.value++;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _ticker;
  String? _nextKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    HomeView.alarmsTabRequests.addListener(_showAlarmsTab);
    // Vakit girince arka plan rengi ve vurgu değişir
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = _computeNextKey(context.read<HomeViewModel>());
      if (next != _nextKey) setState(() => _nextKey = next);
    });
  }

  @override
  void dispose() {
    HomeView.alarmsTabRequests.removeListener(_showAlarmsTab);
    _ticker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _showAlarmsTab() => _tabController.animateTo(1);

  String? _computeNextKey(HomeViewModel vm) {
    final times = vm.prayerTimes;
    if (times == null) return null;
    return upcomingPrayer(times, DateTime.now())?.key;
  }

  void _openLocationSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final loc = AppLocalizations.of(context)!;
    final hasImage = context.watch<ThemeProvider>().backgroundImage != null;
    _nextKey = _computeNextKey(viewModel);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(viewModel, loc),
      body: Stack(
        children: [
          Positioned.fill(
            child: _HeroBackground(nextKey: _nextKey, hasImage: hasImage),
          ),
          SafeArea(
            bottom: false,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimesTab(viewModel, loc, hasImage),
                _buildAlarmsTab(viewModel, loc, hasImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    HomeViewModel viewModel,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    const onHero = Colors.white;
    Widget tabLabel(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: onHero,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: AppTheme.lightBars,
      centerTitle: true,
      iconTheme: const IconThemeData(color: onHero),
      actionsIconTheme: const IconThemeData(color: onHero),
      title: Text(
        loc.appTitle,
        style: theme.textTheme.titleLarge!.copyWith(
          color: onHero,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        AppShowcase(
          showcaseKey: homeLangKey,
          description: loc.showcaseLanguage,
          child: PopupMenuButton<Locale>(
            tooltip: loc.changeLanguage,
            icon: const Icon(Icons.language, color: onHero),
            onSelected: (Locale newLocale) {
              context.read<LanguageProvider>().setLanguage(newLocale);
              final vm = context.read<HomeViewModel>();
              vm.getDailyHadith(newLocale);
              vm.getDailyAyah(newLocale);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('tr'), child: Text("Türkçe")),
              PopupMenuItem(value: Locale('en'), child: Text("English")),
              PopupMenuItem(value: Locale('de'), child: Text("Deutsch")),
              PopupMenuItem(value: Locale('fr'), child: Text("Français")),
              PopupMenuItem(value: Locale('ar'), child: Text("العربية")),
            ],
          ),
        ),
        IconButton(
          tooltip: loc.refreshLocation,
          icon: const Icon(Icons.my_location),
          onPressed: () => viewModel.refreshLocationAndTimes(context),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: onHero,
        unselectedLabelColor: const Color(0xD9FFFFFF),
        indicatorColor: onHero,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: theme.textTheme.titleSmall!.copyWith(fontSize: 15),
        unselectedLabelStyle: theme.textTheme.titleSmall!.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            height: 48,
            child: tabLabel(Icons.access_time_filled, loc.tabTimes),
          ),
          AppShowcase(
            showcaseKey: homeAlarmsKey,
            description: loc.showcaseAlarms,
            child: Tab(height: 48, child: tabLabel(Icons.alarm, loc.tabAlarms)),
          ),
        ],
      ),
    );
  }

  // --- Yükleniyor / hata / veri yok: okunur zeminli tam sayfa ---
  Widget? _buildStatus(HomeViewModel viewModel, AppLocalizations loc) {
    if (viewModel.prayerTimes != null) return null;
    Widget child;
    if (viewModel.isLoading) {
      child = LoadingState(message: loc.loading);
    } else if (viewModel.errorMessageKey.isNotEmpty) {
      final locationProblem = const {
        'gpsOff',
        'permissionDenied',
        'locationError',
        'locationFoundNoName',
      }.contains(viewModel.errorMessageKey);
      child = ErrorState(
        message: _errorText(viewModel.errorMessageKey, loc),
        onRetry: () => viewModel.refreshLocationAndTimes(context),
        secondaryLabel: locationProblem ? loc.changeLocation : null,
        onSecondary: locationProblem ? _openLocationSearch : null,
      );
    } else {
      child = EmptyState(
        icon: Icons.location_searching,
        title: loc.noData,
        actionLabel: loc.changeLocation,
        onAction: _openLocationSearch,
      );
    }
    return _SheetSurface(opaque: true, child: child);
  }

  String _errorText(String key, AppLocalizations loc) => switch (key) {
    'noInternet' => loc.noInternet,
    'gpsOff' => loc.gpsOff,
    'permissionDenied' => loc.permissionDenied,
    'locationError' => loc.locationError,
    'internetNeeded' => loc.internetNeeded,
    'locationFoundNoName' => loc.locationFoundNoName,
    _ => loc.timesLoadError,
  };

  Widget _buildTimesTab(
    HomeViewModel viewModel,
    AppLocalizations loc,
    bool hasImage,
  ) {
    final status = _buildStatus(viewModel, loc);
    if (status != null) return status;
    final times = viewModel.prayerTimes!;
    final hasDaily =
        viewModel.dailyAyah != null ||
        (viewModel.dailyHadith?.content ?? '').isNotEmpty;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bildirim/alarm izni sorunu varsa (yoksa yer kaplamaz)
          AlarmHealthBanner(viewModel: viewModel),
          PrayerTimesGrid(prayerTimes: times),
          const SizedBox(height: AppSpacing.md),
          PrayerTrackerRow(prayerTimes: times),
          if (hasDaily) ...[
            const SizedBox(height: AppSpacing.md),
            AppShowcase(
              showcaseKey: homeStoryKey,
              description: loc.showcaseStory,
              autoScroll: true,
              child: DailyContentRow(
                ayah: viewModel.dailyAyah,
                hadith: viewModel.dailyHadith,
              ),
            ),
          ],
        ],
      ),
    );

    // Zemin tek parça çizilir (içerik + ekranın kalanı): dilim sınırında çizgi olmaz
    final Widget sheet = hasImage
        ? SliverToBoxAdapter(child: content)
        : DecoratedSliver(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: content),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                ),
              ],
            ),
          );

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHero(viewModel, loc)),
        sheet,
      ],
    );
  }

  String _locationText(HomeViewModel viewModel, AppLocalizations loc) {
    final city = viewModel.city;
    if (city == null || city.isEmpty) return loc.waitingLocation;
    var district = viewModel.district ?? '';
    // "Kadıköy" yerine "İstanbul Kadıköy" gibi gelen ilçe adından il adı atılır
    if (district.toLowerCase().startsWith(city.toLowerCase()) &&
        district.length > city.length) {
      district = district.substring(city.length).trim();
    }
    if (district.isEmpty || district.toLowerCase() == city.toLowerCase()) {
      return city;
    }
    return '$city / $district';
  }

  String _dateText(HomeViewModel viewModel, AppLocalizations loc) {
    String gregorian;
    try {
      gregorian = DateFormat('d MMMM y', loc.localeName).format(DateTime.now());
    } catch (_) {
      gregorian = DateFormat('dd.MM.yyyy').format(DateTime.now());
    }
    final hijri = viewModel.hijriDateText.trim();
    if (hijri.isEmpty) return gregorian;
    // Arapça rakamlarda sıfır (٠) noktaya benzer: ayraç olarak virgül
    final separator = loc.localeName.startsWith('ar') ? '، ' : ' · ';
    return '$gregorian$separator$hijri';
  }

  Widget _buildHero(HomeViewModel viewModel, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colors = PrayerColors.of(context);
    final times = viewModel.prayerTimes!;
    final location = _locationText(viewModel, loc);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: Colors.white,
                  backgroundColor: Color(0x40FFFFFF),
                ),
              ),
            ),
          Tooltip(
            message: loc.changeLocation,
            child: Semantics(
              button: true,
              label: '$location. ${loc.changeLocation}',
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: _openLocationSearch,
                  customBorder: const StadiumBorder(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.minTouch,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: colors.onHero,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: colors.onHero,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.expand_more,
                            size: 20,
                            color: colors.onHeroMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            _dateText(viewModel, loc),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: colors.onHeroMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CountdownWidget(prayerTimes: times),
          KerahatCard(prayerTimes: times, onHero: true),
          RamadanCard(prayerTimes: times),
        ],
      ),
    );
  }

  Widget _buildAlarmsTab(
    HomeViewModel viewModel,
    AppLocalizations loc,
    bool hasImage,
  ) {
    final status = _buildStatus(viewModel, loc);
    if (status != null) return status;
    return _SheetSurface(
      opaque: !hasImage,
      child: AlarmSettingsList(
        viewModel: viewModel,
        nextKey: _nextKey,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
      ),
    );
  }
}

/// Hero'nun altındaki yuvarlak köşeli zemin (arka plan resminde şeffaf;
/// kartlar zaten opak)
class _SheetSurface extends StatelessWidget {
  final bool opaque;
  final Widget child;

  const _SheetSurface({required this.opaque, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!opaque) return child;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Sıradaki vakte göre gradyan (gün saatine göre değişir) + yazı için karartma.
/// Arka plan resmi seçiliyse resim MaterialApp'te çizilir; burada sadece karartma.
class _HeroBackground extends StatelessWidget {
  final String? nextKey;
  final bool hasImage;

  const _HeroBackground({required this.nextKey, required this.hasImage});

  static const Map<String, List<Color>> _gradients = {
    'İmsak': [Color(0xFF0D47A1), Color(0xFF42A5F5)],
    'Güneş': [Color(0xFFE65100), Color(0xFFDD2476)],
    'Öğle': [Color(0xFF1E6FA8), Color(0xFF4FB3E0)],
    'İkindi': [Color(0xFF373B44), Color(0xFF4286F4)],
    'Akşam': [Color(0xFF2C3E50), Color(0xFFE0645C)],
    'Yatsı': [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = PrayerColors.of(context);
    if (hasImage) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.45, 1],
            colors: [
              colors.heroImageScrim,
              colors.heroImageScrim.withValues(
                alpha: colors.heroImageScrim.a * 0.8,
              ),
              colors.heroImageScrim.withValues(
                alpha: colors.heroImageScrim.a * 0.4,
              ),
            ],
          ),
        ),
      );
    }
    final gradient =
        _gradients[nextKey] ?? const [Color(0xFF00796B), Color(0xFF26A69A)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: ColoredBox(color: colors.heroScrim),
    );
  }
}
