// HEAL — a quiet Christian mindfulness practice
// Entry point. Wires ProviderScope (Riverpod) around the HEAL app.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/observability.dart';
import 'data/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system chrome for a quiet, low-distraction feel.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Load environment + boot the app.
  final env = await Env.load();
  await runZonedGuarded<Future<void>>(
    () async {
      final container = ProviderContainer(
        observers: <ProviderObserver>[Observability()],
      );
      await bootstrap(container: container, env: env);
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const HealApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      Observability.recordError(error, stack);
    },
  );
}
