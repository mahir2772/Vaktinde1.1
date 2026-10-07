import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// − değer + : 48dp düğmeli sayı ayarlayıcı. [min]/[max] sınırında ilgili düğme
/// kapanır. [onValueTap] verilirse değere dokununca (ör. elle giriş) çağrılır.
/// Ekran okuyucuda "artır/azalt" eylemleriyle ayarlanabilir.
class CounterStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final int step;
  final String Function(int)? format;
  final String? semanticLabel;
  final VoidCallback? onValueTap;

  const CounterStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
    this.format,
    this.semanticLabel,
    this.onValueTap,
  });

  bool get _canDecrease => value - step >= min;
  bool get _canIncrease => max == null || value + step <= max!;

  void _decrease() {
    if (_canDecrease) onChanged(value - step);
  }

  void _increase() {
    if (_canIncrease) onChanged(value + step);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = format?.call(value) ?? '$value';
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
    final buttonStyle = IconButton.styleFrom(
      minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      disabledBackgroundColor: scheme.surfaceContainerHigh,
      disabledForegroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
    );

    return Semantics(
      label: semanticLabel,
      value: text,
      increasedValue: _canIncrease
          ? (format?.call(value + step) ?? '${value + step}')
          : null,
      decreasedValue: _canDecrease
          ? (format?.call(value - step) ?? '${value - step}')
          : null,
      onIncrease: _canIncrease ? _increase : null,
      onDecrease: _canDecrease ? _decrease : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: IconButton(
              style: buttonStyle,
              onPressed: _canDecrease ? _decrease : null,
              icon: const Icon(Icons.remove),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: ExcludeSemantics(
              child: onValueTap == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: label,
                    )
                  : InkWell(
                      onTap: onValueTap,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        child: label,
                      ),
                    ),
            ),
          ),
          ExcludeSemantics(
            child: IconButton(
              style: buttonStyle,
              onPressed: _canIncrease ? _increase : null,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
