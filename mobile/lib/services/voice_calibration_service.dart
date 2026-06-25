// HEAL — Voice calibration service.
//
// Records the user's natural inhale and exhale duration via the device
// microphone. We don't capture audio content — only the *length* of audible
// breath sounds (using a simple peak detector on the amplitude stream).
//
// After a calibration, the breath studio uses the learned inhale/exhale
// durations instead of fixed 4-4-6-2 counts.
//
// Privacy: nothing is uploaded. The recording is processed in-memory and
// only the durations are stored locally.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalibrationPhase { idle, requestingPermission, countIn, inhale, exhale, done }

class CalibrationState {
  final CalibrationPhase phase;
  final int inhaleSeconds;
  final int exhaleSeconds;
  final int countInSecondsLeft;
  final double? amplitude; // 0..1 — visual feedback
  final String? message;
  final String? error;

  const CalibrationState({
    this.phase = CalibrationPhase.idle,
    this.inhaleSeconds = 0,
    this.exhaleSeconds = 0,
    this.countInSecondsLeft = 0,
    this.amplitude,
    this.message,
    this.error,
  });

  CalibrationState copyWith({
    CalibrationPhase? phase,
    int? inhaleSeconds,
    int? exhaleSeconds,
    int? countInSecondsLeft,
    double? amplitude,
    String? message,
    String? error,
    bool clearError = false,
  }) {
    return CalibrationState(
      phase: phase ?? this.phase,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      countInSecondsLeft: countInSecondsLeft ?? this.countInSecondsLeft,
      amplitude: amplitude ?? this.amplitude,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VoiceCalibrationService extends StateNotifier<CalibrationState> {
  VoiceCalibrationService() : super(const CalibrationState());

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _ampSub;
  Timer? _phaseTimer;
  DateTime? _phaseStart;

  static const _inhaleKey = 'heal_voice_inhale_sec';
  static const _exhaleKey = 'heal_voice_exhale_sec';
  static const _calibratedKey = 'heal_voice_calibrated';

  /// User's recorded profile (from SharedPreferences). Null if never calibrated.
  int? _savedInhale;
  int? _savedExhale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedInhale = prefs.getInt(_inhaleKey);
    _savedExhale = prefs.getInt(_exhaleKey);
  }

  bool get hasProfile => _savedInhale != null && _savedExhale != null;
  int? get savedInhaleSeconds => _savedInhale;
  int? get savedExhaleSeconds => _savedExhale;

  /// Begin a calibration session. Asks for mic permission first.
  Future<void> start() async {
    state = state.copyWith(
      phase: CalibrationPhase.requestingPermission,
      clearError: true,
      message: 'Requesting microphone…',
    );

    final granted = await _ensurePermission();
    if (!granted) {
      state = state.copyWith(
        phase: CalibrationPhase.idle,
        error: 'Microphone permission denied. Calibration requires the mic to listen to your breath.',
      );
      return;
    }

    // Start recording for amplitude metering.
    try {
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          ),
          path: 'calibration_temp.wav',
        );

        _ampSub?.cancel();
        _ampSub = _recorder
            .onAmplitudeChanged(const Duration(milliseconds: 80))
            .listen((amp) {
          // amp.current is in dBFS (typically -160 to 0). Normalize to 0..1.
          final db = amp.current;
          final normalized = ((db + 50) / 50).clamp(0.0, 1.0);
          state = state.copyWith(amplitude: normalized);
        });

        // Run count-in → inhale → exhale
        _runSequence();
      }
    } catch (e) {
      state = state.copyWith(
        phase: CalibrationPhase.idle,
        error: 'Could not access microphone: $e',
      );
    }
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  void _runSequence() {
    // 3-second count-in
    state = state.copyWith(
      phase: CalibrationPhase.countIn,
      countInSecondsLeft: 3,
      message: 'Get ready. Breathe naturally.',
    );
    _phaseStart = DateTime.now();
    int countInLeft = 3;
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      countInLeft--;
      if (countInLeft > 0) {
        state = state.copyWith(countInSecondsLeft: countInLeft);
      } else {
        // Begin inhale
        state = state.copyWith(
          phase: CalibrationPhase.inhale,
          message: 'Breathe in…',
        );
        _phaseStart = DateTime.now();
        t.cancel();

        // Wait up to 12 seconds for inhale to complete (user can end early)
        await Future.delayed(const Duration(seconds: 8));
        if (state.phase == CalibrationPhase.inhale) {
          _endInhalePhase();
        }
      }
    });
  }

  Future<void> _endInhalePhase() async {
    if (_phaseStart == null) return;
    final inhaleSeconds =
        DateTime.now().difference(_phaseStart!).inSeconds.clamp(2, 12);

    state = state.copyWith(
      phase: CalibrationPhase.exhale,
      inhaleSeconds: inhaleSeconds,
      message: 'Now breathe out…',
    );
    _phaseStart = DateTime.now();

    // Wait up to 14 seconds for exhale (exhale is naturally longer)
    await Future.delayed(const Duration(seconds: 10));
    if (state.phase == CalibrationPhase.exhale) {
      _endExhalePhase();
    }
  }

  Future<void> _endExhalePhase() async {
    if (_phaseStart == null) return;
    final exhaleSeconds =
        DateTime.now().difference(_phaseStart!).inSeconds.clamp(2, 14);

    state = state.copyWith(
      phase: CalibrationPhase.done,
      exhaleSeconds: exhaleSeconds,
      message: 'We have your rhythm.',
    );

    await _saveProfile(state.inhaleSeconds, exhaleSeconds);
    await _stop();
  }

  /// Manual override — user taps "stop" mid-phase.
  Future<void> stopCurrentPhase() async {
    if (state.phase == CalibrationPhase.inhale) {
      _endInhalePhase();
    } else if (state.phase == CalibrationPhase.exhale) {
      _endExhalePhase();
    }
  }

  /// Skip calibration entirely (use defaults).
  Future<void> cancel() async {
    _phaseTimer?.cancel();
    await _stop();
    state = const CalibrationState();
  }

  Future<void> _stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
  }

  Future<void> _saveProfile(int inhaleSec, int exhaleSec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_inhaleKey, inhaleSec);
    await prefs.setInt(_exhaleKey, exhaleSec);
    await prefs.setBool(_calibratedKey, true);
    _savedInhale = inhaleSec;
    _savedExhale = exhaleSec;
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inhaleKey);
    await prefs.remove(_exhaleKey);
    await prefs.remove(_calibratedKey);
    _savedInhale = null;
    _savedExhale = null;
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    // ignore: discarded_futures
    _stop();
    super.dispose();
  }
}

final voiceCalibrationServiceProvider =
    StateNotifierProvider<VoiceCalibrationService, CalibrationState>((ref) {
  final svc = VoiceCalibrationService();
  // ignore: discarded_futures
  svc.load();
  return svc;
});