import 'package:flutter/material.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// "Reklamlar hakkında": uygulama neden reklam gösteriyor, hangi ekranlar
/// açılırken tam ekran reklam yok. Kendisi reklam göstermez ve hiçbir reklamla
/// aynı dokunuşa bağlanmaz (AdHelper.showInfoInstead / showAdInfo). AdMob
/// politikası: metinde reklama tıklama, izleme ya da destek çağrısı, vaat yok;
/// banner her sekmede olduğundan "reklam yok" değil "tam ekran reklam yok"
/// denir (test/ad_info_test.dart).
Future<void> showAdInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _AdInfoSheet(),
  );
}

class _AdInfoSheet extends StatelessWidget {
  const _AdInfoSheet();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): düğme altında kalmasın
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(loc.adInfoTitle, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(loc.adInfoBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.adInfoGotIt),
          ),
        ],
      ),
    );
  }
}
