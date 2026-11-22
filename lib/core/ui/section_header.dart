import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'prayer_colors.dart';

/// Liste/ekran bölüm başlığı (marka renginde, ekran okuyucuda başlık).
/// Arka plan resmi seçiliyken (Scaffold şeffaf) başlık koyu kapsül üstünde
/// beyaz çizilir: fotoğraf üstünde de okunur. [onImage] ile zorlanabilir.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// null: temadan anlaşılır (arka plan resmi varsa Scaffold şeffaftır)
  final bool? onImage;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding,
    this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = onImage ?? theme.scaffoldBackgroundColor.a == 0;
    final Widget label;
    if (pill) {
      final colors = PrayerColors.of(context);
      label = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            // Açık renkli fotoğrafta da beyaz yazı okunsun (~%50 karartma)
            color: colors.heroImageScrim,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall!.copyWith(color: colors.onHero),
          ),
        ),
      );
    } else {
      label = Text(
        title,
        style: theme.textTheme.titleSmall!.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }
    return Padding(
      padding:
          padding ??
          const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: label)),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
