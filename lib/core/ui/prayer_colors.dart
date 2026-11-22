import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Vakit ekranlarına özgü renkler (hero, sıradaki/şu anki vakit, kerahat, kılındı).
/// `PrayerColors.of(context)` ile okunur; tema kurulmamışsa parlaklığa göre varsayılan döner.
@immutable
class PrayerColors extends ThemeExtension<PrayerColors> {
  /// Hero (gradyan/fotoğraf) üzerindeki ana ve ikincil yazı
  final Color onHero;
  final Color onHeroMuted;

  /// Hero yazısının arkasındaki karartma: gradyan ve fotoğraf için
  final Color heroScrim;
  final Color heroImageScrim;

  /// Hero üzerindeki küçük bilgi kapsülleri (kerahat, Ramazan)
  final Color heroChip;

  /// Sıradaki vakit (vurgulu)
  final Color nextContainer;
  final Color onNextContainer;

  /// Şu an içinde bulunulan vakit
  final Color current;

  /// Geçmiş vakit (soluk ama okunur)
  final Color past;

  /// Güneş (namaz vakti değil)
  final Color sunrise;

  /// Kerahat / uyarı
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Kılındı / başarılı
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  const PrayerColors({
    required this.onHero,
    required this.onHeroMuted,
    required this.heroScrim,
    required this.heroImageScrim,
    required this.heroChip,
    required this.nextContainer,
    required this.onNextContainer,
    required this.current,
    required this.past,
    required this.sunrise,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  static const PrayerColors light = PrayerColors(
    onHero: Colors.white,
    onHeroMuted: Color(0xE6FFFFFF),
    heroScrim: Color(0x33000000),
    heroImageScrim: Color(0x80000000),
    heroChip: Color(0x47000000),
    nextContainer: AppColors.lightPrimary,
    onNextContainer: Colors.white,
    current: AppColors.lightPrimary,
    past: Color(0xFF66706D),
    sunrise: AppColors.lightTertiary,
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    onWarningContainer: AppColors.lightOnWarningContainer,
    success: AppColors.lightSuccess,
    successContainer: AppColors.lightSuccessContainer,
    onSuccessContainer: AppColors.lightOnSuccessContainer,
  );

  static const PrayerColors dark = PrayerColors(
    onHero: Colors.white,
    onHeroMuted: Color(0xE6FFFFFF),
    heroScrim: Color(0x59000000),
    heroImageScrim: Color(0x8C000000),
    heroChip: Color(0x52000000),
    nextContainer: AppColors.darkPrimaryContainer,
    onNextContainer: Colors.white,
    current: AppColors.darkPrimary,
    past: Color(0xFF8E9996),
    sunrise: AppColors.darkTertiary,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    onWarningContainer: AppColors.darkOnWarningContainer,
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    onSuccessContainer: AppColors.darkOnSuccessContainer,
  );

  static PrayerColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PrayerColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  PrayerColors copyWith({
    Color? onHero,
    Color? onHeroMuted,
    Color? heroScrim,
    Color? heroImageScrim,
    Color? heroChip,
    Color? nextContainer,
    Color? onNextContainer,
    Color? current,
    Color? past,
    Color? sunrise,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
  }) {
    return PrayerColors(
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      heroScrim: heroScrim ?? this.heroScrim,
      heroImageScrim: heroImageScrim ?? this.heroImageScrim,
      heroChip: heroChip ?? this.heroChip,
      nextContainer: nextContainer ?? this.nextContainer,
      onNextContainer: onNextContainer ?? this.onNextContainer,
      current: current ?? this.current,
      past: past ?? this.past,
      sunrise: sunrise ?? this.sunrise,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  PrayerColors lerp(ThemeExtension<PrayerColors>? other, double t) {
    if (other is! PrayerColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PrayerColors(
      onHero: l(onHero, other.onHero),
      onHeroMuted: l(onHeroMuted, other.onHeroMuted),
      heroScrim: l(heroScrim, other.heroScrim),
      heroImageScrim: l(heroImageScrim, other.heroImageScrim),
      heroChip: l(heroChip, other.heroChip),
      nextContainer: l(nextContainer, other.nextContainer),
      onNextContainer: l(onNextContainer, other.onNextContainer),
      current: l(current, other.current),
      past: l(past, other.past),
      sunrise: l(sunrise, other.sunrise),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
    );
  }
}
