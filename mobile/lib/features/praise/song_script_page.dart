// HEAL — Read the Song (lyrics-first view) — REDESIGNED 2026-07-18.
//
// When the user opens a praise song from the library, we navigate here.
// Shows the full lyrics as a "script" with nice typography, plus a
// brass play button that auto-plays the song lead on first open.
//
// Audio is back! The earlier decision to remove audio (because some
// hymn MP3s sounded bad) is reversed — the user wants to listen, and
// we have 116/134 songs with valid audio. The mini-player at the
// bottom of the screen shows progress + play/pause once playing.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../data/pb_models.dart';
import '../../services/audio_service.dart';
import '../../services/favorites_service.dart';
import '../../services/activity_tracker.dart';
import '../../services/analytics_service.dart';

/// Read the Song — full lyrics view with auto-cache, auto-favorite,
/// and now a beautiful play button + auto-play.
class SongScriptPage extends HookConsumerWidget {
  final PraiseSong song;

  const SongScriptPage({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-favorite on first open (no waiting, no UI)
    final favorites = ref.read(favoritesServiceProvider);
    if (!favorites.contains('praise', song.slug)) {
      // Fire and forget - don't block the page render
      Future.microtask(() => ref.read(favoritesServiceProvider.notifier).toggle('praise', song.slug));
    }

    // Auto-cache lyrics + illustration locally
    Future.microtask(() async {
      await SongLocalCache._cacheSong(song);
    });

    // Auto-play ONCE on first load. If a different track is currently
    // playing, respect the user's existing session.
    useEffect(() {
      Future.microtask(() async {
        if (song.cdnAudio.isEmpty) return; // no audio for this song
        final state = ref.read(audioServiceProvider);
        final isCurrent = state.track?.id == song.id;
        if (isCurrent) return; // already playing
        await ref.read(audioServiceProvider.notifier).play(AudioTrack(
              id: song.id,
              url: song.cdnAudio,
              title: song.title,
              subtitle: song.subtitle,
              illustrationUrl: song.cdnIllustration,
              source: AudioSource.praise,
              kind: 'praise',
              durationSeconds: song.durationSeconds,
            ));
        HapticFeedback.lightImpact();
        try {
          ref.read(activityTrackerProvider.notifier).log(
            'praise_opened',
            target: song.slug,
            meta: {'auto_play': true, 'title': song.title},
          );
        } catch (_) {}
      });
      return null;
    }, [song.id]);

    return Scaffold(
      backgroundColor: HealTokens.rosewoodDeep,
      body: CustomScrollView(
        slivers: [
          _SongHero(song: song),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            sliver: SliverToBoxAdapter(
              child: _SongScriptBody(song: song),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongHero extends ConsumerWidget {
  final PraiseSong song;
  const _SongHero({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final isCurrent = audio.track?.id == song.id;
    final isPlaying = isCurrent && audio.playing;
    final isLoading = isCurrent && audio.loading;

    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: HealTokens.rosewoodDeep,
      iconTheme: const IconThemeData(color: HealTokens.cream),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Illustration
            if (song.cdnIllustration.isNotEmpty)
              CachedNetworkImage(
                imageUrl: song.cdnIllustration,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: HealTokens.rosewoodDeep),
                errorWidget: (_, __, ___) => Container(
                  color: HealTokens.rosewoodDeep,
                  child: const Icon(Icons.music_note_rounded,
                      color: HealTokens.brass, size: 64),
                ),
              )
            else
              Container(color: HealTokens.rosewoodDeep),
            // Gradient overlay for readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    HealTokens.rosewoodDeep.withValues(alpha: 0.6),
                    HealTokens.rosewoodDeep,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Top-right play button
            if (song.cdnAudio.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: _PlayButton(
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final svc = ref.read(audioServiceProvider.notifier);
                    if (isCurrent) {
                      await svc.togglePlay();
                    } else {
                      await svc.play(AudioTrack(
                        id: song.id,
                        url: song.cdnAudio,
                        title: song.title,
                        subtitle: song.subtitle,
                        illustrationUrl: song.cdnIllustration,
                        source: AudioSource.praise,
                        kind: 'praise',
                        durationSeconds: song.durationSeconds,
                      ));
                    }
                  },
                ),
              ),
            // Title + subtitle at the bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (song.category != null && song.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: HealTokens.brass.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HealTokens.brass.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            song.category!.toUpperCase(),
                            style: const TextStyle(
                              color: HealTokens.brass,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isCurrent && (isPlaying || isLoading)) ...[
                        const SizedBox(width: 8),
                        _NowPlayingBadge(isPlaying: isPlaying, isLoading: isLoading),
                      ],
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: HealTokens.cream,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                  if (song.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      song.subtitle,
                      style: TextStyle(
                        color: HealTokens.creamDim.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isPlaying
              ? HealTokens.brass
              : HealTokens.brass.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HealTokens.brass.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: HealTokens.oxblood,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: HealTokens.oxblood,
                size: 32,
              ),
      ),
    ).animate(target: isPlaying ? 1 : 0, duration: 300.ms).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
        );
  }
}

class _NowPlayingBadge extends StatelessWidget {
  const _NowPlayingBadge({required this.isPlaying, required this.isLoading});
  final bool isPlaying;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final label = isLoading
        ? 'Loading…'
        : isPlaying
            ? 'Playing'
            : 'Paused';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: HealTokens.oxblood.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HealTokens.brass.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlaying) ...[
            // Tiny bouncing bars
            _AudioBars(),
            const SizedBox(width: 6),
          ] else if (isLoading) ...[
            const SizedBox(
              width: 8, height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: HealTokens.brass,
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            const Icon(Icons.pause_circle_outline_rounded,
                color: HealTokens.brass, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: HealTokens.brass,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioBars extends StatefulWidget {
  @override
  State<_AudioBars> createState() => _AudioBarsState();
}

class _AudioBarsState extends State<_AudioBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value + i * 0.33) % 1.0;
            final h = 4 + (phase < 0.5 ? phase * 12 : (1 - phase) * 12);
            return Container(
              width: 2,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: HealTokens.brass,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SongScriptBody extends StatelessWidget {
  final PraiseSong song;
  const _SongScriptBody({required this.song});

  @override
  Widget build(BuildContext context) {
    final lines = song.lyrics.split('\n');
    final sections = _parseScript(lines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scripture refs
        if (song.scriptureRefs.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: HealTokens.brass.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HealTokens.brass.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: HealTokens.brass, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.scriptureRefs.join(' · '),
                    style: const TextStyle(
                      color: HealTokens.brass,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
        ],
        // Description block
        if (song.description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HealTokens.rosewood.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: HealTokens.brass.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              song.description,
              style: const TextStyle(
                color: HealTokens.cream,
                fontSize: 15,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),
        ],
        // Lyrics script
        // (Hymns marked with _hasRealLyrics=false were auto-generated
        //  TTS placeholders. We hide them and show a card explaining.)
        if (_hasRealLyrics(song)) ...[
          ...sections.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return _ScriptSection(section: s, delay: 50 * i)
              .animate()
              .fadeIn(delay: (100 + 50 * i).ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0);
        }),
        ] else ...[
          const _NoLyricsCard(),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 32),
        // Reflection
        if (song.reflection.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HealTokens.rosewood.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HealTokens.brass.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.format_quote_rounded,
                        color: HealTokens.brass, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Reflection',
                      style: TextStyle(
                        color: HealTokens.brass,
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  song.reflection,
                  style: TextStyle(
                    color: HealTokens.cream.withValues(alpha: 0.92),
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
        // Chords (if present)
        if (song.chords.isNotEmpty) ...[
          _ChordsBlock(chords: song.chords),
          const SizedBox(height: 28),
        ],
        // Bottom: actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ShareButton(song: song),
            const SizedBox(width: 16),
            _FavoriteButton(song: song),
          ],
        ),
      ],
    );
  }
}

class _ChordsBlock extends StatefulWidget {
  const _ChordsBlock({required this.chords});
  final String chords;

  @override
  State<_ChordsBlock> createState() => _ChordsBlockState();
}

class _ChordsBlockState extends State<_ChordsBlock> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HealTokens.rosewood.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded,
                      color: HealTokens.brass, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Chords & harmony',
                    style: TextStyle(
                      color: HealTokens.brass,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: HealTokens.brass,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.chords,
                style: TextStyle(
                  color: HealTokens.cream.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScriptSection extends StatelessWidget {
  final _ScriptSectionData section;
  final int delay;
  const _ScriptSection({required this.section, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (Verse 1, Chorus, etc.)
          if (section.header != null) ...[
            Text(
              section.header!,
              style: TextStyle(
                color: HealTokens.brass.withValues(alpha: 0.9),
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Lines
          for (final line in section.lines) ...[
            if (line.isEmpty)
              const SizedBox(height: 12)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: HealTokens.cream,
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ScriptSectionData {
  final String? header;
  final List<String> lines;
  _ScriptSectionData({this.header, required this.lines});
}

/// Heuristic: real lyrics contain verse markers like [Verse 1] or
/// distinct poetic lines. Auto-generated TTS placeholders contain
/// "sing the song of" or "all my days, all my days" — TTS vocal
/// stem boilerplate from the original audio mix.
bool _hasRealLyrics(PraiseSong song) {
  final l = song.lyrics;
  if (l.isEmpty) return false;
  if (l.contains('sing the song of') || l.contains('all my days, all my days')) {
    return false;
  }
  return true;
}

class _NoLyricsCard extends StatelessWidget {
  const _NoLyricsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HealTokens.rosewood.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: HealTokens.brass.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headphones_rounded, color: HealTokens.brass, size: 22),
              SizedBox(width: 10),
              Text(
                'Listen to this hymn',
                style: TextStyle(
                  color: HealTokens.cream,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The full text of this traditional hymn is in the public domain, '
            'and many beautiful versions exist. The version here is a sung '
            'lead — press play above to listen, or read the original on any '
            'hymnal site.',
            style: TextStyle(
              color: HealTokens.creamDim,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

List<_ScriptSectionData> _parseScript(List<String> lines) {
  final sections = <_ScriptSectionData>[];
  String? currentHeader;
  final currentLines = <String>[];

  void flush() {
    if (currentHeader != null || currentLines.isNotEmpty) {
      sections.add(_ScriptSectionData(
        header: currentHeader,
        lines: List.from(currentLines),
      ));
    }
    currentHeader = null;
    currentLines.clear();
  }

  final headerRegex = RegExp(r'^\s*\[(.+?)\]\s*$');
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) {
      currentLines.add('');
      continue;
    }
    final m = headerRegex.firstMatch(line);
    if (m != null) {
      // New section: flush the previous one.
      flush();
      currentHeader = m.group(1)!.toUpperCase();
    } else {
      currentLines.add(line);
    }
  }
  flush();
  return sections;
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.song});
  final PraiseSong song;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        // Build a simple share text — title + subtitle + URL.
        final url = 'https://heal.positiveness.club/praise/${song.slug}';
        final text = '${song.title} — ${song.subtitle}\n\n$url';
        try {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('Share failed: $e');
          }
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.ios_share_rounded, color: HealTokens.brass, size: 18),
            SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                color: HealTokens.brass,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.song});
  final PraiseSong song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesServiceProvider);
    final isFav = favs.contains('praise', song.slug);
    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        await ref.read(favoritesServiceProvider.notifier).toggle('praise', song.slug);
        unawaited(ref.read(analyticsServiceProvider).log(
          AnalyticsEvent(
            isFav ? HealEvents.favoriteRemoved : HealEvents.favoriteAdded,
            params: {'kind': 'praise', 'slug': song.slug},
          ),
        ));
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: HealTokens.brass,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isFav ? 'In your list' : 'Add to list',
              style: const TextStyle(
                color: HealTokens.brass,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Local cache helpers ───────────────────────────────────────────
class SongLocalCache {
  static Future<void> _cacheSong(PraiseSong song) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/praise-${song.slug}.json');
    final json = {
      'id': song.id,
      'title': song.title,
      'subtitle': song.subtitle,
      'lyrics': song.lyrics,
      'reflection': song.reflection,
      'chords': song.chords,
      'scripture_refs': song.scriptureRefs,
      'category': song.category,
      'key_signature': song.keySignature,
      'meter': song.meter,
      'tempo_bpm': song.tempoBpm,
      'audio_url': song.audioUrl,
      'illustration_url': song.illustrationUrl,
      'cached_at': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(json), flush: true);
  } catch (_) {
    // Silent — caching is best-effort.
  }
  }
}

// (kDebugMode imported from flutter/foundation above)
