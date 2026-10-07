import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/json_service.dart';

/// Esmaül Hüsna: okunur kart listesi (Arapça Amiri ile); karta dokununca
/// ayrıntı penceresi (önceki/sonraki).
class EsmaulHusnaView extends StatefulWidget {
  const EsmaulHusnaView({super.key});

  @override
  State<EsmaulHusnaView> createState() => _EsmaulHusnaViewState();
}

class _EsmaulHusnaViewState extends State<EsmaulHusnaView> {
  final JsonService _jsonService = JsonService();
  Future<List<Map<String, dynamic>>>? _future;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _future = _jsonService.getEsmaulHusna(language);
    }
  }

  void _retry() {
    setState(() => _future = _jsonService.getEsmaulHusna(_language ?? 'tr'));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = _language == 'ar';

    return AppScaffold(
      title: loc.esmaulHusnaTitle,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(message: loc.noDataFound, onRetry: _retry);
          }
          if (!snapshot.hasData) return const LoadingState();
          final data = snapshot.data!;
          if (data.isEmpty) {
            return EmptyState(icon: Icons.menu_book, title: loc.noDataFound);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _EsmaCard(
              index: index,
              item: data[index],
              isArabic: isArabic,
              onTap: () => _showDetailDialog(context, data, index, isArabic),
            ),
          );
        },
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    List<Map<String, dynamic>> allData,
    int initialIndex,
    bool isArabic,
  ) {
    var index = initialIndex;
    showDialog<void>(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final item = allData[index];
            final isFirst = index == 0;
            final isLast = index == allData.length - 1;
            final name = '${item['name'] ?? ''}';
            final arabic = '${item['arabic'] ?? ''}';
            final meaning = '${item['meaning'] ?? ''}';

            return Dialog(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: AppTheme.arabicFamily,
                        fontSize: 44,
                        height: 1.4,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${index + 1}. $name',
                      textAlign: TextAlign.center,
                      style: isArabic
                          ? TextStyle(
                              fontFamily: AppTheme.arabicFamily,
                              fontSize: 24,
                              color: scheme.onSurface,
                            )
                          : theme.textTheme.titleLarge,
                    ),
                    const Divider(height: AppSpacing.xxl),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          meaning,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            height: 1.5,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: loc.previousItem,
                          onPressed: isFirst
                              ? null
                              : () => setState(() => index--),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(loc.close),
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: loc.nextItem,
                          onPressed: isLast
                              ? null
                              : () => setState(() => index++),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EsmaCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool isArabic;
  final VoidCallback onTap;

  const _EsmaCard({
    required this.index,
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = '${item['name'] ?? ''}';
    final arabic = '${item['arabic'] ?? ''}';
    final meaning = '${item['meaning'] ?? ''}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: isArabic
                      ? TextStyle(
                          fontFamily: AppTheme.arabicFamily,
                          fontSize: 22,
                          height: 1.4,
                          color: scheme.primary,
                        )
                      : theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  meaning,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
              constraints: const BoxConstraints(maxWidth: 96),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  arabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.arabicFamily,
                    fontSize: 28,
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
