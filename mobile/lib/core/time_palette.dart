// HEAL — Time-of-day adaptive palette.
//
// HEAL shifts its color temperature with the sun:
//   - 4-7 AM:    Pre-dawn blue + cool brass
//   - 7-11 AM:   Dawn rosewood + amber warmth
//   - 11 AM-4 PM: Full noon — bright rosewood + saturated brass
//   - 4-7 PM:   Dusk ember + deep bronze
//   - 7 PM-12 AM: Night rosewood + ember accents
//   - 12-4 AM:  Deep night — near-black with violet undertone
//
// All transitions are gradual (1-second ease), driven by an internal clock
// provider so the entire app shifts in lockstep.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';

class TimePalette {
  final String period;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color glow;

  const TimePalette({
    required this.period,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.glow,
  });
}

const _palettes = <String, TimePalette>{
  'predawn': TimePalette(
    period: 'Pre-dawn',
    background: Color(0xFF0F1419),    // deep blue-black
    surface: Color(0xFF1A1F25),
    primary: Color(0xFF8FA8B0),        // cool silver-blue brass
    secondary: Color(0xFF5A6F7E),
    accent: Color(0xFFB08C4F),         // brass undertone
    glow: Color(0xFF4A6B7A),
  ),
  'dawn': TimePalette(
    period: 'Dawn',
    background: Color(0xFF2A1F1C),    // warming rosewood
    surface: Color(0xFF3A2A24),
    primary: Color(0xFFD4B26A),        // bright brass dawn
    secondary: Color(0xFFA56B6B),
    accent: Color(0xFFE8C26E),         // warm amber
    glow: Color(0xFFD9764E),
  ),
  'noon': TimePalette(
    period: 'Noon',
    background: Color(0xFF2A1815),    // standard rosewood
    surface: Color(0xFF3A201C),
    primary: Color(0xFFB08C4F),        // true brass
    secondary: Color(0xFF7C4A4A),
    accent: Color(0xFFE8C26E),
    glow: Color(0xFFE8C26E),
  ),
  'dusk': TimePalette(
    period: 'Dusk',
    background: Color(0xFF1F1410),    // darker rosewood
    surface: Color(0xFF2E1B17),
    primary: Color(0xFFD9764E),        // ember-copper
    secondary: Color(0xFFA56B6B),
    accent: Color(0xFFE8C26E),
    glow: Color(0xFFD9764E),
  ),
  'night': TimePalette(
    period: 'Night',
    background: Color(0xFF120808),    // deep night
    surface: Color(0xFF1F1410),
    primary: Color(0xFFA88B5E),        // muted brass
    secondary: Color(0xFF7C4A4A),
    accent: Color(0xFFD9764E),         // ember
    glow: Color(0xFF6B4A36),
  ),
  'midnight': TimePalette(
    period: 'Midnight',
    background: Color(0xFF080608),    // near-black with violet
    surface: Color(0xFF15101A),
    primary: Color(0xFF8B7B9B),        // muted violet-brass
    secondary: Color(0xFF5A4A6B),
    accent: Color(0xFFB08C4F),
    glow: Color(0xFF4A3A5B),
  ),
};

TimePalette paletteForHour(int hour) {
  if (hour >= 4 && hour < 7) return _palettes['predawn']!;
  if (hour >= 7 && hour < 11) return _palettes['dawn']!;
  if (hour >= 11 && hour < 16) return _palettes['noon']!;
  if (hour >= 16 && hour < 19) return _palettes['dusk']!;
  if (hour >= 19 && hour < 24) return _palettes['night']!;
  return _palettes['midnight']!;
}

/// Provider that updates the palette every minute, so gradual shifts happen
/// as the hour passes.
final timePaletteProvider = StateNotifierProvider<TimePaletteController, TimePalette>((ref) {
  return TimePaletteController();
});

class TimePaletteController extends StateNotifier<TimePalette> {
  Timer? _timer;

  TimePaletteController() : super(paletteForHour(DateTime.now().hour)) {
    // Update every 60 seconds (cheap) — covers hour-boundary crossings.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      final next = paletteForHour(DateTime.now().hour);
      if (next.period != state.period) state = next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Returns a ColorScheme that overlays the time palette onto the standard
/// HEAL ColorScheme. Used by widgets that want time-aware theming.
ColorScheme paletteScheme(BuildContext context, TimePalette p) {
  final base = Theme.of(context).colorScheme;
  return base.copyWith(
    primary: p.primary,
    onPrimary: p.background,
    primaryContainer: p.primary.withValues(alpha: 0.6),
    secondary: p.secondary,
    onSecondary: p.background,
    secondaryContainer: p.secondary.withValues(alpha: 0.6),
    tertiary: p.accent,
    onTertiary: p.background,
    surface: p.surface,
    onSurface: HealTokens.cream,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: Color.lerp(p.surface, p.primary, 0.12)!,
    surfaceContainerHighest: Color.lerp(p.surface, p.primary, 0.24)!,
  );
}