import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../data/models/hadith_model.dart';
import '../../quran/ayah_model.dart';

/// Günün ayeti / hadisi: tek kartta iki kısa giriş; dokununca okunabilir sayfa
/// (kendiliğinden kapanmaz, kaydırılabilir, kopyala/paylaş).
class DailyContentRow extends StatelessWidget {
  final AyahModel? ayah;
  final HadithModel? hadith;

  const DailyContentRow({super.key, this.ayah, this.hadith});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = <Widget>[
      if (ayah != null)
        _DailyItem(
          icon: Icons.menu_book_rounded,
          title: loc.dailyAyahTitle,
          preview: ayah!.translatedText,
          onTap: () => showDailyAyahSheet(context, ayah!),
        ),
      // Metni olmayan hadis gösterilmez
      if (hadith != null && (hadith!.content ?? '').isNotEmpty)
        _DailyItem(
          icon: Icons.format_quote_rounded,
          title: loc.hadithTitle,
          preview: hadith!.content!,
          onTap: () => showDailyHadithSheet(context, hadith!),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final divider = Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: items[0]),
            if (items.length > 1) ...[divider, Expanded(child: items[1])],
          ],
        ),
      ),
    );
  }
}

class _DailyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String preview;
  final VoidCallback onTap;

  const _DailyItem({
    required this.icon,
    required this.title,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        preview.replaceAll('\n', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showDailyAyahSheet(BuildContext context, AyahModel ayah) {
  final loc = AppLocalizations.of(context)!;
  final source = '${ayah.surahName} ${ayah.numberInSurah}';
  return _showReadingSheet(
    context,
    icon: Icons.menu_book_rounded,
    title: loc.dailyAyahTitle,
    arabic: ayah.arabicText,
    text: ayah.translatedText,
    source: source,
  );
}

Future<void> showDailyHadithSheet(BuildContext context, HadithModel hadith) {
  final loc = AppLocalizations.of(context)!;
  return _showReadingSheet(
    context,
    icon: Icons.format_quote_rounded,
    title: loc.hadithTitle,
    text: hadith.content ?? loc.hadithNotFound,
    source: hadith.source ?? '',
  );
}

Future<void> _showReadingSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? arabic,
  required String text,
  required String source,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => _ReadingContent(
        controller: controller,
        icon: icon,
        title: title,
        arabic: arabic,
        text: text,
        source: source,
      ),
    ),
  );
}

class _ReadingContent extends StatefulWidget {
  final ScrollController controller;
  final IconData icon;
  final String title;
  final String? arabic;
  final String text;
  final String source;

  const _ReadingContent({
    required this.controller,
    required this.icon,
    required this.title,
    required this.arabic,
    required this.text,
    required this.source,
  });

  @override
  State<_ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<_ReadingContent> {
  bool _copied = false;
  Timer? _copiedTimer;

  String get _plainText {
    final buffer = StringBuffer();
    if (widget.arabic != null && widget.arabic!.trim().isNotEmpty) {
      buffer.writeln(widget.arabic!.trim());
      buffer.writeln();
    }
    buffer.write(widget.text.trim());
    if (widget.source.trim().isNotEmpty) {
      buffer.write('\n\n— ${widget.source.trim()}');
    }
    return buffer.toString();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _plainText));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    try {
      await Share.share('$_plainText\n\n${widget.title} · Vaktinde');
    } catch (_) {}
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
    return ListView(
      controller: widget.controller,
      // + gezinme çubuğu (uçtan uca): sondaki butonlar altında kalmasın
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Icon(widget.icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(widget.title, style: theme.textTheme.titleLarge),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (widget.arabic != null && widget.arabic!.trim().isNotEmpty) ...[
          Text(
            widget.arabic!.trim(),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: 26,
              height: 1.9,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        SelectableText(
          widget.text.trim(),
          style: theme.textTheme.bodyLarge!.copyWith(fontSize: 17, height: 1.6),
        ),
        if (widget.source.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '— ${widget.source.trim()}',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: _copy,
              icon: Icon(_copied ? Icons.check : Icons.copy_rounded),
              label: Text(_copied ? loc.textCopied : loc.copy),
            ),
            FilledButton.tonalIcon(
              onPressed: _share,
              icon: const Icon(Icons.share_rounded),
              label: Text(loc.share),
            ),
          ],
        ),
      ],
    );
  }
}
