// HEAL — Timed lyrics parser.
// Splits lyrics into [(timestamp, text)] pairs using estimated durations.
//
// The Praise collection stores lyrics as plain text with optional [Verse]
// markers — no timestamps. We estimate per-line duration from character count
// (rough proxy for singing time) so karaoke-style highlighting works without
// requiring manual timecoding of 100 songs.
//
// Estimation: ~13 chars/sec for sung English lyrics. Verse intros (instrumental
// breaks) get a 1.5s gap. Section tags ([Chorus], [Bridge]) pad by 0.4s.
//
// Returns a flat List<_TimedLine> with absolute offsets from start of song.

class TimedLine {
  final double startSec;
  final double endSec;
  final String text;
  final String? section;     // e.g. "Chorus" — for [Chorus] / [Verse 2] tags
  final bool isBlank;        // spacer between lines (gap)

  const TimedLine({
    required this.startSec,
    required this.endSec,
    required this.text,
    this.section,
    this.isBlank = false,
  });

  bool contains(double positionSec) =>
      positionSec >= startSec && positionSec < endSec;
}

class TimedLyrics {
  final List<TimedLine> lines;
  final double totalSec;

  const TimedLyrics({required this.lines, required this.totalSec});

  int indexAt(double positionSec) {
    if (lines.isEmpty) return -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(positionSec)) return i;
    }
    // If past the end, return last line
    if (positionSec >= lines.last.endSec) return lines.length - 1;
    return -1;
  }
}

class TimedLyricsParser {
  /// Approx chars/sec for sung English lyrics.
  static const double _charsPerSec = 13.0;

  /// Add this much silence at the start of every verse (instrumental intro feel).
  static const double _verseGap = 1.5;

  /// Add this much between section tags ([Chorus], etc).
  static const double _sectionPad = 0.4;

  /// Min duration for any line (so 2-word lines don't flash).
  static const double _minLine = 1.4;

  /// Max duration (so a 5-min song doesn't claim a 12-min line).
  static const double _maxLine = 6.0;

  static TimedLyrics parse(String raw) {
    if (raw.trim().isEmpty) return const TimedLyrics(lines: [], totalSec: 0);
    final out = <TimedLine>[];
    double t = 0;

    final lines = raw.split('\n');

    for (var li = 0; li < lines.length; li++) {
      final rawLine = lines[li];
      final trimmed = rawLine.trim();

      // Section tag: [Verse 1], [Chorus], [Bridge], etc.
      final tagMatch = RegExp(r'^\[(.+?)\]$').firstMatch(trimmed);
      if (tagMatch != null) {
        final tag = tagMatch.group(1)!;
        out.add(TimedLine(
          startSec: t,
          endSec: t + _sectionPad,
          text: tag,
          section: tag,
          isBlank: true,
        ));
        t += _sectionPad;
        // Detect "Verse N" / start-of-verse → add an instrumental lead-in
        if (tag.toLowerCase().contains('verse') ||
            li == 0 ||
            _previousTagWasSection(lines, li)) {
          t += _verseGap;
          out.add(TimedLine(
            startSec: t - 0.01,
            endSec: t,
            text: '',
            isBlank: true,
          ));
        }
        continue;
      }

      // Empty line → short silence
      if (trimmed.isEmpty) {
        out.add(TimedLine(
          startSec: t,
          endSec: t + 0.4,
          text: '',
          isBlank: true,
        ));
        t += 0.4;
        continue;
      }

      // Real lyric line: duration = max(_minLine, min(_maxLine, chars / cps))
      final secs = (trimmed.length / _charsPerSec)
          .clamp(_minLine, _maxLine)
          .toDouble();
      out.add(TimedLine(
        startSec: t,
        endSec: t + secs,
        text: trimmed,
      ));
      t += secs;
    }

    return TimedLyrics(lines: out, totalSec: t);
  }

  static bool _previousTagWasSection(List<String> lines, int idx) {
    for (var j = idx - 1; j >= 0; j--) {
      final t = lines[j].trim();
      if (t.isEmpty) continue;
      return RegExp(r'^\[.+?\]$').hasMatch(t);
    }
    return false;
  }
}
