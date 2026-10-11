import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../common/share_card.dart';
import '../../imsakiye/imsakiye_logic.dart';
import '../../imsakiye/ramadan_calendar_loader.dart';
import '../../../core/ui/app_format.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../../core/ui/tabular_text.dart';
import '../view_model/home_view_model.dart';
import 'hero_chip.dart';

/// Sadece Ramazan'da görünen sahur/iftar sayacı (ana ekran hero'sunda kapsül)
/// + yanında resimli paylaşım ("İftara 1 sa 12 dk", kampanya: iftar).
class RamadanCard extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  /// Şimdiki zaman (testler için); verilmezse DateTime.now
  final DateTime Function()? clock;

  const RamadanCard({super.key, required this.prayerTimes, this.clock});

  @override
  State<RamadanCard> createState() => _RamadanCardState();
}

/// Paylaşılan iftar/sahur kartının metinleri: başlık "Ramazan · 12. gün",
/// büyük metin "İftara 1 sa 12 dk", alt satır "İstanbul · İftar 18:12".
/// Kalan süre dakikaya yukarı yuvarlanır (30 sn → "1 dk").
({String title, String message, String subtitle}) ramadanShareContent(
  AppLocalizations loc, {
  required RamadanCountdown countdown,
  required Duration remaining,
  String? place,
}) {
  final seconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final minutes = (seconds + 59) ~/ 60;
  final duration = minutes < 60
      ? loc.ramadanShareMinutes(minutes)
      : minutes % 60 == 0
      ? loc.ramadanShareHours(minutes ~/ 60)
      : loc.ramadanShareHoursMinutes(minutes ~/ 60, minutes % 60);
  final time = formatClockTime(countdown.target, loc.localeName);
  final isSahur = countdown.phase == RamadanPhase.sahur;
  final at = isSahur
      ? loc.ramadanShareImsakAt(time)
      : loc.ramadanShareIftarAt(time);
  final where = place?.trim() ?? '';
  return (
    title: loc.ramadanShareTitle(countdown.fastDay),
    message: isSahur
        ? loc.ramadanShareSahurIn(duration)
        : loc.ramadanShareIftarIn(duration),
    subtitle: where.isEmpty ? at : '$where · $at',
  );
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
    final now = (widget.clock ?? DateTime.now)();
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

  /// Resimli paylaşım; konum ana ekranla aynı ("İl / İlçe")
  Future<void> _share() async {
    final loc = AppLocalizations.of(context);
    final countdown = _countdown;
    if (loc == null || countdown == null) return;
    final home = Provider.of<HomeViewModel?>(context, listen: false);
    final content = ramadanShareContent(
      loc,
      countdown: countdown,
      remaining: _remaining,
      place: cityLabel(home?.city, home?.district),
    );
    await shareAsImage(
      context,
      title: content.title,
      message: content.message,
      source: content.subtitle,
      campaign: 'iftar',
    );
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
      // Dar ekranda/büyük yazıda paylaş düğmesi kapsülün altına iner
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          Semantics(
            container: true,
            label:
                '$label $remaining. ${loc.ramadanDayLabel(countdown.fastDay)}',
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
          IconButton(
            onPressed: _share,
            tooltip: loc.share,
            style: IconButton.styleFrom(
              backgroundColor: colors.heroChip,
              foregroundColor: colors.onHero,
            ),
            icon: const Icon(Icons.share, size: 20),
          ),
        ],
      ),
    );
  }
}
