import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FanColors {
  static const background = Color(0xFF0E0B18);
  static const surface = Color(0xFF191426);
  static const surface2 = Color(0xFF251C35);
  static const purple = Color(0xFF9B5CF7);
  static const orchid = Color(0xFFD78BFA);
  static const pink = Color(0xFFFFA1DE);
  static const ink = Color(0xFFF8F2FF);
  static const muted = Color(0xFFB7ABC7);
  static const line = Color(0xFF342941);
  static const success = Color(0xFF80D5AE);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9D63FF), Color(0xFFE69BF9)],
  );
}

ThemeData fanTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FanColors.background,
    colorScheme: const ColorScheme.dark(
      primary: FanColors.purple,
      secondary: FanColors.pink,
      surface: FanColors.surface,
      onSurface: FanColors.ink,
      onPrimary: Color(0xFF160D25),
    ),
    textTheme: GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: FanColors.ink, displayColor: FanColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FanColors.background, surfaceTintColor: Colors.transparent,
      elevation: 0, centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: FanColors.muted, fontSize: 13),
      filled: true, fillColor: FanColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: FanColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: FanColors.purple, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    ),
    cardTheme: CardThemeData(color: FanColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FanColors.surface2,
      contentTextStyle: GoogleFonts.sora(color: FanColors.ink, fontSize: 12),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
