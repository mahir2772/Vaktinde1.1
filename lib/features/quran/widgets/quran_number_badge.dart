import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';

/// Sure / ayet numarası: marka renkli daire (büyük yazıda sayı küçülerek sığar)
class QuranNumberBadge extends StatelessWidget {
  static const double size = 36;

  final int number;

  const QuranNumberBadge({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Text(
            '$number',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.labelMedium!.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
