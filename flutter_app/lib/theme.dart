import 'package:flutter/material.dart';

class NightColors {
  static const background = Color(0xFF000000);
  static const card = Color(0xFF0A0A0A);
  static const accent = Color(0xFFFF2E9A);
  static const orange = Color(0xFFFF8A3C);
  static const mint = Color(0xFF7AF0C2);
  static const muted = Color(0xFF9A9A9A);
  static const yellow = Color(0xFFFFDC7A);
}

List<Shadow> neonShadows(Color color) => [
  Shadow(color: color.withValues(alpha: 0.95), blurRadius: 8),
  Shadow(color: color.withValues(alpha: 0.45), blurRadius: 22),
];

InputDecoration nightInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.72),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: NightColors.accent.withValues(alpha: 0.28)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: NightColors.accent, width: 1.4),
    ),
  );
}

ThemeData buildNightTheme() {
  final baseText = Typography.whiteCupertino.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: NightColors.accent,
      secondary: NightColors.orange,
      surface: NightColors.background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: NightColors.background,
    canvasColor: NightColors.background,
    textTheme: baseText,
    appBarTheme: AppBarTheme(
      backgroundColor: NightColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: NightColors.accent.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: selected ? NightColors.accent : NightColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? NightColors.accent : NightColors.muted,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NightColors.accent,
        foregroundColor: Colors.white,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: NightColors.accent.withValues(alpha: 0.28),
      side: BorderSide(color: NightColors.accent.withValues(alpha: 0.35)),
    ),
  );
}
