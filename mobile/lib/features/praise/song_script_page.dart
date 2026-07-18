// HEAL — Read the Song (lyrics-first view).
//
// When the user opens a praise song from the library, we navigate here
// instead of the audio player. Shows the full lyrics as a "script" with
// nice typography and section headers. Auto-favorites the song and caches
// the lyrics + illustration locally on first open.
//
// Why no audio: The hymn MP3s were AI-generated and didn't sound good.
// The lyrics are the actual content. Users can read the song, reflect on
// it, and share it. See HEAL/REMOVE_PRAISE_AUDIO_PLAN.md (2026-07-17).

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../core/time_palette.dart';
import '../../data/pb_models.dart';
import '../../data/pb_repositories.dart';
import '../../services/favorites_service.dart';
import '../../services/activity_tracker.dart';

/// Read the Song — full lyrics view with auto-cache and auto-favorite.
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

    // Track this engagement
    Future.microtask(() {
      try {
        ref.read(activityTrackerProvider.notifier).log(
          'praise_opened',
          meta: {'slug': song.slug, 'title': song.title},
        );
      } catch (_) {}
    });

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

class _SongHero extends StatelessWidget {
  final PraiseSong song;
  const _SongHero({required this.song});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
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
                  stops: const [0.4, 0.75, 1.0],
                ),
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
        ...sections.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return _ScriptSection(section: s, delay: 50 * i)
              .animate()
              .fadeIn(delay: (100 + 50 * i).ms, duration: 300.ms)
              .slideY(begin: 0.1, end: 0);
        }),
        const SizedBox(height: 32),
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
  final String? header; // "[Verse 1]" or null
  final List<String> lines;
  _ScriptSectionData(this.header, this.lines);
}

/// Parse lyrics into sections.
/// Recognizes [Verse 1], [Verse 2], [Chorus], [Bridge], etc. as headers.
/// Empty lines are preserved as paragraph breaks.
List<_ScriptSectionData> _parseScript(List<String> lines) {
  final sections = <_ScriptSectionData>[];
  String? currentHeader;
  final currentLines = <String>[];

  void flush() {
    if (currentLines.isNotEmpty || currentHeader != null) {
      sections.add(_ScriptSectionData(currentHeader, List.from(currentLines)));
    }
    currentHeader = null;
    currentLines.clear();
  }

  final headerRegex = RegExp(r'^\s*\[(.+?)\]\s*$');
  for (final raw in lines) {
    final line = raw.trimRight();
    final match = headerRegex.firstMatch(line);
    if (match != null) {
      // New section
      flush();
      currentHeader = line; // keep [Verse 1] format
    } else {
      currentLines.add(line.trimLeft());
    }
  }
  flush();
  return sections;
}

class _ShareButton extends StatelessWidget {
  final PraiseSong song;
  const _ShareButton({required this.song});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(
          text: '${song.title}\n\n${song.lyrics}',
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.ios_share_rounded, color: HealTokens.creamDim, size: 18),
      label: const Text('Share', style: TextStyle(color: HealTokens.creamDim)),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final PraiseSong song;
  const _FavoriteButton({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesServiceProvider);
    final isFav = favorites.contains('praise', song.slug);

    return TextButton.icon(
      onPressed: () {
        ref.read(favoritesServiceProvider.notifier).toggle('praise', song.slug);
      },
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFav ? HealTokens.brass : HealTokens.creamDim,
        size: 18,
      ),
      label: Text(
        isFav ? 'In your list' : 'Add to list',
        style: TextStyle(
          color: isFav ? HealTokens.brass : HealTokens.creamDim,
        ),
      ),
    );
  }
}

// ── Local cache for lyrics + illustration ───────────────────────

class SongLocalCache {
  /// Cache directory: <docs>/heal_songs/<slug>/
  static Future<Directory> _songDir(String slug) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/heal_songs/$slug');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Cache song lyrics + metadata locally. Idempotent.
  static Future<void> _cacheSong(PraiseSong song) async {
    try {
      final dir = await _songDir(song.slug);
      final meta = File('${dir.path}/meta.json');
      // Only write if not cached or content changed
      if (await meta.exists()) {
        try {
          final existing = jsonDecode(await meta.readAsString());
          if (existing is Map && existing['lyrics'] == song.lyrics) {
            return; // Already cached, content matches
          }
        } catch (_) {}
      }
      await meta.writeAsString(jsonEncode({
        'slug': song.slug,
        'title': song.title,
        'subtitle': song.subtitle,
        'description': song.description,
        'lyrics': song.lyrics,
        'category': song.category,
        'illustration': song.cdnIllustration,
        'cached_at': DateTime.now().toIso8601String(),
      }));
    } catch (_) {
      // Silent - caching is best-effort
    }
  }

  /// List all songs the user has opened (from local cache).
  static Future<List<Map<String, dynamic>>> openedSongs() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/heal_songs');
      if (!await dir.exists()) return [];
      final songs = <Map<String, dynamic>>[];
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final meta = File('${entity.path}/meta.json');
          if (await meta.exists()) {
            try {
              final data = jsonDecode(await meta.readAsString());
              if (data is Map<String, dynamic>) {
                songs.add(data);
              }
            } catch (_) {}
          }
        }
      }
      // Sort by cache time, most recent first
      songs.sort((a, b) {
        final aTime = a['cached_at'] as String? ?? '';
        final bTime = b['cached_at'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
      return songs;
    } catch (_) {
      return [];
    }
  }
}
