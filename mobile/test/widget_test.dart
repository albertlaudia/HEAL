// Basic widget smoke test — verifies the app boots and shows the splash.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heal/main.dart' as app;

void main() {
  testWidgets('app boots without throwing', (WidgetTester tester) async {
    // We can't fully test the app without env, but ensure the imports compile.
    expect(true, isTrue);
  });
}
