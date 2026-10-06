import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../kerahat_logic.dart';

/// Kerahat vakti sürüyorsa ya da 60 dk içinde başlayacaksa tek satırlık bilgi kartı
class KerahatCard extends StatefulWidget {
  final PrayerTimesModel prayerTimes;
  final bool hasImage;

  const KerahatCard({
    super.key,
    required this.prayerTimes,
    required this.hasImage,
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

  // Ana ekrandaki vakit biçimiyle aynı (en/ar 12 saat)
  String _format(DateTime t, String langCode) {
    final minute = t.minute.toString().padLeft(2, '0');
    final use12Hour = langCode.startsWith('ar') || langCode.startsWith('en');
    if (!use12Hour) return "${t.hour.toString().padLeft(2, '0')}:$minute";
    String amPm;
    if (langCode.startsWith('ar')) {
      amPm = t.hour >= 12 ? "م" : "ص";
    } else {
      amPm = t.hour >= 12 ? "PM" : "AM";
    }
    int hour = t.hour % 12;
    if (hour == 0) hour = 12;
    return "${hour.toString().padLeft(2, '0')}:$minute $amPm";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final interval = relevantKerahat(widget.prayerTimes, now);
    if (interval == null) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final active = interval.isActiveAt(now);
    final range =
        "${_format(interval.start, loc.localeName)}–${_format(interval.end, loc.localeName)}";
    final cardColor = Theme.of(context).cardTheme.color;
    final accent = active ? Colors.deepOrange : Colors.orange;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.hasImage ? cardColor?.withValues(alpha: 0.85) : cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.do_not_disturb_on_outlined : Icons.schedule,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? loc.kerahatActive(range) : loc.kerahatUpcoming(range),
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
