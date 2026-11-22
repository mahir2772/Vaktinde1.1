import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../story_data.dart';

/// Kıssalar (Araçlar > Bilgi): kaynak notu ve kategoriler; kategoriye
/// dokununca liste, kıssaya dokununca okuma sayfası
class StoriesView extends StatefulWidget {
  const StoriesView({super.key});

  @override
  State<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends State<StoriesView> {
  Future<StoryLibrary> _future = StoryLibrary.load();

  void _retry() => setState(() => _future = StoryLibrary.load());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      title: loc.storiesTitle,
      body: FutureBuilder<StoryLibrary>(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: InfoBanner(message: loc.storiesNote),
              ),
              AppListSection(
                children: [
                  for (final category in library.categories)
                    AppListTile(
                      leadingIcon:
                          _icons[category.id] ?? Icons.history_edu_outlined,
                      title: category.titleFor(lang),
                      subtitle: loc.storyCount(category.stories.length),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => StoryCategoryView(category: category),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

const Map<String, IconData> _icons = {
  'prophets': Icons.auto_awesome_outlined,
  'siyer': Icons.mosque_outlined,
  'sahabe': Icons.groups_outlined,
  'ulema': Icons.menu_book_outlined,
};

/// Bir kategorinin kıssaları (başlık ve kısa tanım)
class StoryCategoryView extends StatelessWidget {
  final StoryCategory category;

  const StoryCategoryView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      title: category.titleFor(lang),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl,
        ),
        children: [
          AppListSection(
            children: [
              for (final story in category.stories)
                AppListTile(
                  title: story.titleFor(lang),
                  subtitle: story.subtitleFor(lang),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StoryDetailView(story: story),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kıssa sayfası: kısa tanım, metin, ibret ve kaynak
class StoryDetailView extends StatelessWidget {
  final Story story;

  const StoryDetailView({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = story.subtitleFor(lang);
    final lesson = story.lessonFor(lang);
    final source = story.sourceFor(lang);
    return AppScaffold(
      title: story.titleFor(lang),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle,
                    style: theme.textTheme.titleSmall!.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final paragraph in story.paragraphsFor(lang)) ...[
                  Text(
                    paragraph,
                    style: theme.textTheme.bodyLarge!.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (lesson != null) ...[
                  InfoBanner(message: '${loc.storyLesson}: $lesson'),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (source != null)
                  Text(
                    '— $source',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
