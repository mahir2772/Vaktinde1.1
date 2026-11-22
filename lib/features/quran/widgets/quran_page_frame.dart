import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';

/// Sayfa başlığı: "Sayfa 2 · Cüz 1"; sayfa bilgisi yoksa (eski kopya) ayet
/// aralığı ve cüz
String quranPageLabel(
  AppLocalizations loc,
  QuranPageGroup group, {
  required String surahName,
}) {
  final page = group.page;
  final String first;
  if (page != null) {
    first = loc.quranPage(page);
  } else if (group.firstAyah == group.lastAyah) {
    first = loc.quranAyahRef(surahName, group.firstAyah);
  } else {
    first = loc.quranAyahRange(group.firstAyah, group.lastAyah);
  }
  return '$first · ${loc.quranJuz(group.juz)}';
}

/// Mushaf sayfası görünümü: hafif kâğıt tonu, ince çift çerçeve (dışta
/// çizgi, içte altın tonu) ve üstte iki yanı çizgili sayfa başlığı. Opak:
/// arka plan resminde de okunur.
class QuranPageFrame extends StatelessWidget {
  final String label;
  final Widget child;

  const QuranPageFrame({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final card = theme.cardTheme.color ?? scheme.surfaceContainerLowest;
    final paper = Color.alphaBlend(
      scheme.tertiaryContainer.withValues(alpha: isLight ? 0.22 : 0.1),
      card,
    );
    final gold = scheme.tertiary.withValues(alpha: isLight ? 0.45 : 0.4);
    const outerRadius = AppRadius.lg;
    const gap = AppSpacing.xs;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(outerRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(gap),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outerRadius - gap),
              border: Border.all(color: gold),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageLabel(label: label, lineColor: gold),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageLabel extends StatelessWidget {
  final String label;
  final Color lineColor;

  const _PageLabel({required this.label, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = Expanded(child: Divider(color: lineColor, height: 1));
    // Yazı en çok %75 genişlikte (büyük yazıda alt satıra geçer), çizgiler
    // iki yanda eşit
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        header: true,
        child: Row(
          children: [
            line,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            line,
          ],
        ),
      ),
    );
  }
}
