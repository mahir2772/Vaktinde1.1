import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../imsakiye/imsakiye_logic.dart';

/// Sadece Ramazan'da görünen sahur/iftar sayacı (CountdownWidget'ın altında).
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

  // Yarının vakitleri (akşamdan sonraki sahur sayacı için)
  PrayerTimesModel? _tomorrowTimes;
  DateTime? _tomorrowTimesDate;
  DateTime? _tomorrowRequested;

  @override
  void initState() {
    super.initState();
    _tick(rebuild: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
    if (!mounted) return;
    final now = DateTime.now();
    final today = dateOnly(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    final inRamadan = ramadanDayOf(today) != null;
    if (inRamadan && _tomorrowRequested != tomorrow) {
      _loadTomorrow(tomorrow);
    }

    final countdown = inRamadan
        ? ramadanCountdown(
            now: now,
            today: widget.prayerTimes,
            tomorrow: _tomorrowTimesDate == tomorrow ? _tomorrowTimes : null,
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

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds < 0 ? 0 : d.inSeconds;
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(totalSeconds ~/ 3600)}:"
        "${twoDigits((totalSeconds % 3600) ~/ 60)}:"
        "${twoDigits(totalSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final countdown = _countdown;
    if (loc == null || countdown == null) return const SizedBox.shrink();

    final isSahur = countdown.phase == RamadanPhase.sahur;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSahur ? Icons.nightlight_round : Icons.wb_twilight,
              color: Colors.amberAccent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSahur ? loc.ramadanSahurLeft : loc.ramadanIftarLeft,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    loc.ramadanDayLabel(countdown.fastDay),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDuration(_remaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: "Courier",
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
