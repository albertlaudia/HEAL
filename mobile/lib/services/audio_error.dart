// HEAL — Audio error classification.
//
// Translates raw audioplayers / network / codec errors into categories the UI
// can act on. We never show a stack trace to the user; we show a one-line
// copy string + a recovery action (retry / go offline / open settings).
//
// The category lives in `AudioErrorCode` so listeners can branch on it
// without parsing strings.

import 'dart:io' show SocketException, HttpException;

/// Coarse category the UI uses to pick copy + recovery action.
enum AudioErrorCode {
  /// No internet, DNS failed, or server unreachable.
  noNetwork,

  /// Server replied but with a 4xx/5xx (e.g. 404, 403, 5xx).
  serverError,

  /// File found but the audio codec could not be decoded (corrupt, wrong format,
  /// unsupported container, partial download).
  decodeFailed,

  /// Permission for the audio device is denied or session was lost.
  /// On iOS: AVAudioSession interruption. On Android: AudioFocus loss.
  sessionLost,

  /// Catch-all for unexpected cases. We still want to say *something* kind.
  unknown,
}

class AudioError {
  final AudioErrorCode code;
  final String rawMessage;     // for the dev log
  final String userMessage;    // one-line copy in reverent tone
  final String? recoveryLabel; // optional CTA on the player
  final bool canRetry;
  final DateTime at;

  const AudioError({
    required this.code,
    required this.rawMessage,
    required this.userMessage,
    this.recoveryLabel,
    this.canRetry = true,
    required this.at,
  });

  /// Classify any thrown object into an [AudioError].
  ///
  /// Heuristic order matters: we check for network first, then HTTP status
  /// strings, then codec/decoder phrases, then session-lost phrases, and
  /// fall through to unknown. Each tier is matched with case-insensitive
  /// substring search since the underlying message text varies by platform.
  factory AudioError.from(Object? throwable) {
    final raw = throwable?.toString() ?? 'Unknown error';
    final lower = raw.toLowerCase();

    AudioErrorCode code;
    String userMessage;
    String? recoveryLabel;

    if (throwable is SocketException ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection closed') ||
        lower.contains('clientexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('timeout exceeded') ||
        lower.contains('software caused connection abort')) {
      code = AudioErrorCode.noNetwork;
      userMessage =
          "I can't reach the internet right now. Try again, or play a song you've already downloaded.";
      recoveryLabel = 'Try again';
    } else if (lower.contains('404') ||
        lower.contains('403') ||
        lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('http status') ||
        lower.contains('server returned')) {
      code = AudioErrorCode.serverError;
      userMessage =
          "This sound couldn't be loaded. It may be missing from our library. Try the next one.";
      recoveryLabel = 'Try the next track';
    } else if (lower.contains('decoder') ||
        lower.contains('codec') ||
        lower.contains('unsupported format') ||
        lower.contains('mediacodec') ||
        lower.contains('media source') ||
        lower.contains('media error') ||
        lower.contains('format error') ||
        lower.contains('audioplayer.prepare')) {
      code = AudioErrorCode.decodeFailed;
      userMessage =
          "This sound is here, but my player can't open it. Try the next track or download it again.";
      recoveryLabel = 'Try the next track';
    } else if (lower.contains('audio focus') ||
        lower.contains('audiofocus') ||
        lower.contains('audio session') ||
        lower.contains('avaudiosession') ||
        lower.contains('interrupted') ||
        lower.contains('busy')) {
      code = AudioErrorCode.sessionLost;
      userMessage =
          "Another app is using your audio right now. Stop it, then tap play to come back here.";
      recoveryLabel = 'Try again';
    } else {
      code = AudioErrorCode.unknown;
      userMessage =
          "Something gentle went wrong. Take a breath — try again, or try another track.";
      recoveryLabel = 'Try again';
    }

    return AudioError(
      code: code,
      rawMessage: raw,
      userMessage: userMessage,
      recoveryLabel: recoveryLabel,
      at: DateTime.now(),
    );
  }

  /// True if the user has any actionable path forward.
  bool get hasRecovery => recoveryLabel != null;
}

/// Pre-typed so callers can be explicit (e.g. offlineCache miss).
class AudioErrors {
  static AudioError offlineCacheMiss() => AudioError(
        code: AudioErrorCode.serverError,
        rawMessage: 'offline cache miss',
        userMessage:
            "This track isn't downloaded for offline yet. Connect to Wi-Fi to play it for the first time, or pick another from your library.",
        recoveryLabel: 'Try again',
        at: DateTime.now(),
      );
}
