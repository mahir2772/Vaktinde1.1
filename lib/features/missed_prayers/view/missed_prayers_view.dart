import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/fast_tracker_service.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../../data/services/storage_service.dart';
import '../kaza_estimate.dart';

/// Kaza takibi: vakit başına − sayı + (48dp) sayaçlar; sayıya dokununca elle
/// giriş. Büyük ya da sıfırlayan değişiklikler onay ister. "Kaza hesapla"
/// kılınmayan süreden tahmini sayıları hesaplar ve sayaçlara ekler.
class MissedPrayersView extends StatefulWidget {
  const MissedPrayersView({super.key});

  @override
  State<MissedPrayersView> createState() => _MissedPrayersViewState();
}

class _MissedPrayersViewState extends State<MissedPrayersView> {
  final StorageService _storageService = StorageService();

  static const List<(String, IconData)> _prayers = [
    ("Sabah", Icons.wb_twilight),
    ("Öğle", Icons.wb_sunny),
    ("İkindi", Icons.wb_sunny_outlined),
    ("Akşam", Icons.nights_stay_outlined),
    ("Yatsı", Icons.nights_stay),
    ("Vitir", Icons.star_border),
  ];
  static const (String, IconData) _fast = ("Oruç", Icons.restaurant_menu);

  Map<String, int> _missedPrayers = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitir": 0,
    "Oruç": 0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storageService.loadMissedPrayers();
    if (!mounted) return;
    setState(() {
      _missedPrayers = data;
      _isLoading = false;
    });
  }

  void _setCount(String key, int value) {
    final newValue = value < 0 ? 0 : value;
    setState(() => _missedPrayers[key] = newValue);
    _storageService.updateMissedPrayer(key, newValue);
  }

  String _getLocalizedTitle(String key, AppLocalizations loc) {
    switch (key) {
      case "Sabah":
        return loc.sabah;
      case "Öğle":
        return loc.ogle;
      case "İkindi":
        return loc.ikindi;
      case "Akşam":
        return loc.aksam;
      case "Yatsı":
        return loc.yatsi;
      case "Vitir":
        return loc.vitir;
      case "Oruç":
        return loc.oruc;
      default:
        return key;
    }
  }

  /// Yanlışlıkla silme/fazladan sıfır gibi durumlar için onay gerekir mi
  static bool _needsConfirm(int from, int to) =>
      (from - to).abs() >= 10 || (to == 0 && from > 1);

  Future<void> _showManualEntryDialog(String key, AppLocalizations loc) async {
    final current = _missedPrayers[key] ?? 0;
    final displayTitle = _getLocalizedTitle(key, loc);
    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => _CountEntryDialog(
        title: loc.editMissedTitle(displayTitle),
        label: loc.missedCountLabel,
        hint: loc.missedCountHint,
        initialValue: current,
      ),
    );
    if (newValue == null || newValue == current || !mounted) return;
    if (_needsConfirm(current, newValue)) {
      final confirmed = await showConfirmDialog(
        context,
        title: loc.editMissedTitle(displayTitle),
        message: loc.missedChangeConfirm(displayTitle, current, newValue),
        confirmLabel: loc.save,
        destructive: newValue < current,
      );
      if (!confirmed || !mounted) return;
    }
    _setCount(key, newValue);
  }

  /// "Kaza hesapla": onaylanan tahmin sayaçlara eklenir (üzerine yazılmaz).
  /// Namaz sayaçları takip ekranının, oruç sayacı oruç kartının kuyruğunda
  /// yazılır.
  Future<void> _openCalculator(AppLocalizations loc) async {
    final estimate = await showModalBottomSheet<KazaEstimate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _KazaCalculatorSheet(),
    );
    if (estimate == null) return;
    if (estimate.prayers > 0) {
      await PrayerTrackerService().addToKazaCounters({
        for (final (key, _) in _prayers) key: estimate.prayers,
      });
    }
    if (estimate.fasts > 0) {
      await FastTrackerService().addKazaDays(estimate.fasts);
    }
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(loc.kazaCalcAdded)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    Widget row((String, IconData) item) {
      final (key, icon) = item;
      return _KazaRow(
        icon: icon,
        title: _getLocalizedTitle(key, loc),
        value: _missedPrayers[key] ?? 0,
        onChanged: (v) => _setCount(key, v),
        onValueTap: () => _showManualEntryDialog(key, loc),
      );
    }

    return AppScaffold(
      title: loc.missedPrayersTitle,
      body: _isLoading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                InfoBanner(message: loc.missedPrayersInfo),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AppListTile(
                    leadingIcon: Icons.calculate_outlined,
                    title: loc.kazaCalcTitle,
                    subtitle: loc.kazaCalcSubtitle,
                    onTap: () => _openCalculator(loc),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < _prayers.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                          ),
                        row(_prayers[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(padding: EdgeInsets.zero, child: row(_fast)),
              ],
            ),
    );
  }
}

/// Bir kaza satırı: ikon + ad + sayaç. Dar ekranda/büyük yazıda sayaç alt
/// satıra iner (ad kırpılmaz).
class _KazaRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final int? max;
  final ValueChanged<int> onChanged;
  final VoidCallback? onValueTap;

  const _KazaRow({
    required this.icon,
    required this.title,
    required this.value,
    this.max,
    required this.onChanged,
    this.onValueTap,
  });

  // Sayaç: 48 + en az 64 + 48 dp (büyük sayılarda biraz daha)
  static const double _stepperWidth = 176;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = theme.textTheme.titleMedium!;

    final iconBox = Container(
      width: AppSizes.iconBox,
      height: AppSizes.iconBox,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
    );
    final stepper = CounterStepper(
      value: value,
      max: max,
      onChanged: onChanged,
      semanticLabel: title,
      onValueTap: onValueTap,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: title, style: titleStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final titleWidth = painter.width;
          painter.dispose();
          final fits =
              AppSizes.iconBox +
                  AppSpacing.md +
                  titleWidth +
                  AppSpacing.sm +
                  _stepperWidth <=
              constraints.maxWidth;

          final titleRow = Row(
            children: [
              iconBox,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: titleStyle)),
            ],
          );
          if (fits) {
            return Row(
              children: [
                Expanded(child: titleRow),
                const SizedBox(width: AppSpacing.sm),
                stepper,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: AlignmentDirectional.centerEnd, child: stepper),
            ],
          );
        },
      ),
    );
  }
}

/// "Kaza hesapla" alt sayfası: kılınmayan süre (yıl/ay), isteğe bağlı aylık
/// özel gün ve tutulmayan Ramazan → canlı tahmin. "Kaza Takibi'ne ekle"
/// onaylanınca sayfa tahmini döndürerek kapanır.
class _KazaCalculatorSheet extends StatefulWidget {
  const _KazaCalculatorSheet();

  @override
  State<_KazaCalculatorSheet> createState() => _KazaCalculatorSheetState();
}

class _KazaCalculatorSheetState extends State<_KazaCalculatorSheet> {
  int _years = 0;
  int _months = 0;
  int _excusedDays = 0;
  int _ramadans = 0;

  /// Büyük sayılar için elle giriş (sayıya dokununca); sınıra kırpılır
  Future<void> _enter(
    String title,
    int current,
    int max,
    ValueChanged<int> apply, {
    String? label,
  }) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) =>
          _CountEntryDialog(title: title, label: label, initialValue: current),
    );
    if (value != null && mounted) setState(() => apply(value.clamp(0, max)));
  }

  Future<void> _add(KazaEstimate estimate, AppLocalizations loc) async {
    final confirmed = await showConfirmDialog(
      context,
      title: loc.kazaCalcConfirmTitle,
      message: loc.kazaCalcConfirm(estimate.prayers, estimate.fasts),
      confirmLabel: loc.trackerKazaAdd,
    );
    if (confirmed && mounted) Navigator.pop(context, estimate);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final estimate = KazaEstimate(
      years: _years,
      months: _months,
      excusedDays: _excusedDays,
      ramadans: _ramadans,
    );
    const divider = Divider(
      height: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
    Widget header(String title) => SectionHeader(
      title,
      onImage: false,
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
    );

    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): düğme altında kalmasın
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(loc.kazaCalcTitle, style: theme.textTheme.titleLarge),
          ),
          header(loc.kazaCalcPeriod),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _KazaRow(
                  icon: Icons.calendar_month_outlined,
                  title: loc.kazaCalcYears,
                  value: _years,
                  max: KazaEstimate.maxYears,
                  onChanged: (v) => setState(() => _years = v),
                  onValueTap: () => _enter(
                    loc.kazaCalcPeriod,
                    _years,
                    KazaEstimate.maxYears,
                    (v) => _years = v,
                    label: loc.kazaCalcYears,
                  ),
                ),
                divider,
                _KazaRow(
                  icon: Icons.date_range_outlined,
                  title: loc.kazaCalcMonths,
                  value: _months,
                  max: KazaEstimate.maxMonths,
                  onChanged: (v) => setState(() => _months = v),
                ),
              ],
            ),
          ),
          header(loc.kazaCalcOptional),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _KazaRow(
                  // Namaz takibindeki özel gün simgesi
                  icon: Icons.spa_outlined,
                  title: loc.kazaCalcExcused,
                  value: _excusedDays,
                  max: KazaEstimate.maxExcusedDays,
                  onChanged: (v) => setState(() => _excusedDays = v),
                ),
                divider,
                _KazaRow(
                  icon: Icons.restaurant_menu,
                  title: loc.kazaCalcRamadans,
                  value: _ramadans,
                  max: KazaEstimate.maxRamadans,
                  onChanged: (v) => setState(() => _ramadans = v),
                  onValueTap: () => _enter(
                    loc.kazaCalcRamadans,
                    _ramadans,
                    KazaEstimate.maxRamadans,
                    (v) => _ramadans = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            loc.kazaCalcOptionalInfo,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          header(loc.kazaCalcResult),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatTile(
                  value: '${estimate.prayers}',
                  label: loc.kazaCalcEachPrayer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(value: '${estimate.fasts}', label: loc.oruc),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InfoBanner(message: loc.kazaCalcNote),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: estimate.isEmpty ? null : () => _add(estimate, loc),
            icon: const Icon(Icons.playlist_add),
            label: Text(loc.kazaCalcAdd, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Elle sayı girişi; kaydedilirse yeni sayı döner
class _CountEntryDialog extends StatefulWidget {
  final String title;
  final String? label;
  final String? hint;
  final int initialValue;

  const _CountEntryDialog({
    required this.title,
    this.label,
    this.hint,
    required this.initialValue,
  });

  @override
  State<_CountEntryDialog> createState() => _CountEntryDialogState();
}

class _CountEntryDialogState extends State<_CountEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = '${widget.initialValue}';
    // Açılınca metnin tamamı seçili gelsin (doğrudan yazılabilsin)
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, int.tryParse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
        autofocus: true,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(loc.save)),
      ],
    );
  }
}
