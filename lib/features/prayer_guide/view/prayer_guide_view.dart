import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../duas/dua_data.dart';
import '../../duas/view/duas_view.dart';
import '../../quran/view/surah_reader_view.dart';
import '../../zikirmatik/view/dhikr_names.dart';
import '../prayer_guide_data.dart';

/// Namaz Hocası (Araçlar > Namaz, reklamsız): Abdest | Farzlar | Rekâtlar |
/// Kılınış sekmeleri. Kılınışta 2 / 3 / 4 rekâtlı ve vitir seçilir; adımlar
/// numaralı kartlar, kısa zikirler Arapça + okunuş + anlam, dualar Dualar'ın
/// dua sayfasına, Fâtiha Kur'an okuyucusuna bağlanır. Her sekmenin sonunda
/// kaynak notu.
class PrayerGuideView extends StatefulWidget {
  /// Fâtiha bağlantısı için (test; varsayılan: alquran.cloud + cihazdaki kopya)
  final QuranService? quranService;

  const PrayerGuideView({super.key, this.quranService});

  @override
  State<PrayerGuideView> createState() => _PrayerGuideViewState();
}

class _PrayerGuideViewState extends State<PrayerGuideView> {
  Future<(PrayerGuide, DuaLibrary)> _future = _load();
  int _method = 0;

  static Future<(PrayerGuide, DuaLibrary)> _load() =>
      (PrayerGuide.load(), DuaLibrary.load()).wait;

  void _retry() => setState(() => _future = _load());

  void _openDua(Dua dua) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => DuaDetailView(dua: dua)),
  );

  Future<void> _openSurah(int number) async {
    final loc = AppLocalizations.of(context)!;
    final service = widget.quranService ?? QuranService();
    List<Surah>? surahs;
    try {
      surahs = await service.loadSurahs();
    } catch (_) {}
    if (!mounted) return;
    final surah = surahs?.where((s) => s.number == number).firstOrNull;
    if (surah == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(loc.noDataFound)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SurahReaderView(
          surah: surah,
          service: service,
          surahs: surahs,
          trackLastRead: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: loc.prayerGuideTitle,
        bottom: TabBar(
          // %130 yazıda / dar ekranda etiketler kesilmesin
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            Tab(text: loc.prayerGuideTabWudu),
            Tab(text: loc.prayerGuideTabFards),
            Tab(text: loc.prayerGuideTabRakats),
            Tab(text: loc.prayerGuideTabSteps),
          ],
        ),
        body: FutureBuilder<(PrayerGuide, DuaLibrary)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(message: loc.noDataFound, onRetry: _retry);
            }
            final data = snapshot.data;
            if (data == null) return const LoadingState();
            final (guide, duas) = data;
            final method = guide.methods[_method];
            final example = method.exampleFor(lang);

            Widget step(int index, GuideStep step) => _StepContent(
              number: index + 1,
              step: step,
              lang: lang,
              duas: duas,
              onDua: _openDua,
              onSurah: _openSurah,
            );

            Widget page(String key, List<Widget> children) => ListView(
              key: PageStorageKey(key),
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                ...children,
                if (guide.noteFor(lang) case final note?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      0,
                    ),
                    child: InfoBanner(
                      message: note,
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
              ],
            );

            // Madde listesi: başlık + tek kartta numaralı satırlar
            List<Widget> sections(List<GuideSection> list) => [
              for (final section in list) ...[
                SectionHeader(section.titleFor(lang)),
                AppCard(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, item) in section.items.indexed) ...[
                        if (i > 0) const Divider(height: AppSpacing.xl),
                        step(i, item),
                      ],
                    ],
                  ),
                ),
              ],
            ];

            return TabBarView(
              children: [
                page('wudu', sections(guide.wudu)),
                page('fards', sections(guide.fards)),
                page('rakats', [_RakatTable(guide: guide, lang: lang)]),
                page('steps', [
                  AppCard(
                    margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final (i, m) in guide.methods.indexed)
                              ChoiceChip(
                                label: Text(m.titleFor(lang)),
                                selected: i == _method,
                                onSelected: (_) => setState(() => _method = i),
                              ),
                          ],
                        ),
                        if (example != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            example,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final (i, item) in method.steps.indexed)
                    AppCard(
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: step(i, item),
                    ),
                  for (final note in method.notes)
                    if (pickText(note, lang) case final text?)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          0,
                        ),
                        child: InfoBanner(message: text),
                      ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Numaralı adım: numara + başlık + açıklama (TalkBack'te tek düğüm, başlıklı
/// adım "başlık" olarak), altında okunanlar
class _StepContent extends StatelessWidget {
  final int number;
  final GuideStep step;
  final String lang;
  final DuaLibrary duas;
  final ValueChanged<Dua> onDua;
  final ValueChanged<int> onSurah;

  const _StepContent({
    required this.number,
    required this.step,
    required this.lang,
    required this.duas,
    required this.onDua,
    required this.onSurah,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = step.titleFor(lang);
    final text = step.textFor(lang);
    // Numara yuvarlağı yazıyla büyür (iki basamak da sığar)
    final badge = MediaQuery.textScalerOf(context).scale(28);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Semantics(
            header: title != null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    minWidth: badge,
                    minHeight: badge,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title, style: theme.textTheme.titleMedium),
                      if (text != null)
                        Padding(
                          padding: EdgeInsets.only(
                            top: title == null ? 2 : AppSpacing.xs,
                          ),
                          child: Text(
                            text,
                            style:
                                (title == null
                                        ? theme.textTheme.bodyLarge!
                                        : theme.textTheme.bodyMedium!)
                                    .copyWith(height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final r in step.recite)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _Recitation(
              item: r,
              lang: lang,
              duas: duas,
              onDua: onDua,
              onSurah: onSurah,
            ),
          ),
      ],
    );
  }
}

class _Recitation extends StatelessWidget {
  final GuideRecitation item;
  final String lang;
  final DuaLibrary duas;
  final ValueChanged<Dua> onDua;
  final ValueChanged<int> onSurah;

  const _Recitation({
    required this.item,
    required this.lang,
    required this.duas,
    required this.onDua,
    required this.onSurah,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dhikr = item.dhikr;
    final surah = item.surah;
    final duaId = item.dua;
    if (duaId != null) {
      final dua = duas.byId(duaId);
      if (dua == null) return const SizedBox.shrink();
      return _LinkRow(
        icon: Icons.auto_stories_outlined,
        title: dua.titleFor(lang),
        subtitle: item.textFor(lang),
        onTap: () => onDua(dua),
      );
    }
    if (surah != null) {
      return _LinkRow(
        icon: Icons.menu_book_outlined,
        title: item.titleFor(lang) ?? '',
        onTap: () => onSurah(surah),
      );
    }

    final translit = dhikr?.translitFor(lang);
    final meaning = dhikr?.meaningFor(lang);
    final title = item.titleFor(lang);
    final text = item.textFor(lang);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: dhikr == null
          // Açıklama (zamm-ı sûre)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title, style: theme.textTheme.titleSmall),
                if (text != null)
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium!.copyWith(height: 1.5),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.times > 1)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      loc.prayerGuideTimes(item.times),
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                Text(
                  dhikr.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: arabicDhikrStyle(context, fontSize: 24),
                ),
                if (translit != null)
                  Text(
                    translit,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (meaning != null)
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Dua / sûre bağlantısı (RTL'de dönen ok)
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: scheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vakitlere göre rekâtlar: her vakit bir satır, kısımlar sırayla (rekât
/// sayısı + tür; farz vurgulu)
class _RakatTable extends StatelessWidget {
  final PrayerGuide guide;
  final String lang;

  const _RakatTable({required this.guide, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(pickText(guide.rakatsTitle, lang) ?? ''),
        AppCard(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in guide.rakats.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          row.titleFor(lang),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final part in row.parts)
                            _RakatChip(
                              count: part.count,
                              label: guide.rakatKindFor(part.kind, lang) ?? '',
                              background: part.kind == 'fard'
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHigh,
                              foreground: part.kind == 'fard'
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RakatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color background;
  final Color foreground;

  const _RakatChip({
    required this.count,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleMedium!.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
