import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/fast_tracker.dart';
import '../../../data/services/fast_tracker_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../imsakiye/imsakiye_logic.dart';
import '../../imsakiye/ramadan_calendar_loader.dart';

/// Ramazan orucu kartı (Namaz Takibi): Ramazan'da ve bitişinden sonraki
/// [FastTracker.daysAfterRamadan] gün görünür. Bugün ve geçmiş günlere dokununca
/// tutuldu işaretlenir; tutulmayan geçmiş günler kaza orucu sayacına eklenir.
/// Kazaya eklenen gün dokununca (sayaç varsa onayla) tutuldu olur, sayaçtan düşülür.
class RamadanFastCard extends StatefulWidget {
  /// Test: bugünün tarihi ve Ramazan takvimi (varsayılan: şimdi, Diyanet takvimi)
  final DateTime Function()? clock;
  final RamadanCalendar? calendar;

  /// Namaz takibindeki özel günler (hayız/nifas). Sadece görünüm: o günün
  /// namazı kaza edilmez ama tutulamayan Ramazan orucu kaza edilir, bu yüzden
  /// tutulmamış özel gün "Tutulmayanları kaza orucuna ekle"de yine sayılır
  /// (FastTracker.kazaCandidates özel günü ayırmaz). Gün yine işaretlenebilir
  /// (ör. akşamdan sonra başlayan özel hal o günün orucunu bozmaz).
  final Set<String> excused;

  const RamadanFastCard({
    super.key,
    this.clock,
    this.calendar,
    this.excused = const {},
  });

  @override
  State<RamadanFastCard> createState() => _RamadanFastCardState();
}

class _RamadanFastCardState extends State<RamadanFastCard> {
  static const double _dot = 38;

  final FastTrackerService _service = FastTrackerService();
  RamadanCalendar? _calendar;
  Set<String> _log = const {};
  Set<String> _added = const {};
  bool _loaded = false;
  bool _busy = false;
  // Kaydedilmemiş dokunuş varken okunan eski kayıt ekrana yazılmaz
  int _saving = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _calendar = widget.calendar;
    if (_calendar == null) {
      loadRamadanCalendar().then((calendar) {
        if (mounted) setState(() => _calendar = calendar);
      });
    }
    _load();
  }

  DateTime _today() => PrayerTracker.day((widget.clock ?? DateTime.now)());

  Future<void> _load() async {
    if (_saving > 0) return;
    final generation = _generation;
    try {
      final log = await _service.loadLog();
      final added = await _service.loadKazaAdded();
      if (!mounted || _saving > 0 || generation != _generation) return;
      setState(() {
        _log = log;
        _added = added;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save(Future<Object?> Function() write) async {
    _saving++;
    try {
      await write();
    } catch (_) {
    } finally {
      _saving--;
    }
    _load();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(DateTime day, AppLocalizations loc) async {
    final key = PrayerTracker.dateKey(day);
    if (!_log.contains(key) && _added.contains(key)) {
      await _removeFromKaza(day, loc);
      return;
    }
    final today = _today();
    final fasted = !_log.contains(key);
    _generation++;
    setState(() => _log = FastTracker.withDay(_log, day, fasted, today: today));
    await _save(() => _service.setFasted(day, fasted, now: today));
  }

  // Kazaya eklenmiş gün tutuldu yapılır; kaza sayacı azalacaksa önce onay
  Future<void> _removeFromKaza(DateTime day, AppLocalizations loc) async {
    final count = await _service.loadKazaCount();
    if (!mounted) return;
    if (count > 0) {
      final confirmed = await showConfirmDialog(
        context,
        title: loc.fastKazaRemoveTitle,
        message: loc.fastKazaRemoveConfirm(count, count - 1),
        confirmLabel: loc.fastFastedAction,
      );
      if (!confirmed || !mounted) return;
    }
    final today = _today();
    _generation++;
    setState(() {
      _log = FastTracker.withDay(_log, day, true, today: today);
      _added = FastTracker.withDay(_added, day, false, today: today);
    });
    await _save(() => _service.removeFromKaza(day, now: today));
  }

  Future<void> _addToKaza(RamadanRange range, AppLocalizations loc) async {
    if (_busy) return;
    // Özel günler de sayılır (widget.excused bilerek verilmez): orucun
    // kazası gerekir
    final count = FastTracker.kazaCandidates(
      range,
      _log,
      _added,
      _today(),
    ).length;
    if (count == 0) {
      _snack(loc.fastKazaNone);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: loc.fastKazaButton,
      message: loc.fastKazaConfirm(count),
      confirmLabel: loc.trackerKazaAdd,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final added = await _service.addMissedToKaza(range, now: _today());
      if (mounted) {
        _snack(added > 0 ? loc.fastKazaDone(added) : loc.fastKazaNone);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final calendar = _calendar;
    if (calendar == null || !_loaded) return const SizedBox.shrink();
    final today = _today();
    final range = FastTracker.visibleRamadan(calendar, today);
    if (range == null) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = range.days;
    final showExcused = days.any(
      (d) => _isExcusedOnly(PrayerTracker.dateKey(d)),
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(loc.fastTitle, style: theme.textTheme.titleMedium),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                loc.fastCount(
                  FastTracker.fastedCount(range, _log),
                  range.length,
                ),
                style: theme.textTheme.titleSmall!.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.fastInfo,
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            children: [
              for (var i = 0; i < days.length; i++)
                _dayCell(i + 1, days[i], today, loc),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _legend(scheme.primary, loc.fastLegendFasted),
              _legend(scheme.tertiary, loc.fastLegendKaza),
              if (showExcused)
                _legend(
                  scheme.surfaceContainerHigh,
                  loc.fastLegendExcused,
                  border: scheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : () => _addToKaza(range, loc),
            icon: const Icon(Icons.playlist_add),
            label: Text(loc.fastKazaButton, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
    int number,
    DateTime day,
    DateTime today,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final key = PrayerTracker.dateKey(day);
    final fasted = _log.contains(key);
    final kaza = !fasted && _added.contains(key);
    final excused = _isExcusedOnly(key);
    final future = FastTracker.isFuture(day, today);
    final isToday = PrayerTracker.daysBetween(today, day) == 0;
    Color fill = Colors.transparent;
    Color border = future
        ? scheme.outlineVariant
        : (isToday ? scheme.primary : scheme.outline);
    Color text = future ? scheme.onSurfaceVariant : scheme.onSurface;
    if (fasted) {
      fill = scheme.primary;
      border = scheme.primary;
      text = scheme.onPrimary;
    } else if (kaza) {
      fill = scheme.tertiary;
      border = scheme.tertiary;
      text = scheme.onTertiary;
    } else if (excused) {
      // Sadece görünüm: kaza orucu adayı olmaya devam eder
      fill = scheme.surfaceContainerHigh;
      if (!isToday) border = scheme.outlineVariant;
      text = scheme.onSurfaceVariant;
    }
    // Dokunma alanı 48dp; gelecek günler kapalı
    return Semantics(
      button: !future,
      enabled: !future,
      checked: fasted,
      label: loc.ramadanDayLabel(number),
      value: kaza
          ? loc.fastLegendKaza
          : (excused ? loc.fastLegendExcused : null),
      excludeSemantics: true,
      child: InkWell(
        onTap: future ? null : () => _toggle(day, loc),
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: AppSizes.minTouch,
          child: Center(
            child: Container(
              width: _dot,
              height: _dot,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: isToday ? 2.5 : 1.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tutulmamış, kazaya eklenmemiş özel gün (namaz takibinde işaretli)
  bool _isExcusedOnly(String key) =>
      widget.excused.contains(key) &&
      !_log.contains(key) &&
      !_added.contains(key);

  Widget _legend(Color color, String text, {Color? border}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border),
          ),
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
}
