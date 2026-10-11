import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../core/ui/app_format.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../../core/ui/tabular_text.dart';
import '../../../data/models/prayer_times_model.dart';
import '../prayer_schedule.dart';

/// Ana ekranın odak noktası: sıradaki vakit adı, saati ve geri sayım.
/// Hero (gradyan/fotoğraf) üzerinde beyaz yazıyla çizilir; saniyede bir yenilenir.
/// Ekran okuyucu tek etiket okur ("Öğle vaktine 1 saat 12 dakika kaldı");
/// etiket dakikada bir değişir, saniyeler okunmaz.
class CountdownWidget extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  /// Şimdiki zaman (testler için); verilmezse DateTime.now
  final DateTime Function()? clock;

  const CountdownWidget({super.key, required this.prayerTimes, this.clock});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  late DateTime _now = _clock();

  DateTime _clock() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = _clock());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = PrayerColors.of(context);
    final next = upcomingPrayer(widget.prayerTimes, _now);
    if (next == null) return const SizedBox.shrink();

    final name = localizedPrayerName(next.key, loc);
    final time = formatPrayerTime(
      prayerTimeOf(widget.prayerTimes, next.key),
      loc.localeName,
    );
    final left = next.time.difference(_now);
    final remaining = formatCountdown(left);
    final timeLabel = next.isTomorrow ? '$time ${loc.tomorrow}' : time;

    return Semantics(
      container: true,
      // Saniyeli sayaç değil, dakikalık süre: odaktayken her saniye okunmaz
      label:
          '${loc.nextPrayer}: $name, $timeLabel. '
          '${loc.a11yTimeUntil(name, formatSpokenDuration(left, loc))}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.nextPrayer,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall!.copyWith(
              color: colors.onHeroMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineMedium!.copyWith(
                  color: colors.onHero,
                  height: 1.15,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  timeLabel,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: colors.onHeroMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          TabularText(
            remaining,
            style: theme.textTheme.displayMedium!.copyWith(
              color: colors.onHero,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
