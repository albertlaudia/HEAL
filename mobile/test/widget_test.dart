// HEAL — Smoke test that actually exercises the app.
//
// Renders the Lumen widget (a pure CustomPainter, no PB / Firebase
// required) and verifies it produces a non-error render. This catches
// regressions in the design system — the most common source of breakage
// during token-routing refactors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heal/design/lumen.dart';
import 'package:heal/design/edge_glow.dart';
import 'package:heal/design/empty_state.dart';
import 'package:heal/design/copy.dart';
import 'package:heal/design/emotion_palette.dart';

void main() {
  testWidgets('Lumen renders all 8 emotion states without throwing',
      (WidgetTester tester) async {
    for (final emotion in LumenEmotion.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Lumen(emotion: emotion, size: 64, celebration: 0.5),
        ),
      ));
      expect(find.byType(Lumen), findsOneWidget);
      // Pump a frame so the AnimationController ticks
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('EdgeGlow renders with all 4 emotion palettes',
      (WidgetTester tester) async {
    for (final palette in [
      EmotionPalette.resting,
      EmotionPalette.practicing,
      EmotionPalette.evening,
      EmotionPalette.celebrating,
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdgeGlow(palette: palette),
        ),
      ));
      expect(find.byType(EdgeGlow), findsOneWidget);
    }
  });

  testWidgets('EmptyState renders with all required fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(
          title: 'No hymns here yet',
          body: 'Try the All tab, or come back tomorrow.',
          ctaLabel: 'Browse',
        ),
      ),
    ));
    expect(find.text('No hymns here yet'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
  });

  test('Copy tokens are non-empty and well-formed', () {
    expect(Copy.appName, isNotEmpty);
    expect(Copy.tagline, isNotEmpty);
    expect(Copy.greetingForHour(8), equals('Good morning'));
    expect(Copy.greetingForHour(20), equals('Good evening'));
    expect(Copy.greetingForHour(2), equals('Still up?'));
    expect(Copy.scripture('Psalm', 23, 1), equals('Psalm 23:1'));
    expect(Copy.scripture('Psalm', 23, null), equals('Psalm 23'));
  });

  test('Emotion palette variants are distinct', () {
    expect(EmotionPalette.resting.primary, isNot(equals(EmotionPalette.evening.primary)));
    expect(EmotionPalette.practicing.surface, isNot(equals(EmotionPalette.celebrating.surface)));
  });
}
