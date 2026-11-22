import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ezan_saati/core/ui/ui.dart';

import '../../../data/services/quran_service.dart';
import 'quran_page_frame.dart';
import 'reader_item.dart';

/// Sayfa görünümünde Arapça yazı boyutu (ölçek 1) ve satır yüksekliği:
/// harekeler üst üste binmesin, satırlar mushaftaki gibi eşit aralıklı olsun
const double mushafFontSize = 25;
const double mushafLineHeight = 2.25;

/// Ayetin arka planı: alt sayfası açık / "Ayete git" ile gelinen ayet ve
/// yer imli ayet
Color? ayahHighlight(
  ColorScheme scheme, {
  required bool selected,
  required bool bookmarked,
}) {
  if (selected) return scheme.primaryContainer.withValues(alpha: 0.75);
  if (bookmarked) return scheme.tertiaryContainer.withValues(alpha: 0.75);
  return null;
}

/// Sayfa görünümünün bir sayfası: çerçeve içinde tek Text.rich ile
/// kesintisiz Arapça metin (sağdan sola, iki yana yaslı, Amiri). Her ayetin
/// sonunda ﴿١٢﴾ işareti; ayete (ya da işaretine) dokununca [onAyahTap].
/// Ayet başına bir TapGestureRecognizer; sayfa kaldırılınca dispose edilir.
class MushafPage extends StatefulWidget {
  final ReaderItemRegistry registry;
  final int index;
  final QuranPageGroup group;
  final String label;
  final double fontScale;
  final int? selectedAyah;
  final int? bookmarkedAyah;
  final ValueChanged<QuranAyah> onAyahTap;

  const MushafPage({
    super.key,
    required this.registry,
    required this.index,
    required this.group,
    required this.label,
    required this.fontScale,
    required this.selectedAyah,
    required this.bookmarkedAyah,
    required this.onAyahTap,
  });

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage>
    with RegisteredAyahItem<MushafPage> {
  final GlobalKey _textKey = GlobalKey();
  final Map<int, TapGestureRecognizer> _recognizers = {};

  /// Ayetlerin düz metindeki aralıkları (UTF-16): [start, end), işaret dahil
  List<({int start, int end, int ayah})> _ranges = const [];

  @override
  ReaderItemRegistry get registry => widget.registry;

  @override
  int get index => widget.index;

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.group, widget.group)) {
      final keep = {for (final a in widget.group.ayahs) a.number};
      _recognizers.removeWhere((number, recognizer) {
        if (keep.contains(number)) return false;
        recognizer.dispose();
        return true;
      });
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  TapGestureRecognizer _recognizer(QuranAyah ayah) =>
      (_recognizers[ayah.number] ??= TapGestureRecognizer())
        ..onTap = () => widget.onAyahTap(ayah);

  RenderParagraph? get _paragraph {
    final object = _textKey.currentContext?.findRenderObject();
    if (object is RenderParagraph) return object.hasSize ? object : null;
    RenderParagraph? found;
    void visit(RenderObject child) {
      if (found != null) return;
      if (child is RenderParagraph) {
        found = child;
      } else {
        child.visitChildren(visit);
      }
    }

    object?.visitChildren(visit);
    return found != null && found!.hasSize ? found : null;
  }

  @override
  int ayahAt(double dy) {
    final group = widget.group;
    final paragraph = _paragraph;
    final item = context.findRenderObject();
    if (paragraph == null || item is! RenderBox) return group.firstAyah;
    final y = paragraph.globalToLocal(item.localToGlobal(Offset(0, dy))).dy;
    if (y <= 0) return group.firstAyah;
    if (y >= paragraph.size.height) return group.lastAyah;
    // Satırın baştan sona aralığı (sağdan sola: ilk harf sağ kenarda, son
    // harf sol kenarda)
    final a = paragraph
        .getPositionForOffset(Offset(paragraph.size.width - 1, y))
        .offset;
    final b = paragraph.getPositionForOffset(Offset(1, y)).offset;
    final lineStart = math.min(a, b);
    final lineEnd = math.max(a, b);
    // Satırda başlayan ilk ayet (önceki ayetin sonu satır başında kalsa da);
    // yoksa satırın içinde sürdüğü ayet
    for (final range in _ranges) {
      if (range.start > lineEnd) break;
      if (range.start >= lineStart) return range.ayah;
    }
    for (final range in _ranges) {
      if (lineStart < range.end) return range.ayah;
    }
    return group.lastAyah;
  }

  @override
  double offsetOf(int ayah) {
    if (ayah <= widget.group.firstAyah) return 0;
    final range = _ranges.where((r) => r.ayah == ayah).firstOrNull;
    final paragraph = _paragraph;
    final item = context.findRenderObject();
    if (range == null || paragraph == null || item is! RenderBox) return 0;
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: range.start),
      Rect.zero,
    );
    return item.globalToLocal(paragraph.localToGlobal(Offset(0, caret.dy))).dy;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = mushafFontSize * widget.fontScale;
    final spans = <InlineSpan>[];
    final ranges = <({int start, int end, int ayah})>[];
    var offset = 0;
    for (final ayah in widget.group.ayahs) {
      final background = ayahHighlight(
        scheme,
        selected: ayah.number == widget.selectedAyah,
        bookmarked: ayah.number == widget.bookmarkedAyah,
      );
      final recognizer = _recognizer(ayah);
      // Bölünmez boşluk: işaret ayetin son kelimesinden ayrı satıra düşmez
      final marker = '\u00A0${QuranService.ayahEndMarker(ayah.number)}';
      spans
        ..add(
          TextSpan(
            text: ayah.arabic,
            recognizer: recognizer,
            style: background == null
                ? null
                : TextStyle(backgroundColor: background),
          ),
        )
        ..add(
          TextSpan(
            text: marker,
            recognizer: recognizer,
            style: TextStyle(
              color: scheme.primary,
              backgroundColor: background,
            ),
          ),
        )
        ..add(const TextSpan(text: ' '));
      final end = offset + ayah.arabic.length + marker.length;
      ranges.add((start: offset, end: end, ayah: ayah.number));
      offset = end + 1;
    }
    _ranges = ranges;

    final scaledSize = MediaQuery.textScalerOf(context).scale(size);
    return QuranPageFrame(
      label: widget.label,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: LayoutBuilder(
          // Satıra az kelime sığıyorsa (dar ekran, büyük yazı) iki yana
          // yaslama kelime aralarını çok açar: sağa yaslı
          builder: (context, constraints) => Text.rich(
            TextSpan(children: spans),
            key: _textKey,
            textAlign: constraints.maxWidth / scaledSize >= minJustifyEms
                ? TextAlign.justify
                : TextAlign.start,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: size,
              height: mushafLineHeight,
              color: scheme.onSurface,
            ),
            strutStyle: StrutStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: size,
              height: mushafLineHeight,
              forceStrutHeight: true,
            ),
          ),
        ),
      ),
    );
  }

  /// İki yana yaslama için satır genişliği (yazı boyutu cinsinden) en az
  static const double minJustifyEms = 10;
}
