import 'package:flutter/material.dart';

/// Boşluk ölçüleri (dp). Ekranlarda sabit sayı yerine bunlar kullanılır.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Köşe yarıçapları (dp)
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Erişilebilir minimum dokunma alanı ve sık kullanılan boyutlar
abstract final class AppSizes {
  static const double minTouch = 48;
  static const double listTileMinHeight = 56;
  static const double iconBox = 40;
  static const double buttonHeight = 52;
}

/// Marka ve palet sabitleri. Ekranlarda doğrudan değil, tema
/// (`Theme.of(context).colorScheme`, `PrayerColors.of(context)`) üzerinden kullanılır.
abstract final class AppColors {
  static const Color brand = Color(0xFF00796B);

  // Açık tema
  static const Color lightPrimary = Color(0xFF00796B);
  static const Color lightPrimaryContainer = Color(0xFFB2DFDB);
  static const Color lightOnPrimaryContainer = Color(0xFF00332E);
  static const Color lightTertiary = Color(0xFF8A5A00);
  static const Color lightTertiaryContainer = Color(0xFFFFE8C2);
  static const Color lightOnTertiaryContainer = Color(0xFF2C1A00);
  static const Color lightSurface = Color(0xFFF6F8F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightOutlineVariant = Color(0xFFDCE3E1);
  static const Color lightOnSurface = Color(0xFF1B1F1E);
  static const Color lightOnSurfaceVariant = Color(0xFF49524F);

  // Koyu tema
  static const Color darkPrimary = Color(0xFF4DB6AC);
  static const Color darkOnPrimary = Color(0xFF00201C);
  static const Color darkPrimaryContainer = Color(0xFF00504A);
  static const Color darkOnPrimaryContainer = Color(0xFFA7F3EA);
  static const Color darkTertiary = Color(0xFFF5BD62);
  static const Color darkTertiaryContainer = Color(0xFF5C3D00);
  static const Color darkOnTertiaryContainer = Color(0xFFFFDDB3);
  static const Color darkSurface = Color(0xFF0F1413);
  static const Color darkCard = Color(0xFF161D1C);
  static const Color darkOutlineVariant = Color(0xFF2C3633);
  static const Color darkOnSurface = Color(0xFFE1E6E4);
  static const Color darkOnSurfaceVariant = Color(0xFFBFC9C6);

  // Kerahat / uyarı (amber)
  static const Color lightWarning = Color(0xFF8A5A00);
  static const Color lightWarningContainer = Color(0xFFFFF1D6);
  static const Color lightOnWarningContainer = Color(0xFF3D2600);
  static const Color darkWarning = Color(0xFFF5BD62);
  static const Color darkWarningContainer = Color(0xFF3A2A0E);
  static const Color darkOnWarningContainer = Color(0xFFFFDDB3);

  // Başarılı (kılındı vb.)
  static const Color lightSuccess = Color(0xFF2E7D32);
  static const Color lightSuccessContainer = Color(0xFFDDF3DF);
  static const Color lightOnSuccessContainer = Color(0xFF0B2E10);
  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkSuccessContainer = Color(0xFF1C3A20);
  static const Color darkOnSuccessContainer = Color(0xFFCDEFD0);
}
