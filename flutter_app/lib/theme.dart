import 'package:flutter/material.dart';

class NightColors {
  static const background = Color(0xFF000000);
  static const card = Color(0xFF050505);
  static const accent = Color(0xFFFF2E9A);
  static const orange = Color(0xFFFF8A3C);
  static const mint = Color(0xFF7AF0C2);
  static const muted = Color(0xFF9A9A9A);
  static const yellow = Color(0xFFFFDC7A);
}

List<Shadow> neonShadows(Color color) => [
  Shadow(color: color, blurRadius: 4),
  Shadow(color: color.withValues(alpha: 0.95), blurRadius: 14),
  Shadow(color: color.withValues(alpha: 0.55), blurRadius: 28),
];

List<BoxShadow> neonGlow([Color color = NightColors.accent]) => [
  BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 16),
  BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 32),
];

InputDecoration nightInputDecoration(String label, {bool glowing = true}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: NightColors.accent.withValues(alpha: glowing ? 0.85 : 0.35),
      width: 1.4,
    ),
  );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.black,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: NightColors.accent, width: 1.8),
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
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: Colors.white.withValues(alpha: 0.08),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NightColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: NightColors.accent, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: NightColors.accent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return NightColors.accent;
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: NightColors.accent, width: 1.4),
    ),
    chipTheme: ChipThemeData(
      selectedColor: NightColors.orange,
      side: BorderSide(color: NightColors.accent.withValues(alpha: 0.7)),
      labelStyle: const TextStyle(color: Colors.white),
    ),
  );
}
