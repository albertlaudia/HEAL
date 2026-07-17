// HEAL — Deep link service.
//
// Routes inbound deep links (Universal Links on iOS, App Links on Android,
// custom URL schemes on both) to Flutter routes.
//
// Supported URL shapes:
//   https://heal.positiveness.club/meditate/<slug>     → /meditate/<slug>
//   https://heal.positiveness.club/praise/<slug>       → /praise/<slug>
//   https://heal.positiveness.club/prayer/<slug>       → /prayer/<slug>
//   https://heal.positiveness.club/scripture/<slug>    → /scripture/<slug>
//   https://heal.positiveness.club/essay/<slug>        → /essay/<slug>
//   https://heal.positiveness.club/world/<slug>        → /world/<slug>
//   https://heal.positiveness.club/bible               → /bible
//   https://heal.positiveness.club/library             → /library
//   https://heal.positiveness.club/search?q=...        → /search (q is dropped)
//   healf://meditate/<slug>                            → /meditate/<slug>  (legacy)
//
// Set up:
//   iOS — Universal Links verified on `applinks:heal.positiveness.club`
//         in apple-app-site-association. Add `applinks:healf.positiveness.club`
//         if Flutter web is on a different host.
//   Android — App Links verified on `assetlinks.json` published at
//             /.well-known/assetlinks.json on the same host.
//
// Backed by the `app_links` package (replaces `uni_links`).

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'activity_tracker.dart';
import 'analytics_service.dart';

class DeepLinkService {
  DeepLinkService(this._appLinks);
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// The user's current GoRouter (set on init). Used to navigate on
  /// inbound deep links.
  GoRouter? router;

  /// Initialize and start listening for inbound links.
  Future<void> init() async {
    try {
      // Fire any link that opened the app.
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        // Slight delay so the router is fully built before we navigate.
        Future.delayed(const Duration(milliseconds: 500), () {
          handle(initial, reason: 'cold_start');
        });
      }
      // Live updates while the app is open.
      _sub = _appLinks.uriLinkStream.listen((uri) {
        handle(uri, reason: 'warm');
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DeepLinkService.init failed: $e');
      }
    }
  }

  /// Handle an inbound URI: convert to a Flutter route and navigate.
  Future<void> handle(Uri uri, {String reason = 'unknown'}) async {
    final route = _routeFromUri(uri);
    if (route == null) return;
    final r = router;
    if (r == null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DeepLinkService.handle: router not yet attached, dropping $uri');
      }
      return;
    }
    // ignore: unawaited_futures
    _analytics?.log(AnalyticsEvent(HealEvents.deepLinkOpened, params: {
      'path': route,
      'reason': reason,
    }));
    // ignore: unawaited_futures
    _activity?.log('deep_link', target: route);
    r.push(route);
  }

  // Hook for analytics + activity. The provider wires these up at init.
  AnalyticsService? _analytics;
  ActivityTracker? _activity;
  void attachAnalytics(AnalyticsService a, ActivityTracker t) {
    _analytics = a;
    _activity = t;
  }

  /// Map a URI to a Flutter route, or null if not handled.
  /// (Exposed as public for tests + the `web` entry point.)
  static String? _routeFromUri(Uri uri) {
    // Path: /<route>[/<id>]
    final segs = uri.pathSegments;
    if (segs.isEmpty) return null;
    final first = segs[0];
    switch (first) {
      case 'meditate':
      case 'praise':
      case 'prayer':
      case 'scripture':
      case 'essay':
      case 'world':
        if (segs.length < 2) return null;
        return '/$first/${segs[1]}';
      case 'bible':
        return '/bible';
      case 'library':
        return '/library';
      case 'search':
        return '/search';
      case 'settings':
        return '/settings';
      case 'stickers':
        return '/stickers';
      case 'profile':
        return '/profile';
    }
    return null;
  }

  /// Public for tests.
  static String? routeForUri(Uri uri) => _routeFromUri(uri);

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final svc = DeepLinkService(AppLinks());
  ref.onDispose(svc.dispose);
  return svc;
});
