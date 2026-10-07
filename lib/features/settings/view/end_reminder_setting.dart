import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../home/view_model/home_view_model.dart';

/// "Vakit çıkmadan hatırlat" anahtarı + dakika seçimi (15/30/45).
/// Ayarlar listesindeki diğer satırlarla aynı görünüm (AppListTile).
class EndReminderSetting extends StatelessWidget {
  const EndReminderSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final enabled = viewModel.endReminderEnabled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppListTile(
              leadingIcon: Icons.hourglass_bottom,
              title: loc.endReminderTitle,
              subtitle: loc.endReminderSub,
              showChevron: false,
              trailing: Switch(
                value: enabled,
                onChanged: (value) => viewModel.setEndReminder(enabled: value),
              ),
              onTap: () => viewModel.setEndReminder(enabled: !enabled),
            ),
            if (enabled)
              Padding(
                // Başlıkla aynı hizada (ikon kutusu + boşluk)
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg + AppSizes.iconBox + AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final minutes
                        in PrayerTracker.endReminderMinuteOptions)
                      ChoiceChip(
                        label: Text(loc.timeAdjustMinutes('$minutes')),
                        selected: viewModel.endReminderMinutes == minutes,
                        onSelected: (_) =>
                            viewModel.setEndReminder(minutes: minutes),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
