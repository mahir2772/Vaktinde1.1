import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../app_guide/view/app_guide_view.dart';
import '../../common/ad_consent.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
import '../../home/view_model/home_view_model.dart';
import '../../location_search_dialog/location_search_dialog.dart';
import '../../notification_health/view/notification_health_view.dart';
import 'add_widget_sheet.dart';
import 'backup_setting.dart';
import 'language_sheet.dart';
import 'notification_settings_view.dart';
import 'privacy_ads_view.dart';
import 'time_adjust_view.dart';

/// Ayarlar: dil ve görünüm, konum ve vakitler, bildirimler, yedekleme, destek
/// (gizlilik ve reklamlar ayrı sayfada), sürüm
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const String appLink =
      "https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde";
  static const String _supportMail = 'mmdigitall.dev@gmail.com';

  /// Gizlilik politikası adresi ([AppLinks.privacyPolicy]); Gizlilik ve
  /// Reklamlar sayfasına verilir, boşken satır gizli. Testte doldurulabilir.
  @visibleForTesting
  static String privacyPolicyUrl = AppLinks.privacyPolicy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final languageCode = context.watch<LanguageProvider>().locale.languageCode;

    return AppScaffold(
      title: loc.menuTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          HomeWidgetPinSupport(
            builder: (context, canPinWidget) => AppListSection(
              title: loc.sectionAppearance,
              children: [
                AppListTile(
                  leadingIcon: Icons.language,
                  title: loc.changeLanguage,
                  subtitle: languageNativeName(languageCode),
                  onTap: () => showLanguageSheet(context),
                ),
                AppListTile(
                  leadingIcon: Icons.palette_outlined,
                  title: loc.appearanceSettings,
                  subtitle: loc.appearanceSub,
                  onTap: () => _showAppearanceSettings(context),
                ),
                // Başlatıcı uygulamadan eklemeyi destekliyorsa (Android 8+)
                if (canPinWidget)
                  AppListTile(
                    leadingIcon: Icons.widgets_outlined,
                    title: loc.addWidgetTitle,
                    subtitle: loc.addWidgetSub,
                    onTap: () => showAddWidgetSheet(context),
                  ),
              ],
            ),
          ),
          AppListSection(
            title: loc.sectionLocation,
            children: [
              Consumer<HomeViewModel>(
                builder: (context, viewModel, child) => AppListTile(
                  leadingIcon: Icons.location_on_outlined,
                  title: loc.changeLocation,
                  subtitle: _locationText(viewModel, loc),
                  onTap: () => _showLocationSearch(context),
                ),
              ),
              AppListTile(
                leadingIcon: Icons.tune,
                title: loc.timeAdjustTitle,
                subtitle: loc.timeAdjustSub,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TimeAdjustView(),
                  ),
                ),
              ),
            ],
          ),
          AppListSection(
            title: loc.sectionNotifications,
            children: [
              // Ezan alarmları, hatırlatmalar, günün ayeti, kandil, kalıcı bildirim
              AppListTile(
                leadingIcon: Icons.notifications_outlined,
                title: loc.notificationSettingsTitle,
                subtitle: loc.notificationSettingsSub,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsView(),
                  ),
                ),
              ),
              // Bildirim izni, alarm izni, ses, pil, üretici ayarları ve test ezanı
              AppListTile(
                leadingIcon: Icons.notifications_active_outlined,
                title: loc.healthTitle,
                subtitle: loc.healthSub,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationHealthView(),
                  ),
                ),
              ),
            ],
          ),
          // Namaz takibi, kaza, zikir ve ayarlar tek dosyaya / dosyadan
          const BackupSection(),
          // AB/EEA'da reklam rızası Gizlilik ve Reklamlar sayfasından sonradan
          // değiştirilebilir (UMP zorunlu kılarsa satırın alt yazısı bunu söyler)
          ValueListenableBuilder<bool>(
            valueListenable: AdConsent.privacyOptionsRequired,
            builder: (context, privacyRequired, _) => AppListSection(
              title: loc.sectionSupport,
              children: [
                // Özellikler, nasıl kullanılır ve tanıtım turunu yeniden izle
                AppListTile(
                  leadingIcon: Icons.lightbulb_outline,
                  title: loc.appGuideTitle,
                  subtitle: loc.appGuideSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AppGuideView(),
                    ),
                  ),
                ),
                AppListTile(
                  leadingIcon: Icons.share_outlined,
                  title: loc.shareApp,
                  onTap: () => Share.share(loc.shareText(AppLinks.playStoreLink('invite'))),
                ),
                AppListTile(
                  leadingIcon: Icons.star_outline,
                  title: loc.rateApp,
                  onTap: _openStoreListing,
                ),
                AppListTile(
                  leadingIcon: Icons.mail_outline,
                  title: loc.contactUs,
                  onTap: () => _sendSupportMail(loc),
                ),
                // Gizlilik politikası, reklamlar hakkında, reklam gizlilik ayarları
                AppListTile(
                  leadingIcon: Icons.shield_outlined,
                  title: loc.privacyAdsTitle,
                  subtitle: privacyRequired
                      ? loc.privacyAdsConsentSub
                      : loc.privacyAdsSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PrivacyAdsView(privacyPolicyUrl: privacyPolicyUrl),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _AboutFooter(),
        ],
      ),
    );
  }

  static String _locationText(HomeViewModel viewModel, AppLocalizations loc) {
    final city = viewModel.city ?? loc.citySelect;
    final district = viewModel.district;
    if (district != null && district.isNotEmpty) return '$district, $city';
    return city;
  }

  static Future<void> _openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing(
        appStoreId: 'com.mmdigital.vaktinde',
      );
    } catch (e) {
      if (!await launchUrl(
        Uri.parse(appLink),
        mode: LaunchMode.externalApplication,
      )) {
        debugPrint("Link açılamadı");
      }
    }
  }

  static Future<void> _sendSupportMail(AppLocalizations loc) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportMail,
      query: 'subject=${Uri.encodeComponent(loc.supportMailSubject)}',
    );
    try {
      if (!await launchUrl(uri)) debugPrint("Mail açılamadı");
    } catch (e) {
      debugPrint("Mail açılamadı: $e");
    }
  }

  void _showLocationSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSearchDialog(),
    );
  }

  void _showAppearanceSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _AppearanceSheet(),
    );
  }
}

/// Tema (sistem/açık/koyu), yazı boyutu ve arka plan görseli seçimi
class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  static const List<String> _mosques = ThemeProvider.mosqueBackgrounds;
  static const List<String> _kaabas = ThemeProvider.kaabaBackgrounds;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    Widget optionRow(
      IconData icon,
      String label, {
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: AppListTile(
          leadingIcon: icon,
          title: label,
          showChevron: false,
          trailing: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      );
    }

    Widget modeRow(ThemeMode mode, IconData icon, String label) => optionRow(
      icon,
      label,
      selected: themeProvider.themeMode == mode,
      onTap: () => themeProvider.setThemeMode(mode),
    );

    // Seçilince hemen uygulanır (bu pencere de büyür)
    Widget scaleRow(double scale, IconData icon, String label) => optionRow(
      icon,
      label,
      selected: themeProvider.textScale == scale,
      onTap: () => themeProvider.setTextScale(scale),
    );

    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): görseller altında kalmasın
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              loc.appearanceSettings,
              style: theme.textTheme.titleLarge,
            ),
          ),
          SectionHeader(loc.themeMode),
          modeRow(ThemeMode.system, Icons.brightness_auto, loc.themeSystem),
          modeRow(ThemeMode.light, Icons.light_mode_outlined, loc.themeLight),
          modeRow(ThemeMode.dark, Icons.dark_mode_outlined, loc.themeDark),
          SectionHeader(loc.textSizeTitle),
          scaleRow(1.0, Icons.text_fields, loc.textSizeNormal),
          scaleRow(1.15, Icons.format_size, loc.textSizeLarge),
          scaleRow(1.3, Icons.text_increase, loc.textSizeExtraLarge),
          SectionHeader(loc.bgImage),
          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _BackgroundOption(
                  image: null,
                  label: loc.bgDefault,
                  selected: themeProvider.backgroundImage == null,
                  onTap: () => themeProvider.setBackgroundImage(null),
                ),
                for (var i = 0; i < _mosques.length; i++)
                  _BackgroundOption(
                    image: _mosques[i],
                    label: '${loc.bgMosque} ${i + 1}',
                    selected: themeProvider.backgroundImage == _mosques[i],
                    onTap: () => themeProvider.setBackgroundImage(_mosques[i]),
                  ),
                for (var i = 0; i < _kaabas.length; i++)
                  _BackgroundOption(
                    image: _kaabas[i],
                    label: '${loc.bgKaaba} ${i + 1}',
                    selected: themeProvider.backgroundImage == _kaabas[i],
                    onTap: () => themeProvider.setBackgroundImage(_kaabas[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOption extends StatelessWidget {
  final String? image;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundOption({
    required this.image,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: selected
                ? BorderSide(color: scheme.primary, width: 3)
                : BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            width: 80,
            decoration: image == null
                ? null
                : BoxDecoration(
                    // Yüklenemezse boş kutu kalır; hata bildirilmez
                    image: DecorationImage(
                      image: AssetImage('assets/images/backgrounds/$image'),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    ),
                  ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  if (image == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        // Büyük yazıda kelime bölünmesin: tek satıra sığacak
                        // kadar küçülür
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  if (selected)
                    PositionedDirectional(
                      top: AppSpacing.xs,
                      end: AppSpacing.xs,
                      child: Icon(
                        Icons.check_circle,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uygulama adı, gerçek sürüm (paket bilgisinden) ve yapımcı
class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  static Future<String?>? _version;

  static Future<String?> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isEmpty) return null;
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.mosque, color: scheme.primary, size: 40),
          const SizedBox(height: AppSpacing.sm),
          Text(loc.appTitle, style: theme.textTheme.titleMedium),
          FutureBuilder<String?>(
            future: _version ??= _loadVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data;
              if (version == null) return const SizedBox.shrink();
              return Text(
                loc.versionLabel(version),
                textAlign: TextAlign.center,
                style: muted,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.madeBy,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
