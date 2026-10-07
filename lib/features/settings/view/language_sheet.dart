import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/language_provider.dart';
import '../../home/view_model/home_view_model.dart';

/// Uygulamanın dilleri (adlar kendi dillerinde; bayrak emojisi her cihazda
/// çizilmediği için kullanılmaz)
const List<({String code, String name})> appLanguages = [
  (code: 'tr', name: 'Türkçe'),
  (code: 'en', name: 'English'),
  (code: 'de', name: 'Deutsch'),
  (code: 'fr', name: 'Français'),
  (code: 'ar', name: 'العربية'),
];

String languageNativeName(String code) => appLanguages
    .firstWhere((l) => l.code == code, orElse: () => appLanguages.first)
    .name;

/// Dil seçimi (alttan açılan liste). Seçince günün ayeti/hadisi de yeni dilde
/// yüklenir.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  void _select(BuildContext context, String code) {
    final locale = Locale(code);
    context.read<LanguageProvider>().setLanguage(locale);
    try {
      final viewModel = context.read<HomeViewModel>();
      viewModel.getDailyHadith(locale);
      viewModel.getDailyAyah(locale);
    } catch (_) {
      // Ana ekran modeli yoksa (ör. testte) sadece dil değişir
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final current = context.watch<LanguageProvider>().locale.languageCode;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(loc.changeLanguage, style: theme.textTheme.titleLarge),
          ),
          for (final language in appLanguages)
            Semantics(
              selected: language.code == current,
              inMutuallyExclusiveGroup: true,
              child: AppListTile(
                title: language.name,
                showChevron: false,
                trailing: language.code == current
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => _select(context, language.code),
              ),
            ),
        ],
      ),
    );
  }
}
