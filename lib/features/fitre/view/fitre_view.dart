import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/fitre_service.dart';
import '../../zakat/view/zakat_view.dart' show parseAmount;

/// Fitre ve fidye: kişi başı tutar (Diyanet, fitre.json; elle değiştirilebilir)
/// × kişi sayısı / oruç tutulamayan gün sayısı. Tutar değiştirilince para birimi
/// gösterilmez (yurt dışında yerel tutar yazılabilir).
class FitreView extends StatefulWidget {
  /// Test: tutar kaynağı ve bugünün tarihi
  final FitreService? service;
  final DateTime Function()? clock;

  const FitreView({super.key, this.service, this.clock});

  @override
  State<FitreView> createState() => _FitreViewState();
}

class _FitreViewState extends State<FitreView> {
  static const int _maxPeople = 50;
  static const int _maxDays = 30;

  final TextEditingController _amountController = TextEditingController();
  FitreAmount? _official;
  bool _loading = true;
  int _people = 1;
  int _days = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = widget.service ?? FitreService();
    final today = (widget.clock ?? DateTime.now)();
    FitreAmount? local;
    try {
      local = await service.loadLocal(today);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _apply(local);
      _loading = false;
    });
    // Uzak json'da yeni tutar varsa (Diyanet açıkladıysa) alan güncellenir
    FitreAmount? fresh;
    try {
      fresh = await service.refresh(today);
    } catch (_) {}
    if (!mounted || fresh == null) return;
    setState(() => _apply(fresh));
  }

  /// Kullanıcı tutarı değiştirmediyse alan yeni tutara çekilir
  void _apply(FitreAmount? amount) {
    final edited = _edited;
    _official = amount;
    if (!edited && amount != null) {
      _amountController.text = _fieldText(amount.amount);
    }
  }

  bool get _edited {
    final official = _official;
    if (official == null) return _amountController.text.trim().isNotEmpty;
    return parseAmount(_amountController.text) != official.amount;
  }

  static String _fieldText(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  static String? _symbol(String? code, String localeName) {
    if (code == null) return null;
    try {
      return NumberFormat.simpleCurrency(
        locale: localeName,
        name: code,
      ).currencySymbol;
    } catch (_) {
      return code;
    }
  }

  static String _money(
    double value,
    String localeName,
    int digits,
    String? symbol,
  ) {
    String text;
    try {
      text = NumberFormat.decimalPatternDigits(
        locale: localeName,
        decimalDigits: digits,
      ).format(value);
    } catch (_) {
      text = value.toStringAsFixed(digits);
    }
    return symbol == null ? text : '$text $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeName = loc.localeName;
    final official = _official;
    final edited = _edited;
    final perPerson = parseAmount(_amountController.text);
    final digits = (perPerson * 100).round() % 100 == 0 ? 0 : 2;
    final symbol = edited ? null : _symbol(official?.currency, localeName);
    String money(int count) =>
        _money(perPerson * count, localeName, digits, symbol);

    return AppScaffold(
      title: loc.fitreTitle,
      body: _loading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                InfoBanner(message: loc.fitreInfo),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: loc.fitreAmountLabel,
                      helperText: official == null
                          ? null
                          : loc.fitreSource(
                              official.source,
                              '${official.validFrom.year}',
                            ),
                      helperMaxLines: 2,
                      suffixText: symbol,
                      suffixIcon: edited && official != null
                          ? IconButton(
                              tooltip: loc.fitreResetAmount,
                              icon: const Icon(Icons.restart_alt),
                              onPressed: () => setState(
                                () => _amountController.text = _fieldText(
                                  official.amount,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _section(
                  loc,
                  title: loc.fitreSectionTitle,
                  label: loc.fitrePeopleLabel,
                  value: _people,
                  max: _maxPeople,
                  onChanged: (v) => setState(() => _people = v),
                  total: money(_people),
                ),
                const SizedBox(height: AppSpacing.md),
                _section(
                  loc,
                  title: loc.fidyeSectionTitle,
                  label: loc.fidyeDaysLabel,
                  value: _days,
                  max: _maxDays,
                  onChanged: (v) => setState(() => _days = v),
                  total: money(_days),
                ),
              ],
            ),
    );
  }

  Widget _section(
    AppLocalizations loc, {
    required String title,
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
    required String total,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              const SizedBox(width: AppSpacing.sm),
              CounterStepper(
                value: value,
                min: 1,
                max: max,
                onChanged: onChanged,
                semanticLabel: label,
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Semantics(
            container: true,
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    loc.fitreTotal,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Uzun tutar sığmazsa küçülür; satır sonuna hizalı
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      total,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
