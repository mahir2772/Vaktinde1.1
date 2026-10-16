import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../common/ad_helper.dart';
import '../../common/theme_provider.dart';
import '../../duas/view/duas_view.dart';
import '../../esmaul_husna/view/esmaul_husna_view.dart';
import '../../fitre/view/fitre_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../imsakiye/view/imsakiye_view.dart';
import '../../prayer_guide/view/prayer_guide_view.dart';
import '../../prayer_tracker/view/prayer_tracker_view.dart';
import '../../religious_days/view/religious_days_view.dart';
import '../../settings/view/settings_view.dart';
import '../../zakat/view/zakat_view.dart';
import '../nearby_mosques.dart';

/// Araçlar sekmesi: Namaz / Bilgi / Hesap gruplarında büyük kutucuklar
/// (ToolTile; açıklama ekran okuyucuda ipucu) ve en altta Ayarlar satırı.
/// Sütun sayısı ekran genişliği ve yazı boyutuyla azalır (en çok 3); büyük
/// yazıda kutucuklar uzar, tek kaydırılabilir liste.
class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  static const int _maxColumns = 3;

  // Araç açılışında geçiş reklamı (sıklık sınırını AdHelper uygular).
  // Ayarlar (sorun giderme, izinler, destek), Dualar ve Namaz Hocası (ibadet;
  // Kur'an, Kıble, Zikir gibi) ve uygulamadan çıkan Yakındaki Camiler
  // reklamsız açılır.
  static void _open(BuildContext context, Widget page, {bool showAd = true}) {
    if (showAd) AdHelper.instance.showInterstitialAd(context);
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
          // Kaza sayaçları da burada ("Kaza" sekmesi)
          _ToolItem(
            Icons.task_alt,
            loc.trackerTitle,
            loc.toolTrackerDesc,
            () => const PrayerTrackerView(),
          ),
          _ToolItem(
            Icons.auto_stories_outlined,
            loc.duasTitle,
            loc.toolDuasDesc,
            () => const DuasView(),
            showAd: false,
          ),
          _ToolItem(
            Icons.school_outlined,
            loc.prayerGuideTitle,
            loc.toolPrayerGuideDesc,
            () => const PrayerGuideView(),
            showAd: false,
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
          // Kur'an alt menüde (MainWrapper sekmesi)
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
          _ToolItem(
            Icons.volunteer_activism_outlined,
            loc.fitreTitle,
            loc.toolFitreDesc,
            () => const FitreView(),
          ),
        ],
      ),
    ];

    return AppScaffold(
      title: loc.navTools,
      showBanner: false, // alt menüde zaten banner var
      automaticallyImplyLeading: false,
      // Liste uzun: Ayarlar kaydırmadan da açılsın
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: loc.menuTitle,
          onPressed: () => _open(context, const SettingsView(), showAd: false),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Her başlığın en uzun kelimesi bölünmeden sığsın (dil, yazı boyutu)
          var tileWidth = 0.0;
          for (final (_, items) in groups) {
            for (final item in items) {
              tileWidth = max(
                tileWidth,
                ToolTile.minWidth(context, item.title),
              );
            }
          }
          final width = constraints.maxWidth - 2 * AppSpacing.lg;
          final columns =
              ((width + AppSpacing.md) / (tileWidth + AppSpacing.md))
                  .floor()
                  .clamp(1, _maxColumns);
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              for (final (title, items) in groups) ...[
                _GroupHeader(title: title, onImage: hasImage),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _ToolGrid(
                    columns: columns,
                    children: [
                      for (final item in items)
                        ToolTile(
                          icon: item.icon,
                          title: item.title,
                          hint: item.description,
                          onTap:
                              item.onTap ??
                              () => _open(
                                context,
                                item.page!(),
                                showAd: item.showAd,
                              ),
                        ),
                    ],
                  ),
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
          );
        },
      ),
    );
  }
}

/// Kutucukları [columns] sütunlu satırlara dizer: satırdaki kutucuklar eşit
/// genişlik ve yükseklikte (en uzun başlık belirler), eksik satır boş kalır
class _ToolGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _ToolGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: i < children.length
                        ? children[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;

  /// Aracın kısa açıklaması (ekran okuyucu ipucu)
  final String description;
  final Widget Function()? page;

  /// Sayfa yerine uygulama dışına çıkan araç (harita): geçiş reklamı yok
  final VoidCallback? onTap;

  /// Açılışta geçiş reklamı (ibadet ekranlarında yok)
  final bool showAd;

  const _ToolItem(
    this.icon,
    this.title,
    this.description,
    Widget Function() this.page, {
    this.showAd = true,
  }) : onTap = null;

  const _ToolItem.external(
    this.icon,
    this.title,
    this.description,
    VoidCallback this.onTap,
  ) : page = null,
      showAd = false;
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
