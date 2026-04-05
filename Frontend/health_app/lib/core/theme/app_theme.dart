import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Colors ──
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgCard = Color(0xFF152238);

  // ── Accents & Semantic Colors ──
  static const Color accent = Color(0xFF4DD0E1);
  static const Color purple = Color(0xFF7E57C2);
  static const Color green = Color(0xFF66BB6A);
  static const Color orange = Color(0xFFFFB74D);
  static const Color red = Color(0xFFEF5350);
  static const Color indigo = Color(0xFF5C6BC0);
  static const Color gold = Color(0xFFFFD54F);

  // ── Gradients ──
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1527), bgDark, Color(0xFF132E4A)],
  );

  // ── ThemeData ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: purple,
        tertiary: indigo,
        surface: bgCard,
        onPrimary: bgDark,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgDark,
        indicatorColor: accent.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent);
          }
          return const IconThemeData(color: Colors.white38);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.white38, fontSize: 12);
        }),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white54),
        prefixIconColor: Colors.white38,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }
}
