import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../prayer_schedule.dart';
import '../view_model/home_view_model.dart';
import 'alarm_health_banner.dart';

/// "Alarmlar" sekmesi: en üstte izin uyarısı (varsa) ve "sessiz modda da çal" (8.0+);
/// sonra her vakit için açılır kart (tam vakitte ezan, sessiz bildirim, ses
/// seçimi, önceden uyarı). Sıradaki vakit vurgulanır. Aynı denetimler ana
/// ekranda vakit hücresine dokununca alt sayfada açılır ([showPrayerAlarmSheet]).
class AlarmSettingsList extends StatelessWidget {
  final HomeViewModel viewModel;
  final String? nextKey;
  final EdgeInsetsGeometry padding;

  const AlarmSettingsList({
    super.key,
    required this.viewModel,
    required this.nextKey,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final times = viewModel.prayerTimes!;
    return ListView.separated(
      padding: padding,
      itemCount: homePrayerKeys.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AlarmHealthBanner(viewModel: viewModel),
              if (viewModel.alarmStreamSupported)
                _AlarmStreamTile(viewModel: viewModel),
            ],
          );
        }
        final key = homePrayerKeys[i - 1];
        return _AlarmCard(
          viewModel: viewModel,
          prayerKey: key,
          time: prayerTimeOf(times, key),
          isNext: key == nextKey,
        );
      },
    );
  }
}

/// "Sessiz modda da çal" (varsayılan kapalı): açıkken ezan alarm ses
/// seviyesinde çalar; hatırlatmalar ve yazılı bildirimler değişmez
class _AlarmStreamTile extends StatelessWidget {
  final HomeViewModel viewModel;

  const _AlarmStreamTile({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final enabled = viewModel.ezanAlarmStream;
    return AppCard(
      padding: EdgeInsets.zero,
      child: AppListTile(
        leadingIcon: Icons.volume_up_outlined,
        title: loc.ezanAlarmStreamTitle,
        subtitle: loc.ezanAlarmStreamSub,
        showChevron: false,
        trailing: Switch(
          value: enabled,
          onChanged: (value) => viewModel.setEzanAlarmStream(value),
        ),
        onTap: () => viewModel.setEzanAlarmStream(!enabled),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final HomeViewModel viewModel;
  final String prayerKey;
  final String time;
  final bool isNext;

  const _AlarmCard({
    required this.viewModel,
    required this.prayerKey,
    required this.time,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final anyActive = _anyAlarmOn(viewModel, prayerKey);

    final cardColor = isNext
        ? scheme.primaryContainer
        : theme.cardTheme.color ?? scheme.surfaceContainerLowest;
    final titleColor = isNext ? scheme.onPrimaryContainer : scheme.onSurface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: isNext
          ? BorderSide(color: colors.current, width: 1.5)
          : (theme.brightness == Brightness.light
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none),
    );
    return Material(
      color: cardColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.md,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNext ? scheme.primary : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              anyActive
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: isNext
                  ? scheme.onPrimary
                  : (anyActive ? scheme.primary : scheme.onSurfaceVariant),
              size: 20,
            ),
          ),
          // Dar ekranda büyük yazıda vakit adı ortadan bölünmez, küçülür
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              localizedPrayerName(prayerKey, loc),
              maxLines: 1,
              style: theme.textTheme.titleMedium!.copyWith(
                color: titleColor,
                fontSize: 17,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatPrayerTime(time, loc.localeName),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isNext
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          children: [
            Divider(color: scheme.outlineVariant),
            PrayerAlarmControls(viewModel: viewModel, prayerKey: prayerKey),
          ],
        ),
      ),
    );
  }
}

bool _anyAlarmOn(HomeViewModel viewModel, String prayerKey) =>
    (viewModel.onTimeAlarms[prayerKey] ?? false) ||
    (viewModel.reminderAlarms[prayerKey] ?? false);

/// Bir vaktin alarm denetimleri: tam vakitte ezan (+ sessiz bildirim, ezan
/// sesi), önceden uyarı (+ uyarı sesi). "Alarmlar" sekmesindeki kartta ve ana
/// ekranın alt sayfasında, aynı görünüm modeli yöntemleriyle.
class PrayerAlarmControls extends StatelessWidget {
  final HomeViewModel viewModel;
  final String prayerKey;

  const PrayerAlarmControls({
    super.key,
    required this.viewModel,
    required this.prayerKey,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isOnTimeActive = viewModel.onTimeAlarms[prayerKey] ?? false;
    final isReminderActive = viewModel.reminderAlarms[prayerKey] ?? false;
    final isSilentActive = viewModel.silentModeSettings[prayerKey] ?? false;
    final sureDegeri = (prayerKey == "İmsak" || prayerKey == "Güneş")
        ? "30"
        : "15";
    final currentEzanId = viewModel.selectedSounds[prayerKey] ?? "ezan1";
    final currentReminderId =
        viewModel.selectedReminderSounds[prayerKey] ?? "bildirim1";
    final switchTitle = theme.textTheme.titleSmall;
    final switchSubtitle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(loc.exactAlarm, style: switchTitle),
          subtitle: Text(loc.exactAlarmSub, style: switchSubtitle),
          value: isOnTimeActive,
          onChanged: (val) => viewModel.toggleAlarm(prayerKey, true, val),
        ),
        if (isOnTimeActive)
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
            ),
            title: Text(loc.silentNotif, style: switchTitle),
            subtitle: Text(loc.silentNotifSub, style: switchSubtitle),
            value: isSilentActive,
            onChanged: (val) => viewModel.toggleSilentMode(prayerKey, val),
          ),
        if (isOnTimeActive && !isSilentActive)
          _SoundSelector(
            viewModel: viewModel,
            prayerKey: prayerKey,
            currentSoundId: currentEzanId,
            soundList: viewModel.soundIds,
            isReminder: false,
          ),
        const SizedBox(height: AppSpacing.xs),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(loc.warningAlarm(sureDegeri), style: switchTitle),
          subtitle: Text(loc.warningAlarmSub, style: switchSubtitle),
          value: isReminderActive,
          onChanged: (val) => viewModel.toggleAlarm(prayerKey, false, val),
        ),
        if (isReminderActive)
          _SoundSelector(
            viewModel: viewModel,
            prayerKey: prayerKey,
            currentSoundId: currentReminderId,
            soundList: viewModel.reminderSoundIds,
            isReminder: true,
          ),
      ],
    );
  }
}

/// Ana ekranda vakit hücresine dokununca: o vaktin alarm ayarları (başlıkta
/// vakit adı ve saati; izin sorunu varsa uyarı şeridi). Kapanınca çalan ses
/// önizlemesi durur (durduracak düğme kalmaz).
Future<void> showPrayerAlarmSheet(
  BuildContext context, {
  required HomeViewModel viewModel,
  required String prayerKey,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        PrayerAlarmSheet(viewModel: viewModel, prayerKey: prayerKey),
  );
  await viewModel.stopPreview();
}

/// [showPrayerAlarmSheet] içeriği; ayar değişince yeniden çizilir
class PrayerAlarmSheet extends StatelessWidget {
  final HomeViewModel viewModel;
  final String prayerKey;

  const PrayerAlarmSheet({
    super.key,
    required this.viewModel,
    required this.prayerKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final loc = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final times = viewModel.prayerTimes;
        final anyActive = _anyAlarmOn(viewModel, prayerKey);
        return SingleChildScrollView(
          // + gezinme çubuğu (uçtan uca): son satır altında kalmasın
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.iconBox,
                    height: AppSizes.iconBox,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      anyActive
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: scheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Dar ekranda büyük yazıda vakit adı bölünmez, küçülür
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          localizedPrayerName(prayerKey, loc),
                          maxLines: 1,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                  if (times != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatPrayerTime(
                        prayerTimeOf(times, prayerKey),
                        loc.localeName,
                      ),
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AlarmHealthBanner(
                viewModel: viewModel,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              PrayerAlarmControls(viewModel: viewModel, prayerKey: prayerKey),
            ],
          ),
        );
      },
    );
  }
}

class _SoundSelector extends StatelessWidget {
  final HomeViewModel viewModel;
  final String prayerKey;
  final String currentSoundId;
  final List<String> soundList;
  final bool isReminder;

  const _SoundSelector({
    required this.viewModel,
    required this.prayerKey,
    required this.currentSoundId,
    required this.soundList,
    required this.isReminder,
  });

  String _soundName(String id, AppLocalizations loc) {
    if (id.startsWith("ezan")) {
      return "${loc.soundEzan} ${id.replaceAll("ezan", "")}";
    }
    if (id.startsWith("bildirim")) {
      return "${loc.soundBeep} ${id.replaceAll("bildirim", "")}";
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final accent = isReminder ? colors.warning : scheme.primary;
    final value = soundList.contains(currentSoundId)
        ? currentSoundId
        : soundList.first;
    final playing = viewModel.currentlyPlayingSound == value;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            isReminder ? Icons.notifications_active : Icons.volume_up,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.popupMenuTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.md),
                items: soundList
                    .map(
                      (soundId) => DropdownMenuItem<String>(
                        value: soundId,
                        child: Text(_soundName(soundId, loc)),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  if (newValue == null) return;
                  isReminder
                      ? viewModel.changeReminderSound(prayerKey, newValue)
                      : viewModel.changeSound(prayerKey, newValue);
                },
              ),
            ),
          ),
          IconButton(
            onPressed: () => viewModel.playPreview(value),
            // Ekran okuyucu: sesin adı değil, düğmenin yaptığı iş
            tooltip: playing
                ? loc.a11yStopSound
                : loc.a11yPlaySound(_soundName(value, loc)),
            icon: Icon(
              playing ? Icons.stop_circle : Icons.play_circle_fill,
              color: accent,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
