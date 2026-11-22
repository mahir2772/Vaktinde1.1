import 'package:flutter/material.dart';

/// Rakamları eşit genişlikte çizen metin (geri sayım, saat).
///
/// Poppins'te tabular rakam (tnum) yok; sayaç her saniye kaymasın diye her rakam
/// en geniş rakam kadar kutuya ortalanır. Metin her dilde soldan sağa çizilir
/// (saatler RTL'de de "02:05:09" okunur). Ekran okuyucu metni tek parça okur.
/// Sığmazsa orantılı küçülür.
class TabularText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TabularText(this.text, {super.key, this.style});

  static final Map<(TextStyle, TextScaler), double> _digitWidthCache = {};

  static double _digitWidth(TextStyle style, TextScaler scaler) {
    final key = (style, scaler);
    final cached = _digitWidthCache[key];
    if (cached != null) return cached;
    var width = 0.0;
    for (var d = 0; d <= 9; d++) {
      final painter = TextPainter(
        text: TextSpan(text: '$d', style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      if (painter.width > width) width = painter.width;
      painter.dispose();
    }
    if (_digitWidthCache.length > 64) _digitWidthCache.clear();
    _digitWidthCache[key] = width;
    return width;
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final width = _digitWidth(effective, scaler).ceilToDouble();
    final children = <Widget>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      children.add(Text(buffer.toString(), style: effective));
      buffer.clear();
    }

    for (final rune in text.runes) {
      if (_isDigit(rune)) {
        flush();
        children.add(
          SizedBox(
            width: width,
            child: Text(
              String.fromCharCode(rune),
              style: effective,
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else {
        buffer.writeCharCode(rune);
      }
    }
    flush();

    // Dar ekranda/büyük yazıda sığmazsa küçülür (taşmaz)
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: children,
        ),
      ),
    );
  }
}
