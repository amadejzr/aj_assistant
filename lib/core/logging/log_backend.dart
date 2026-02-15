enum LogLevel { debug, info, warning, error }

/// Interface for log destinations (console, Crashlytics, etc.).
///
/// Implement this and register via [Log.addBackend] to receive all log calls.
abstract class LogBackend {
  /// Called for every log statement. Filter on [level] as needed.
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}
