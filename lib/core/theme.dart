import 'package:flutter/material.dart';

class FanColors {
  static const background = Color(0xFF101017);
  static const surface = Color(0xFF191922);
  static const surface2 = Color(0xFF23232F);
  static const purple = Color(0xFF9B78FF);
  static const orchid = Color(0xFFBBA2FF);
  static const pink = Color(0xFFF2A7CF);
  static const ink = Color(0xFFF4F2FA);
  static const muted = Color(0xFFA9A6BA);
  static const line = Color(0xFF30303D);
  static const success = Color(0xFF80D5AE);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB99AFF), Color(0xFF9271EE)],
  );
}

ThemeData fanTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FanColors.purple,
    brightness: Brightness.dark,
    surface: FanColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FanColors.background,
    fontFamily: 'Sora',
    fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
    textTheme: ThemeData.dark().textTheme
        .apply(
          fontFamily: 'Sora',
          fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
          bodyColor: FanColors.ink,
          displayColor: FanColors.ink,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'Sora',
            fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.15,
            color: FanColors.ink,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Sora',
            fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
            color: FanColors.ink,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Sora',
            fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FanColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Sora',
            fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
            fontSize: 16,
            height: 1.6,
            color: FanColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Sora',
            fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
            fontSize: 14,
            height: 1.5,
            color: FanColors.ink,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FanColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Sora',
        fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: FanColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FanColors.surface,
      hintStyle: const TextStyle(
        fontFamily: 'Sora',
        fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
        color: FanColors.muted,
        fontSize: 14,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FanColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FanColors.purple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
    cardTheme: CardThemeData(
      color: FanColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: FanColors.line),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FanColors.ink,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: FanColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: FanColors.surface2,
      contentTextStyle: TextStyle(
        fontFamily: 'Sora',
        fontFamilyFallback: ['NotoSymbols', 'NotoEmoji'],
        color: FanColors.ink,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: FanColors.line),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: FanColors.surface,
      indicatorColor: FanColors.purple.withValues(alpha: .18),
      height: 76,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Sora',
          fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? FanColors.orchid
              : FanColors.muted,
        ),
      ),
    ),
  );
}
