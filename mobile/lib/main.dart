// HEAL — App entry point.
// Initializes PB + Firebase + notifications, then runs the app.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/observability.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'data/pb_repositories.dart';
import 'services/notification_service.dart';
import 'package:pocketbase/pocketbase.dart';

Future<void> main() async {
  // Crash-safe zone
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Style the system bars
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    final logger = HealLogger();
    logger.i('App', 'Booting HEAL…');

    final pb = PocketBase(HealEnv.pocketbaseUrl);

    // Create a root container so we can override PB before runApp
    final container = ProviderContainer(
      overrides: [
        pocketbaseProvider.overrideWithValue(pb),
      ],
    );

    // Init notifications
    await container.read(notificationServiceProvider).init();

    // Check if first launch — show onboarding if so
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_complete') ?? false;

    // If not onboarded, the splash page will redirect to onboarding after delay
    logger.i('App', 'Onboarded: $onboarded');

    runApp(
      ProviderScope(
        parent: container,
        child: HealApp(
          firstLaunch: !onboarded,
        ),
      ),
    );
  }, (error, stack) {
    // ignore: avoid_print
    print('Uncaught: $error\n$stack');
  });
}