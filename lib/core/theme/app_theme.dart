import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF0B5FFF);
  static const safe = Color(0xFF28A745);
  static const low = Color(0xFFFFC107);
  static const medium = Color(0xFFFD7E14);
  static const danger = Color(0xFFDC3545);
  static const darkSurface = Color(0xFF151A1F);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      chipTheme: const ChipThemeData(
        side: BorderSide(color: Color(0xFFE3E7EC)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
