import 'dart:developer' as dev;

abstract final class AppLogger {
  static void info(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'Nexloza');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    dev.log(
      message,
      name: tag ?? 'Nexloza',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void warning(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'Nexloza', level: 900);
  }

  static void debug(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'Nexloza', level: 500);
  }
}
