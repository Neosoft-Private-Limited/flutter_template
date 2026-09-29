import 'dart:async';

import 'package:core/src/logging/log_level.dart';
import 'package:logging/logging.dart';

/// Receives every log record at or above the configured level.
typedef LogSink = void Function(LogRecord record);

/// Configures `package:logging` for the whole app and returns the listener
/// subscription (cancel it in tests).
///
/// Code logs through named loggers: `final _log = Logger('PostsRepository');`.
/// Never log tokens, passwords or personal data; use `Redactor` for payloads.
StreamSubscription<LogRecord> configureLogging({
  required LogLevel level,
  required LogSink sink,
}) {
  hierarchicalLoggingEnabled = false;
  Logger.root.level = level.level;
  return Logger.root.onRecord.listen(sink);
}

/// Formats a record as a single human-readable line (plus error and stack).
String formatLogRecord(LogRecord record) {
  final buffer = StringBuffer()
    ..write(record.time.toIso8601String())
    ..write(' ')
    ..write(record.level.name.padRight(7))
    ..write(' [')
    ..write(record.loggerName)
    ..write('] ')
    ..write(record.message);
  if (record.error != null) buffer.write('\n  error: ${record.error}');
  if (record.stackTrace != null) buffer.write('\n${record.stackTrace}');
  return buffer.toString();
}
