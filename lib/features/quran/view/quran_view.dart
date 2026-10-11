import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';
import '../widgets/quran_number_badge.dart';
import 'surah_reader_view.dart';

/// Kur'an-ı Kerim: sure listesi (gömülü, internetsiz) ve kaldığın yer varsa en
/// üstte "Kaldığın yerden devam et" kartı. Sure açılışında reklam yok (geçiş
/// reklamı Araçlar'dan bu ekran açılırken).
class QuranView extends StatefulWidget {
  /// Test için (varsayılan: gömülü liste + alquran.cloud)
  final QuranService? service;

  const QuranView({super.key, this.service});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  late final QuranService _service = widget.service ?? QuranService();
  late Future<List<Surah>> _surahs = _service.loadSurahs();
  QuranBookmark? _bookmark;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final bookmark = await _service.loadBookmark();
    if (mounted) setState(() => _bookmark = bookmark);
  }

  void _retry() {
    setState(() {
      _surahs = _service.loadSurahs();
    });
  }

  Future<void> _open(Surah surah, {int? ayah}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SurahReaderView(surah: surah, initialAyah: ayah, service: _service),
      ),
    );
    await _loadBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;

    return AppScaffold(
      title: loc.quranTitle,
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
          final bookmark = _bookmark;
          // Kayıtlı yer listedeki bir ayetse devam kartı
          final resume = bookmark == null
              ? null
              : surahs
                    .where(
                      (s) =>
                          s.number == bookmark.surah &&
                          bookmark.ayah <= s.ayahCount,
                    )
                    .firstOrNull;
          final offset = resume == null ? 0 : 1;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: surahs.length + offset,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (resume != null && index == 0) {
                return _ContinueCard(
                  title: loc.quranContinue,
                  subtitle: loc.quranAyahRef(
                    resume.displayName(language),
                    bookmark!.ayah,
                  ),
                  onTap: () => _open(resume, ayah: bookmark.ayah),
                );
              }
              final surah = surahs[index - offset];
              return _SurahCard(
                surah: surah,
                language: language,
                onTap: () => _open(surah),
              );
            },
          );
        },
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      color: scheme.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.bookmark, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
        ],
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  surah.arabicName,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.arabicFamily,
                    fontSize: 24,
                    height: 1.4,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
