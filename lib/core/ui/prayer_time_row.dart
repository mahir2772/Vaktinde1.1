import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_tokens.dart';
import 'prayer_colors.dart';

/// Vaktin güne göre durumu: geçti / şu an / sıradaki / gelecek
enum PrayerRowState { past, current, next, upcoming }

/// Vakit satırı: ad + saat. Sıradaki vakit dolu renkle, şu anki vakit marka
/// rengiyle vurgulanır; geçmiş vakit soluk (ama okunur) çizilir.
class PrayerTimeRow extends StatelessWidget {
  final String name;
  final String time;
  final PrayerRowState state;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PrayerTimeRow({
    super.key,
    required this.name,
    required this.time,
    this.state = PrayerRowState.upcoming,
    this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isNext = state == PrayerRowState.next;
    final Color foreground = switch (state) {
      PrayerRowState.next => colors.onNextContainer,
      PrayerRowState.current => colors.current,
      PrayerRowState.past => colors.past,
      PrayerRowState.upcoming => scheme.onSurface,
    };
    final emphasized =
        state == PrayerRowState.next || state == PrayerRowState.current;
    final nameStyle = theme.textTheme.bodyLarge!.copyWith(
      color: foreground,
      fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
    );
    final timeStyle = theme.textTheme.titleMedium!.copyWith(
      color: foreground,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: AppTheme.tabularFigures,
    );

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: foreground),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: Text(name, style: nameStyle)),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(time, style: timeStyle, textDirection: TextDirection.ltr),
          ],
        ),
      ),
    );

    // Ink: dokunma dalgası dolu arka planın üstünde görünsün
    final decorated = Ink(
      decoration: BoxDecoration(
        color: isNext ? colors.nextContainer : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: state == PrayerRowState.current
            ? Border.all(color: colors.current, width: 1.5)
            : null,
      ),
      child: row,
    );

    return MergeSemantics(
      child: Semantics(
        selected: emphasized,
        button: onTap != null,
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null
              ? decorated
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: decorated,
                ),
        ),
      ),
    );
  }
}
