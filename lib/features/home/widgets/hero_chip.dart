import 'package:flutter/material.dart';

import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/prayer_colors.dart';

/// Ana ekran hero'sundaki bilgi kapsülü (kerahat, Ramazan sayacı).
/// Koyu yarı saydam zemin + beyaz yazı: gradyan ve fotoğraf üstünde okunur.
/// [emphasized]: dikkat gerektiren durum (ör. kerahat sürüyor) amber zeminle.
class HeroChip extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final bool emphasized;

  const HeroChip({
    super.key,
    required this.icon,
    required this.child,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = PrayerColors.of(context);
    final background = emphasized ? const Color(0xFFFFD08A) : colors.heroChip;
    final foreground = emphasized ? const Color(0xFF3D2600) : colors.onHero;
    final iconColor = emphasized
        ? const Color(0xFF3D2600)
        : const Color(0xFFFFD08A);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        6,
        AppSpacing.lg,
        6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall!.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
