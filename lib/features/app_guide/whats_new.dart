import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/quran_audio_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'app_feature.dart';

typedef WhatsNewItem = ({
  IconData icon,
  String title,
  String subtitle,
  AppFeature feature,
});

/// "Yenilikler": bu sürüme güncelleyen kullanıcıya açılış akışından sonra bir
/// kez gösterilen alt sayfa. Yeni sürümde [items] ve [version] birlikte
/// değiştirilir; görülen liste 'whats_new_seen' olarak kaydedilir.
class WhatsNew {
  WhatsNew._();

  static const String seenKey = 'whats_new_seen';

  /// Listenin ait olduğu sürüm
  static const String version = '1.4.0';

  static List<WhatsNewItem> items(AppLocalizations loc) => [
    // Dinleme ara sunucusuyla derlenmediyse yok
    if (QuranAudioService.configured)
      (
        icon: Icons.headphones_outlined,
        title: loc.whatsNewListenTitle,
        subtitle: loc.whatsNewListenDesc,
        feature: AppFeature.quran,
      ),
    (
      icon: Icons.flag_outlined,
      title: loc.hatimTitle,
      subtitle: loc.whatsNewHatimDesc,
      feature: AppFeature.quran,
    ),
    (
      icon: Icons.auto_stories_outlined,
      title: loc.duasTitle,
      subtitle: loc.whatsNewDuasDesc,
      feature: AppFeature.duas,
    ),
    (
      icon: Icons.history_edu_outlined,
      title: loc.storiesTitle,
      subtitle: loc.whatsNewStoriesDesc,
      feature: AppFeature.stories,
    ),
    (
      icon: Icons.touch_app_outlined,
      title: loc.whatsNewDhikrsTitle,
      subtitle: loc.whatsNewDhikrsDesc,
      feature: AppFeature.zikir,
    ),
  ];

  /// Açılış akışının sonunda: bu liste görülmediyse görüldü kaydedilir ve
  /// sadece önceki bir sürümden güncelleyen kullanıcıya ([updated]: tanıtım
  /// turu bu açılıştan önce görülmüştü; tur kaydı yayımlanan her sürümde var)
  /// gösterilir. Yeni kurulum turu görür, listeyi görmez.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required bool updated,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(seenKey) == version) return;
      await prefs.setString(seenKey, version);
    } catch (e) {
      return;
    }
    if (updated && context.mounted) await showWhatsNewSheet(context);
  }
}

/// Yenilikler alt sayfası; satıra dokununca sayfa kapanır, özellik açılır
Future<void> showWhatsNewSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _WhatsNewSheet(
      onOpen: (feature) {
        Navigator.pop(sheetContext);
        openAppFeature(context, feature);
      },
    ),
  );
}

class _WhatsNewSheet extends StatelessWidget {
  final ValueChanged<AppFeature> onOpen;

  const _WhatsNewSheet({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): düğme altında kalmasın
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    loc.whatsNewTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text(
                  loc.versionLabel(WhatsNew.version),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in WhatsNew.items(loc))
            AppListTile(
              leadingIcon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              onTap: () => onOpen(item.feature),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.tipGotIt),
            ),
          ),
        ],
      ),
    );
  }
}
