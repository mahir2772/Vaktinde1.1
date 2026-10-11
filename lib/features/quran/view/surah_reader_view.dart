import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';
import '../../common/share_card.dart';
import '../widgets/quran_number_badge.dart';

/// Sure okuyucu: başlık kartı (Arapça ad, iniş yeri, ayet sayısı, besmele),
/// ayet kartları (Arapça Amiri ile sağdan sola + meal) ve sonda kaynak.
/// Ayet başına "kaldığın yer" (ikon ya da uzun basma) ve resimli paylaşım;
/// Arapça yazı boyutu A-/A+ ile ('quran_font_scale').
///
/// [initialAyah] verilirse liste o ayetten başlar (tembel liste: CustomScrollView
/// merkezi o ayet, öncekiler yukarı kaydırınca görünür).
class SurahReaderView extends StatefulWidget {
  final Surah surah;
  final int? initialAyah;

  /// Test için (varsayılan: alquran.cloud + cihazdaki kopya)
  final QuranService? service;

  const SurahReaderView({
    super.key,
    required this.surah,
    this.initialAyah,
    this.service,
  });

  @override
  State<SurahReaderView> createState() => _SurahReaderViewState();
}

class _SurahReaderViewState extends State<SurahReaderView> {
  late final QuranService _service = widget.service ?? QuranService();
  final Key _centerKey = UniqueKey();
  Future<SurahText>? _text;
  String? _language;
  double _fontScale = 1;
  QuranBookmark? _bookmark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _text = _service.loadSurah(widget.surah, language);
    }
  }

  Future<void> _loadSettings() async {
    final scale = await _service.loadFontScale();
    final bookmark = await _service.loadBookmark();
    if (!mounted) return;
    setState(() {
      _fontScale = scale;
      _bookmark = bookmark;
    });
  }

  void _retry() {
    setState(() {
      _text = _service.loadSurah(widget.surah, _language!);
    });
  }

  void _changeFontScale(int direction) {
    final next = QuranService.clampFontScale(
      _fontScale + direction * QuranService.fontScaleStep,
    );
    if (next == _fontScale) return;
    setState(() => _fontScale = next);
    _service.saveFontScale(next);
  }

  /// [toggle]: ikon (kayıtlı ayette siler); uzun basma her zaman kaydeder
  Future<void> _setBookmark(int ayah, {required bool toggle}) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final mark = QuranBookmark(surah: widget.surah.number, ayah: ayah);
    final remove = toggle && _bookmark == mark;
    try {
      if (remove) {
        await _service.clearBookmark();
      } else {
        await _service.saveBookmark(mark);
      }
    } catch (_) {
      _showSnack(messenger, loc.shareFailed);
      return;
    }
    if (!mounted) return;
    setState(() => _bookmark = remove ? null : mark);
    _showSnack(
      messenger,
      remove ? loc.quranBookmarkRemoved : loc.quranBookmarkSaved,
    );
  }

  void _share(QuranAyah ayah) {
    final loc = AppLocalizations.of(context)!;
    final translation = ayah.translation;
    shareAsImage(
      context,
      title: loc.quranAyahRef(
        widget.surah.displayName(_language!),
        ayah.number,
      ),
      message: translation ?? ayah.arabic,
      arabic: translation == null ? null : ayah.arabic,
      campaign: 'quran',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppScaffold(
      title: widget.surah.displayName(_language!),
      actions: [
        IconButton(
          tooltip: loc.quranFontSmaller,
          onPressed: _fontScale > QuranService.minFontScale
              ? () => _changeFontScale(-1)
              : null,
          icon: const Icon(Icons.text_decrease),
        ),
        IconButton(
          tooltip: loc.quranFontLarger,
          onPressed: _fontScale < QuranService.maxFontScale
              ? () => _changeFontScale(1)
              : null,
          icon: const Icon(Icons.text_increase),
        ),
      ],
      body: FutureBuilder<SurahText>(
        future: _text,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorState(message: loc.quranLoadError, onRetry: _retry);
          }
          return _buildList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildList(SurahText text) {
    final ayahs = text.ayahs;
    // 0: başlık, 1..n: ayetler, n + 1: kaynak
    final count = ayahs.length + 2;
    final center = (widget.initialAyah ?? 0).clamp(0, ayahs.length);

    Widget item(int index) {
      if (index == 0) {
        return _SurahHeader(
          surah: widget.surah,
          language: _language!,
          bismillah: text.bismillah,
          fontScale: _fontScale,
        );
      }
      if (index == count - 1) {
        return _SourceNote(translationEdition: text.translationEdition);
      }
      final ayah = ayahs[index - 1];
      return _AyahCard(
        ayah: ayah,
        fontScale: _fontScale,
        bookmarked:
            _bookmark ==
            QuranBookmark(surah: widget.surah.number, ayah: ayah.number),
        onBookmark: () => _setBookmark(ayah.number, toggle: true),
        onLongPress: () => _setBookmark(ayah.number, toggle: false),
        onShare: () => _share(ayah),
      );
    }

    return CustomScrollView(
      center: _centerKey,
      slivers: [
        // Merkezden önceki öğeler ters sırayla yukarı doğru dizilir
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => item(center - 1 - i),
            childCount: center,
          ),
        ),
        SliverList(
          key: _centerKey,
          delegate: SliverChildBuilderDelegate(
            (context, i) => item(center + i),
            childCount: count - center,
          ),
        ),
      ],
    );
  }
}

void _showSnack(ScaffoldMessengerState? messenger, String text) {
  if (messenger == null || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
}

/// Ayetin Arapça metni (Amiri, sağdan sola); boyut [fontScale] ile
TextStyle _arabicStyle(BuildContext context, double fontScale) => TextStyle(
  fontFamily: AppTheme.arabicFamily,
  fontSize: 26 * fontScale,
  height: 2,
  color: Theme.of(context).colorScheme.onSurface,
);

class _SurahHeader extends StatelessWidget {
  final Surah surah;
  final String language;
  final String? bismillah;
  final double fontScale;

  const _SurahHeader({
    required this.surah,
    required this.language,
    required this.bismillah,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info =
        '${surah.isMedinan ? loc.quranMedinan : loc.quranMeccan} · '
        '${loc.quranAyahCount(surah.ayahCount)}';
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(
            surah.arabicName,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: 30,
              height: 1.5,
              color: scheme.primary,
            ),
          ),
          if (language != 'ar')
            Text(
              surah.displayName(language),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            info,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (bismillah != null) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              bismillah!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: _arabicStyle(context, fontScale),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final QuranAyah ayah;
  final double fontScale;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onLongPress;
  final VoidCallback onShare;

  const _AyahCard({
    required this.ayah,
    required this.fontScale,
    required this.bookmarked,
    required this.onBookmark,
    required this.onLongPress,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final translation = ayah.translation;
    // Kaldığın yer: hafif marka tonu (opak; arka plan resminde de okunur)
    final cardColor = theme.cardTheme.color ?? scheme.surfaceContainerLowest;
    final color = bookmarked
        ? Color.alphaBlend(
            scheme.primaryContainer.withValues(alpha: 0.5),
            cardColor,
          )
        : null;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: EdgeInsets.zero,
      color: color,
      child: InkWell(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.xs,
                0,
              ),
              child: Row(
                children: [
                  QuranNumberBadge(number: ayah.number),
                  const Spacer(),
                  IconButton(
                    tooltip: bookmarked
                        ? loc.quranBookmarkRemove
                        : loc.quranBookmarkSave,
                    onPressed: onBookmark,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: bookmarked ? scheme.primary : null,
                    ),
                  ),
                  IconButton(
                    tooltip: loc.quranShareAyah,
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ayah.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: _arabicStyle(context, fontScale),
                  ),
                  if (translation != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      translation,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        height: 1.55,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metin kaynağı: Tanzil (koşulu: kaynak ve tanzil.net bağlantısı belirtilir)
/// ve meal sahibi
class _SourceNote extends StatelessWidget {
  final String? translationEdition;

  const _SourceNote({required this.translationEdition});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final edition = translationEdition;
    final translator = edition == null
        ? null
        : QuranEdition.translatorOf(edition);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.quranTextSource, style: style),
          if (translator != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(loc.quranTranslationSource(translator), style: style),
          ],
        ],
      ),
    );
  }
}
