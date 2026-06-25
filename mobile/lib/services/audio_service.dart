// HEAL — Audio service.
// Single audio source, observable state, background-capable.
//
// Wraps audioplayers with:
//   - progress stream
//   - completion callbacks
//   - speed control
//   - resume from last position
//   - skip ±15s
//   - lockscreen metadata (basic; full controls would need just_audio_background)

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
  final AudioSource source;
  final Duration? startAt;

  const AudioTrack({
    required this.id,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.illustrationUrl,
    required this.source,
    this.startAt,
  });
}

class AudioState {
  final AudioTrack? track;
  final bool playing;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? error;

  const AudioState({
    this.track,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.error,
  });

  bool get hasTrack => track != null;
  bool get isComplete =>
      duration > Duration.zero && position >= duration - const Duration(milliseconds: 200);

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioState copyWith({
    AudioTrack? track,
    bool? playing,
    Duration? position,
    Duration? duration,
    double? speed,
    String? error,
    bool clearError = false,
  }) {
    return AudioState(
      track: track ?? this.track,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      error: clearError ? null : (error ?? this.error),
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
  /// Receives (track, durationSeconds) when a track completes naturally.
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
      state = state.copyWith(playing: ps == PlayerState.playing);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final completedTrack = state.track;
      final durationSec = state.duration.inSeconds;
      state = state.copyWith(
        playing: false,
        position: state.duration,
      );
      // Fire completion hook (set by caller via onTrackComplete)
      if (completedTrack != null && durationSec > 0) {
        onTrackComplete?.call(completedTrack, durationSec);
      }
    });
  }

  Future<void> play(AudioTrack track) async {
    if (state.track?.id != track.id) {
      // New track
      state = AudioState(track: track, playing: true);
      try {
        await _player.play(UrlSource(track.url));
        if (track.startAt != null) {
          await _player.seek(track.startAt!);
        }
      } catch (e) {
        if (kDebugMode) print('AudioService.play error: $e');
        state = state.copyWith(error: e.toString(), playing: false);
      }
    } else {
      // Same track — resume
      await resume();
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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
  // Fire-and-forget init — caller can await if needed
  // ignore: discarded_futures
  svc.init();
  return svc;
});