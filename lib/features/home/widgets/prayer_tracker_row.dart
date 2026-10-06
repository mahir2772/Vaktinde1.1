// ignore_for_file: empty_catches

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../common/ad_helper.dart';
import '../../prayer_tracker/view/prayer_tracker_view.dart';
import '../view_model/home_view_model.dart';

/// Ana ekranda "Bugün" satırı: 5 farz vakit için "kıldım" işaretleri.
/// Vakti girmemiş namaz işaretlenemez. Başlığa dokununca takip ekranı açılır.
class PrayerTrackerRow extends StatefulWidget {
  final PrayerTimesModel prayerTimes;
  final bool hasImage;

  const PrayerTrackerRow({
    super.key,
    required this.prayerTimes,
    required this.hasImage,
  });

  @override
  State<PrayerTrackerRow> createState() => _PrayerTrackerRowState();
}

class _PrayerTrackerRowState extends State<PrayerTrackerRow>
    with WidgetsBindingObserver {
  final PrayerTrackerService _service = PrayerTrackerService();
  Map<String, int> _log = const {};
  Timer? _timer;
  // Kaydedilmemiş dokunuş varken okunan eski kayıt ekrana yazılmaz
  int _saving = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PrayerTrackerService.changes.addListener(_load);
    _load();
    // Vakit girince işaret açılır; bildirimden (başka isolate) işaretlenen vakit,
    // gün değişimi de kayıttan yeniden okunarak yansır
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PrayerTrackerService.changes.removeListener(_load);
    _timer?.cancel();
    super.dispose();
  }

  // Bildirimden "Kıldım" denmiş olabilir
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_saving > 0) return;
    final generation = _generation;
    try {
      final log = await _service.loadLog();
      if (!mounted || _saving > 0 || generation != _generation) return;
      setState(() => _log = log);
    } catch (e) {}
  }

  bool _isDue(String key, DateTime now) {
    try {
      final parts = PrayerRefreshService.timesMap(widget.prayerTimes)[key]!
          .split(':');
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return !now.isBefore(time);
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggle(String key, AppLocalizations loc) async {
    final now = DateTime.now();
    if (!_isDue(key, now)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(loc.trackerNotYet)));
      return;
    }
    final today = PrayerTracker.day(now);
    final prayed = !PrayerTracker.isPrayed(_log, today, key);
    final viewModel = context.read<HomeViewModel>();
    _saving++;
    _generation++;
    setState(() {
      _log = PrayerTracker.withPrayed(_log, today, key, prayed, today: now);
    });
    try {
      await _service.setPrayed(today, key, prayed);
    } catch (e) {
    } finally {
      _saving--;
    }
    _load();
    // Geri alınan vaktin "vakit çıkıyor" hatırlatması yeniden kurulur
    if (!prayed) {
      try {
        await viewModel.refreshEndReminders();
      } catch (e) {}
    }
  }

  void _openTracker() {
    AdHelper.instance.showInterstitialAd();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrayerTrackerView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final names = trackerPrayerNames(loc);
    final now = DateTime.now();
    final today = PrayerTracker.day(now);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardTheme.color;
    final doneCount = PrayerTracker.countOf(PrayerTracker.maskOf(_log, today));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: widget.hasImage ? cardColor?.withValues(alpha: 0.85) : cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _openTracker,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.task_alt, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.trackerToday,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    "$doneCount/${PrayerTracker.prayerKeys.length}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              for (final key in PrayerTracker.prayerKeys)
                Expanded(
                  child: _buildChip(
                    label: names[key]!,
                    prayed: PrayerTracker.isPrayed(_log, today, key),
                    due: _isDue(key, now),
                    onTap: () => _toggle(key, loc),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool prayed,
    required bool due,
    required VoidCallback onTap,
  }) {
    final Color circleColor = prayed ? Colors.teal : Colors.transparent;
    final Color borderColor = prayed
        ? Colors.teal
        : (due ? Colors.teal.withValues(alpha: 0.6) : Colors.grey.shade400);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: due || prayed ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: prayed
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : (due
                          ? null
                          : Icon(
                              Icons.schedule,
                              color: Colors.grey.shade500,
                              size: 16,
                            )),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
