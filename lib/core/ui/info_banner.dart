import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'prayer_colors.dart';

enum InfoTone { info, warning, danger, success }

/// Bilgi/uyarı şeridi (opak; fotoğraf üstünde de okunur)
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final InfoTone tone;
  final Widget? action;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon,
    this.tone = InfoTone.info,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final (
      Color background,
      Color foreground,
      Color accent,
      IconData fallback,
    ) = switch (tone) {
      InfoTone.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.onPrimaryContainer,
        Icons.info_outline,
      ),
      InfoTone.warning => (
        colors.warningContainer,
        colors.onWarningContainer,
        colors.warning,
        Icons.warning_amber_rounded,
      ),
      InfoTone.danger => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        scheme.error,
        Icons.error_outline,
      ),
      InfoTone.success => (
        colors.successContainer,
        colors.onSuccessContainer,
        colors.success,
        Icons.check_circle_outline,
      ),
    };
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon ?? fallback, size: 22, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium!.copyWith(color: foreground),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
