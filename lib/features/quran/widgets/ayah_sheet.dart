import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';
import '../../common/share_card.dart';
import 'quran_number_badge.dart';

/// Ayet alt sayfası (sayfa ve meal görünümünde ayete dokununca): ayetin
/// Arapçası ve meali, yer imi, kopyalama ve resimli paylaşım. İçerik kadar
/// yer kaplar (uzun ayette kaydırılır); altta gezinme çubuğu boşluğu.
/// [onToggleBookmark] yeni durumu döner (kayıt olmazsa null).
Future<void> showAyahSheet(
  BuildContext context, {
  required Surah surah,
  required QuranAyah ayah,
  required String language,
  required String? pageLabel,
  required double fontScale,
  required double translationScale,
  required bool bookmarked,
  required Future<bool?> Function() onToggleBookmark,
  VoidCallback? onListen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: AyahSheet(
        surah: surah,
        ayah: ayah,
        language: language,
        pageLabel: pageLabel,
        fontScale: fontScale,
        translationScale: translationScale,
        bookmarked: bookmarked,
        onToggleBookmark: onToggleBookmark,
        onListen: onListen,
      ),
    ),
  );
}

class AyahSheet extends StatefulWidget {
  final Surah surah;
  final QuranAyah ayah;
  final String language;
  final String? pageLabel;
  final double fontScale;
  final double translationScale;
  final bool bookmarked;
  final Future<bool?> Function() onToggleBookmark;

  /// "Bu ayetten dinle" (dinleme açıksa; alt sayfa kapanır)
  final VoidCallback? onListen;

  const AyahSheet({
    super.key,
    required this.surah,
    required this.ayah,
    required this.language,
    required this.pageLabel,
    required this.fontScale,
    required this.translationScale,
    required this.bookmarked,
    required this.onToggleBookmark,
    this.onListen,
  });

  @override
  State<AyahSheet> createState() => _AyahSheetState();
}

class _AyahSheetState extends State<AyahSheet> {
  late bool _bookmarked = widget.bookmarked;
  bool _copied = false;
  Timer? _copiedTimer;

  String get _reference => AppLocalizations.of(context)!.quranAyahRef(
    widget.surah.displayName(widget.language),
    widget.ayah.number,
  );

  Future<void> _toggleBookmark() async {
    final result = await widget.onToggleBookmark();
    if (result != null && mounted) setState(() => _bookmarked = result);
  }

  Future<void> _copy() async {
    final translation = widget.ayah.translation;
    final text = [
      widget.ayah.arabic,
      ?translation,
      '— $_reference',
    ].join('\n\n');
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _share() {
    final translation = widget.ayah.translation;
    shareAsImage(
      context,
      title: _reference,
      message: translation ?? widget.ayah.arabic,
      arabic: translation == null ? null : widget.ayah.arabic,
      campaign: 'quran',
    );
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ayah = widget.ayah;
    final translation = ayah.translation;
    final pageLabel = widget.pageLabel;

    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): düğmeler altında kalmasın
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              QuranNumberBadge(number: ayah.number),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        _reference,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (pageLabel != null)
                      Text(
                        pageLabel,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ayah.arabic),
                // Sayfadaki gibi marka renkli ayet sonu işareti
                TextSpan(
                  text: '\u00A0${QuranService.ayahEndMarker(ayah.number)}',
                  style: TextStyle(color: scheme.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: 26 * widget.fontScale,
              height: 2,
              color: scheme.onSurface,
            ),
          ),
          if (translation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              translation,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 17 * widget.translationScale,
                height: 1.6,
                color: scheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (widget.onListen case final listen?)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    listen();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, AppSizes.minTouch),
                  ),
                  icon: const Icon(Icons.headphones_outlined),
                  label: Text(loc.quranListenFromAyah),
                ),
              OutlinedButton.icon(
                onPressed: _toggleBookmark,
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text(
                  _bookmarked ? loc.quranBookmarkRemove : loc.quranBookmarkSave,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: Icon(_copied ? Icons.check : Icons.copy_rounded),
                label: Text(_copied ? loc.textCopied : loc.copy),
              ),
              FilledButton.tonalIcon(
                onPressed: _share,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, AppSizes.minTouch),
                ),
                icon: const Icon(Icons.image_outlined),
                label: Text(loc.shareAsImage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
