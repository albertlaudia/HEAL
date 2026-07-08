// HEAL — Design tokens & Material 3 theme.
//
// Palette philosophy:
//   - Background: deep rosewood (#1A1110 → #2A1815)
//   - Surface: warm charcoal (#2A1815 → #3A201C)
//   - Primary: brass (#B08C4F, #D4B26A highlight)
//   - Secondary: bronze (#7C4A4A, #A56B6B)
//   - Accent: soft amber (#E8C26E)
//
// Typography: Cormorant Garamond (display) + Inter (body) —
// mirrors /web's choice for a contemplative feel.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// HEAL design tokens.
abstract class HealTokens {
  // ── Palette ─────────────────────────────────────────────────────
  static const Color rosewoodDeep = Color(0xFF1A1110);
  static const Color rosewood = Color(0xFF2A1815);
  static const Color rosewoodLight = Color(0xFF3A201C);
  static const Color charcoal = Color(0xFF1F1614);

  static const Color brass = Color(0xFFB08C4F);
  static const Color brassLight = Color(0xFFD4B26A);
  static const Color brassDeep = Color(0xFF8B6A36);

  static const Color bronze = Color(0xFF7C4A4A);
  static const Color bronzeLight = Color(0xFFA56B6B);

  static const Color amber = Color(0xFFE8C26E);
  static const Color ember = Color(0xFFD9764E);

  static const Color cream = Color(0xFFEDE3D2);
  static const Color creamDim = Color(0xFFC8B8A0);

  // ── Emotion tints (used in Prayer reader + ring glow) ───────────
  static const Map<String, Color> emotionGlow = {
    'joy': Color(0xFFE8C26E),
    'gratitude': Color(0xFFD4B26A),
    'love': Color(0xFFD08E8E),
    'comfort': Color(0xFFB08C4F),
    'hope': Color(0xFFC5A572),
    'peace': Color(0xFF8FA8B0),
    'stillness': Color(0xFF7B8FA1),
    'rest': Color(0xFF6B7D8C),
    'courage': Color(0xFFD9764E),
    'strength': Color(0xFFB8654D),
    'anxiety': Color(0xFF8A6F8E),
    'sorrow': Color(0xFF5B6B7E),
    'grief': Color(0xFF4A5868),
    'fear': Color(0xFF5A4A6B),
    'anger': Color(0xFF8B4A4A),
    'longing': Color(0xFF9B7B7B),
    'forgiveness': Color(0xFFA0B5A8),
    'wonder': Color(0xFFB5A8C5),
    'tender': Color(0xFFD0B5A5),
    'weary': Color(0xFF8B8074),
    'steady': Color(0xFF8B8B6B),
  };

  // ── Spacing scale ──────────────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s80 = 80;
  static const double s96 = 96;
  static const double s120 = 120;
  static const double s160 = 160;

  // ── Radius ─────────────────────────────────────────────────────
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double r32 = 32;
  static const double r40 = 40;

  // ── Durations ──────────────────────────────────────────────────
  static const Duration d100 = Duration(milliseconds: 100);
  static const Duration d200 = Duration(milliseconds: 200);
  static const Duration d300 = Duration(milliseconds: 300);
  static const Duration d400 = Duration(milliseconds: 400);
  static const Duration d500 = Duration(milliseconds: 500);
  static const Duration d800 = Duration(milliseconds: 800);
  static const Duration d1200 = Duration(milliseconds: 1200);
  static const Duration d2000 = Duration(milliseconds: 2000);

  // ── Curves ─────────────────────────────────────────────────────
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeInOutQuart = Cubic(0.76, 0, 0.24, 1);
  static const Curve easeInOutSine = Cubic(0.39, 0.575, 0.565, 1);
}

class HealTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HealTokens.brass,
      brightness: Brightness.dark,
      primary: HealTokens.brass,
      onPrimary: HealTokens.rosewoodDeep,
      primaryContainer: HealTokens.brassDeep,
      onPrimaryContainer: HealTokens.cream,
      secondary: HealTokens.bronzeLight,
      onSecondary: HealTokens.rosewoodDeep,
      secondaryContainer: HealTokens.bronze,
      onSecondaryContainer: HealTokens.cream,
      tertiary: HealTokens.amber,
      onTertiary: HealTokens.rosewoodDeep,
      surface: HealTokens.rosewood,
      onSurface: HealTokens.cream,
      surfaceContainerLowest: HealTokens.rosewoodDeep,
      surfaceContainerLow: HealTokens.rosewood,
      surfaceContainer: HealTokens.rosewoodLight,
      surfaceContainerHigh: const Color(0xFF4A2C26),
      surfaceContainerHighest: const Color(0xFF5A3830),
      onSurfaceVariant: HealTokens.creamDim,
      outline: HealTokens.brassDeep,
      outlineVariant: const Color(0xFF6B4A36),
      error: const Color(0xFFCF6679),
      onError: HealTokens.rosewoodDeep,
    );

    // Typography
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.05,
        color: HealTokens.cream,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 44,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.1,
        color: HealTokens.cream,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: HealTokens.cream,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: HealTokens.cream,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: HealTokens.cream,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: HealTokens.cream,
      ),
      titleLarge: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: HealTokens.cream,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.15,
        color: HealTokens.cream,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
        color: HealTokens.cream,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        letterSpacing: 0.15,
        color: HealTokens.cream,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: HealTokens.cream,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
        color: HealTokens.creamDim,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: HealTokens.cream,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: HealTokens.creamDim,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: HealTokens.creamDim,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HealTokens.rosewoodDeep,
      canvasColor: HealTokens.rosewoodDeep,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: HealTokens.rosewoodDeep,
        foregroundColor: HealTokens.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HealTokens.rosewoodDeep,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: HealTokens.rosewood,
        selectedItemColor: HealTokens.brass,
        unselectedItemColor: HealTokens.creamDim,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HealTokens.rosewood,
        indicatorColor: HealTokens.brass.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? HealTokens.brass
                : HealTokens.creamDim,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? HealTokens.brass
                : HealTokens.creamDim,
            size: 24,
          ),
        ),
        elevation: 0,
        height: 68,
      ),
      cardTheme: CardThemeData(
        color: HealTokens.rosewood,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealTokens.r20),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HealTokens.brass,
          foregroundColor: HealTokens.rosewoodDeep,
          padding: const EdgeInsets.symmetric(
            horizontal: HealTokens.s24,
            vertical: HealTokens.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HealTokens.r16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: HealTokens.rosewoodDeep),
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HealTokens.brass,
          side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(
            horizontal: HealTokens.s24,
            vertical: HealTokens.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HealTokens.r16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: HealTokens.brass),
          minimumSize: const Size(0, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HealTokens.brass,
          textStyle: textTheme.labelLarge?.copyWith(color: HealTokens.brass),
        ),
      ),
      iconTheme: const IconThemeData(color: HealTokens.cream, size: 24),
      dividerTheme: DividerThemeData(
        color: HealTokens.creamDim.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: HealTokens.brass,
        inactiveTrackColor: HealTokens.creamDim.withValues(alpha: 0.24),
        thumbColor: HealTokens.brass,
        overlayColor: HealTokens.brass.withValues(alpha: 0.16),
        trackHeight: 3,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HealTokens.brass,
        linearTrackColor: Color(0xFF6B4A36),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HealTokens.rosewoodLight,
        selectedColor: HealTokens.brass,
        side: BorderSide(color: HealTokens.brass.withValues(alpha: 0.24)),
        labelStyle: textTheme.labelSmall?.copyWith(color: HealTokens.cream),
        secondaryLabelStyle:
            textTheme.labelSmall?.copyWith(color: HealTokens.rosewoodDeep),
        padding: const EdgeInsets.symmetric(
          horizontal: HealTokens.s12,
          vertical: HealTokens.s8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealTokens.r12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HealTokens.rosewoodLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HealTokens.s16,
          vertical: HealTokens.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HealTokens.r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HealTokens.r12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HealTokens.r12),
          borderSide: const BorderSide(color: HealTokens.brass, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: HealTokens.creamDim),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HealTokens.rosewoodLight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: HealTokens.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealTokens.r12),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: HealTokens.brass.withValues(alpha: 0.08),
    );
  }
}