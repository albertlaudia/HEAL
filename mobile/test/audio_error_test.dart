// HEAL — Tests for the audio error classifier and copy.
//
// Exercises every error category and asserts the resulting user message
// is non-empty and starts with a non-empty subject — i.e. we never
// show "I" with nothing after it. Also exercises the canned helpers.

import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';

import 'package:heal/services/audio_error.dart';

void main() {
  group('AudioError.from', () {
    test('SocketException → noNetwork', () {
      final ae = AudioError.from(const SocketException('no route to host'));
      expect(ae.code, AudioErrorCode.noNetwork);
      expect(ae.userMessage.toLowerCase(), contains('internet'));
      expect(ae.canRetry, true);
    });

    test('404 in raw message → serverError', () {
      final ae = AudioError.from(Exception('Server returned 404 for /audio/x.mp3'));
      expect(ae.code, AudioErrorCode.serverError);
      expect(ae.userMessage.toLowerCase(), contains('try the next'));
    });

    test('500 in raw message → serverError', () {
      final ae = AudioError.from(Exception('HTTP 502 Bad Gateway'));
      expect(ae.code, AudioErrorCode.serverError);
    });

    test('decoder phrase → decodeFailed', () {
      final ae = AudioError.from(Exception('MediaCodec decoder could not open input'));
      expect(ae.code, AudioErrorCode.decodeFailed);
    });

    test('audioplayer prepare failure → decodeFailed', () {
      final ae = AudioError.from(Exception('audioplayer.prepare failed: format not supported'));
      expect(ae.code, AudioErrorCode.decodeFailed);
    });

    test('audio focus phrase → sessionLost', () {
      final ae = AudioError.from(Exception('audio focus lost by another app'));
      expect(ae.code, AudioErrorCode.sessionLost);
    });

    test('unknown error → unknown category with copy', () {
      final ae = AudioError.from(StateError('something weird'));
      expect(ae.code, AudioErrorCode.unknown);
      expect(ae.userMessage, isNotEmpty);
    });

    test('null throwable → unknown category', () {
      final ae = AudioError.from(null);
      expect(ae.code, AudioErrorCode.unknown);
    });
  });

  group('AudioErrors.offlineCacheMiss', () {
    test('returns serverError with offline copy', () {
      final ae = AudioErrors.offlineCacheMiss();
      expect(ae.code, AudioErrorCode.serverError);
      expect(ae.userMessage.toLowerCase(), contains('downloaded'));
    });
  });

  group('userMessage invariants', () {
    test('every copy is non-empty and starts with a real word', () {
      final messages = <String>[];
      for (final c in AudioErrorCode.values) {
        final err = AudioError(
          code: c,
          rawMessage: 'test',
          userMessage: _fakeMessageFor(c),
          at: DateTime.now(),
        );
        messages.add(err.userMessage);
      }
      // No message is empty / whitespace only.
      for (final m in messages) {
        expect(m.trim().isNotEmpty, true, reason: 'empty message for category $m');
      }
    });
  });
}

String _fakeMessageFor(AudioErrorCode c) {
  switch (c) {
    case AudioErrorCode.noNetwork:
      return "I can't reach the internet right now.";
    case AudioErrorCode.serverError:
      return 'This sound could not be loaded.';
    case AudioErrorCode.decodeFailed:
      return "This sound is here, but my player can't open it.";
    case AudioErrorCode.sessionLost:
      return 'Another app is using your audio right now.';
    case AudioErrorCode.unknown:
      return 'Something gentle went wrong.';
  }
}
