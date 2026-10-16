import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../home/view/home_view.dart';
import '../../home/view_model/home_view_model.dart';
import '../../prayer_tracker/view/prayer_tracker_view.dart' show kExcusedIcon;
import 'end_reminder_setting.dart';
import 'friday_notification_setting.dart';

/// Bildirim Ayarları (Ayarlar > Bildirimler): ezan alarmları (ana ekranın
/// "Alarmlar" sekmesi), vakit çıkmadan hatırlatma, günün ayeti ve hadisi, dini
/// gün ve kandil, Cuma, özel gün, kalıcı bildirim
class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppScaffold(
      title: loc.notificationSettingsTitle,
      showBanner: false,
      body: ListView(
        // Banner yok: son satır gezinme çubuğunun üstünde kalsın (uçtan uca)
        padding: EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppListSection(
            children: [
              // Vakit başına ezan, sessiz bildirim, ses ve önceden hatırlatma:
              // MainWrapper ana sekmeye, HomeView "Alarmlar" sekmesine geçer
              AppListTile(
                leadingIcon: Icons.alarm,
                title: loc.ezanAlarmsTitle,
                subtitle: loc.ezanAlarmsSub,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  HomeView.openAlarmsTab();
                },
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
              const FridayNotificationSetting(),
              Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  final enabled = viewModel.excusedSilentEzan;
                  return AppListTile(
                    leadingIcon: kExcusedIcon,
                    title: loc.excusedSilentEzanTitle,
                    subtitle: loc.excusedSilentEzanSub,
                    showChevron: false,
                    trailing: Switch(
                      value: enabled,
                      onChanged: viewModel.setExcusedSilentEzan,
                    ),
                    onTap: () => viewModel.setExcusedSilentEzan(!enabled),
                  );
                },
              ),
              Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  final enabled = viewModel.persistentNotificationEnabled;
                  return AppListTile(
                    leadingIcon: Icons.timer_outlined,
                    title: loc.persistentNotifTitle,
                    subtitle: loc.persistentNotifSub,
                    showChevron: false,
                    trailing: Switch(
                      value: enabled,
                      onChanged: viewModel.setPersistentNotificationEnabled,
                    ),
                    onTap: () =>
                        viewModel.setPersistentNotificationEnabled(!enabled),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
