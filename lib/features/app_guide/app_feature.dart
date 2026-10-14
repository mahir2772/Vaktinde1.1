import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../duas/view/duas_view.dart';
import '../esmaul_husna/view/esmaul_husna_view.dart';
import '../fitre/view/fitre_view.dart';
import '../friday_messages/view/friday_messages_view.dart';
import '../home/view/home_view.dart';
import '../imsakiye/view/imsakiye_view.dart';
import '../location_search_dialog/location_search_dialog.dart';
import '../main_wrapper/main_tabs.dart';
import '../missed_prayers/view/missed_prayers_view.dart';
import '../notification_health/view/notification_health_view.dart';
import '../prayer_guide/view/prayer_guide_view.dart';
import '../prayer_tracker/view/prayer_tracker_view.dart';
import '../qibla/view/qibla_view.dart';
import '../quran/view/quran_view.dart';
import '../religious_days/view/religious_days_view.dart';
import '../settings/view/add_widget_sheet.dart';
import '../settings/view/time_adjust_view.dart';
import '../tools/nearby_mosques.dart';
import '../zakat/view/zakat_view.dart';
import '../zikirmatik/view/zikir_view.dart';

/// Yenilikler ve Uygulamayı Tanı satırlarının açtığı yerler
enum AppFeature {
  location,
  alarms,
  timeAdjust,
  notificationHealth,
  tracker,
  kaza,
  prayerGuide,
  qibla,
  zikir,
  quran,
  duas,
  imsakiye,
  religiousDays,
  esma,
  fridayMessages,
  zakat,
  fitre,
  nearbyMosques,
  widgets,
}

/// Özelliğin ekranını/sekmesini açar (reklamsız). Alt menü sekmesine geçerken
/// üstteki sayfalar kapanır; çerçeve yoksa (testler) sayfa açılır.
Future<void> openAppFeature(BuildContext context, AppFeature feature) async {
  final navigator = Navigator.of(context);
  void push(Widget page) =>
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  void tab(MainTab tab, Widget Function() page) {
    if (MainTabRequests.show(tab)) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      push(page());
    }
  }

  switch (feature) {
    case AppFeature.location:
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LocationSearchDialog(),
      );
    case AppFeature.alarms:
      // MainWrapper ana sekmeye, HomeView "Alarmlar" sekmesine geçer
      navigator.popUntil((route) => route.isFirst);
      HomeView.openAlarmsTab();
    case AppFeature.timeAdjust:
      push(const TimeAdjustView());
    case AppFeature.notificationHealth:
      push(const NotificationHealthView());
    case AppFeature.tracker:
      push(const PrayerTrackerView());
    case AppFeature.kaza:
      push(const MissedPrayersView());
    case AppFeature.prayerGuide:
      push(const PrayerGuideView());
    case AppFeature.qibla:
      tab(MainTab.qibla, () => const QiblaView());
    case AppFeature.zikir:
      tab(MainTab.zikir, () => const ZikirView());
    case AppFeature.quran:
      tab(MainTab.quran, () => const QuranView());
    case AppFeature.duas:
      push(const DuasView());
    case AppFeature.imsakiye:
      push(const ImsakiyeView());
    case AppFeature.religiousDays:
      push(const ReligiousDaysView());
    case AppFeature.esma:
      push(const EsmaulHusnaView());
    case AppFeature.fridayMessages:
      push(const FridayMessagesView());
    case AppFeature.zakat:
      push(const ZakatView());
    case AppFeature.fitre:
      push(const FitreView());
    case AppFeature.nearbyMosques:
      await openNearbyMosques(context);
    case AppFeature.widgets:
      // Başlatıcı eklemeyi desteklemiyorsa nasıl ekleneceği yazılır
      if (await canPinHomeWidget()) {
        if (context.mounted) await showAddWidgetSheet(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.guideWidgets)),
          );
      }
  }
}
