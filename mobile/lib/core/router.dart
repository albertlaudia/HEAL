// go_router setup for HEAL — single Stack with deep support for
// /meditate/:slug, /praise/:slug, /breathe/:pattern, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/breathe/breath_studio_page.dart';
import '../features/essays/essay_page.dart';
import '../features/home/home_page.dart';
import '../features/home/splash_page.dart';
import '../features/meditate/meditate_detail_page.dart';
import '../features/now/now_page.dart';
import '../features/praise/praise_detail_page.dart';
import '../features/praise/praise_library_page.dart';
import '../features/prayer/prayer_page.dart';

final healRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'home',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: 'now',
            builder: (_, __) => const NowPage(),
          ),
          GoRoute(
            path: 'meditate/:slug',
            builder: (BuildContext c, GoRouterState s) =>
                MeditateDetailPage(slug: s.pathParameters['slug']!),
          ),
          GoRoute(
            path: 'praise',
            builder: (_, __) => const PraiseLibraryPage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':slug',
                builder: (BuildContext c, GoRouterState s) =>
                    PraiseDetailPage(slug: s.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(
            path: 'prayer',
            builder: (_, __) => const PrayerPage(),
          ),
          GoRoute(
            path: 'essays/:slug',
            builder: (BuildContext c, GoRouterState s) =>
                EssayPage(slug: s.pathParameters['slug']!),
          ),
          GoRoute(
            path: 'breathe/:pattern',
            builder: (BuildContext c, GoRouterState s) =>
                BreathStudioPage(pattern: s.pathParameters['pattern']!),
          ),
        ],
      ),
    ],
  );
});
