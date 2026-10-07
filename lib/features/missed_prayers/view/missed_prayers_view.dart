import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/storage_service.dart';

/// Kaza takibi: vakit başına − sayı + (48dp) sayaçlar; sayıya dokununca elle
/// giriş. Büyük ya da sıfırlayan değişiklikler onay ister.
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
      builder: (context) =>
          _CountEntryDialog(title: displayTitle, initialValue: current),
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
  final ValueChanged<int> onChanged;
  final VoidCallback onValueTap;

  const _KazaRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onValueTap,
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

/// Elle sayı girişi; kaydedilirse yeni sayı döner
class _CountEntryDialog extends StatefulWidget {
  final String title;
  final int initialValue;

  const _CountEntryDialog({required this.title, required this.initialValue});

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
      title: Text(loc.editMissedTitle(widget.title)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: loc.missedCountLabel,
          hintText: loc.missedCountHint,
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
