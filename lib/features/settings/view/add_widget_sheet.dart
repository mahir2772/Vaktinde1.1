import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// Ana ekran widget'ları (AndroidManifest'teki sağlayıcılar). Adlar widget
/// seçicidekiyle aynı (res/values*/strings.xml); açıklamada boyut ipucu var.
enum HomeScreenWidget {
  large(
    'com.mmdigital.vaktinde.VaktindeWidgetLargeProvider',
    Icons.view_list_outlined,
  ),
  wide('com.mmdigital.vaktinde.VaktindeWidgetSmall2Provider', Icons.schedule),
  small(
    'com.mmdigital.vaktinde.VaktindeWidgetSmallProvider',
    Icons.timer_outlined,
  );

  const HomeScreenWidget(this.qualifiedAndroidName, this.icon);

  /// home_widget sınıfı bu adla bulur (manifest'teki sınıf adı R8'de korunur)
  final String qualifiedAndroidName;
  final IconData icon;

  String title(AppLocalizations loc) => switch (this) {
    HomeScreenWidget.large => loc.widgetLargeName,
    HomeScreenWidget.wide => loc.widgetWideName,
    HomeScreenWidget.small => loc.widgetSmallName,
  };

  String description(AppLocalizations loc) => switch (this) {
    HomeScreenWidget.large => loc.widgetLargeDesc,
    HomeScreenWidget.wide => loc.widgetWideDesc,
    HomeScreenWidget.small => loc.widgetSmallDesc,
  };
}

/// Başlatıcı uygulamadan widget eklemeyi destekliyor mu (Android 8+ ve
/// başlatıcıya bağlı); eklenti yoksa ya da hata olursa false
Future<bool> canPinHomeWidget() async {
  try {
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  } catch (e) {
    return false;
  }
}

/// Başlatıcının "Ana ekrana ekle" onay penceresini açar; hata yutulur
Future<void> requestPinHomeWidget(HomeScreenWidget widget) async {
  try {
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: widget.qualifiedAndroidName,
    );
  } catch (e) {
    debugPrint('Widget eklenemedi: $e');
  }
}

/// [builder]'a widget eklemenin desteklenip desteklenmediğini verir (bir kez
/// sorulur; cevap gelene kadar false: satır sonradan belirir)
class HomeWidgetPinSupport extends StatefulWidget {
  const HomeWidgetPinSupport({super.key, required this.builder});

  final Widget Function(BuildContext context, bool supported) builder;

  @override
  State<HomeWidgetPinSupport> createState() => _HomeWidgetPinSupportState();
}

class _HomeWidgetPinSupportState extends State<HomeWidgetPinSupport> {
  late final Future<bool> _supported = canPinHomeWidget();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _supported,
    initialData: false,
    builder: (context, snapshot) =>
        widget.builder(context, snapshot.data ?? false),
  );
}

/// Widget seçimi; dokununca sayfa kapanır, onay penceresi başlatıcınındır
Future<void> showAddWidgetSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _AddWidgetSheet(),
  );
}

class _AddWidgetSheet extends StatelessWidget {
  const _AddWidgetSheet();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): son satır altında kalmasın
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(loc.addWidgetTitle, style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              loc.addWidgetHint,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in HomeScreenWidget.values)
            AppListTile(
              leadingIcon: item.icon,
              title: item.title(loc),
              subtitle: item.description(loc),
              showChevron: false,
              trailing: Icon(Icons.add, color: scheme.primary),
              onTap: () {
                Navigator.pop(context);
                requestPinHomeWidget(item);
              },
            ),
        ],
      ),
    );
  }
}
