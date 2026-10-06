import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../home/view_model/home_view_model.dart';

/// "Vakit çıkmadan hatırlat" anahtarı + dakika seçimi (15/30/45)
class EndReminderSetting extends StatelessWidget {
  const EndReminderSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            SwitchListTile(
              secondary: const Icon(
                Icons.hourglass_bottom,
                color: Colors.deepOrange,
              ),
              title: Text(loc.endReminderTitle),
              subtitle: Text(loc.endReminderSub),
              value: viewModel.endReminderEnabled,
              activeColor: Colors.teal,
              onChanged: (value) => viewModel.setEndReminder(enabled: value),
            ),
            if (viewModel.endReminderEnabled)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final minutes
                          in PrayerTracker.endReminderMinuteOptions)
                        ChoiceChip(
                          label: Text(loc.timeAdjustMinutes('$minutes')),
                          selected: viewModel.endReminderMinutes == minutes,
                          selectedColor: Colors.teal.withValues(alpha: 0.25),
                          onSelected: (_) =>
                              viewModel.setEndReminder(minutes: minutes),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
