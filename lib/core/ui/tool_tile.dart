import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_tokens.dart';

/// Araçlar ızgarası kutucuğu: büyük ikon kutusu + ortalı başlık (kırpılmaz,
/// sığmayan kelime alt satıra geçer). Kutucuğun tamamı dalga efektli düğme;
/// ekran okuyucu başlığı okur, [hint] aracın ne yaptığını söyler. Yüksekliği
/// içerik belirler (ızgarada satır en uzun başlığa göre gerilir); sütun sayısı
/// [minWidth] ile seçilir.
class ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback onTap;

  const ToolTile({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    required this.onTap,
  });

  // Liste satırlarındaki ikon kutusunun (40dp, simge 22) büyüğü
  static const double _iconBox = 52;
  static const double _iconSize = 28;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.md,
  );

  static TextStyle _titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!;

  /// [title]'ın en uzun kelimesinin bölünmeden sığdığı en dar kutucuk (dile ve
  /// yazı boyutuna göre)
  static double minWidth(BuildContext context, String title) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    var widest = _iconBox;
    for (final word in title.split(' ')) {
      painter
        ..text = TextSpan(text: word, style: _titleStyle(context))
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    return widest + _padding.horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        hint: hint,
        child: AppCard(
          onTap: onTap,
          padding: _padding,
          child: Column(
            children: [
              Container(
                width: _iconBox,
                height: _iconBox,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  icon,
                  size: _iconSize,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _titleStyle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
