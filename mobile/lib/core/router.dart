// HEAL — Main scaffold with bottom navigation.
// Home / Now / Pray / Praise / Settings
// Includes MiniPlayer for currently-playing audio.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'widgets/brass_widgets.dart';
import '../features/home/home_page.dart';
import '../features/now/now_page.dart';
import '../features/prayer/prayer_page.dart';
import '../features/praise/praise_library_page.dart';
import '../features/praise/karaoke_lyrics.dart';
import '../features/praise/timed_lyrics.dart';
import '../features/meditate/meditate_detail_page.dart';
import '../features/essays/essay_page.dart';
import '../features/world/world_day_page.dart';
import '../features/breathe/breath_studio_page.dart';
import '../features/breathe/voice_calibration_page.dart';
import '../features/scripture/sit_with_verse_page.dart';
import '../features/settings/settings_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/home/splash_page.dart';
import '../data/pb_repositories.dart';
import '../data/pb_models.dart';
import '../services/audio_service.dart';

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
          if (audio.hasTrack)
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
        final src = audio.track?.source;
        // Praise tracks: tap opens the lyrics sheet so you can read while it plays.
        // Other sources: tap opens the full /now player.
        if (src == AudioSource.praise && (audio.track?.lyrics ?? '').isNotEmpty) {
          showModalBottomSheet(
            context: context,
            backgroundColor: HealTokens.rosewoodDeep,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
            ),
            builder: (_) => _LyricsSheet(
              title: audio.track?.title ?? '',
              subtitle: audio.track?.subtitle ?? '',
              lyrics: audio.track!.lyrics!,
              position: audio.position,
              duration: audio.duration,
            ),
          );
        } else {
          context.push('/now');
        }
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
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
            if (audio.inPlaylist && audio.hasNext)
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  size: 22,
                  color: audio.hasNext ? HealTokens.brass : HealTokens.creamDim,
                ),
                onPressed: audio.hasNext
                    ? () => ref.read(audioServiceProvider.notifier).next()
                    : null,
              ),
            if (audio.track?.source == AudioSource.praise &&
                (audio.track?.lyrics ?? '').isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.lyrics_rounded, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: HealTokens.rosewoodDeep,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(HealTokens.r24)),
                    ),
                    builder: (_) => _LyricsSheet(
                      title: audio.track?.title ?? '',
                      subtitle: audio.track?.subtitle ?? '',
                      lyrics: audio.track!.lyrics!,
                      position: audio.position,
                      duration: audio.duration,
                    ),
                  );
                },
              ),
            ],
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

/// ── Lyrics bottom sheet ────────────────────────────────────────────────
/// Shown when the user taps the MiniPlayer (or the lyrics icon) while a
/// praise track is playing. The track keeps playing underneath — this sheet
/// only overlays the lyrics so the user can read along, sing along, or share.
class _LyricsSheet extends HookConsumerWidget {
  final String title;
  final String subtitle;
  final String lyrics;
  final Duration position;
  final Duration duration;

  const _LyricsSheet({
    required this.title,
    required this.subtitle,
    required this.lyrics,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final timed = useMemoized(() => TimedLyricsParser.parse(lyrics), [lyrics]);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HealTokens.rosewoodDeep, Color(0xFF1A1010)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(HealTokens.r24)),
        ),
        child: Column(
          children: [
            // Grab handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: HealTokens.creamDim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HealTokens.s24, HealTokens.s12, HealTokens.s24, HealTokens.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: HealTokens.cream,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: HealTokens.creamDim,
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: HealTokens.creamDim,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            // Karaoke lyrics
            Expanded(
              child: KaraokeLyrics(
                timed: timed,
                position: audio.position,
                onSeek: (s) => ref.read(audioServiceProvider.notifier)
                    .seek(Duration(milliseconds: (s * 1000).round())),
              ),
            ),
            // Bottom playback bar
            Container(
              padding: const EdgeInsets.fromLTRB(
                HealTokens.s24, HealTokens.s12, HealTokens.s24, HealTokens.s32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    HealTokens.rosewoodDeep.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _SheetProgressBar(pos: audio.position, dur: audio.duration),
                  const SizedBox(height: HealTokens.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded, size: 28),
                        color: HealTokens.cream,
                        onPressed: () => ref.read(audioServiceProvider.notifier).skipBack(const Duration(seconds: 10)),
                      ),
                      const SizedBox(width: HealTokens.s16),
                      _SheetPlayButton(
                        playing: audio.playing,
                        loading: audio.loading,
                        onTap: () => ref.read(audioServiceProvider.notifier).togglePlay(),
                      ),
                      const SizedBox(width: HealTokens.s16),
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded, size: 28),
                        color: HealTokens.cream,
                        onPressed: () => ref.read(audioServiceProvider.notifier).skipForward(const Duration(seconds: 10)),
                      ),
                      if (audio.inPlaylist) ...[
                        const SizedBox(width: HealTokens.s8),
                        IconButton(
                          icon: Icon(Icons.skip_next_rounded, size: 24),
                          color: audio.hasNext ? HealTokens.brass : HealTokens.creamDim.withValues(alpha: 0.3),
                          onPressed: audio.hasNext
                              ? () => ref.read(audioServiceProvider.notifier).next()
                              : null,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPlayButton extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback onTap;
  const _SheetPlayButton({required this.playing, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [HealTokens.brassLight, HealTokens.brass, HealTokens.brassDeep],
          ),
          shape: BoxShape.circle,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: HealTokens.rosewoodDeep),
              )
            : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: HealTokens.rosewoodDeep,
                size: 32,
              ),
      ),
    );
  }
}

class _SheetProgressBar extends StatelessWidget {
  final Duration pos;
  final Duration dur;
  const _SheetProgressBar({required this.pos, required this.dur});

  @override
  Widget build(BuildContext context) {
    final progress = dur.inMilliseconds == 0
        ? 0.0
        : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(_fmt(pos),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
        const SizedBox(width: HealTokens.s8),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: HealTokens.creamDim.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [HealTokens.brassLight, HealTokens.brass],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: HealTokens.s8),
        Text(_fmt(dur),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HealTokens.creamDim)),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Australia's local 'today' for the daily world piece (matches the cron slug).
String _todaySlug() {
  // UTC + 8h = WST. Cron runs at 21:00 UTC = 06:00 WST.
  final ms = DateTime.now().toUtc().millisecondsSinceEpoch + 8 * 3600 * 1000;
  final d  = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final y  = d.year.toString().padLeft(4, '0');
  final m  = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'world-$y-$m-$day';
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
        path: '/world',
        redirect: (_, __) => '/world/world-${_todaySlug()}',
      ),
      GoRoute(
        path: '/world/:slug',
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return _verticalSlide(state, WorldDayPage(slug: slug));
        },
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
          return _verticalSlide(
            state,
            Consumer(
              builder: (context, ref, _) {
                final daily = ref.watch(_dailyScriptureProvider);
                return daily.when(
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
              },
            ),
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