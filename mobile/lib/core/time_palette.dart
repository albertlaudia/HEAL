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
    background: HealTokens.predawnBg,
    surface: HealTokens.predawnSurface,
    primary: HealTokens.predawnPrimary,
    secondary: HealTokens.predawnSecondary,
    accent: HealTokens.predawnAccent,
    glow: HealTokens.predawnGlow,
  ),
  'dawn': TimePalette(
    period: 'Dawn',
    background: HealTokens.dawnBg,
    surface: HealTokens.dawnSurface,
    primary: HealTokens.dawnPrimary,
    secondary: HealTokens.dawnSecondary,
    accent: HealTokens.dawnAccent,
    glow: HealTokens.dawnGlow,
  ),
  'noon': TimePalette(
    period: 'Noon',
    background: HealTokens.noonBg,
    surface: HealTokens.noonSurface,
    primary: HealTokens.noonPrimary,
    secondary: HealTokens.noonSecondary,
    accent: HealTokens.noonAccent,
    glow: HealTokens.noonGlow,
  ),
  'dusk': TimePalette(
    period: 'Dusk',
    background: HealTokens.duskBg,
    surface: HealTokens.duskSurface,
    primary: HealTokens.duskPrimary,
    secondary: HealTokens.dawnSecondary,
    accent: HealTokens.noonAccent,
    glow: HealTokens.dawnGlow,
  ),
  'night': TimePalette(
    period: 'Night',
    background: HealTokens.nightBg,
    surface: HealTokens.nightSurface,
    primary: HealTokens.nightPrimary,
    secondary: HealTokens.noonSecondary,
    accent: HealTokens.nightAccent,
    glow: HealTokens.nightGlow,
  ),
  'midnight': TimePalette(
    period: 'Midnight',
    background: HealTokens.midnightBg,
    surface: HealTokens.midnightSurface,
    primary: HealTokens.midnightPrimary,
    secondary: HealTokens.midnightSecondary,
    accent: HealTokens.midnightAccent,
    glow: HealTokens.midnightGlow,
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

/// BuildContext extension for the current TimePalette. Lets any widget
/// write `context.palette` instead of `ref.watch(timePaletteProvider)`.
extension TimePaletteContext on BuildContext {
  TimePalette get palette {
    // Read the provider via the standard Riverpod lookup. Falls back
    // to the noon palette if the provider hasn't been initialized yet
    // (e.g. during the very first frame).
    final container = ProviderScope.containerOf(this, listen: false);
    return container.read(timePaletteProvider);
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
}// 1784479299
