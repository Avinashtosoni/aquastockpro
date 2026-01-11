import 'package:flutter/material.dart';

/// AquaStock Pro Brand Colors
/// Supports both Light and Dark themes
class AppColors {
  AppColors._();

  // ================== LIGHT THEME ==================
  
  // Primary Brand Colors
  static const Color primary = Color(0xFF292966);        // Dark Navy
  static const Color primaryLight = Color(0xFF5C5C99);   // Deep Blue-Purple
  static const Color secondary = Color(0xFFA3A3CC);      // Medium Periwinkle
  static const Color accent = Color(0xFFCCCCFF);         // Light Periwinkle

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Light Theme Background Colors
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F5);
  
  // Light Theme Card & Container Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8E8EE);
  static const Color border = cardBorder;
  
  // Light Theme Text Colors
  static const Color textPrimary = Color(0xFF292966);
  static const Color textSecondary = Color(0xFF5C5C99);
  static const Color textTertiary = Color(0xFFA3A3CC);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF292966);

  // ================== DARK THEME ==================
  
  // Dark Theme Background Colors
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2D);
  static const Color darkSurfaceVariant = Color(0xFF2A2A3D);
  
  // Dark Theme Card & Container Colors
  static const Color darkCardBackground = Color(0xFF1E1E2D);
  static const Color darkCardBorder = Color(0xFF3A3A4D);
  
  // Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFE8E8F0);
  static const Color darkTextSecondary = Color(0xFFB0B0C8);
  static const Color darkTextTertiary = Color(0xFF7A7A99);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, secondary],
  );

  // Dark Theme Gradient
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A3A7D), Color(0xFF5C5C99)],
  );

  // Shadow Colors
  static Color shadowColor = primary.withValues(alpha: 0.1);
  static Color shadowColorLight = primary.withValues(alpha: 0.05);
  static Color darkShadowColor = black.withValues(alpha: 0.3);
  
  // Pastel Card Colors (for dashboard stats)
  static const Color pastelCyan = Color(0xFFE0F7FA);
  static const Color pastelCyanDark = Color(0xFF4DD0E1);
  static const Color pastelGreen = Color(0xFFE8F5E9);
  static const Color pastelGreenDark = Color(0xFF66BB6A);
  static const Color pastelPink = Color(0xFFFCE4EC);
  static const Color pastelPinkDark = Color(0xFFEC407A);
  static const Color pastelPurple = Color(0xFFEDE7F6);
  static const Color pastelPurpleDark = Color(0xFF7E57C2);
  static const Color pastelOrange = Color(0xFFFFF3E0);
  static const Color pastelOrangeDark = Color(0xFFFF9800);
  
  // Dark mode pastel colors (muted versions with transparency)
  static const Color darkPastelCyan = Color(0xFF0D3D41);
  static const Color darkPastelGreen = Color(0xFF1B3D1E);
  static const Color darkPastelPink = Color(0xFF3D1B29);
  static const Color darkPastelPurple = Color(0xFF2A1F3D);
  static const Color darkPastelOrange = Color(0xFF3D2B1A);
}

/// Extension to get colors based on theme brightness
extension AppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get backgroundColor => isDarkMode ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor => isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get cardBackgroundColor => isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground;
  Color get cardBorderColor => isDarkMode ? AppColors.darkCardBorder : AppColors.cardBorder;
  Color get textPrimaryColor => isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiaryColor => isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary;
}
