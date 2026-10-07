import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_format.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../../core/ui/prayer_time_row.dart';
import '../../../data/models/prayer_times_model.dart';
import '../prayer_schedule.dart';

/// Ana ekrandaki 2×3 vakit ızgarası: sıradaki vakit dolu renkte, şu anki vakit
/// çerçeveli, geçmiş vakitler soluk; Güneş namaz vakti olmadığı için ikonla
/// ayrılır. Vakit girdikçe kendini yeniler.
class PrayerTimesGrid extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  const PrayerTimesGrid({super.key, required this.prayerTimes});

  @override
  State<PrayerTimesGrid> createState() => _PrayerTimesGridState();
}

class _PrayerTimesGridState extends State<PrayerTimesGrid> {
  Timer? _timer;
  late Map<String, PrayerRowState> _states;

  @override
  void initState() {
    super.initState();
    _states = prayerRowStates(widget.prayerTimes, DateTime.now());
    // Sadece durum değişince yeniden çizilir
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant PrayerTimesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTimes != widget.prayerTimes) {
      _states = prayerRowStates(widget.prayerTimes, DateTime.now());
    }
  }

  void _refresh() {
    if (!mounted) return;
    final states = prayerRowStates(widget.prayerTimes, DateTime.now());
    final changed = homePrayerKeys.any((k) => states[k] != _states[k]);
    if (changed) setState(() => _states = states);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cell(String key) => Expanded(
      child: _PrayerCell(
        prayerKey: key,
        time: prayerTimeOf(widget.prayerTimes, key),
        state: _states[key] ?? PrayerRowState.upcoming,
      ),
    );
    Widget row(String a, String b) => Row(
      children: [
        cell(a),
        const SizedBox(width: AppSpacing.sm),
        cell(b),
      ],
    );
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          row('İmsak', 'Güneş'),
          const SizedBox(height: AppSpacing.sm),
          row('Öğle', 'İkindi'),
          const SizedBox(height: AppSpacing.sm),
          row('Akşam', 'Yatsı'),
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  final String prayerKey;
  final String time;
  final PrayerRowState state;

  const _PrayerCell({
    required this.prayerKey,
    required this.time,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isSunrise = prayerKey == 'Güneş';
    final name = localizedPrayerName(prayerKey, loc);
    final formatted = formatPrayerTime(time, loc.localeName);

    final Color background = switch (state) {
      PrayerRowState.next => colors.nextContainer,
      _ => isLight ? scheme.surfaceContainerLow : scheme.surfaceContainer,
    };
    final Color nameColor = switch (state) {
      PrayerRowState.next => colors.onNextContainer,
      PrayerRowState.current => colors.current,
      PrayerRowState.past => colors.past,
      PrayerRowState.upcoming => scheme.onSurfaceVariant,
    };
    final Color timeColor = switch (state) {
      PrayerRowState.next => colors.onNextContainer,
      PrayerRowState.current => colors.current,
      PrayerRowState.past => colors.past,
      PrayerRowState.upcoming => scheme.onSurface,
    };
    final emphasized =
        state == PrayerRowState.next || state == PrayerRowState.current;

    final semantics = StringBuffer('$name $formatted');
    if (state == PrayerRowState.next) semantics.write(', ${loc.nextPrayer}');
    if (state == PrayerRowState.current) {
      semantics.write(', ${loc.currentPrayer}');
    }
    if (isSunrise) semantics.write(', ${loc.sunriseNotPrayer}');

    return Semantics(
      container: true,
      label: semantics.toString(),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: state == PrayerRowState.current
                ? colors.current
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSunrise) ...[
                  Icon(
                    Icons.wb_twilight,
                    size: 16,
                    color: state == PrayerRowState.next
                        ? colors.onNextContainer
                        : colors.sunrise,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: nameColor,
                      fontWeight: emphasized
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatted,
                maxLines: 1,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: timeColor,
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
