// HEAL — Audio service.
// Single audio source, observable state, background-capable.
//
// Wraps audioplayers with:
//   - progress stream
//   - completion callbacks
//   - speed control
//   - resume from last position
//   - skip ±15s
//   - playlist queue (auto-advance next/prev)
//   - offline-aware playback (DeviceFileSource if cached)
//   - loading flag (true between setSource() and onPlayerStateChanged(playing))

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AudioSource { meditation, praise, reference, custom }

class AudioTrack {
  final String id;
  final String url;
  final String title;
  final String subtitle;
  final String illustrationUrl;
  final String? lyrics;
  final AudioSource source;
  final Duration? startAt;

  const AudioTrack({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.illustrationUrl,
    required this.source,
    this.lyrics,
    this.startAt,
  });
}

class AudioState {
  final AudioTrack? track;
  final bool playing;
  final bool loading;          // true while setSource() resolves
  final Duration position;
  final Duration duration;
  final double speed;
  final String? error;

  /// Playlist context — when set, track-completion auto-advances.
  final List<AudioTrack> queue;
  final int queueIndex;

  /// Parallel list to `queue` of local file paths for tracks that are
  /// downloaded for offline playback. `queueLocalPaths[i]` corresponds to
  /// `queue[i]`. Empty string = use the URL.
  final List<String> queueLocalPaths;

  const AudioState({
    this.track,
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.error,
    this.queue = const [],
    this.queueIndex = -1,
    this.queueLocalPaths = const [],
  });

  bool get hasTrack => track != null;
  bool get isComplete =>
      duration > Duration.zero && position >= duration - const Duration(milliseconds: 200);

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get inPlaylist => queue.isNotEmpty;
  bool get hasNext => inPlaylist && queueIndex < queue.length - 1;
  bool get hasPrev => inPlaylist && queueIndex > 0;

  AudioState copyWith({
    AudioTrack? track,
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? duration,
    double? speed,
    String? error,
    List<AudioTrack>? queue,
    int? queueIndex,
    List<String>? queueLocalPaths,
    bool clearError = false,
  }) {
    return AudioState(
      track: track ?? this.track,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      error: clearError ? null : (error ?? this.error),
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      queueLocalPaths: queueLocalPaths ?? this.queueLocalPaths,
    );
  }
}

class AudioService extends StateNotifier<AudioState> {
  AudioService() : super(const AudioState());

  final AudioPlayer _player = AudioPlayer(playerId: 'heal_main');
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  /// Hook for callers to react to track completion (e.g. record session).
  void Function(AudioTrack track, int durationSeconds)? onTrackComplete;

  AudioPlayer get player => _player;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);

    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      state = state.copyWith(position: p);
    });

    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      state = state.copyWith(duration: d);
    });

    _stateSub = _player.onPlayerStateChanged.listen((ps) {
      if (!mounted) return;
      state = state.copyWith(
        playing: ps == PlayerState.playing,
        // loading clears once we know we're playing OR we've stopped (failed)
        loading: ps == PlayerState.playing ? false : state.loading,
      );
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final completedTrack = state.track;
      final durationSec = state.duration.inSeconds;
      state = state.copyWith(
        playing: false,
        position: state.duration,
        loading: false,
      );
      if (completedTrack != null && durationSec > 0) {
        onTrackComplete?.call(completedTrack, durationSec);
      }
      // Auto-advance playlist
      if (state.hasNext) {
        // Don't await — let the UI update naturally
        // ignore: discarded_futures
        _playIndex(state.queueIndex + 1);
      }
    });
  }

  /// Play a single track (no playlist context).
  Future<void> play(AudioTrack track) async {
    await _playInternal(track, queue: const [], index: -1);
  }

  /// Play a track as part of a playlist queue. Auto-advances on completion.
  /// `localPaths` is an optional parallel list of local file paths for
  /// offline-cached tracks. Empty strings mean "use the URL".
  Future<void> playPlaylist(
    List<AudioTrack> queue,
    int index, {
    List<String> localPaths = const [],
  }) async {
    if (index < 0 || index >= queue.length) return;
    final path = index < localPaths.length ? localPaths[index] : '';
    await _playInternal(
      queue[index],
      queue: queue,
      index: index,
      localPath: path.isEmpty ? null : path,
      queueLocalPaths: localPaths,
    );
  }

  Future<void> _playInternal(
    AudioTrack track, {
    required List<AudioTrack> queue,
    required int index,
    String? localPath,
    List<String> queueLocalPaths = const [],
  }) async {
    final isNewTrack = state.track?.id != track.id;
    state = state.copyWith(
      track: track,
      loading: true,
      position: Duration.zero,
      duration: Duration.zero,
      playing: false,
      queue: queue,
      queueIndex: index,
      queueLocalPaths: queueLocalPaths,
      clearError: true,
    );

    try {
      if (localPath != null) {
        await _player.play(DeviceFileSource(localPath));
      } else {
        await _player.play(UrlSource(track.url));
      }
      if (track.startAt != null) {
        await _player.seek(track.startAt!);
      }
      if (!isNewTrack) {
        // Resumed an already-loaded track — loading should already be false
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      if (kDebugMode) print('AudioService.play error: $e');
      state = state.copyWith(error: e.toString(), playing: false, loading: false);
    }
  }

  Future<void> _playIndex(int index) async {
    if (!state.inPlaylist) return;
    if (index < 0 || index >= state.queue.length) return;
    final t = state.queue[index];
    final localPath = index < state.queueLocalPaths.length
        ? state.queueLocalPaths[index]
        : '';
    state = state.copyWith(queueIndex: index);
    await _playInternal(
      t,
      queue: state.queue,
      index: index,
      localPath: localPath.isEmpty ? null : localPath,
      queueLocalPaths: state.queueLocalPaths,
    );
  }

  Future<void> next() async {
    if (state.hasNext) await _playIndex(state.queueIndex + 1);
  }

  Future<void> prev() async {
    if (state.hasPrev) await _playIndex(state.queueIndex - 1);
  }

  Future<void> pause() async {
    try { await _player.pause(); }
    catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> resume() async {
    try { await _player.resume(); }
    catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      state = const AudioState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      state = state.copyWith(position: position);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipForward(Duration by) async {
    final newPos = state.position + by;
    final max = state.duration == Duration.zero ? newPos : state.duration;
    await seek(newPos > max ? max : newPos);
  }

  Future<void> skipBack(Duration by) async {
    final newPos = state.position - by;
    await seek(newPos.isNegative ? Duration.zero : newPos);
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setPlaybackRate(speed);
      state = state.copyWith(speed: speed);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePlay() async {
    if (state.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioServiceProvider =
    StateNotifierProvider<AudioService, AudioState>((ref) {
  final svc = AudioService();
  // ignore: discarded_futures
  svc.init();
  return svc;
});
