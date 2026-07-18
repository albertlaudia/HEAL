// HEAL — App entry point.
// Initializes PB + Firebase + notifications, then runs the app.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'services/history_service.dart';
import 'services/deep_link_service.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/analytics_service.dart';
import 'services/force_update_service.dart';
import 'services/app_review_service.dart';
import 'data/bible_progress_cache.dart';
import 'features/settings/force_update_dialog.dart';
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

    // Create PocketBase + root container so providers are available
    // for all subsequent initialization steps.
    final pb = PocketBase(HealEnv.pocketbaseUrl);
    final container = ProviderContainer(
      overrides: [
        pocketbaseProvider.overrideWithValue(pb),
      ],
    );

    // Initialize Crashlytics — must come AFTER Firebase init.
    // (Wires FlutterError.onError + PlatformDispatcher.onError.)
    try {
      final crashlytics = container.read(crashlyticsServiceProvider);
      final localId = await UserIdService().get();
      await crashlytics.init(
        environment: kDebugMode ? 'debug' : 'release',
        userIdentifier: localId,
        initialKeys: {
          'launch_at': DateTime.now().toIso8601String(),
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        },
      );
      logger.i('App', 'Crashlytics initialized');
    } catch (e) {
      logger.w('App', 'Crashlytics init failed: $e.');
    }

    // Initialize Analytics. (Same lifecycle as Crashlytics — after Firebase.)
    try {
      final analytics = container.read(analyticsServiceProvider);
      await analytics.init();
      forwardActivityToAnalytics(container, analytics);
      // Log app_open as the first event so dashboards light up immediately.
      unawaited(analytics.log(AnalyticsEvent(HealEvents.appOpen, params: {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'session_count': container.read(streakServiceProvider).totalSessions,
      })));
      logger.i('App', 'Analytics initialized');
    } catch (e) {
      logger.w('App', 'Analytics init failed: $e.');
    }

    // Wire deep link service. Must come AFTER the GoRouter is built and
    // attached to the MaterialApp. We do this here so that the router is
    // available for the deep link handler to push to.
    try {
      final deepLink = container.read(deepLinkServiceProvider);
      deepLink.router = HealRouter.router;
      deepLink.attachAnalytics(
        container.read(analyticsServiceProvider),
        container.read(activityTrackerProvider.notifier),
      );
      await deepLink.init();
      logger.i('App', 'Deep link service started');
    } catch (e) {
      logger.w('App', 'Deep link init failed: $e.');
    }

    // Force update check — run on every cold start.
    // (We don't show a dialog here because main.dart has no BuildContext.
    // The router's redirect logic will pop the dialog when the home page
    // builds. We just cache the result so the redirect can read it.)
    try {
      final forceUpdate = container.read(forceUpdateServiceProvider);
      final manifest = await forceUpdate.fetch();
      if (manifest != null) {
        final state = await forceUpdate.check();
        // Stash the state in a SharedPreferences key the redirect reads.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('force_update_state_v1', state.name);
        await prefs.setString('force_update_manifest_v1',
            '${manifest.minVersion}|${manifest.latestVersion}');
      }
    } catch (e) {
      logger.w('App', 'Force update check failed: $e.');
    }

    // Init notifications (with timeout so a slow plugin can't block launch)
    await container.read(notificationServiceProvider).init()
        .timeout(const Duration(seconds: 5), onTimeout: () {});

    // Load streak state from local storage
    await container.read(streakServiceProvider.notifier).load();

    // Smart in-app review: show after the user's 5th completed session
    // (per Apple + Google guidelines — only after a positive experience).
    // The service is throttled to 1 prompt per 180 days.
    final streak = container.read(streakServiceProvider);
    if (streak.totalSessions == 5) {
      unawaited(container
          .read(appReviewServiceProvider)
          .requestReview(reason: '5th_session'));
      unawaited(container.read(analyticsServiceProvider).log(
        const AnalyticsEvent(HealEvents.appReviewPrompted, params: {'reason': '5th_session'}),
      ));
    }

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

        // Record the play in the user-facing history list.
        // We use the track's kind for routing in the history list.
        final kindStr = switch (track.source) {
          AudioSource.meditation => 'meditation',
          AudioSource.praise => 'praise',
          AudioSource.reference => 'scripture',
          AudioSource.custom => 'meditation',
        };
        await container.read(historyServiceProvider.notifier).record(
          HistoryEntry(
            kind: kindStr,
            slug: track.id,
            title: track.title,
            subtitle: track.subtitle,
            imageUrl: track.illustrationUrl,
            durationSeconds: durationSeconds,
            playedAt: DateTime.now(),
            completionRatio: 1.0,
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
            // 4. Log to analytics (covered by forwardActivityToAnalytics)
            // 5. Smart in-app review: prompt for the 7-day streak milestone
            //    and the 30-day streak milestone. Per Apple + Google
            //    guidelines, only after the user has had a meaningful
            //    positive experience.
            if (sticker.id == 'streak-7' || sticker.id == 'streak-30') {
              unawaited(container
                  .read(appReviewServiceProvider)
                  .requestReview(reason: sticker.id));
            }
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

    // Bridge: when the user signs in or out, update the Crashlytics user
    // identifier so crashes are tied to the right account. We also push
    // current streak + total sessions for context.
    container.listen<AsyncValue<HealUser?>>(
      authStateProvider,
      (_, next) {
        final user = next.valueOrNull;
        final crashlytics = container.read(crashlyticsServiceProvider);
        unawaited(crashlytics.setUser(user?.uid));
        if (user != null && user.isSignedIn) {
          final streak = container.read(streakServiceProvider);
          unawaited(crashlytics.setKey('streak_days', streak.currentStreak));
          unawaited(crashlytics.setKey('total_sessions', streak.totalSessions));
        }
      },
      fireImmediately: true,
    );

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: HealApp(
          firstLaunch: !onboarded,
        ),
      ),
    );
  }, (error, stack) {
    // Last-resort crash capture for errors that escape the zone.
    // (Most errors are caught by FlutterError.onError + PlatformDispatcher.onError
    // wired up in CrashlyticsService.init.)
    final crashlytics = ProviderContainer()
        .read(crashlyticsServiceProvider);
    if (crashlytics.isEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    assert(() {
      // ignore: avoid_print
      print('Uncaught: $error\n$stack');
      return true;
    }());
  });
}// Last verified: 2026-07-17 v18 build with intl pinned to ^0.19.0 + 12 quick wins
