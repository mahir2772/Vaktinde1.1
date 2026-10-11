import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';
import '../widgets/quran_number_badge.dart';
import 'surah_reader_view.dart';

/// Kur'an-ı Kerim: iki sekme — Sureler (gömülü liste, internetsiz; ad ya da
/// numarayla arama) ve Cüzler (30 cüz, başladığı sure:ayet). Üstte "Kaldığın
/// yerden devam et" (son okunan ayet, okuyucu kendisi saklar) ve ondan
/// farklıysa "Yer imi". Alt menü sekmesi; sekme geçişinde ve sure açılışında
/// reklam yok.
class QuranView extends StatefulWidget {
  /// Test için (varsayılan: gömülü liste + alquran.cloud)
  final QuranService? service;

  /// Alt menü sekmesi (MainWrapper): banner alt menüde (çift banner olmaz),
  /// geri düğmesi yok
  final bool asTab;

  const QuranView({super.key, this.service, this.asTab = false});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  late final QuranService _service = widget.service ?? QuranService();
  late Future<List<Surah>> _surahs = _service.loadSurahs();
  final TextEditingController _search = TextEditingController();
  QuranBookmark? _lastRead;
  QuranBookmark? _bookmark;

  @override
  void initState() {
    super.initState();
    _loadPositions();
    QuranService.lastReadChanges.addListener(_loadPositions);
  }

  @override
  void dispose() {
    QuranService.lastReadChanges.removeListener(_loadPositions);
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    final lastRead = await _service.loadLastRead();
    final bookmark = await _service.loadBookmark();
    if (!mounted) return;
    setState(() {
      _lastRead = lastRead;
      _bookmark = bookmark;
    });
  }

  void _retry() {
    setState(() {
      _surahs = _service.loadSurahs();
    });
  }

  Future<void> _open(List<Surah> surahs, Surah surah, {int? ayah}) async {
    FocusScope.of(context).unfocus();
    // Okuyucu sonraki/önceki sureye geçerse bu Future yeni okuyucu kapanınca
    // tamamlanır
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SurahReaderView(
          surah: surah,
          initialAyah: ayah,
          service: _service,
          surahs: surahs,
        ),
      ),
    );
    await _loadPositions();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: loc.quranTitle,
        showBanner: !widget.asTab,
        automaticallyImplyLeading: !widget.asTab,
        bottom: TabBar(
          tabs: [
            Tab(text: loc.quranTabSurahs),
            Tab(text: loc.quranTabJuz),
          ],
        ),
        body: FutureBuilder<List<Surah>>(
          future: _surahs,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ErrorState(message: loc.noDataFound, onRetry: _retry);
            }
            final surahs = snapshot.data!;
            return TabBarView(
              children: [
                _buildSurahList(surahs),
                _JuzList(
                  surahs: surahs,
                  onOpen: (surah, ayah) => _open(surahs, surah, ayah: ayah),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Kayıtlı konum listedeki bir ayetse suresi
  Surah? _surahOf(List<Surah> surahs, QuranBookmark? position) {
    if (position == null) return null;
    return surahs
        .where(
          (s) => s.number == position.surah && position.ayah <= s.ayahCount,
        )
        .firstOrNull;
  }

  Widget _buildSurahList(List<Surah> surahs) {
    final loc = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final lastRead = _lastRead;
    final bookmark = _bookmark;
    final lastReadSurah = _surahOf(surahs, lastRead);
    final bookmarkSurah = bookmark == lastRead
        ? null
        : _surahOf(surahs, bookmark);
    final results = QuranService.searchSurahs(surahs, _search.text);

    final header = <Widget>[
      if (lastReadSurah != null)
        _ResumeCard(
          icon: Icons.auto_stories,
          title: loc.quranContinue,
          subtitle: loc.quranAyahRef(
            lastReadSurah.displayName(language),
            lastRead!.ayah,
          ),
          emphasized: true,
          onTap: () => _open(surahs, lastReadSurah, ayah: lastRead.ayah),
        ),
      if (bookmarkSurah != null)
        _ResumeCard(
          icon: Icons.bookmark,
          title: loc.quranBookmark,
          subtitle: loc.quranAyahRef(
            bookmarkSurah.displayName(language),
            bookmark!.ayah,
          ),
          emphasized: false,
          onTap: () => _open(surahs, bookmarkSurah, ayah: bookmark.ayah),
        ),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: loc.quranSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: () => setState(_search.clear),
                ),
        ),
      ),
      if (results.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            loc.quranNoResults,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: header.length + results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final surah = results[index - header.length];
        return _SurahCard(
          surah: surah,
          language: language,
          onTap: () => _open(surahs, surah),
        );
      },
    );
  }
}

/// Cüzler: numara, "Cüz N" ve başladığı ayet; dokununca o ayetten açılır
class _JuzList extends StatelessWidget {
  final List<Surah> surahs;
  final void Function(Surah surah, int ayah) onOpen;

  const _JuzList({required this.surahs, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const starts = QuranService.juzStarts;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: starts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final start = starts[index];
        final surah = surahs.where((s) => s.number == start.surah).firstOrNull;
        if (surah == null) return const SizedBox.shrink();
        return AppCard(
          onTap: () => onOpen(surah, start.ayah),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              QuranNumberBadge(number: index + 1),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.quranJuz(index + 1),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.quranAyahRef(surah.displayName(language), start.ayah),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (language != 'ar') ...[
                const SizedBox(width: AppSpacing.md),
                _ArabicName(surah.arabicName),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Kaldığın yer (son okunan) ve yer imi kartı
class _ResumeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Marka tonlu (son okunan); değilse normal kart
  final bool emphasized;
  final VoidCallback onTap;

  const _ResumeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emphasized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = emphasized ? scheme.onPrimaryContainer : null;
    return AppCard(
      onTap: onTap,
      color: emphasized ? scheme.primaryContainer : null,
      child: Row(
        children: [
          Icon(icon, color: foreground ?? scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: foreground ?? scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, color: foreground ?? scheme.primary),
        ],
      ),
    );
  }
}

/// Sure adının Arapçası (dar alanda küçülerek sığar)
class _ArabicName extends StatelessWidget {
  final String name;

  const _ArabicName(this.name);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          name,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppTheme.arabicFamily,
            fontSize: 24,
            height: 1.4,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Surah surah;
  final String language;
  final VoidCallback onTap;

  const _SurahCard({
    required this.surah,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isArabic = language == 'ar';
    final info =
        '${surah.isMedinan ? loc.quranMedinan : loc.quranMeccan} · '
        '${loc.quranAyahCount(surah.ayahCount)}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          QuranNumberBadge(number: surah.number),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surah.displayName(language),
                  style: isArabic
                      ? TextStyle(
                          fontFamily: AppTheme.arabicFamily,
                          fontSize: 22,
                          height: 1.4,
                          color: scheme.onSurface,
                        )
                      : theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  info,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Arapça arayüzde ad zaten Arapça; diğer dillerde yanında gösterilir
          if (!isArabic) ...[
            const SizedBox(width: AppSpacing.md),
            _ArabicName(surah.arabicName),
          ],
        ],
      ),
    );
  }
}
