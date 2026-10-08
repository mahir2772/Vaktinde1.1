import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../alarm_health.dart';
import '../view_model/home_view_model.dart';

/// Ezan uyarısını engelleyen durum için kısa uyarı şeridi (ana ekran ve
/// "Alarmlar" sekmesi). Sorun yoksa ya da hiç alarm açık değilse yer kaplamaz.
/// Bildirimler kapalıysa o, değilse tam zamanlı alarm izni uyarısı gösterilir.
class AlarmHealthBanner extends StatelessWidget {
  final HomeViewModel viewModel;
  final EdgeInsetsGeometry padding;

  const AlarmHealthBanner({
    super.key,
    required this.viewModel,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final health = viewModel.alarmHealth;
    return ListenableBuilder(
      listenable: health,
      builder: (context, _) {
        final issue = health.issue(anyAlarmEnabled: viewModel.anyAlarmEnabled);
        if (issue == null) return const SizedBox.shrink();
        final loc = AppLocalizations.of(context)!;
        final colors = PrayerColors.of(context);
        final (
          String message,
          String actionLabel,
          IconData icon,
          Future<void> Function() onFix,
        ) = switch (issue) {
          AlarmHealthIssue.notificationsOff => (
            loc.alarmHealthNotificationsOff,
            loc.alarmHealthNotificationsAction,
            Icons.notifications_off_outlined,
            health.fixNotifications,
          ),
          AlarmHealthIssue.exactAlarmsOff => (
            loc.alarmHealthExactOff,
            loc.alarmHealthExactAction,
            Icons.alarm_off,
            health.fixExactAlarms,
          ),
        };
        return Padding(
          padding: padding,
          child: InfoBanner(
            tone: InfoTone.warning,
            icon: icon,
            message: message,
            actionBelow: true,
            action: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colors.onWarningContainer,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              onPressed: onFix,
              child: Text(actionLabel),
            ),
          ),
        );
      },
    );
  }
}
