import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/language_provider.dart';
import '../../home/view_model/home_view_model.dart';
import '../../main_wrapper/main_wrapper.dart';
import '../../settings/view/language_sheet.dart';

/// İlk açılış: dil seçimi. Seçimden sonra ana ekran + tanıtım turu açılır;
/// tur bitince kısa bir açıklama ve ardından bildirim/konum izinleri istenir.
class OnboardingLanguageView extends StatelessWidget {
  const OnboardingLanguageView({super.key});

  void _select(BuildContext context, String code) {
    context.read<LanguageProvider>().setLanguage(Locale(code));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => ShowCaseWidget(
          onFinish: () => requestPermissionsWithPriming(context),
          builder: (context) => const MainWrapper(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language,
                  size: 48,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                loc.onboardingWelcome,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.onboardingSelectLanguage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final language in appLanguages)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () => _select(context, language.code),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          language.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sistem izin pencerelerinden önce neden gerektiklerini anlatan kısa pencere,
/// sonra önce bildirim, ardından konum izni. Konum izni verilirse vakitler
/// gerçek konumla yenilenir.
Future<void> requestPermissionsWithPriming(BuildContext context) async {
  if (context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          icon: const Icon(Icons.notifications_active_outlined, size: 36),
          title: Text(loc.permissionPrimingTitle, textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Text(loc.permissionPrimingBody, textAlign: TextAlign.center),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.continueAction),
            ),
          ],
        );
      },
    );
  }

  // 1. Bildirim izni
  try {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  } catch (e) {
    debugPrint("Bildirim izni hatası: $e");
  }

  // 2. Konum izni; verilirse varsayılan konum yerine gerçek konum alınır
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if ((permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) &&
        context.mounted) {
      context.read<HomeViewModel>().refreshLocationAndTimes(context);
    }
  } catch (e) {
    debugPrint("Konum izni hatası: $e");
  }
}
