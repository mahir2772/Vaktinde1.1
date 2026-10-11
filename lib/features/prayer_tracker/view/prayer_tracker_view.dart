// ignore_for_file: empty_catches

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:provider/provider.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../home/view_model/home_view_model.dart';
import '../../imsakiye/imsakiye_logic.dart';
import '../widgets/ramadan_fast_card.dart';

/// Takip edilen vakitlerin ekran adları ("İmsak" anahtarı = sabah namazı)
Map<String, String> trackerPrayerNames(AppLocalizations loc) => {
  "İmsak": loc.sabah,
  "Öğle": loc.ogle,
  "İkindi": loc.ikindi,
  "Akşam": loc.aksam,
  "Yatsı": loc.yatsi,
};

/// Özel gün (hayız/nifas) işareti: hücrelerde, açıklamada ve başlık düğmesinde
const IconData kExcusedIcon = Icons.spa_outlined;

/// Namaz takibi: son 7 gün, 30 günlük oran, seri ve kılınmayanları kazaya ekleme;
/// Ramazan'da (ve sonraki 30 gün) üstte Ramazan orucu kartı. Özel gün: gün adına
/// basılı tutunca (ya da başlıktaki düğmeyle bugün) işaretlenir; o günün hücreleri
/// soluk ve kapalıdır, seri/oran/kaza hesabına girmez (PrayerTracker).
class PrayerTrackerView extends StatefulWidget {
  /// Test: oruç kartının günü ve Ramazan takvimi (varsayılan: şimdi, Diyanet)
  final DateTime Function()? fastClock;
  final RamadanCalendar? ramadanCalendar;

  const PrayerTrackerView({super.key, this.fastClock, this.ramadanCalendar});

  @override
  State<PrayerTrackerView> createState() => _PrayerTrackerViewState();
}

class _PrayerTrackerViewState extends State<PrayerTrackerView>
    with WidgetsBindingObserver {
  static const int _gridDays = 7;
  static const double _minLabelWidth = 60;
  static const double _maxLabelWidth = 96;

  final PrayerTrackerService _service = PrayerTrackerService();
  Map<String, int> _log = const {};
  Map<String, int> _kazaAdded = const {};
  // Özel günler; açıklama sayfasındaki anahtar da dinler
  final ValueNotifier<Set<String>> _excusedDays = ValueNotifier(const {});
  Set<String> get _excused => _excusedDays.value;
  set _excused(Set<String> value) => _excusedDays.value = value;
  DateTime? _since;
  bool _isLoading = true;
  bool _busy = false;
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
    // Bildirimden (başka isolate) işaretlenen vakit ve gün değişimi yansısın
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PrayerTrackerService.changes.removeListener(_load);
    _timer?.cancel();
    _excusedDays.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_saving > 0) return;
    final generation = _generation;
    try {
      final log = await _service.loadLog();
      final added = await _service.loadKazaAdded();
      final excused = await _service.loadExcused();
      final since = await _service.loadSince();
      if (!mounted || _saving > 0 || generation != _generation) return;
      setState(() {
        _log = log;
        _kazaAdded = added;
        _excused = excused;
        _since = since;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _todayTime(PrayerTimesModel? times, String key, DateTime now) {
    if (times == null) return null;
    try {
      final parts = PrayerRefreshService.timesMap(times)[key]!.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  // Bugünün vakti girmemişse işaretlenemez; vakitler bilinmiyorsa bugün kapalı
  bool _isDue(DateTime date, String key, PrayerTimesModel? times) {
    final now = DateTime.now();
    if (PrayerTracker.daysBetween(now, date) < 0) return true;
    if (PrayerTracker.daysBetween(now, date) > 0) return false;
    final t = _todayTime(times, key, now);
    return t != null && !now.isBefore(t);
  }

  // İmsak girmeden dünün yatsısı henüz kazaya kalmamıştır
  bool _yesterdayYatsiOngoing(PrayerTimesModel? times) {
    final now = DateTime.now();
    final imsak = _todayTime(times, "İmsak", now);
    return imsak == null || now.isBefore(imsak);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(
    DateTime date,
    String key,
    PrayerTimesModel? times,
    AppLocalizations loc,
  ) async {
    // Özel günün hücreleri kapalı: işaret gün adından kaldırılır
    if (PrayerTracker.isExcused(_excused, date)) {
      _snack(loc.trackerExcusedCellSnack);
      return;
    }
    if (!PrayerTracker.isPrayed(_log, date, key) &&
        PrayerTracker.isPrayed(_kazaAdded, date, key)) {
      await _removeFromKaza(date, key, loc);
      return;
    }
    if (!_isDue(date, key, times)) {
      _snack(loc.trackerNotYet);
      return;
    }
    final prayed = !PrayerTracker.isPrayed(_log, date, key);
    final viewModel = context.read<HomeViewModel>();
    _saving++;
    _generation++;
    setState(() {
      _log = PrayerTracker.withPrayed(
        _log,
        date,
        key,
        prayed,
        today: DateTime.now(),
      );
    });
    try {
      await _service.setPrayed(date, key, prayed);
    } catch (e) {
    } finally {
      _saving--;
    }
    _load();
    if (!prayed) {
      try {
        await viewModel.refreshEndReminders();
      } catch (e) {}
    }
  }

  // Kazaya eklenmiş vakit kılındı yapılır; kaza sayacı azalacaksa önce onay
  Future<void> _removeFromKaza(
    DateTime date,
    String key,
    AppLocalizations loc,
  ) async {
    final count = await _service.loadKazaCount(key);
    if (!mounted) return;
    if (count > 0) {
      final confirmed = await showConfirmDialog(
        context,
        title: loc.trackerKazaRemoveTitle,
        message: loc.trackerKazaRemoveConfirm(
          trackerPrayerNames(loc)[key]!,
          count,
          count - 1,
        ),
        confirmLabel: loc.trackerPrayedAction,
      );
      if (!confirmed || !mounted) return;
    }
    final now = DateTime.now();
    _saving++;
    _generation++;
    setState(() {
      _log = PrayerTracker.withPrayed(_log, date, key, true, today: now);
      _kazaAdded = PrayerTracker.withPrayed(
        _kazaAdded,
        date,
        key,
        false,
        today: now,
      );
    });
    try {
      await _service.removeFromKaza(date, key);
    } catch (e) {
    } finally {
      _saving--;
    }
    _load();
  }

  /// [date] gününü özel gün yapar/kaldırır. O günün kazaya eklenmiş vakitleri
  /// kaza sayacından düşülecekse önce onay; uygulandıysa true.
  Future<bool> _setExcused(
    DateTime date,
    bool excused,
    AppLocalizations loc,
  ) async {
    if (excused) {
      final mask = PrayerTracker.maskOf(_kazaAdded, date);
      var counted = false;
      for (final key in PrayerTracker.prayerKeys) {
        if ((mask & PrayerTracker.bit(key)) != 0 &&
            await _service.loadKazaCount(key) > 0) {
          counted = true;
          break;
        }
      }
      if (!mounted) return false;
      if (counted) {
        final confirmed = await showConfirmDialog(
          context,
          title: loc.trackerExcusedTitle,
          message: loc.trackerExcusedKazaConfirm(PrayerTracker.countOf(mask)),
          confirmLabel: loc.trackerExcusedMark,
        );
        if (!confirmed || !mounted) return false;
      }
    }
    final now = DateTime.now();
    _saving++;
    _generation++;
    setState(() {
      _excused = PrayerTracker.withExcused(_excused, date, excused, today: now);
      if (excused) {
        _kazaAdded = {..._kazaAdded}..remove(PrayerTracker.dateKey(date));
      }
    });
    try {
      await _service.setExcused(date, excused);
    } catch (e) {
    } finally {
      _saving--;
    }
    _load();
    return true;
  }

  // Gün adına basılı tutma: özel gün işareti açılır/kapanır
  Future<void> _toggleExcused(DateTime date, AppLocalizations loc) async {
    final excused = !PrayerTracker.isExcused(_excused, date);
    if (await _setExcused(date, excused, loc) && mounted) {
      _snack(excused ? loc.trackerExcusedMarked : loc.trackerExcusedUnmarked);
    }
  }

  /// Özel gün açıklaması + "Bugünü özel gün olarak işaretle" anahtarı
  void _showExcusedSheet(AppLocalizations loc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SingleChildScrollView(
          // + gezinme çubuğu (uçtan uca): anahtar altında kalmasın
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  loc.trackerExcusedTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.trackerExcusedInfo,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<Set<String>>(
                valueListenable: _excusedDays,
                builder: (context, excused, _) {
                  final today = PrayerTracker.day(DateTime.now());
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(kExcusedIcon),
                    title: Text(loc.trackerExcusedToday),
                    value: PrayerTracker.isExcused(excused, today),
                    onChanged: (value) => _setExcused(today, value, loc),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToKaza(
    PrayerTimesModel? times,
    AppLocalizations loc,
  ) async {
    if (_busy) return;
    final ongoing = _yesterdayYatsiOngoing(times);
    final count = PrayerTracker.totalCount(
      PrayerTracker.kazaCandidates(
        _log,
        _kazaAdded,
        DateTime.now(),
        since: _since,
        excused: _excused,
        yesterdayYatsiOngoing: ongoing,
      ),
    );
    if (count == 0) {
      _snack(loc.trackerKazaNone);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: loc.trackerKazaButton,
      message: loc.trackerKazaConfirm(count),
      confirmLabel: loc.trackerKazaAdd,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final added = await _service.addMissedToKaza(
        yesterdayYatsiOngoing: ongoing,
      );
      if (mounted) {
        _snack(added > 0 ? loc.trackerKazaDone(added) : loc.trackerKazaNone);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final times = context.watch<HomeViewModel>().prayerTimes;

    return AppScaffold(
      title: loc.trackerTitle,
      body: _isLoading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                RamadanFastCard(
                  clock: widget.fastClock,
                  calendar: widget.ramadanCalendar,
                  excused: _excused,
                ),
                _buildStats(times, loc),
                const SizedBox(height: AppSpacing.md),
                _buildGrid(times, loc),
                const SizedBox(height: AppSpacing.md),
                _buildKazaSection(times, loc),
              ],
            ),
    );
  }

  Widget _buildStats(PrayerTimesModel? times, AppLocalizations loc) {
    final now = DateTime.now();
    int todayDue = 0;
    for (final key in PrayerTracker.prayerKeys) {
      if (_isDue(now, key, times)) todayDue++;
    }
    final ongoing = _yesterdayYatsiOngoing(times);
    final rate = PrayerTracker.completionRate(
      _log,
      now,
      todayDue: todayDue,
      since: _since,
      excused: _excused,
      yesterdayYatsiOngoing: ongoing,
    );
    final streak = PrayerTracker.streak(
      _log,
      now,
      excused: _excused,
      yesterdayYatsiOngoing: ongoing,
    );
    final rateText = rate == null
        ? "–"
        : NumberFormat.percentPattern(loc.localeName).format(rate);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.pie_chart_outline,
              label: loc.trackerCompletion,
              value: rateText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              icon: Icons.local_fire_department_outlined,
              label: loc.trackerStreak,
              value: loc.trackerStreakDays(streak),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(PrayerTimesModel? times, AppLocalizations loc) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = trackerPrayerNames(loc);
    final now = DateTime.now();
    final localeCode = Localizations.localeOf(context).toString();

    String dayLabel(int daysAgo, DateTime date) {
      if (daysAgo == 0) return loc.trackerToday;
      if (daysAgo == 1) return loc.trackerYesterday;
      try {
        return DateFormat('EEE d', localeCode).format(date);
      } catch (e) {
        return PrayerTracker.dateKey(date).substring(5);
      }
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Gün etiketi sütunu: dar ekranda daralır, hücreler genişler
          final labelWidth = (constraints.maxWidth * 0.24).clamp(
            _minLabelWidth,
            _maxLabelWidth,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.xs,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          loc.trackerLast7Days,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  // Özel gün: açıklama + bugünü işaretle (sade, ikon düğme)
                  IconButton(
                    onPressed: () => _showExcusedSheet(loc),
                    tooltip: loc.trackerExcusedTitle,
                    icon: Icon(kExcusedIcon, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  SizedBox(width: labelWidth),
                  for (final key in PrayerTracker.prayerKeys)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            names[key]!,
                            maxLines: 1,
                            style: theme.textTheme.labelMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (int i = 0; i < _gridDays; i++)
                _buildGridRow(
                  PrayerTracker.addDays(now, -i),
                  dayLabel(i, PrayerTracker.addDays(now, -i)),
                  times,
                  loc,
                  labelWidth,
                ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _legend(
                      scheme.primary,
                      scheme.onPrimary,
                      Icons.check,
                      loc.trackerLegendPrayed,
                    ),
                    _legend(
                      scheme.tertiary,
                      scheme.onTertiary,
                      Icons.history,
                      loc.trackerLegendKaza,
                    ),
                    // Özel günün nasıl işaretlendiği (tek satır, göze batmaz)
                    _legend(
                      scheme.surfaceContainerHigh,
                      scheme.onSurfaceVariant,
                      kExcusedIcon,
                      loc.trackerLegendExcused,
                      border: scheme.outlineVariant,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridRow(
    DateTime date,
    String label,
    PrayerTimesModel? times,
    AppLocalizations loc,
    double labelWidth,
  ) {
    final theme = Theme.of(context);
    final excused = PrayerTracker.isExcused(_excused, date);
    return Row(
      children: [
        // Gün adına basılı tutunca özel gün işareti açılır/kapanır
        Semantics(
          value: excused ? loc.trackerExcusedTitle : null,
          onLongPressHint: excused
              ? loc.trackerExcusedUnmark
              : loc.trackerExcusedMark,
          child: InkWell(
            onLongPress: () => _toggleExcused(date, loc),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: labelWidth,
              height: AppSizes.minTouch,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  end: AppSpacing.xs,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: excused
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final key in PrayerTracker.prayerKeys)
          Expanded(
            child: _buildCell(
              prayed: PrayerTracker.isPrayed(_log, date, key),
              kaza: PrayerTracker.isPrayed(_kazaAdded, date, key),
              due: _isDue(date, key, times),
              excused: excused,
              onTap: () => _toggle(date, key, times, loc),
            ),
          ),
      ],
    );
  }

  Widget _buildCell({
    required bool prayed,
    required bool kaza,
    required bool due,
    required bool excused,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    Color fill = Colors.transparent;
    Color border = due ? scheme.outline : scheme.outlineVariant;
    Widget? icon;
    if (excused) {
      // Özel gün: soluk, kapalı (dokununca açıklama); işaretler kayıtta kalır
      fill = scheme.surfaceContainerHigh;
      border = scheme.outlineVariant;
      icon = Icon(kExcusedIcon, color: scheme.onSurfaceVariant, size: 14);
    } else if (prayed) {
      fill = scheme.primary;
      border = scheme.primary;
      icon = Icon(Icons.check, color: scheme.onPrimary, size: 18);
    } else if (kaza) {
      fill = scheme.tertiary;
      border = scheme.tertiary;
      icon = Icon(Icons.history, color: scheme.onTertiary, size: 16);
    } else if (!due) {
      icon = Icon(Icons.schedule, color: scheme.outline, size: 14);
    }
    // Dokunma alanı hücrenin tamamı (en az 48dp yükseklik)
    return Semantics(
      checked: excused ? null : prayed,
      enabled: excused ? false : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          height: AppSizes.minTouch,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 2),
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(
    Color color,
    Color onColor,
    IconData icon,
    String text, {
    Color? border,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border),
          ),
          child: Icon(icon, color: onColor, size: 14),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKazaSection(PrayerTimesModel? times, AppLocalizations loc) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: loc.trackerKazaInfo),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : () => _addToKaza(times, loc),
            icon: const Icon(Icons.playlist_add),
            label: Text(loc.trackerKazaButton, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
