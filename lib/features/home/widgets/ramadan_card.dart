import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../imsakiye/imsakiye_logic.dart';
import '../../imsakiye/ramadan_calendar_loader.dart';
import '../../../core/ui/app_format.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../../core/ui/tabular_text.dart';
import 'hero_chip.dart';

/// Sadece Ramazan'da görünen sahur/iftar sayacı (ana ekran hero'sunda kapsül).
class RamadanCard extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  const RamadanCard({super.key, required this.prayerTimes});

  @override
  State<RamadanCard> createState() => _RamadanCardState();
}

class _RamadanCardState extends State<RamadanCard> {
  Timer? _timer;
  RamadanCountdown? _countdown;
  Duration _remaining = Duration.zero;

  // Diyanet tarihleri bir kez yüklenir; yüklenene kadar kart gizli
  RamadanCalendar? _calendar;

  // Yarının vakitleri (akşamdan sonraki sahur sayacı için)
  PrayerTimesModel? _tomorrowTimes;
  DateTime? _tomorrowTimesDate;
  DateTime? _tomorrowRequested;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    loadRamadanCalendar().then((calendar) {
      if (!mounted) return;
      _calendar = calendar;
      _tick();
    });
  }

  @override
  void didUpdateWidget(covariant RamadanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTimes != widget.prayerTimes) {
      // Konum/ince ayar değişmiş olabilir: yarını yeniden al
      _tomorrowTimes = null;
      _tomorrowTimesDate = null;
      _tomorrowRequested = null;
      _tick(rebuild: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick({bool rebuild = true}) {
    final calendar = _calendar;
    if (!mounted || calendar == null) return;
    final now = DateTime.now();
    final today = dateOnly(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    // Ramazan'dan önceki akşam da (ilk sahur) dahil
    final inRamadan =
        calendar.dayOf(today) != null || calendar.dayOf(tomorrow) != null;
    if (inRamadan && _tomorrowRequested != tomorrow) {
      _loadTomorrow(tomorrow);
    }

    final countdown = inRamadan
        ? ramadanCountdown(
            now: now,
            today: widget.prayerTimes,
            tomorrow: _tomorrowTimesDate == tomorrow ? _tomorrowTimes : null,
            calendar: calendar,
          )
        : null;
    if (countdown == null && _countdown == null) return;

    var remaining = countdown == null
        ? Duration.zero
        : countdown.target.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    if (rebuild) {
      setState(() {
        _countdown = countdown;
        _remaining = remaining;
      });
    } else {
      // initState/didUpdateWidget: ardından zaten build gelir
      _countdown = countdown;
      _remaining = remaining;
    }
  }

  Future<void> _loadTomorrow(DateTime date) async {
    _tomorrowRequested = date;
    try {
      final times = await PrayerTimeService().forDate(date);
      if (!mounted || _tomorrowRequested != date) return;
      _tomorrowTimes = times;
      _tomorrowTimesDate = date;
    } catch (_) {
      // Yedek: bugünün imsak saati yarına uygulanır
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final countdown = _countdown;
    if (loc == null || countdown == null) return const SizedBox.shrink();

    final isSahur = countdown.phase == RamadanPhase.sahur;
    final theme = Theme.of(context);
    final colors = PrayerColors.of(context);
    final label = isSahur ? loc.ramadanSahurLeft : loc.ramadanIftarLeft;
    final remaining = formatCountdown(_remaining);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: '$label $remaining. ${loc.ramadanDayLabel(countdown.fastDay)}',
        excludeSemantics: true,
        child: HeroChip(
          icon: isSahur ? Icons.nightlight_round : Icons.wb_twilight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      loc.ramadanDayLabel(countdown.fastDay),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onHeroMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TabularText(
                remaining,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: colors.onHero,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
