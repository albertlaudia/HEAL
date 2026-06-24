// HEAL — Material 3 dark theme, warm dawn palette.
// The centerpieces are:
//   - dark base (slate-tinted black)
//   - primary: rosewood (#7c4a4a)
//   - secondary: brass (#b08c4f)
//   - tertiary: bronze (#8c6a3a)
//   - soft cream foreground

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealTheme {
  static const Color _bg = Color(0xFF14110E);
  static const Color _surface = Color(0xFF1C1814);
  static const Color _surfaceHigh = Color(0xFF25201A);
  static const Color _rosewood = Color(0xFF7C4A4A);
  static const Color _brass = Color(0xFFB08C4F);
  static const Color _bronze = Color(0xFF8C6A3A);
  static const Color _cream = Color(0xFFE8DFD0);
  static const Color _muted = Color(0xFF8B8275);

  static ThemeData dark() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: _rosewood,
      onPrimary: _cream,
      primaryContainer: Color(0xFF5C2E2E),
      onPrimaryContainer: _cream,
      secondary: _brass,
      onSecondary: Color(0xFF1A1206),
      secondaryContainer: Color(0xFF4A3A1F),
      onSecondaryContainer: _cream,
      tertiary: _bronze,
      onTertiary: _cream,
      tertiaryContainer: Color(0xFF3A2A14),
      onTertiaryContainer: _cream,
      error: Color(0xFFE0A29A),
      onError: Color(0xFF3B0E0A),
      errorContainer: Color(0xFF6B2A22),
      onErrorContainer: _cream,
      surface: _bg,
      onSurface: _cream,
      surfaceContainerLowest: Color(0xFF0C0A08),
      surfaceContainerLow: _bg,
      surfaceContainer: _surface,
      surfaceContainerHigh: _surfaceHigh,
      surfaceContainerHighest: Color(0xFF2E2820),
      onSurfaceVariant: _muted,
      outline: Color(0xFF3A3328),
      outlineVariant: Color(0xFF251F18),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _cream,
      onInverseSurface: _bg,
      inversePrimary: _rosewood,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
    );

    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: _cream,
      displayColor: _cream,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: _cream,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: _cream,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        selectedItemColor: _brass,
        unselectedItemColor: _muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _rosewood,
          foregroundColor: _cream,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _cream,
          side: const BorderSide(color: _brass, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF251F18),
        space: 1,
        thickness: 0.5,
      ),
    );
  }
}
