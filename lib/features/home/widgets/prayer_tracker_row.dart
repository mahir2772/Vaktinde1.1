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
/// Vakti girmemiş namaz işaretlenemez. Başlığa dokununca takip ekranı açılır.
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
              child: InkWell(
                onTap: _openTracker,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final Color borderColor = prayed
        ? scheme.primary
        : (due ? scheme.primary : scheme.outlineVariant);
    return Semantics(
      button: true,
      toggled: prayed,
      enabled: due || prayed,
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
                  color: prayed ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: prayed
                    ? Icon(Icons.check, color: scheme.onPrimary, size: 20)
                    : (due
                          ? null
                          : Icon(
                              Icons.schedule,
                              color: scheme.onSurfaceVariant,
                              size: 16,
                            )),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: due || prayed ? scheme.onSurface : colors.past,
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
