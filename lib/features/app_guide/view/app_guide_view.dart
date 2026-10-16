import 'package:flutter/material.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../main_wrapper/app_showcase.dart';
import '../app_feature.dart';

typedef _GuideItem = (IconData, String, String, AppFeature);

/// Uygulamayı Tanı (Ayarlar): en üstte tanıtım turunu yeniden izleme, sonra
/// gruplu özellik listesi (kısa "nasıl kullanılır"); her satır ilgili ekranı
/// ya da sekmeyi açar. Reklamsız (geçiş reklamı ve banner yok).
class AppGuideView extends StatelessWidget {
  const AppGuideView({super.key});

  // Tur ana ekranda: sayfalar kapanır, MainWrapper ana sekmede turu başlatır
  static void _replayTour(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    TourRequests.replay();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final groups = <(String, List<_GuideItem>)>[
      (
        loc.guideGroupTimes,
        [
          (
            Icons.location_on_outlined,
            loc.changeLocation,
            loc.guideLocation,
            AppFeature.location,
          ),
          (Icons.alarm, loc.tabAlarms, loc.guideAlarms, AppFeature.alarms),
          (
            Icons.notifications_paused_outlined,
            loc.whatsNewStopTitle,
            loc.whatsNewStopDesc,
            AppFeature.alarms,
          ),
          (
            Icons.tune,
            loc.timeAdjustTitle,
            loc.timeAdjustSub,
            AppFeature.timeAdjust,
          ),
          (
            Icons.notifications_outlined,
            loc.notificationSettingsTitle,
            loc.notificationSettingsSub,
            AppFeature.notificationSettings,
          ),
          (
            Icons.notifications_active_outlined,
            loc.healthTitle,
            loc.healthSub,
            AppFeature.notificationHealth,
          ),
        ],
      ),
      (
        loc.guideGroupPrayer,
        [
          (
            Icons.task_alt,
            loc.trackerTitle,
            loc.guideTracker,
            AppFeature.tracker,
          ),
          (
            Icons.history_edu,
            loc.missedPrayersTitle,
            loc.guideKaza,
            AppFeature.kaza,
          ),
          (
            Icons.school_outlined,
            loc.prayerGuideTitle,
            loc.toolPrayerGuideDesc,
            AppFeature.prayerGuide,
          ),
          (
            Icons.explore_outlined,
            loc.qiblaTitle,
            loc.guideQibla,
            AppFeature.qibla,
          ),
          (
            Icons.touch_app_outlined,
            loc.zikirmatikTitle,
            loc.guideZikir,
            AppFeature.zikir,
          ),
        ],
      ),
      (
        loc.guideGroupQuran,
        [
          (
            Icons.auto_stories_outlined,
            loc.quranTitle,
            loc.guideQuran,
            AppFeature.quran,
          ),
          (Icons.flag_outlined, loc.hatimTitle, loc.hatimIntro, AppFeature.quran),
          (
            Icons.menu_book_outlined,
            loc.duasTitle,
            loc.toolDuasDesc,
            AppFeature.duas,
          ),
        ],
      ),
      (
        loc.navTools,
        [
          (
            Icons.calendar_month,
            loc.imsakiyeTitle,
            loc.toolImsakiyeDesc,
            AppFeature.imsakiye,
          ),
          (
            Icons.event_note,
            loc.religiousDaysTitle,
            loc.toolReligiousDaysDesc,
            AppFeature.religiousDays,
          ),
          (
            Icons.menu_book,
            loc.esmaulHusnaTitle,
            loc.toolEsmaDesc,
            AppFeature.esma,
          ),
          (
            Icons.forum_outlined,
            loc.fridayMessagesTitle,
            loc.toolFridayDesc,
            AppFeature.fridayMessages,
          ),
          (
            Icons.calculate_outlined,
            loc.zakatTitle,
            loc.toolZakatDesc,
            AppFeature.zakat,
          ),
          (
            Icons.volunteer_activism_outlined,
            loc.fitreTitle,
            loc.toolFitreDesc,
            AppFeature.fitre,
          ),
          (
            Icons.mosque_outlined,
            loc.nearbyMosquesTitle,
            loc.toolNearbyMosquesDesc,
            AppFeature.nearbyMosques,
          ),
        ],
      ),
      (
        loc.guideGroupWidgets,
        [
          (
            Icons.widgets_outlined,
            loc.addWidgetTitle,
            loc.guideWidgets,
            AppFeature.widgets,
          ),
        ],
      ),
    ];

    return AppScaffold(
      title: loc.appGuideTitle,
      showBanner: false,
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl,
        ),
        children: [
          AppListSection(
            children: [
              AppListTile(
                leadingIcon: Icons.play_circle_outline,
                title: loc.appGuideReplayTour,
                subtitle: loc.appGuideReplayTourSub,
                onTap: () => _replayTour(context),
              ),
              AppListTile(
                leadingIcon: Icons.format_size,
                title: loc.textSizeTitle,
                subtitle: loc.whatsNewTextSizeDesc,
                onTap: () => openAppFeature(context, AppFeature.textSize),
              ),
            ],
          ),
          for (final (title, items) in groups)
            AppListSection(
              title: title,
              children: [
                for (final (icon, name, howTo, feature) in items)
                  AppListTile(
                    leadingIcon: icon,
                    title: name,
                    subtitle: howTo,
                    onTap: () => openAppFeature(context, feature),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
