import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import 'dhikr_list_view.dart';
import 'dhikr_names.dart';
import 'dhikr_stats_view.dart';
import 'zikir_settings_view.dart';

/// Zikirmatik sekmesi: seçili zikir + hedef, büyük sayaç (modern düğme veya
/// klasik tesbih), altta düzenle / sıfırla.
class ZikirView extends StatelessWidget {
  const ZikirView({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.zikirmatikTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: loc.dhikrListTitle,
            onPressed: () => _open(context, const DhikrListView()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: loc.statisticsTitle,
            onPressed: () => _open(context, const DhikrStatsView()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.zikirSettings,
            onPressed: () => _open(context, const ZikirSettingsView()),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            final name = dhikrDisplayName(viewModel.selectedDhikr, loc);
            final arabic = viewModel.getArabicForDhikr(viewModel.selectedDhikr);
            void editCount() => _editCount(context, viewModel, loc);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _DhikrHeader(
                    name: name,
                    arabic: arabic,
                    targetLabel: loc.targetCount(viewModel.target),
                    onEditTarget: () => _editTarget(context, viewModel, loc),
                  ),
                ),
                Expanded(
                  child: viewModel.viewMode == 0
                      ? _ModernCounter(
                          viewModel: viewModel,
                          dhikrName: name,
                          onEdit: editCount,
                        )
                      : _ClassicTasbihView(
                          viewModel: viewModel,
                          dhikrName: name,
                          onEdit: editCount,
                        ),
                ),
                _ActionRow(
                  onEdit: editCount,
                  onReset: () => _confirmReset(context, viewModel, loc),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _targetReached(ZikirViewModel viewModel) =>
    viewModel.target > 0 &&
    viewModel.count > 0 &&
    viewModel.count % viewModel.target == 0;

Future<void> _editCount(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final value = await _askNumber(
    context,
    title: loc.editCounterTitle,
    initial: viewModel.count,
    hint: loc.exampleHint(2000),
    min: 0,
  );
  if (value != null) await viewModel.setCount(value);
}

Future<void> _editTarget(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final value = await _askNumber(
    context,
    title: loc.setTarget,
    initial: viewModel.target,
    hint: loc.exampleHint(99),
    min: 1,
  );
  if (value != null) await viewModel.setTarget(value);
}

Future<void> _confirmReset(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: loc.resetCounter,
    message: loc.resetCounterConfirm,
    confirmLabel: loc.resetCounter,
    destructive: true,
  );
  if (confirmed) await viewModel.reset();
}

/// Sayı girişi; geçersiz/boş giriş değişiklik yapmadan kapanır (null)
Future<int?> _askNumber(
  BuildContext context, {
  required String title,
  required int initial,
  required String hint,
  required int min,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _NumberInputDialog(
      title: title,
      initial: initial,
      hint: hint,
      min: min,
    ),
  );
}

class _NumberInputDialog extends StatefulWidget {
  final String title;
  final int initial;
  final String hint;
  final int min;

  const _NumberInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.min,
  });

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = '${widget.initial}';
    // Değer seçili gelir: yazınca yerine geçer
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.pop(context, value != null && value >= widget.min ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(loc.save)),
      ],
    );
  }
}

/// Seçili zikir (ad + Arapça) ve hedef düğmesi
class _DhikrHeader extends StatelessWidget {
  final String name;
  final String arabic;
  final String targetLabel;
  final VoidCallback onEditTarget;

  const _DhikrHeader({
    required this.name,
    required this.arabic,
    required this.targetLabel,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (arabic.isNotEmpty)
            ConstrainedBox(
              // Uzun dualar kartı büyütmez, kayar
              constraints: const BoxConstraints(maxHeight: 84),
              child: SingleChildScrollView(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    arabic,
                    textDirection: TextDirection.rtl,
                    style: arabicDhikrStyle(context, fontSize: 24),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: onEditTarget,
              icon: const Icon(Icons.flag_outlined),
              label: Text(targetLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern görünüm: dokunarak sayılan büyük daire (basılı tutunca düzenlenir)
class _ModernCounter extends StatelessWidget {
  final ZikirViewModel viewModel;
  final String dhikrName;
  final VoidCallback onEdit;

  const _ModernCounter({
    required this.viewModel,
    required this.dhikrName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reached = _targetReached(viewModel);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.max(
          0.0,
          math.min(
            300.0,
            math.min(constraints.maxWidth - 48, constraints.maxHeight - 32),
          ),
        );
        return Center(
          child: Semantics(
            container: true,
            button: true,
            label: dhikrName,
            value: '${viewModel.count}',
            hint: loc.tapToCount,
            onLongPressHint: loc.editCounterTitle,
            onTap: viewModel.increment,
            onLongPress: onEdit,
            excludeSemantics: true,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: isDark ? 0.18 : 0.25,
                    ),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Material(
                color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
                shape: CircleBorder(
                  side: BorderSide(
                    color: reached
                        ? colors.success
                        : scheme.primary.withValues(alpha: 0.5),
                    width: 8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: viewModel.increment,
                  onLongPress: onEdit,
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabularText(
                            '${viewModel.count}',
                            style: TextStyle(
                              fontSize: 88,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: reached
                                  ? colors.success
                                  : scheme.onSurface,
                            ),
                          ),
                          if (reached) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _ReachedChip(text: loc.targetReached),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReachedChip extends StatelessWidget {
  final String text;

  const _ReachedChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = PrayerColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: colors.onSuccessContainer),
      ),
    );
  }
}

/// Altta görünür "Sayacı Düzenle" ve "Sıfırla" (dar ekranda alt alta)
class _ActionRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onReset;

  const _ActionRow({required this.onEdit, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(loc.editCounterTitle),
          ),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: Text(loc.resetCounter),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Klasik görünüm: aşağı çekilen (veya dokunulan) tesbih boncukları
class _ClassicTasbihView extends StatefulWidget {
  final ZikirViewModel viewModel;
  final String dhikrName;
  final VoidCallback onEdit;

  const _ClassicTasbihView({
    required this.viewModel,
    required this.dhikrName,
    required this.onEdit,
  });

  @override
  State<_ClassicTasbihView> createState() => _ClassicTasbihViewState();
}

class _ClassicTasbihViewState extends State<_ClassicTasbihView>
    with SingleTickerProviderStateMixin {
  static const int _visibleBeads = 6;
  static const double _beadHeight = 65.0;

  // Tesbih görseli (temadan bağımsız ahşap tonları)
  static const Color _cord = Color(0xFF4E342E);
  static const Color _beadLight = Color(0xFFFFB74D);
  static const Color _beadDark = Color(0xFF5D4037);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pullBead() {
    if (_controller.isAnimating) return;
    widget.viewModel.increment();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final reached = _targetReached(widget.viewModel);
    final count = widget.viewModel.count;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        // Sayaç (basılı tutunca düzenlenir)
        Semantics(
          container: true,
          label: widget.dhikrName,
          value: '$count',
          onLongPressHint: loc.editCounterTitle,
          onLongPress: widget.onEdit,
          excludeSemantics: true,
          child: Material(
            color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(
                color: reached
                    ? colors.success
                    : scheme.primary.withValues(alpha: 0.35),
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onLongPress: widget.onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabularText(
                        '$count',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: reached ? colors.success : scheme.onSurface,
                        ),
                      ),
                      if (reached) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _ReachedChip(text: loc.targetReached),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // İp ve boncuklar: dokun veya aşağı çek
        Expanded(
          child: Semantics(
            container: true,
            button: true,
            label: loc.tapToCount,
            onTap: _pullBead,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity;
                if (velocity != null && velocity > 0) _pullBead();
              },
              onTap: _pullBead,
              child: SizedBox(
                width: double.infinity,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Center(
                        child: SizedBox(
                          width: 150,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              const Positioned.fill(
                                child: Center(
                                  child: SizedBox(
                                    width: 5,
                                    child: ColoredBox(color: _cord),
                                  ),
                                ),
                              ),
                              for (int i = -1; i <= _visibleBeads; i++)
                                Positioned(
                                  top:
                                      (i + _controller.value) * _beadHeight +
                                      10,
                                  child: Opacity(
                                    opacity: (i == _visibleBeads)
                                        ? 1.0 - _controller.value
                                        : (i == -1)
                                        ? _controller.value
                                        : 1.0,
                                    child: _buildBead(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBead() {
    return Container(
      width: 55,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 5)),
        ],
        gradient: const RadialGradient(
          colors: [_beadLight, _beadDark],
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 8,
          height: 45,
          child: ColoredBox(color: Color(0x4D000000)),
        ),
      ),
    );
  }
}
