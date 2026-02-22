import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'log_backend.dart';

/// Pretty-prints to the debug console. No-ops in release builds.
class ConsoleLogBackend implements LogBackend {
  const ConsoleLogBackend();

  static const _levelLabels = {
    LogLevel.debug: 'D',
    LogLevel.info: 'I',
    LogLevel.warning: 'W',
    LogLevel.error: 'E',
  };

  @override
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final label = _levelLabels[level]!;
    final prefix = tag != null ? '[$label] $tag' : '[$label]';
    final buffer = StringBuffer('$prefix: $message');

    if (error != null) buffer.write('\n    ↳ $error');

    dev.log(
      buffer.toString(),
      name: 'Bower',
      level: _devLogLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _devLogLevel(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}
