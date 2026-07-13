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
import 'services/streak_service.dart';
import 'services/audio_service.dart';
import 'services/activity_tracker.dart';
import 'services/auth_service.dart';
import 'data/bible_progress_cache.dart';
import 'design/lumen_state.dart';
import 'data/pb_models.dart';
import 'services/sticker_book.dart';
import 'services/sound_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
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

    // Initialize Firebase (auth + firestore for the user profile doc that
    // stores the legacy userId on first sign-in). Falls back to a stub if
    // Firebase isn't configured for this build flavor (e.g. plain
    // `flutter run` before `flutterfire configure`).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('App', 'Firebase initialized');
    } catch (e) {
      logger.w('App', 'Firebase init failed: $e. Continuing without auth.');
    }

    final pb = PocketBase(HealEnv.pocketbaseUrl);

    // Create a root container so we can override PB before runApp
    final container = ProviderContainer(
      overrides: [
        pocketbaseProvider.overrideWithValue(pb),
      ],
    );

    // Init notifications (with timeout so a slow plugin can't block launch)
    await container.read(notificationServiceProvider).init()
        .timeout(const Duration(seconds: 5), onTimeout: () {});

    // Load streak state from local storage
    await container.read(streakServiceProvider.notifier).load();

    // Load activity tracker (shows "what's your pattern")
    await container.read(activityTrackerProvider.notifier).hydrate();

    // Load sticker book (so the very first session can immediately evaluate)
    await container.read(stickerBookProvider.notifier).hydrate();

    // Log this session
    unawaited(container
        .read(activityTrackerProvider.notifier)
        .log('session', meta: {'platform': 'flutter'}));

    // Wire audio completion → streak session
    final audio = container.read(audioServiceProvider.notifier);
    audio.onTrackComplete = (track, durationSeconds) async {
      // Map AudioSource to SessionType
      SessionType? sessionType;
      switch (track.source) {
        case AudioSource.meditation:
          sessionType = SessionType.meditate;
          break;
        case AudioSource.praise:
          sessionType = SessionType.praise;
          break;
        case AudioSource.reference:
          sessionType = SessionType.scripture;
          break;
        case AudioSource.custom:
          sessionType = SessionType.meditate;
          break;
      }
      if (sessionType != null && durationSeconds >= 30) {
        container.read(streakServiceProvider.notifier).recordSession(
              SessionRecord(
                timestamp: DateTime.now(),
                type: sessionType,
                durationSeconds: durationSeconds,
              ),
        );

        // Coalesce sticker evaluation + Bible progress fetch into ONE
        // call per 2-second window — fixes P0 #3 (network spam).
        // A user skipping 10 praise songs in 30 seconds used to fire 10
        // PB requests for Bible progress + 10 sticker evals. Now: one.
        final debouncer = container.read(stickerEvalDebouncerProvider);
        if (!debouncer.tick()) return;
        debouncer.markInflight(true);

        try {
          final streak = container.read(streakServiceProvider);
          final track = container.read(activityTrackerProvider);
          final userId = await UserIdService().get();

          // Bible progress via cached provider. First call hits network,
          // subsequent calls are free for 5 minutes.
          final progressList = await container
              .read(bibleProgressCacheProvider(userId).notifier)
              .ensure();
          final completedDays = progressList
              .map((p) => p.dayNumber)
              .toSet();

          final sticker = await container.read(stickerBookProvider.notifier).evaluate(
            currentStreak: streak.currentStreak,
            totalSessions: streak.totalSessions,
            hasBreathed:     track.countFor('open_breath') > 0 || sessionType == SessionType.breath,
            hasMeditated:    track.countFor('open_meditation') > 0 || sessionType == SessionType.meditate,
            hasPrayed:       track.countFor('today_play_prayer') > 0 || sessionType == SessionType.prayer,
            hasPraised:      track.countFor('today_play_praise') > 0 || sessionType == SessionType.praise,
            hasReadBible:    track.countFor('open_bible') > 0 || completedDays.isNotEmpty,
            hasFavorited:    track.countFor('favorite_added') > 0,
            hasShared:       track.countFor('reflection_shared') > 0,
            completedBibleDays: completedDays,
          );
          if (sticker != null) {
            // 1. Play the family-matched sound
            await container.read(soundServiceProvider).play(
              sticker.family == 'moment' ? SoundKind.stickerBible
              : sticker.family == 'streak' ? SoundKind.stickerStreak
              : SoundKind.stickerPractice,
            );
            // 2. Trigger Lumen celebration — drives global emotion state
            container.read(lumenProvider.notifier).celebrate(peak: 1.0);
            // 3. The overlay is fired by the listening screen so the user
            //    actually sees it. main.dart has no BuildContext.
            // The Bible completion overlay in bible_program_page.dart fires
            // its own milestone overlay for the day-level celebration.
          }
        } finally {
          debouncer.markInflight(false);
        }
      }
    };

    // Check if first launch — show onboarding if so
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_complete') ?? false;

    // If not onboarded, the splash page will redirect to onboarding after delay
    logger.i('App', 'Onboarded: $onboarded');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: HealApp(
          firstLaunch: !onboarded,
        ),
      ),
    );
  }, (error, stack) {
    // In release: send to a crash reporter (TODO: Firebase Crashlytics).
    // In debug: dev-friendly logging without polluting release logs.
    assert(() {
      // ignore: avoid_print
      print('Uncaught: $error\n$stack');
      return true;
    }());
  });
}