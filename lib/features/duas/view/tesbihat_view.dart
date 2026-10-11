import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../zikirmatik/view/dhikr_names.dart';
import '../../zikirmatik/view_model/zikir_view_model.dart';
import '../dua_data.dart';

/// Namaz sonrası tesbihat, adım adım: Âyetü'l-Kürsî → 33 Sübhânallâh →
/// 33 Elhamdülillâh → 33 Allâhü ekber → tevhid → dua. Her adımda büyük
/// sayaç; hedefe ulaşınca titreşir ve sonraki adıma geçer. Sayılar
/// kaydedilmez (sadece bu ekran açıkken). Titreşim zikirmatik ayarına uyar.
class TesbihatView extends StatefulWidget {
  final List<Dua> steps;

  const TesbihatView({super.key, required this.steps});

  /// Sayaç düğmesi (testler için)
  static const Key counterKey = ValueKey('tesbihat_counter');

  /// Hedefe ulaşınca sonraki adıma geçmeden önceki kısa bekleme
  static const Duration advanceDelay = Duration(milliseconds: 400);

  @override
  State<TesbihatView> createState() => _TesbihatViewState();
}

class _TesbihatViewState extends State<TesbihatView> {
  int _index = 0;
  int _count = 0;
  Timer? _advance;

  Dua get _step => widget.steps[_index];

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _goTo(int index) {
    _advance?.cancel();
    _advance = null;
    setState(() {
      _index = index.clamp(0, widget.steps.length - 1);
      _count = 0;
    });
  }

  void _tap() {
    final target = _step.count;
    if (target <= 0 || _advance != null) return;
    final vibrate = context.read<ZikirViewModel?>()?.isVibrationEnabled ?? true;
    setState(() => _count++);
    if (vibrate) HapticFeedback.vibrate();
    if (_count < target) return;
    // Hedef: ikinci titreşimle sonraki adım
    _advance = Timer(TesbihatView.advanceDelay, () {
      if (!mounted) return;
      if (vibrate) HapticFeedback.vibrate();
      _goTo(_index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final steps = widget.steps;
    final step = _step;
    final isLast = _index == steps.length - 1;
    final target = step.count;
    final progress =
        (_index + (target > 0 ? _count / target : 1)) / steps.length;

    return AppScaffold(
      title: loc.tesbihatTitle,
      body: LayoutBuilder(
        builder: (context, box) {
          final counterSize = (box.maxHeight * 0.3).clamp(112.0, 184.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: loc.previousItem,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            loc.tesbihatStep(_index + 1, steps.length),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: isLast ? null : () => _goTo(_index + 1),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: loc.nextItem,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _StepText(step: step, lang: lang),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: target > 0
                    ? _Counter(
                        count: _count,
                        target: target,
                        size: counterSize,
                        label: step.titleFor(lang),
                        hint: target > 1
                            ? loc.tapToCount
                            : loc.tesbihatTapWhenRead,
                        onTap: _tap,
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _goTo(0),
                            icon: const Icon(Icons.replay),
                            label: Text(loc.tesbihatRestart),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.check),
                            label: Text(loc.close),
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
}

final RegExp _marks = RegExp('[ً-ْٰ]');

class _StepText extends StatelessWidget {
  final Dua step;
  final String lang;

  const _StepText({required this.step, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = step.titleFor(lang);
    final arabic = step.arabic;
    final translit = step.translitFor(lang);
    final meaning = step.meaningFor(lang);
    final note = step.noteFor(lang);
    // Arapça arayüzde başlık metnin harekesiz hali ise tekrar edilmez
    final showTitle = arabic.replaceAll(_marks, '') != title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle)
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
        if (arabic.isNotEmpty) ...[
          if (showTitle) const SizedBox(height: AppSpacing.md),
          Text(
            arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: arabicDhikrStyle(context, fontSize: 30),
          ),
        ],
        if (translit != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            translit,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(height: 1.5),
          ),
        ],
        if (meaning != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            meaning,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        // Son adım (dua): yönerge
        if (arabic.isEmpty && note != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            note,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(height: 1.6),
          ),
        ],
      ],
    );
  }
}

/// Büyük dokunmatik sayaç (zikirmatik görünümü): sayı / hedef
class _Counter extends StatelessWidget {
  final int count;
  final int target;
  final double size;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _Counter({
    required this.count,
    required this.target,
    required this.size,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final done = count >= target;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          button: true,
          label: label,
          value: '$count / $target',
          hint: hint,
          onTap: onTap,
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: size,
            child: Material(
              key: TesbihatView.counterKey,
              color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
              shape: CircleBorder(
                side: BorderSide(
                  color: done
                      ? colors.success
                      : scheme.primary.withValues(alpha: 0.5),
                  width: 6,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(size * 0.2),
                  child: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabularText(
                          '$count',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: done ? colors.success : scheme.onSurface,
                          ),
                        ),
                        Text(
                          '/ $target',
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
