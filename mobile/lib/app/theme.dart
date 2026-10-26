import 'package:flutter/material.dart';

abstract final class GuardianColors {
  static const seed = Color(0xFF0D7377);
  static const safetyGreen = Color(0xFF2E7D32);
  static const alertRed = Color(0xFFC62828);
  static const warmAmber = Color(0xFFF9A825);
  static const deepNight = Color(0xFF1A1A2E);
}

ThemeData buildGuardianTheme({required Brightness brightness}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GuardianColors.seed,
    brightness: brightness,
    primary: GuardianColors.seed,
    secondary: GuardianColors.safetyGreen,
    error: GuardianColors.alertRed,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? GuardianColors.deepNight
        : colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
