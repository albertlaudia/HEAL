// HEAL — Karaoke-style lyrics view.
// Renders timed lyrics with the active line highlighted, auto-scrolling
// the current line to the vertical centre of the viewport.
//
// Usage:
//   KaraokeLyrics(
//     timed: TimedLyricsParser.parse(song.lyrics),
//     position: audioState.position,
//     onSeek: (sec) => audioService.seek(Duration(seconds: sec.toInt())),
//   )

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'timed_lyrics.dart';

class KaraokeLyrics extends StatefulWidget {
  final TimedLyrics timed;
  final Duration position;
  final void Function(double seconds)? onSeek;

  const KaraokeLyrics({
    super.key,
    required this.timed,
    required this.position,
    this.onSeek,
  });

  @override
  State<KaraokeLyrics> createState() => _KaraokeLyricsState();
}

class _KaraokeLyricsState extends State<KaraokeLyrics> {
  late final ScrollController _scroll;
  final Map<int, GlobalKey> _keys = {};
  int _centeredIndex = -1;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    for (var i = 0; i < widget.timed.lines.length; i++) {
      _keys[i] = GlobalKey();
    }
    // Settle on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerActiveLine(force: true);
    });
  }

  @override
  void didUpdateWidget(KaraokeLyrics old) {
    super.didUpdateWidget(old);
    if (old.timed.lines.length != widget.timed.lines.length) {
      _keys.clear();
      for (var i = 0; i < widget.timed.lines.length; i++) {
        _keys[i] = GlobalKey();
      }
    }
    if (old.position != widget.position) {
      _centerActiveLine();
    }
  }

  void _centerActiveLine({bool force = false}) {
    final activeIdx = widget.timed.indexAt(widget.position.inMilliseconds / 1000.0);
    if (activeIdx < 0) return;
    if (!force && activeIdx == _centeredIndex) return;

    final key = _keys[activeIdx];
    final ctx = key?.currentContext;
    if (ctx == null || !_scroll.hasClients) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final viewport = RenderAbstractViewport.of(box);
    final offset = viewport.getOffsetToReveal(box, 0.5).offset;
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    setState(() => _centeredIndex = activeIdx);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.position.inMilliseconds / 1000.0;
    final activeIdx = widget.timed.indexAt(pos);
    final lines = widget.timed.lines;

    if (lines.isEmpty) {
      return Center(
        child: Text('No lyrics',
            style: TextStyle(color: HealTokens.creamDim, fontStyle: FontStyle.italic)),
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: HealTokens.s24,
        vertical: HealTokens.s120, // generous top/bottom so first/last line can centre
      ),
      itemCount: lines.length,
      itemBuilder: (_, i) {
        final l = lines[i];
        final isActive = i == activeIdx;
        return _LyricRow(
          key: _keys[i],
          line: l,
          active: isActive,
          onTap: l.isBlank || widget.onSeek == null
              ? null
              : () => widget.onSeek!(l.startSec),
        );
      },
    );
  }
}

class _LyricRow extends StatelessWidget {
  final TimedLine line;
  final bool active;
  final VoidCallback? onTap;
  const _LyricRow({super.key, required this.line, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Section tags (e.g. "Chorus")
    if (line.section != null) {
      return Padding(
        padding: const EdgeInsets.only(top: HealTokens.s32, bottom: HealTokens.s12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: HealTokens.s12, vertical: HealTokens.s4),
            decoration: BoxDecoration(
              color: HealTokens.brass.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              line.section!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: HealTokens.brassLight,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      );
    }

    // Blank / spacer line
    if (line.isBlank) {
      return const SizedBox(height: HealTokens.s16);
    }

    // Real lyric
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: HealTokens.s8,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: active
                    ? HealTokens.cream
                    : HealTokens.creamDim.withValues(alpha: 0.45),
                fontWeight: active ? FontWeight.w500 : FontWeight.w300,
                height: 1.4,
                fontSize: active ? 24 : 20,
                shadows: active
                    ? [
                        Shadow(
                          color: HealTokens.brass.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
          textAlign: TextAlign.center,
          child: Text(line.text),
        ),
      ),
    );
  }
}
