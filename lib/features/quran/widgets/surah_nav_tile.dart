import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';

import '../../../data/services/quran_service.dart';

/// Önceki / sonraki sure düğmesi (okuyucunun başında ve sonunda): küçük
/// etiket + sure adı ve yön oku (sağdan sola dilde ok döner)
class SurahNavTile extends StatelessWidget {
  final String label;
  final Surah surah;
  final String language;

  /// true: sonraki (ok sonda), false: önceki (ok başta)
  final bool forward;
  final VoidCallback onTap;

  const SurahNavTile({
    super.key,
    required this.label,
    required this.surah,
    required this.language,
    required this.forward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arrow = Icon(
      forward ? Icons.chevron_right : Icons.chevron_left,
      color: scheme.primary,
    );
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (!forward) ...[arrow, const SizedBox(width: AppSpacing.sm)],
          Expanded(
            child: Column(
              crossAxisAlignment: forward
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  surah.displayName(language),
                  textAlign: forward ? TextAlign.end : TextAlign.start,
                  // Arapça arayüzde ad Arapça (Amiri)
                  style: language == 'ar'
                      ? TextStyle(
                          fontFamily: AppTheme.arabicFamily,
                          fontSize: 20,
                          height: 1.4,
                          color: scheme.onSurface,
                        )
                      : theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (forward) ...[const SizedBox(width: AppSpacing.sm), arrow],
        ],
      ),
    );
  }
}
