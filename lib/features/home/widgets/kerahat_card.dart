import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../core/ui/app_format.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/info_banner.dart';
import '../../../data/models/prayer_times_model.dart';
import '../kerahat_logic.dart';
import 'hero_chip.dart';

/// Kerahat vakti sürüyorsa ya da 60 dk içinde başlayacaksa tek satırlık bilgi.
/// [onHero]: ana ekran sayacının altında kapsül (üstte 8dp boşlukla); değilse
/// uyarı şeridi. Gösterilecek bir şey yoksa yer kaplamaz.
class KerahatCard extends StatefulWidget {
  final PrayerTimesModel prayerTimes;
  final bool onHero;

  const KerahatCard({
    super.key,
    required this.prayerTimes,
    this.onHero = false,
  });

  @override
  State<KerahatCard> createState() => _KerahatCardState();
}

class _KerahatCardState extends State<KerahatCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final interval = relevantKerahat(widget.prayerTimes, now);
    if (interval == null) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final active = interval.isActiveAt(now);
    final range =
        '${formatClockTime(interval.start, loc.localeName)}–'
        '${formatClockTime(interval.end, loc.localeName)}';
    final message = active
        ? loc.kerahatActive(range)
        : loc.kerahatUpcoming(range);
    final icon = active ? Icons.do_not_disturb_on_outlined : Icons.schedule;

    if (widget.onHero) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: HeroChip(icon: icon, emphasized: active, child: Text(message)),
      );
    }
    return InfoBanner(message: message, icon: icon, tone: InfoTone.warning);
  }
}
