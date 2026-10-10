import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/ad_consent.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
import '../../home/view_model/home_view_model.dart';
import '../../location_search_dialog/location_search_dialog.dart';
import '../../notification_health/view/notification_health_view.dart';
import 'add_widget_sheet.dart';
import 'end_reminder_setting.dart';
import 'language_sheet.dart';
import 'time_adjust_view.dart';

/// Ayarlar: dil ve görünüm, konum ve vakitler, destek, sürüm
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const String appLink =
      "https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde";
  static const String _supportMail = 'mmdigitall.dev@gmail.com';

  /// "Uygulamayı paylaş" linki: Play Console edinme raporlarında kaynak
  /// app_share olarak görünür
  static const String _inviteLink =
      'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde'
      '&referrer=utm_source%3Dapp_share%26utm_campaign%3Dinvite';

  /// Gizlilik politikası adresi ([AppLinks.privacyPolicy]); boşken satır gizli.
  /// Testte doldurulabilir.
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
              const EndReminderSetting(),
              Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  final enabled = viewModel.dailyContentEnabled;
                  return AppListTile(
                    leadingIcon: Icons.menu_book_outlined,
                    title: loc.dailyContentNotifTitle,
                    subtitle: loc.dailyContentNotifSub,
                    showChevron: false,
                    trailing: Switch(
                      value: enabled,
                      onChanged: viewModel.setDailyContentEnabled,
                    ),
                    onTap: () => viewModel.setDailyContentEnabled(!enabled),
                  );
                },
              ),
              Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  final enabled = viewModel.religiousDaysEnabled;
                  return AppListTile(
                    leadingIcon: Icons.event_note_outlined,
                    title: loc.religiousDaysNotifTitle,
                    subtitle: loc.religiousDaysNotifSub,
                    showChevron: false,
                    trailing: Switch(
                      value: enabled,
                      onChanged: viewModel.setReligiousDaysEnabled,
                    ),
                    onTap: () => viewModel.setReligiousDaysEnabled(!enabled),
                  );
                },
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
          // AB/EEA'da reklam rızası buradan sonradan değiştirilebilir (UMP zorunlu kılarsa)
          ValueListenableBuilder<bool>(
            valueListenable: AdConsent.privacyOptionsRequired,
            builder: (context, privacyRequired, _) => AppListSection(
              title: loc.sectionSupport,
              children: [
                AppListTile(
                  leadingIcon: Icons.share_outlined,
                  title: loc.shareApp,
                  onTap: () => Share.share(loc.shareText(_inviteLink)),
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
                if (privacyPolicyUrl.isNotEmpty)
                  AppListTile(
                    leadingIcon: Icons.policy_outlined,
                    title: loc.privacyPolicy,
                    onTap: _openPrivacyPolicy,
                  ),
                if (privacyRequired)
                  AppListTile(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: loc.adPrivacySettings,
                    subtitle: loc.adPrivacySettingsSub,
                    onTap: AdConsent.showPrivacyOptions,
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

  // Tarayıcıda (uygulama içi görünüm değil)
  static Future<void> _openPrivacyPolicy() async {
    try {
      if (!await launchUrl(
        Uri.parse(privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      )) {
        debugPrint("Gizlilik politikası açılamadı");
      }
    } catch (e) {
      debugPrint("Gizlilik politikası açılamadı: $e");
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

/// Tema (sistem/açık/koyu) ve arka plan görseli seçimi
class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  static const List<String> _mosques = ThemeProvider.mosqueBackgrounds;
  static const List<String> _kaabas = ThemeProvider.kaabaBackgrounds;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    Widget modeRow(ThemeMode mode, IconData icon, String label) {
      final selected = themeProvider.themeMode == mode;
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
          onTap: () => themeProvider.setThemeMode(mode),
        ),
      );
    }

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
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium,
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
