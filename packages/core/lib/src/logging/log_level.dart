import 'package:logging/logging.dart';

/// Verbosity accepted by the `LOG_LEVEL` configuration value.
enum LogLevel {
  /// Everything, including diagnostic detail. Not allowed in prod.
  debug(Level.FINE),

  /// Notable events in normal operation. The default.
  info(Level.INFO),

  /// Unexpected situations the app recovered from.
  warning(Level.WARNING),

  /// Failures only.
  error(Level.SEVERE),

  /// Disables logging entirely.
  off(Level.OFF);

  new(this.level);

  /// The equivalent `package:logging` level.
  final Level level;

  /// Parses a `LOG_LEVEL` value, ignoring case and surrounding whitespace.
  /// Returns `null` for unknown or `null` values.
  static LogLevel? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final logLevel in values) {
      if (logLevel.name == normalized) return logLevel;
    }
    return null;
  }
}
