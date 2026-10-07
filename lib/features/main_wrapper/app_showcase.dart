import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/ui/app_tokens.dart';

// İlk açılış tanıtım turu (5 adım) hedefleri
final GlobalKey homeLangKey = GlobalKey();
final GlobalKey homeStoryKey = GlobalKey();
final GlobalKey homeAlarmsKey = GlobalKey();
final GlobalKey qiblaKey = GlobalKey();
final GlobalKey zikirmatikKey = GlobalKey();

/// Tanıtım turu baloncuğu (marka renginde, okunur yazı)
class AppShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String description;
  final Widget child;
  final bool autoScroll;

  const AppShowcase({
    super.key,
    required this.showcaseKey,
    required this.description,
    required this.child,
    this.autoScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Showcase(
      key: showcaseKey,
      description: description,
      descTextStyle: theme.textTheme.bodyLarge!.copyWith(color: Colors.white),
      overlayColor: Colors.black,
      overlayOpacity: 0.75,
      tooltipBackgroundColor: AppColors.lightOnPrimaryContainer,
      textColor: Colors.white,
      tooltipBorderRadius: BorderRadius.circular(AppRadius.md),
      targetBorderRadius: BorderRadius.circular(AppRadius.md),
      enableAutoScroll: autoScroll,
      child: child,
    );
  }
}
