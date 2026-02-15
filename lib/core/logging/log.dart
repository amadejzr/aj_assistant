import 'log_backend.dart';

export 'log_backend.dart' show LogLevel, LogBackend;

/// Lightweight static logger. Add backends at startup; call anywhere.
///
/// ```dart
/// Log.d('loaded 42 entries', tag: 'ModuleRepo');
/// Log.e('sync failed', tag: 'Sync', error: e, stackTrace: st);
/// ```
///
/// In release builds, register only your Crashlytics backend —
/// console backend is debug-only by default.
abstract final class Log {
  static final List<LogBackend> _backends = [];

  /// Register a backend. Call once per backend at app startup.
  static void addBackend(LogBackend backend) => _backends.add(backend);

  /// Remove all backends (useful for tests).
  static void clearBackends() => _backends.clear();

  static void d(String message, {String? tag}) =>
      _dispatch(LogLevel.debug, message, tag: tag);

  static void i(String message, {String? tag}) =>
      _dispatch(LogLevel.info, message, tag: tag);

  static void w(String message, {String? tag, Object? error}) =>
      _dispatch(LogLevel.warning, message, tag: tag, error: error);

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _dispatch(LogLevel.error, message,
          tag: tag, error: error, stackTrace: stackTrace);

  static void _dispatch(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final backend in _backends) {
      backend.log(level, message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }
}
