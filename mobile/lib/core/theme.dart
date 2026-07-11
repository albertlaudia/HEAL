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
  // Cream-family variants used in Sleep + ambient pages
  static const Color creamSleep  = Color(0xFFD9C5A8);  // sleepier, dimmer cream
  static const Color creamWarm   = Color(0xFFE8DCC8);  // warmer cream
  static const Color creamDusk   = Color(0xFFB8A88F);  // dusk cream
  // Pre-baked alpha tokens for the sleep palette
  static const Color creamSleep08 = Color(0x14D9C5A8);  // 8%
  static const Color creamSleep20 = Color(0x33D9C5A8);  // 20%
  static const Color creamSleep40 = Color(0x66D9C5A8);  // 40%
  static const Color creamSleep50 = Color(0x80D9C5A8);  // 50%
  static const Color creamDim = Color(0xFFC8B8A0);

  /// Deep oxblood red — used for high-contrast accents and completion overlays.
  static const Color oxblood = Color(0xFF8B2C2C);

  // ── Emotion state tokens (drive Lumen + palette + edge glow) ──
  // Lumen's body color when in each emotion state.
  static const Color lumenResting     = Color(0xFFB08C4F);  // = brass
  static const Color lumenBreathing   = Color(0xFFB5A8C5);  // = wonder
  static const Color lumenAttentive   = Color(0xFFC5A572);  // = hope
  static const Color lumenListening   = Color(0xFFD4B26A);  // = gratitude
  static const Color lumenOffering    = Color(0xFFD08E8E);  // = love
  static const Color lumenWeary       = Color(0xFF8B8074);  // = weary
  static const Color lumenCelebrating = Color(0xFFE8C26E);  // = amber
  static const Color lumenEncouraging = Color(0xFFD9764E);  // = ember

  // ── Mood backdrop tints (per emotion) ──────────────────────────
  // Slightly darker than Lumen's body so the character reads against bg.
  static const Color backdropResting     = Color(0xFF1A1110);  // = rosewoodDeep
  static const Color backdropPracticing  = Color(0xFF1F1310);  // active practice
  static const Color backdropPracticingDeep = Color(0xFF150A09);
  static const Color backdropPracticingGlow = Color(0xFF4A2C26);
  static const Color backdropEvening     = Color(0xFF160D17);  // evening, indigo
  static const Color backdropEveningDeep = Color(0xFF0A0610);
  static const Color backdropEveningSurface = Color(0xFF221830);
  static const Color backdropEveningGlow = Color(0xFF2E1F40);
  static const Color backdropEveningPrimary = Color(0xFF8FA8B0);  // = peace
  static const Color backdropEveningPrimarySoft = Color(0xFFA5BCC4);
  static const Color backdropEveningOnPrimary = Color(0xFF0A0610);
  static const Color backdropEveningSuccess = Color(0xFFB5C5B5);
  static const Color backdropEveningWarning = Color(0xFFB08C7A);
  static const Color backdropCelebrating = Color(0xFF1A1308);
  static const Color backdropCelebratingDeep = Color(0xFF0F0B05);
  static const Color backdropCelebratingSurface = Color(0xFF3A2810);
  static const Color backdropCelebratingGlow = Color(0xFF5A3C1A);

  // ── Time-of-day palette tokens (used by TimePalette) ───────────
  // Pre-dawn: deep blue-black, cool silver-blue brass
  static const Color predawnBg     = Color(0xFF0F1419);
  static const Color predawnSurface = Color(0xFF1A1F25);
  static const Color predawnPrimary = Color(0xFF8FA8B0);
  static const Color predawnSecondary = Color(0xFF5A6F7E);
  static const Color predawnAccent = Color(0xFFB08C4F);
  static const Color predawnGlow   = Color(0xFF4A6B7A);

  // Dawn: warming rosewood, bright brass dawn
  static const Color dawnBg        = Color(0xFF2A1F1C);
  static const Color dawnSurface   = Color(0xFF3A2A24);
  static const Color dawnPrimary   = Color(0xFFD4B26A);
  static const Color dawnSecondary = Color(0xFFA56B6B);
  static const Color dawnAccent    = Color(0xFFE8C26E);
  static const Color dawnGlow      = Color(0xFFD9764E);

  // Noon: standard rosewood, true brass
  static const Color noonBg        = Color(0xFF2A1815);
  static const Color noonSurface   = Color(0xFF3A201C);
  static const Color noonPrimary   = Color(0xFFB08C4F);
  static const Color noonSecondary = Color(0xFF7C4A4A);
  static const Color noonAccent    = Color(0xFFE8C26E);
  static const Color noonGlow      = Color(0xFFE8C26E);

  // Dusk: darker rosewood, ember-copper
  static const Color duskBg        = Color(0xFF1F1410);
  static const Color duskSurface   = Color(0xFF2E1B17);
  static const Color duskPrimary   = Color(0xFFD9764E);
  static const Color duskSecondary = Color(0xFFA56B6B);
  static const Color duskAccent    = Color(0xFFE8C26E);
  static const Color duskGlow      = Color(0xFFD9764E);

  // Night: deep night, muted brass
  static const Color nightBg       = Color(0xFF120808);
  static const Color nightSurface  = Color(0xFF1F1410);
  static const Color nightPrimary  = Color(0xFFA88B5E);
  static const Color nightSecondary = Color(0xFF7C4A4A);
  static const Color nightAccent   = Color(0xFFD9764E);
  static const Color nightGlow     = Color(0xFF6B4A36);

  // Midnight: near-black with violet
  static const Color midnightBg    = Color(0xFF080608);
  static const Color midnightSurface = Color(0xFF15101A);
  static const Color midnightPrimary = Color(0xFF8B7B9B);
  static const Color midnightSecondary = Color(0xFF5A4A6B);
  static const Color midnightAccent = Color(0xFFB08C4F);  // brass undertone
  static const Color midnightGlow = Color(0xFF4A3A5B);

  // Mini-player gradient end (used by router for the slide-up sheet)
  static const Color miniPlayerGradientEnd = Color(0xFF1A1010);

  // ── Per-practice palette tokens (used by _TodayCard) ─────────
  // Meditate — sage green
  static const Color practiceMeditateFrom = Color(0xFF4A6B5E);
  static const Color practiceMeditateTo   = Color(0xFF2C3E36);
  // Scripture — warm bronze
  static const Color practiceScriptureFrom = Color(0xFF8E6F47);
  static const Color practiceScriptureTo   = Color(0xFF5B4530);
  // Prayer — coral rose
  static const Color practicePrayerFrom   = Color(0xFFA66B5C);
  static const Color practicePrayerTo     = Color(0xFF6F4538);
  // Reflection — slate blue
  static const Color practiceReflectionFrom = Color(0xFF5B6E8E);
  static const Color practiceReflectionTo   = Color(0xFF394861);
  // Praise — amethyst
  static const Color practicePraiseFrom   = Color(0xFF6E5BA6);
  static const Color practicePraiseTo     = Color(0xFF44386F);
  // World — teal
  static const Color practiceWorldFrom    = Color(0xFF4A8E8E);
  static const Color practiceWorldTo      = Color(0xFF2E6363);
  // Sleep — midnight brown (used in practice grid sleep tile)
  static const Color practiceSleepFrom    = Color(0xFF2A1A18);
  static const Color practiceSleepTo      = Color(0xFF0F0807);
  // Sticker tile gradient
  static const Color practiceStickerFrom  = Color(0xFF4A3A2E);
  static const Color practiceStickerTo    = Color(0xFF2E2520);
  // Brass widget gradient (used in modal sheets)
  static const Color brassSheetFrom       = Color(0xFF3A201C);
  static const Color brassSheetTo         = Color(0xFF2A1815);

  // ── World day emotion colors (per emotional content type) ────
  static const Color worldChallenge = Color(0xFF1F3A40);  // deep teal-blue
  static const Color worldGrace     = Color(0xFF1F3328);  // deep sage
  static const Color worldGratitude = Color(0xFF3D2E1A);  // deep amber
  static const Color worldDefault   = Color(0xFF2A2A2A);
  // Mini-player sheet scrim
  static const Color miniPlayerScrim = Color(0xFF120A09);

  // ── Overlays & scrims ─────────────────────────────────────────
  // 55% black — used for general modal scrims (lighter than the
  // 60% milestone scrim so the user feels the page is still there).
  static const Color scrimSoft = Color(0x8C000000);  // ~55% black

  // Pre-baked alpha tokens for white (used on dark backgrounds)
  static const Color white04 = Color(0x0AFFFFFF);  // 4% (subtle borders)
  static const Color white05 = Color(0x0DFFFFFF);  // 5% (pressed highlight)
  static const Color white06 = Color(0x0FFFFFFF);  // 6% (hairline)
  static const Color white12 = Color(0x1FFFFFFF);  // 12% (border)
  static const Color white18 = Color(0x2EFFFFFF);  // 18% (icon backgrounds)
  static const Color white70 = Color(0xB3FFFFFF);  // 70% (muted text)
  static const Color white80 = Color(0xCCFFFFFF);  // 80% (medium text)
  static const Color white85 = Color(0xD9FFFFFF);  // 85% (bright text)
  static const Color black32 = Color(0x52000000);  // 32% (pressed overlay)
  static const Color black40 = Color(0x66000000);  // 40% (mini player sheet scrim)

  // ── Misc design tokens used across the system ─────────────────
  static const Color scrim = Color(0x99000000);  // 60% black overlay
  static const Color whiteAlpha04 = Color(0x0AFFFFFF);  // 4% white (pressed)
  static const Color whiteAlpha05 = Color(0x0DFFFFFF);  // 5% white
  static const Color whiteAlpha22 = Color(0x38FFFFFF);  // 22% white (Lumen highlight)

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