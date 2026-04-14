import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'Cover';

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: developer.Level.debug.value,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: developer.Level.info.value,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: developer.Level.warning.value,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: developer.Level.error.value,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
