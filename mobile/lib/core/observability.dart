// HEAL — Lightweight observability / logger.
// Avoids pulling in `package:logging`. Designed for prod where we want
// crashlytics-style breadcrumbs but minimal cost.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry(this.timestamp, this.level, this.tag, this.message,
      {this.error, this.stackTrace});

  @override
  String toString() {
    final ts = DateFormat('HH:mm:ss.SSS').format(timestamp);
    final lvl = level.name.toUpperCase().padRight(5);
    return '[$ts] $lvl $tag: $message'
        '${error != null ? '\n  ${error.toString()}' : ''}'
        '${stackTrace != null ? '\n  ${stackTrace.toString().split("\n").take(3).join("\n  ")}' : ''}';
  }
}

class HealLogger {
  final List<LogEntry> _buffer = [];
  final int maxBufferSize = 500;

  void _log(LogLevel level, String tag, String message,
      {Object? error, StackTrace? stackTrace}) {
    final entry = LogEntry(DateTime.now(), level, tag, message,
        error: error, stackTrace: stackTrace);
    _buffer.add(entry);
    if (_buffer.length > maxBufferSize) _buffer.removeAt(0);
    if (kDebugMode) {
      // ignore: avoid_print
      print(entry);
    }
  }

  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message, {Object? error}) =>
      _log(LogLevel.warn, tag, message, error: error);
  void e(String tag, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  List<LogEntry> tail(int n) =>
      _buffer.length <= n ? List.of(_buffer) : _buffer.sublist(_buffer.length - n);
}

final loggerProvider = Provider<HealLogger>((ref) => HealLogger());