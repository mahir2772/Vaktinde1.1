import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'prayer_colors.dart';

/// Uygulamanın tek teması: `AppTheme.light()` / `AppTheme.dark()`.
///
/// Yazı tipi pubspec'te kayıtlı Poppins (400-900, italik yok); en küçük boyut 13sp.
/// Arapça metin (ayet, dua) için `AppTheme.arabicFamily` (Amiri) kullanılır.
/// TabBar teması AppBar.bottom içindir (açık temada beyaz yazı).
abstract final class AppTheme {
  static const String fontFamily = 'Poppins';
  static const String arabicFamily = 'Amiri';

  /// Poppins'te olmayan karakterler (Arapça arayüz metni) için sistem yazı tipi
  static const List<String> fontFallback = ['sans-serif'];

  /// Saat/sayaç gibi rakam hizası önemli metinler için
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// [hasBackgroundImage]: kullanıcı arka plan resmi seçtiyse Scaffold şeffaf
  /// kalır (resim MaterialApp.builder'da çizilir); kartlar yine opaktır.
  static ThemeData light({bool hasBackgroundImage = false}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.lightPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.lightPrimaryContainer,
          onPrimaryContainer: AppColors.lightOnPrimaryContainer,
          secondary: AppColors.lightPrimary,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.lightPrimaryContainer,
          onSecondaryContainer: AppColors.lightOnPrimaryContainer,
          tertiary: AppColors.lightTertiary,
          onTertiary: Colors.white,
          tertiaryContainer: AppColors.lightTertiaryContainer,
          onTertiaryContainer: AppColors.lightOnTertiaryContainer,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightOnSurface,
          onSurfaceVariant: AppColors.lightOnSurfaceVariant,
          surfaceContainerLowest: AppColors.lightCard,
          surfaceContainerLow: const Color(0xFFF0F4F3),
          surfaceContainer: const Color(0xFFEAF0EE),
          surfaceContainerHigh: const Color(0xFFE4EAE8),
          surfaceContainerHighest: const Color(0xFFDEE4E2),
          outline: const Color(0xFF6F7976),
          outlineVariant: AppColors.lightOutlineVariant,
          surfaceTint: Colors.transparent,
        );
    return _build(
      scheme: scheme,
      card: AppColors.lightCard,
      appBarBackground: AppColors.lightPrimary,
      appBarForeground: Colors.white,
      prayerColors: PrayerColors.light,
      hasBackgroundImage: hasBackgroundImage,
    );
  }

  static ThemeData dark({bool hasBackgroundImage = false}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkOnPrimary,
          primaryContainer: AppColors.darkPrimaryContainer,
          onPrimaryContainer: AppColors.darkOnPrimaryContainer,
          secondary: AppColors.darkPrimary,
          onSecondary: AppColors.darkOnPrimary,
          secondaryContainer: AppColors.darkPrimaryContainer,
          onSecondaryContainer: AppColors.darkOnPrimaryContainer,
          tertiary: AppColors.darkTertiary,
          onTertiary: const Color(0xFF452B00),
          tertiaryContainer: AppColors.darkTertiaryContainer,
          onTertiaryContainer: AppColors.darkOnTertiaryContainer,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkOnSurface,
          onSurfaceVariant: AppColors.darkOnSurfaceVariant,
          surfaceContainerLowest: const Color(0xFF0A0F0E),
          surfaceContainerLow: AppColors.darkCard,
          surfaceContainer: const Color(0xFF1A2221),
          surfaceContainerHigh: const Color(0xFF222B2A),
          surfaceContainerHighest: const Color(0xFF2C3534),
          outline: const Color(0xFF89938F),
          outlineVariant: AppColors.darkOutlineVariant,
          surfaceTint: Colors.transparent,
        );
    return _build(
      scheme: scheme,
      card: AppColors.darkCard,
      appBarBackground: AppColors.darkCard,
      appBarForeground: AppColors.darkOnSurface,
      prayerColors: PrayerColors.dark,
      hasBackgroundImage: hasBackgroundImage,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle s(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
    );
    return TextTheme(
      displayLarge: s(52, FontWeight.w700, 1.1),
      displayMedium: s(44, FontWeight.w700, 1.1),
      displaySmall: s(36, FontWeight.w700, 1.15),
      headlineLarge: s(32, FontWeight.w700, 1.2),
      headlineMedium: s(28, FontWeight.w700, 1.25),
      headlineSmall: s(24, FontWeight.w600, 1.3),
      titleLarge: s(20, FontWeight.w600, 1.3),
      titleMedium: s(16, FontWeight.w600, 1.35),
      titleSmall: s(14, FontWeight.w600, 1.35),
      bodyLarge: s(16, FontWeight.w400, 1.45),
      bodyMedium: s(14, FontWeight.w400, 1.45),
      bodySmall: s(13, FontWeight.w400, 1.4),
      labelLarge: s(14, FontWeight.w600, 1.3),
      labelMedium: s(13, FontWeight.w500, 1.3),
      labelSmall: s(13, FontWeight.w500, 1.3),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color card,
    required Color appBarBackground,
    required Color appBarForeground,
    required PrayerColors prayerColors,
    required bool hasBackgroundImage,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    final text = _textTheme(scheme);
    final radiusMd = BorderRadius.circular(AppRadius.md);
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: isLight
          ? BorderSide(color: scheme.outlineVariant)
          : BorderSide.none,
    );
    final inputFill = isLight ? card : scheme.surfaceContainer;
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: text,
      scaffoldBackgroundColor: hasBackgroundImage
          ? Colors.transparent
          : scheme.surface,
      canvasColor: scheme.surface,
      cardColor: card,
      dividerColor: scheme.outlineVariant,
      extensions: [prayerColors],
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge!.copyWith(color: appBarForeground),
        toolbarTextStyle: text.bodyLarge!.copyWith(color: appBarForeground),
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isLight ? Colors.white : scheme.primary,
        unselectedLabelColor: isLight
            ? const Color(0xD9FFFFFF)
            : scheme.onSurfaceVariant,
        indicatorColor: isLight ? Colors.white : scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall!.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        titleTextStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: text.bodyMedium,
        minVerticalPadding: AppSpacing.sm,
        minLeadingWidth: AppSizes.iconBox,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                )
              : text.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: text.labelLarge!.copyWith(fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.minTouch),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        labelStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall!.copyWith(color: scheme.error),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? card : scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? card : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: isLight ? card : scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? card : scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
