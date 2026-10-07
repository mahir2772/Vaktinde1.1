import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';

/// Zikirmatik ayarları: görünüm (modern/klasik), titreşim, ses, ekran açık
class ZikirSettingsView extends StatelessWidget {
  const ZikirSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppScaffold(
      title: loc.zikirSettings,
      body: Consumer<ZikirViewModel>(
        builder: (context, viewModel, child) {
          Widget modeRow(int mode, IconData icon, String title) {
            final selected = viewModel.viewMode == mode;
            return Semantics(
              selected: selected,
              inMutuallyExclusiveGroup: true,
              child: AppListTile(
                leadingIcon: icon,
                title: title,
                showChevron: false,
                trailing: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => viewModel.setViewMode(mode),
              ),
            );
          }

          Widget switchRow(
            IconData icon,
            String title,
            bool value,
            ValueChanged<bool> onChanged,
          ) {
            return AppListTile(
              leadingIcon: icon,
              title: title,
              showChevron: false,
              trailing: Switch(value: value, onChanged: onChanged),
              onTap: () => onChanged(!value),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              AppListSection(
                title: loc.appearance,
                children: [
                  modeRow(0, Icons.touch_app_outlined, loc.themeModern),
                  modeRow(1, Icons.blur_circular, loc.themeClassic),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppListSection(
                children: [
                  switchRow(
                    Icons.vibration,
                    loc.vibration,
                    viewModel.isVibrationEnabled,
                    viewModel.toggleVibration,
                  ),
                  switchRow(
                    Icons.volume_up_outlined,
                    loc.sound,
                    viewModel.isSoundEnabled,
                    viewModel.toggleSound,
                  ),
                  switchRow(
                    Icons.screen_lock_portrait_outlined,
                    loc.keepAwake,
                    viewModel.isKeepAwakeEnabled,
                    viewModel.toggleKeepAwake,
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
