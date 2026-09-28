import 'package:logging/logging.dart';

/// Verbosity accepted by the `LOG_LEVEL` configuration value.
enum LogLevel {
  debug(Level.FINE),
  info(Level.INFO),
  warning(Level.WARNING),
  error(Level.SEVERE),
  off(Level.OFF);

  new(this.level);

  /// The equivalent `package:logging` level.
  final Level level;

  static LogLevel? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final logLevel in values) {
      if (logLevel.name == normalized) return logLevel;
    }
    return null;
  }
}
