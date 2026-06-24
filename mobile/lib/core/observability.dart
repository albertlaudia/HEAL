// Lightweight observability — pluggable for Firebase Crashlytics / Sentry / Console.
// Default: console + in-memory ring buffer; production swaps in Crashlytics.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Observability extends ProviderObserver {
  static final List<_Record> _buffer = <_Record>[];

  static void log(String message) {
    if (kDebugMode) debugPrint('[heal] $message');
    _buffer.add(_Record(DateTime.now(), 'log', message));
  }

  static void recordError(Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[heal] ERROR: $error');
      debugPrint(stack.toString());
    }
    _buffer.add(_Record(DateTime.now(), 'error', '$error\n$stack'));
  }

  static List<_Record> snapshot() => List<_Record>.unmodifiable(_buffer);

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    recordError(error, stackTrace);
  }
}

class _Record {
  _Record(this.timestamp, this.level, this.message);
  final DateTime timestamp;
  final String level;
  final String message;
}
