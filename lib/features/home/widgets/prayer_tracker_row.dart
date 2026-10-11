// ignore_for_file: empty_catches

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';
import '../../prayer_tracker/view/prayer_tracker_view.dart';
import '../view_model/home_view_model.dart';

/// Ana ekranda "Bugün" satırı: 5 farz vakit için "kıldım" işaretleri.
/// Vakti girmemiş namaz işaretlenemez. Başlığa dokununca takip ekranı açılır;
/// basılı tutunca bugün özel gün olur/olmaktan çıkar (takip ekranındaki gün
/// adıyla aynı). Özel günde işaretler soluk ve kapalıdır.
class PrayerTrackerRow extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  const PrayerTrackerRow({super.key, required this.prayerTimes});

  @override
  State<PrayerTrackerRow> createState() => _PrayerTrackerRowState();
}

class _PrayerTrackerRowState extends State<PrayerTrackerRow>
    with WidgetsBindingObserver {
  final PrayerTrackerService _service = PrayerTrackerService();
  Map<String, int> _log = const {};
  Set<String> _excused = const {};
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
      final excused = await _service.loadExcused();
      if (!mounted || _saving > 0 || generation != _generation) return;
      setState(() {
        _log = log;
        _excused = excused;
      });
    } catch (e) {}
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // Bugünün vakitleri kazaya eklenmiş olamaz (adaylar dünden başlar): onay yok
  Future<void> _toggleExcused(AppLocalizations loc) async {
    final now = DateTime.now();
    final today = PrayerTracker.day(now);
    final excused = !PrayerTracker.isExcused(_excused, today);
    _saving++;
    _generation++;
    setState(() {
      _excused = PrayerTracker.withExcused(
        _excused,
        today,
        excused,
        today: now,
      );
    });
    try {
      await _service.setExcused(today, excused);
    } catch (e) {
    } finally {
      _saving--;
    }
    _load();
    if (mounted) {
      _snack(excused ? loc.trackerExcusedMarked : loc.trackerExcusedUnmarked);
    }
  }

  bool _isDue(String key, DateTime now) {
    try {
      final parts = PrayerRefreshService.timesMap(
        widget.prayerTimes,
      )[key]!.split(':');
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
    final today = PrayerTracker.day(now);
    if (PrayerTracker.isExcused(_excused, today)) {
      _snack(loc.trackerExcusedCellSnack);
      return;
    }
    if (!_isDue(key, now)) {
      _snack(loc.trackerNotYet);
      return;
    }
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrayerTrackerView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = trackerPrayerNames(loc);
    final now = DateTime.now();
    final today = PrayerTracker.day(now);
    final doneCount = PrayerTracker.countOf(PrayerTracker.maskOf(_log, today));
    final total = PrayerTracker.prayerKeys.length;
    final excused = PrayerTracker.isExcused(_excused, today);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          MergeSemantics(
            child: Semantics(
              button: true,
              value: excused ? loc.trackerExcusedTitle : null,
              onLongPressHint: excused
                  ? loc.trackerExcusedUnmark
                  : loc.trackerExcusedMark,
              child: InkWell(
                onTap: _openTracker,
                onLongPress: () => _toggleExcused(loc),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouch,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.task_alt, color: scheme.primary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            loc.trackerToday,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        // Özel günde sayı yerine sade işaret (sayılmaz)
                        if (excused)
                          Icon(
                            kExcusedIcon,
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          )
                        else
                          Text(
                            "$doneCount/$total",
                            style: theme.textTheme.labelLarge!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Icon(
                          Icons.chevron_right,
                          color: scheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final key in PrayerTracker.prayerKeys)
                Expanded(
                  child: _buildChip(
                    label: names[key]!,
                    // Özel günde işaretler kayıtta kalır ama gösterilmez
                    prayed:
                        !excused && PrayerTracker.isPrayed(_log, today, key),
                    due: _isDue(key, now),
                    excused: excused,
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
    required bool excused,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final Color borderColor = excused
        ? scheme.outlineVariant
        : (prayed || due ? scheme.primary : scheme.outlineVariant);
    final Widget? mark = excused
        ? Icon(kExcusedIcon, color: scheme.onSurfaceVariant, size: 16)
        : prayed
        ? Icon(Icons.check, color: scheme.onPrimary, size: 20)
        : (due
              ? null
              : Icon(Icons.schedule, color: scheme.onSurfaceVariant, size: 16));
    return Semantics(
      button: true,
      toggled: excused ? null : prayed,
      enabled: !excused && (due || prayed),
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: excused
                      ? scheme.surfaceContainerHigh
                      : (prayed ? scheme.primary : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: mark,
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: !excused && (due || prayed)
                        ? scheme.onSurface
                        : colors.past,
                    fontWeight: FontWeight.w500,
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
