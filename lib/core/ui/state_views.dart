import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_tokens.dart';

/// Ortak boş / hata / yükleniyor görünümleri (ortalanmış, küçük ekranda kayar)
class _CenteredStateView extends StatelessWidget {
  final List<Widget> children;

  const _CenteredStateView({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? math.max(0.0, constraints.maxHeight - 2 * AppSpacing.xl)
                : 0.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _iconBadge(BuildContext context, IconData icon, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: error ? scheme.errorContainer : scheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      size: 36,
      color: error ? scheme.onErrorContainer : scheme.onPrimaryContainer,
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredStateView(
      children: [
        _iconBadge(context, icon),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  /// İsteğe bağlı ikinci yol (ör. "Konum Değiştir")
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = AppLocalizations.of(context)?.retry ?? 'Retry';
    return _CenteredStateView(
      children: [
        _iconBadge(context, Icons.error_outline, error: true),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retry),
          ),
        ],
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}

class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredStateView(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3.5),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
