import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Opak kart (açık temada 1px çerçeve, yarıçap 16). [onTap] verilirse dalga
/// efektiyle dokunulabilir olur.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final shape =
        cardTheme.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        );
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, customBorder: shape, child: content);
    }
    Widget card = Material(
      color:
          color ?? cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        child: card,
      );
    }
    return Padding(padding: margin, child: card);
  }
}
