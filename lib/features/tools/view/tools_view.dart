import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../common/ad_helper.dart';
import '../../common/theme_provider.dart';
import '../../esmaul_husna/view/esmaul_husna_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../imsakiye/view/imsakiye_view.dart';
import '../../missed_prayers/view/missed_prayers_view.dart';
import '../../prayer_tracker/view/prayer_tracker_view.dart';
import '../../religious_days/view/religious_days_view.dart';
import '../../settings/view/settings_view.dart';
import '../../zakat/view/zakat_view.dart';
import '../nearby_mosques.dart';

/// Araçlar sekmesi: Ayarlar ile aynı dikey liste stili (ikon kutusu + başlık +
/// kısa açıklama, ≥56dp satırlar), Namaz / Bilgi / Hesap grupları ve en altta
/// Ayarlar satırı. Tek kaydırılabilir liste; büyük yazıda satırlar uzar.
class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  // Araç açılışında geçiş reklamı (AdHelper 5 dk soğuma süresini kendisi
  // uygular). Ayarlar (sorun giderme, izinler, destek) ve uygulamadan çıkan
  // Yakındaki Camiler (harita) reklamsız açılır.
  static void _open(BuildContext context, Widget page, {bool showAd = true}) {
    if (showAd) AdHelper.instance.showInterstitialAd();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasImage = context.watch<ThemeProvider>().backgroundImage != null;

    final groups = <(String, List<_ToolItem>)>[
      (
        loc.toolsGroupPrayer,
        [
          _ToolItem(
            Icons.calendar_month,
            loc.imsakiyeTitle,
            loc.toolImsakiyeDesc,
            () => const ImsakiyeView(),
          ),
          _ToolItem(
            Icons.task_alt,
            loc.trackerTitle,
            loc.toolTrackerDesc,
            () => const PrayerTrackerView(),
          ),
          _ToolItem(
            Icons.history_edu,
            loc.missedPrayersTitle,
            loc.toolKazaDesc,
            () => const MissedPrayersView(),
          ),
          _ToolItem.external(
            Icons.mosque_outlined,
            loc.nearbyMosquesTitle,
            loc.toolNearbyMosquesDesc,
            () => openNearbyMosques(context),
          ),
        ],
      ),
      (
        loc.toolsGroupInfo,
        [
          _ToolItem(
            Icons.event_note,
            loc.religiousDaysTitle,
            loc.toolReligiousDaysDesc,
            () => const ReligiousDaysView(),
          ),
          _ToolItem(
            Icons.menu_book,
            loc.esmaulHusnaTitle,
            loc.toolEsmaDesc,
            () => const EsmaulHusnaView(),
          ),
          _ToolItem(
            Icons.forum_outlined,
            loc.fridayMessagesTitle,
            loc.toolFridayDesc,
            () => const FridayMessagesView(),
          ),
        ],
      ),
      (
        loc.toolsGroupCalc,
        [
          _ToolItem(
            Icons.calculate_outlined,
            loc.zakatTitle,
            loc.toolZakatDesc,
            () => const ZakatView(),
          ),
        ],
      ),
    ];

    return AppScaffold(
      title: loc.navTools,
      showBanner: false, // alt menüde zaten banner var
      automaticallyImplyLeading: false,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          for (final (title, items) in groups) ...[
            _GroupHeader(title: title, onImage: hasImage),
            AppListSection(
              children: [
                for (final item in items)
                  AppListTile(
                    leadingIcon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    onTap: item.onTap ?? () => _open(context, item.page!()),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppListSection(
            children: [
              AppListTile(
                leadingIcon: Icons.settings_outlined,
                title: loc.menuTitle,
                subtitle: loc.toolSettingsDesc,
                onTap: () =>
                    _open(context, const SettingsView(), showAd: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function()? page;

  /// Sayfa yerine uygulama dışına çıkan araç (harita): geçiş reklamı yok
  final VoidCallback? onTap;

  const _ToolItem(
    this.icon,
    this.title,
    this.subtitle,
    Widget Function() this.page,
  ) : onTap = null;

  const _ToolItem.external(
    this.icon,
    this.title,
    this.subtitle,
    VoidCallback this.onTap,
  ) : page = null;
}

/// Grup başlığı; arka plan görseli seçiliyse okunur kalsın diye opak kapsül içinde
class _GroupHeader extends StatelessWidget {
  final String title;
  final bool onImage;

  const _GroupHeader({required this.title, required this.onImage});

  @override
  Widget build(BuildContext context) {
    if (!onImage) return SectionHeader(title);
    final theme = Theme.of(context);
    final colors = PrayerColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          header: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.heroChip,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall!.copyWith(
                color: colors.onHero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
