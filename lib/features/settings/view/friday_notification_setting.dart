import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../home/view_model/home_view_model.dart';

/// "Cuma bildirimi" anahtarı: her Cuma 09:00 Kehf Suresi ve Cuma mesajı
/// hatırlatması (varsayılan açık). Ayarlar listesindeki diğer satırlarla aynı
/// görünüm (AppListTile).
class FridayNotificationSetting extends StatelessWidget {
  const FridayNotificationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final enabled = viewModel.fridayNotifEnabled;
        return AppListTile(
          leadingIcon: Icons.forum_outlined,
          title: loc.fridayNotifTitle,
          subtitle: loc.fridayNotifSub,
          showChevron: false,
          trailing: Switch(
            value: enabled,
            onChanged: viewModel.setFridayNotifEnabled,
          ),
          onTap: () => viewModel.setFridayNotifEnabled(!enabled),
        );
      },
    );
  }
}
