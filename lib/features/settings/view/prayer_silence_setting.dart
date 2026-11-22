import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/prayer_silence.dart';
import 'package:ezan_saati/data/services/prayer_tracker.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../home/view_model/home_view_model.dart';

/// Bildirim Ayarları satırı: "Namazdayım (otomatik sessiz)".
/// Anahtar açıldığında Rahatsız Etmeyin (DND) erişimi henüz yoksa ayar sayfası
/// açılarak izin adımı gösterilir; satıra dokununca süre, vakit ve Cuma ayarları
/// alttan açılır.
class PrayerSilenceSetting extends StatelessWidget {
  const PrayerSilenceSetting({super.key});

  Future<void> _openSheet(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    await vm.refreshDndAccess();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _PrayerSilenceSheet(),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    HomeViewModel vm,
    bool value,
  ) async {
    await vm.setPrayerSilence(enabled: value);
    if (value && !vm.dndAccessGranted && context.mounted) {
      await _openSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, _) {
        final settings = viewModel.prayerSilence;
        final needsPermission = settings.enabled && !viewModel.dndAccessGranted;
        final subtitle = !settings.enabled
            ? loc.prayerSilenceSub
            : needsPermission
            ? loc.prayerSilencePermissionNeeded
            : loc.prayerSilenceActiveSub(settings.durationMinutes);
        return AppListTile(
          leadingIcon: Icons.do_not_disturb_on_outlined,
          title: loc.prayerSilenceTitle,
          subtitle: subtitle,
          showChevron: false,
          trailing: Switch(
            value: settings.enabled,
            onChanged: (v) => _toggle(context, viewModel, v),
          ),
          onTap: () => _openSheet(context),
        );
      },
    );
  }
}

class _PrayerSilenceSheet extends StatelessWidget {
  const _PrayerSilenceSheet();

  String _prayerLabel(String key, AppLocalizations loc) => switch (key) {
    'İmsak' => loc.sabah,
    'Öğle' => loc.ogle,
    'İkindi' => loc.ikindi,
    'Akşam' => loc.aksam,
    'Yatsı' => loc.yatsi,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, _) {
        final settings = viewModel.prayerSilence;
        final hasAccess = viewModel.dndAccessGranted;
        return SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  loc.prayerSilenceTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!hasAccess) ...[
                InfoBanner(
                  message: loc.prayerSilencePermissionBanner,
                  icon: Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: viewModel.openDndAccessSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(loc.prayerSilenceGrantAccess),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                padding: EdgeInsets.zero,
                child: AppListTile(
                  leadingIcon: Icons.do_not_disturb_on_outlined,
                  title: loc.prayerSilenceTitle,
                  showChevron: false,
                  trailing: Switch(
                    value: settings.enabled,
                    onChanged: (v) => viewModel.setPrayerSilence(enabled: v),
                  ),
                  onTap: () =>
                      viewModel.setPrayerSilence(enabled: !settings.enabled),
                ),
              ),
              SectionHeader(
                loc.prayerSilenceDuration,
                onImage: false,
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final minutes in PrayerSilence.durationOptions)
                    ChoiceChip(
                      label: Text(loc.prayerSilenceMinutes(minutes)),
                      selected: settings.durationMinutes == minutes,
                      onSelected: (_) =>
                          viewModel.setPrayerSilence(durationMinutes: minutes),
                    ),
                ],
              ),
              SectionHeader(
                loc.prayerSilencePrayers,
                onImage: false,
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final key in PrayerTracker.prayerKeys)
                    FilterChip(
                      label: Text(_prayerLabel(key, loc)),
                      selected: settings.prayers.contains(key),
                      onSelected: (selected) {
                        final next = Set<String>.from(settings.prayers);
                        if (selected) {
                          next.add(key);
                        } else {
                          next.remove(key);
                        }
                        viewModel.setPrayerSilence(prayers: next);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: AppListTile(
                  leadingIcon: Icons.mosque_outlined,
                  title: loc.prayerSilenceFridayTitle,
                  subtitle: loc.prayerSilenceFridaySub,
                  showChevron: false,
                  trailing: Switch(
                    value: settings.fridayEnabled,
                    onChanged: (v) =>
                        viewModel.setPrayerSilence(fridayEnabled: v),
                  ),
                  onTap: () => viewModel.setPrayerSilence(
                    fridayEnabled: !settings.fridayEnabled,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoBanner(message: loc.prayerSilenceNote),
            ],
          ),
        );
      },
    );
  }
}
