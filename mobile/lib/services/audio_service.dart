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
import 'package:audioplayers/audioplayers.dart' hide AVAudioSessionCategory;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_error.dart';

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
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _errorSub;

  /// Hook for callers to react to track completion (e.g. record session).
  void Function(AudioTrack track, int durationSeconds)? onTrackComplete;

  AudioPlayer get player => _player;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);

    // Single position listener: updates state.position AND drives fade-out.
    // (Previously had two listeners on onPositionChanged, which double-updated
    // state every 200ms and wasted frames.)
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      final dur = state.duration;
      state = state.copyWith(position: pos);
      if (dur <= Duration.zero) return;

      final remaining = dur - pos;
      const fadeWindow = Duration(seconds: 4);
      if (remaining > Duration.zero && remaining <= fadeWindow) {
        // Inside fade window: ease volume down toward 0 with cubic curve.
        final ratio = remaining.inMilliseconds / fadeWindow.inMilliseconds;
        final eased = ratio * ratio * ratio;
        _player.setVolume(eased.clamp(0.0, 1.0));
      } else if (remaining > fadeWindow && !_volumeWasFaded) {
        // Outside fade window: restore full volume ONCE per fade-cycle.
        _player.setVolume(1.0);
        _volumeWasFaded = false;
      }
    });

    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      state = state.copyWith(duration: d);
    });

    _stateSub = _player.onPlayerStateChanged.listen((ps) {
      if (!mounted) return;
      state = state.copyWith(
        playing: ps == PlayerState.playing,
        loading: ps == PlayerState.playing ? false : state.loading,
      );
    });

    // Asynchronous error stream: errors that happen AFTER setSource()
    // (e.g. mid-playback network drop, codec crash). The synchronous catch
    // around _player.play only catches errors thrown during setSource().
    _errorSub = _player.onPlayerError.listen((err) {
      if (!mounted) return;
      if (kDebugMode) print('AudioService.onPlayerError: $err');
      final ae = AudioError.from(err);
      _lastError = ae;
      state = state.copyWith(
        error: ae.userMessage,
        playing: false,
        loading: false,
      );
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      // Restore volume for the next track
      _player.setVolume(1.0);
      _volumeWasFaded = false;
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
        // ignore: discarded_futures
        _playIndex(state.queueIndex + 1);
      }
    });
  }

  bool _volumeWasFaded = false;

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
      final ae = AudioError.from(e);
      state = state.copyWith(
        error: ae.userMessage,
        playing: false,
        loading: false,
      );
      // Stash the structured error so the UI can react (retry / next).
      _lastError = ae;
    }
  }

  AudioError? _lastError;

  /// Structured error from the most recent play failure.
  /// Cleared when the user starts a new play or dismisses.
  AudioError? get lastError => _lastError;
  void clearError() {
    _lastError = null;
    state = state.copyWith(clearError: true);
  }

  /// Replay the last requested track. Used by the recovery CTA.
  Future<void> retry() async {
    if (state.inPlaylist && state.queueIndex >= 0) {
      await _playIndex(state.queueIndex);
    } else if (state.track != null) {
      await play(state.track!);
    }
  }

  /// Skip to the next track in the queue. Used by the recovery CTA when
  /// the current track is broken.
  Future<void> nextOrStop() async {
    if (state.hasNext) {
      await _playIndex(state.queueIndex + 1);
    } else {
      await stop();
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
    catch (e) {
      final ae = AudioError.from(e);
      state = state.copyWith(error: ae.userMessage);
      _lastError = ae;
    }
  }

  Future<void> resume() async {
    try { await _player.resume(); }
    catch (e) {
      final ae = AudioError.from(e);
      state = state.copyWith(error: ae.userMessage);
      _lastError = ae;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      state = const AudioState();
    } catch (e) {
      final ae = AudioError.from(e);
      state = state.copyWith(error: ae.userMessage);
      _lastError = ae;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      state = state.copyWith(position: position);
    } catch (e) {
      final ae = AudioError.from(e);
      state = state.copyWith(error: ae.userMessage);
      _lastError = ae;
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
      final ae = AudioError.from(e);
      state = state.copyWith(error: ae.userMessage);
      _lastError = ae;
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
    // _posSub consolidated into _positionSub
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _positionSub?.cancel();
    _errorSub?.cancel();
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
