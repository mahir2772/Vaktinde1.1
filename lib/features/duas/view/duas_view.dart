import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../common/share_card.dart';
import '../../zikirmatik/view/dhikr_names.dart';
import '../dua_data.dart';
import 'tesbihat_view.dart';

/// Dualar: en üstte namaz sonrası tesbihat, altında kategoriler (namaz,
/// sabah-akşam, günlük, Ramazan); satıra dokununca dua sayfası.
class DuasView extends StatefulWidget {
  const DuasView({super.key});

  @override
  State<DuasView> createState() => _DuasViewState();
}

class _DuasViewState extends State<DuasView> {
  Future<DuaLibrary> _future = DuaLibrary.load();

  void _retry() => setState(() => _future = DuaLibrary.load());

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      title: loc.duasTitle,
      body: FutureBuilder<DuaLibrary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(message: loc.noDataFound, onRetry: _retry);
          }
          final library = snapshot.data;
          if (library == null) return const LoadingState();
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            children: [
              AppListSection(
                children: [
                  AppListTile(
                    leadingIcon: Icons.touch_app_outlined,
                    title: loc.tesbihatTitle,
                    subtitle: loc.tesbihatDesc,
                    onTap: () => _open(TesbihatView(steps: library.tesbihat)),
                  ),
                ],
              ),
              for (final category in library.categories) ...[
                SectionHeader(category.titleFor(lang)),
                AppListSection(
                  children: [
                    for (final dua in category.duas)
                      AppListTile(
                        title: dua.titleFor(lang),
                        subtitle: _subtitle(dua, lang),
                        onTap: () => _open(DuaDetailView(dua: dua)),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Satır alt yazısı: okunuşun başı; Arapçada kısa açıklama
String? _subtitle(Dua dua, String lang) {
  if (lang == 'ar') return dua.noteFor(lang);
  final text = dua.translitFor(lang) ?? dua.meaningFor(lang);
  if (text == null) return null;
  final line = text.split('\n').first;
  const max = 44;
  if (line.length <= max) return line;
  var cut = line.lastIndexOf(' ', max);
  if (cut < max ~/ 2) cut = max;
  return '${line.substring(0, cut).replaceFirst(RegExp(r'[\s,.;:]+$'), '')}…';
}

/// Dua sayfası: Arapça (Amiri, sağdan sola), okunuş, anlam, kaynak ve not;
/// kopyala, metni paylaş, resimli paylaş (kampanya: dua).
class DuaDetailView extends StatelessWidget {
  final Dua dua;

  const DuaDetailView({super.key, required this.dua});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = dua.titleFor(lang);
    final hasArabic = dua.arabic.isNotEmpty;
    final translit = dua.translitFor(lang);
    final meaning = dua.meaningFor(lang);
    final note = dua.noteFor(lang);
    final source = dua.sourceFor(lang);
    final bodyStyle = theme.textTheme.bodyLarge!.copyWith(
      height: 1.6,
      color: scheme.onSurface,
    );

    Widget section(String label, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: theme.textTheme.titleSmall!.copyWith(color: scheme.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: bodyStyle),
      ],
    );

    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasArabic)
                  Text(
                    dua.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: arabicDhikrStyle(
                      context,
                      fontSize: 28,
                    ).copyWith(height: 1.9),
                  )
                else if (meaning != null)
                  // Arapçası olmayan (niyet): metnin kendisi
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium!.copyWith(height: 1.6),
                  ),
                if (hasArabic && (translit != null || meaning != null))
                  const Divider(height: AppSpacing.xxl),
                if (hasArabic && translit != null)
                  section(loc.duaTransliteration, translit),
                if (hasArabic && translit != null && meaning != null)
                  const SizedBox(height: AppSpacing.lg),
                if (hasArabic && meaning != null)
                  section(loc.duaMeaning, meaning),
                if (source != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '— $source',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (note != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  InfoBanner(message: note),
                ],
                const SizedBox(height: AppSpacing.lg),
                _DuaActions(dua: dua, title: title, lang: lang),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaActions extends StatelessWidget {
  final Dua dua;
  final String title;
  final String lang;

  const _DuaActions({
    required this.dua,
    required this.title,
    required this.lang,
  });

  Future<void> _copy(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    var text = loc.textCopied;
    try {
      await Clipboard.setData(ClipboardData(text: dua.plainText(lang)));
    } catch (_) {
      text = loc.shareFailed;
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _shareImage(BuildContext context) {
    final arabic = dua.arabic.isEmpty ? null : dua.arabic;
    return shareAsImage(
      context,
      title: title,
      // Arapça arayüzde (anlam yok) kartın metni Arapçanın kendisi
      message: dua.meaningFor(lang) ?? arabic ?? dua.noteFor(lang) ?? title,
      arabic: arabic,
      source: dua.sourceFor(lang),
      campaign: 'dua',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: 20),
          label: Text(loc.copy),
        ),
        OutlinedButton.icon(
          onPressed: () => shareAsText(
            context,
            text: dua.plainText(lang),
            title: title,
            campaign: 'dua',
          ),
          icon: const Icon(Icons.share_rounded, size: 20),
          label: Text(loc.shareAsText),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _shareImage(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, AppSizes.minTouch),
          ),
          icon: const Icon(Icons.image_outlined, size: 20),
          label: Text(loc.shareAsImage),
        ),
      ],
    );
  }
}
