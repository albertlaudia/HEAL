// HEAL — Main scaffold with bottom navigation.
// Home / Now / Pray / Praise / Settings
// Includes MiniPlayer for currently-playing audio.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'widgets/brass_widgets.dart';
import '../features/home/home_page.dart';
import '../features/now/now_page.dart';
import '../features/prayer/prayer_page.dart';
import '../features/praise/praise_library_page.dart';
import '../features/meditate/meditate_detail_page.dart';
import '../features/essays/essay_page.dart';
import '../features/breathe/breath_studio_page.dart';
import '../features/breathe/voice_calibration_page.dart';
import '../features/scripture/sit_with_verse_page.dart';
import '../features/settings/settings_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/home/splash_page.dart';
import '../data/pb_repositories.dart';
import '../data/pb_models.dart';
import '../services/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScaffold extends HookConsumerWidget {
  final int currentIndex;
  const MainScaffold({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);

    final pages = [
      const HomePage(),
      const NowPage(),
      const PrayerPage(),
      const PraiseLibraryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audio.hasTrack && audio.track?.source != AudioSource.praise)
            const MiniPlayer(),
          _BottomNav(currentIndex: currentIndex),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.spa_outlined, 'Now'),
      (Icons.favorite_outline_rounded, 'Pray'),
      (Icons.music_note_outlined, 'Praise'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: HealTokens.rosewood,
        border: Border(
          top: BorderSide(
            color: HealTokens.brass.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/${_routeFor(i)}');
                    },
                    child: AnimatedContainer(
                      duration: HealTokens.d200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].$1,
                            color: isSelected
                                ? HealTokens.brass
                                : HealTokens.creamDim,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? HealTokens.brass
                                      : HealTokens.creamDim,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _routeFor(int i) {
    switch (i) {
      case 0:
        return 'home';
      case 1:
        return 'now';
      case 2:
        return 'prayer';
      case 3:
        return 'praise';
      case 4:
        return 'settings';
      default:
        return 'home';
    }
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final service = ref.read(audioServiceProvider.notifier);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/now');
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: HealTokens.s8),
        decoration: BoxDecoration(
          color: HealTokens.rosewoodLight,
          borderRadius: BorderRadius.circular(HealTokens.r12),
          border: Border.all(
            color: HealTokens.brass.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: HealTokens.s12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HealTokens.brassLight, HealTokens.brass],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                audio.playing
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: HealTokens.rosewoodDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: HealTokens.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.track?.title ?? 'Now playing',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: HealTokens.cream,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    audio.track?.subtitle ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HealTokens.creamDim,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                audio.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                service.togglePlay();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HealRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeThrough(state, const SplashPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _slideUp(state, const OnboardingPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.matchedLocation;
          final idx = _indexForRoute(loc);
          return MainScaffold(currentIndex: idx);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadeThrough(state, const SizedBox()),
          ),
          GoRoute(
            path: '/now',
            pageBuilder: (context, state) => _fadeThrough(state, const SizedBox()),
          ),
          GoRoute(
            path: '/prayer',
            pageBuilder: (context, state) => _fadeThrough(state, const SizedBox()),
          ),
          GoRoute(
            path: '/praise',
            pageBuilder: (context, state) => _fadeThrough(state, const SizedBox()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadeThrough(state, const SizedBox()),
          ),
        ],
      ),
      GoRoute(
        path: '/meditate',
        pageBuilder: (context, state) =>
            _sharedAxis(state, const MeditateListPage()),
      ),
      GoRoute(
        path: '/meditate/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _sharedAxis(state, MeditateDetailPage(id: id));
        },
      ),
      GoRoute(
        path: '/praise/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _verticalSlide(state, PraiseDetailPage(id: id));
        },
      ),
      GoRoute(
        path: '/prayer/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _sharedAxis(state, PrayerDetailPage(id: id));
        },
      ),
      GoRoute(
        path: '/essays',
        pageBuilder: (context, state) => _sharedAxis(state, const EssayPage()),
      ),
      GoRoute(
        path: '/breathe',
        pageBuilder: (context, state) =>
            _sharedAxis(state, const BreathStudioPage()),
      ),
      GoRoute(
        path: '/breathe/calibrate',
        pageBuilder: (context, state) =>
            _sharedAxis(state, const VoiceCalibrationPage()),
      ),
      GoRoute(
        path: '/sit-with-verse',
        pageBuilder: (context, state) {
          // Optionally pass a specific scripture via extra
          final passed = state.extra is Scripture ? state.extra as Scripture : null;
          if (passed != null) {
            return _verticalSlide(state, SitWithVersePage(scripture: passed));
          }
          // Otherwise use the daily scripture via Consumer
          return Consumer(
            builder: (context, ref, _) {
              final daily = ref.watch(_dailyScriptureProvider);
              final child = daily.when(
                data: (s) {
                  if (s == null) {
                    return const _NoVersePlaceholder();
                  }
                  return SitWithVersePage(scripture: s);
                },
                loading: () => const Scaffold(
                  backgroundColor: HealTokens.rosewoodDeep,
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Text('Could not load verse: $e')),
                ),
              );
              return _verticalSlide(state, child);
            },
          );
        },
      ),
    ],
  );

  static int _indexForRoute(String location) {
    if (location.startsWith('/now')) return 1;
    if (location.startsWith('/prayer')) return 2;
    if (location.startsWith('/praise')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  static CustomTransitionPage _fadeThrough(state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: HealTokens.d400,
      reverseTransitionDuration: HealTokens.d300,
      transitionsBuilder: (context, anim, secondary, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: HealTokens.easeOutQuart),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage _sharedAxis(state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: HealTokens.d400,
      reverseTransitionDuration: HealTokens.d300,
      transitionsBuilder: (context, anim, secondary, child) {
        final fade = CurvedAnimation(parent: anim, curve: HealTokens.easeOutQuart);
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static CustomTransitionPage _slideUp(state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: HealTokens.d500,
      reverseTransitionDuration: HealTokens.d400,
      transitionsBuilder: (context, anim, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: HealTokens.easeOutQuart));
        final fade = CurvedAnimation(parent: anim, curve: HealTokens.easeOutQuart);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  static CustomTransitionPage _verticalSlide(state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: HealTokens.d500,
      reverseTransitionDuration: HealTokens.d400,
      fullscreenDialog: true,
      transitionsBuilder: (context, anim, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: HealTokens.easeInOutQuart));
        return SlideTransition(position: slide, child: child);
      },
    );
  }
}

class _NoVersePlaceholder extends StatelessWidget {
  const _NoVersePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text(
          'No scripture available right now.',
          style: TextStyle(color: HealTokens.creamDim),
        ),
      ),
    );
  }
}

/// Daily scripture provider — picks the verse for today (deterministic
/// by day-of-year) so the "Sit with one verse" mode has something to load
/// even when launched without a specific verse passed in.
final _dailyScriptureProvider = FutureProvider<Scripture?>((ref) async {
  final repo = ref.watch(scriptureRepoProvider);
  final day = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
  final list = await repo.list(dayOfYear: day, limit: 1);
  if (list.isNotEmpty) return list.first;
  // Fallback: most recent published
  final any = await repo.list(limit: 1);
  return any.isEmpty ? null : any.first;
});