import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';

import '../../../data/services/quran_service.dart';
import 'mushaf_page.dart' show ayahHighlight;
import 'quran_page_frame.dart';
import 'reader_item.dart';

/// Meal görünümünde yazı boyutu (ölçek 1)
const double translationFontSize = 17;

/// Meal görünümünün bir sayfası (sayfa görünümüyle aynı çerçeve ve
/// başlık): her ayetin meali, başında küçük ayet numarasıyla bir paragraf.
/// Paragrafa dokununca [onAyahTap] (ayetin Arapçası ve işlemler).
class TranslationPage extends StatefulWidget {
  final ReaderItemRegistry registry;
  final int index;
  final QuranPageGroup group;
  final String label;
  final double translationScale;
  final int? selectedAyah;
  final int? bookmarkedAyah;
  final ValueChanged<QuranAyah> onAyahTap;

  const TranslationPage({
    super.key,
    required this.registry,
    required this.index,
    required this.group,
    required this.label,
    required this.translationScale,
    required this.selectedAyah,
    required this.bookmarkedAyah,
    required this.onAyahTap,
  });

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage>
    with RegisteredAyahItem<TranslationPage> {
  final Map<int, GlobalKey> _keys = {};

  @override
  ReaderItemRegistry get registry => widget.registry;

  @override
  int get index => widget.index;

  /// Paragrafın öge içindeki dikey aralığı
  ({double top, double bottom})? _span(int ayah) {
    final item = context.findRenderObject();
    final box = _keys[ayah]?.currentContext?.findRenderObject();
    if (item is! RenderBox || box is! RenderBox || !box.hasSize) return null;
    final top = item.globalToLocal(box.localToGlobal(Offset.zero)).dy;
    return (top: top, bottom: top + box.size.height);
  }

  @override
  int ayahAt(double dy) {
    for (final ayah in widget.group.ayahs) {
      final span = _span(ayah.number);
      if (span != null && span.bottom > dy) return ayah.number;
    }
    return widget.group.lastAyah;
  }

  @override
  double offsetOf(int ayah) {
    if (ayah <= widget.group.firstAyah) return 0;
    return _span(ayah)?.top ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = translationFontSize * widget.translationScale;
    final textStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: size,
      height: 1.65,
      color: scheme.onSurface,
    );
    final numberStyle = TextStyle(
      fontSize: math.max(13, size * 0.8),
      fontWeight: FontWeight.w700,
      color: scheme.primary,
    );
    return QuranPageFrame(
      label: widget.label,
      // Dokunma dalgası kâğıt renginin üstünde görünsün
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final ayah in widget.group.ayahs)
                InkWell(
                  key: _keys.putIfAbsent(ayah.number, GlobalKey.new),
                  onTap: () => widget.onAyahTap(ayah),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: ayahHighlight(
                        scheme,
                        selected: ayah.number == widget.selectedAyah,
                        bookmarked: ayah.number == widget.bookmarkedAyah,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs + 2,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${ayah.number}\u00A0\u00A0',
                            style: numberStyle,
                          ),
                          TextSpan(text: ayah.translation ?? ''),
                        ],
                      ),
                      style: textStyle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
