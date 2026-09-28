import 'package:core/src/config/app_environment.dart';
import 'package:core/src/logging/log_level.dart';
import 'package:meta/meta.dart';

/// Keys read from `--dart-define` / `--dart-define-from-file`.
abstract final class ConfigKeys {
  static const environment = 'APP_ENV';
  static const apiBaseUrl = 'API_BASE_URL';
  static const logLevel = 'LOG_LEVEL';
  static const networkLogs = 'NETWORK_LOGS';
}

/// Thrown when the build configuration is missing or invalid.
///
/// [problems] lists every issue found, so a developer can fix them in one go.
final class ConfigException implements Exception {
  const new(this.problems);

  final List<String> problems;

  @override
  String toString() =>
      'Invalid app configuration:\n${problems.map((p) => '  - $p').join('\n')}';
}

/// Typed, validated build configuration.
///
/// Everything here is compiled into the app binary and can be extracted by
/// anyone who has the app. **Never put secrets in it**; keep API secrets on a
/// server you control.
@immutable
final class AppConfig {
  const new({
    required this.environment,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.networkLogs,
  });

  /// Parses and validates raw configuration values.
  ///
  /// [flavor] is the native build flavor (`--flavor`), when there is one. It
  /// takes precedence as the source of the environment and must agree with
  /// `APP_ENV` when both are present, which catches running the `prod` flavor
  /// with `config/dev.json` (or the other way round).
  ///
  /// Throws a [ConfigException] listing every problem found.
  factory fromMap(Map<String, String> values, {String? flavor}) {
    final problems = <String>[];

    String? read(String key) {
      final value = values[key]?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    // Environment -----------------------------------------------------------
    final rawEnvironment = read(ConfigKeys.environment);
    final fromDefine = AppEnvironment.tryParse(rawEnvironment);
    final fromFlavor = AppEnvironment.tryParse(flavor);
    if (flavor != null && flavor.isNotEmpty && fromFlavor == null) {
      problems.add('Unknown flavor "$flavor". Expected one of: $_envNames.');
    }
    if (rawEnvironment != null && fromDefine == null) {
      problems.add(
        '${ConfigKeys.environment} "$rawEnvironment" is not one of: '
        '$_envNames.',
      );
    }
    if (fromFlavor != null && fromDefine != null && fromFlavor != fromDefine) {
      problems.add(
        'Flavor "${fromFlavor.name}" does not match '
        '${ConfigKeys.environment}="${fromDefine.name}". Pass '
        '--dart-define-from-file=config/${fromFlavor.name}.json.',
      );
    }
    final environment = fromFlavor ?? fromDefine;
    if (environment == null && rawEnvironment == null) {
      problems.add(
        '${ConfigKeys.environment} is not set. Run with '
        '--dart-define-from-file=config/<environment>.json.',
      );
    }

    // Log level -------------------------------------------------------------
    final rawLogLevel = read(ConfigKeys.logLevel);
    final logLevel = rawLogLevel == null
        ? LogLevel.info
        : LogLevel.tryParse(rawLogLevel);
    if (logLevel == null) {
      problems.add(
        '${ConfigKeys.logLevel} "$rawLogLevel" is not one of: '
        '${LogLevel.values.map((l) => l.name).join(', ')}.',
      );
    }

    // Network logs ----------------------------------------------------------
    final rawNetworkLogs = read(ConfigKeys.networkLogs);
    final networkLogs = switch (rawNetworkLogs?.toLowerCase()) {
      null || 'false' => false,
      'true' => true,
      _ => null,
    };
    if (networkLogs == null) {
      problems.add(
        '${ConfigKeys.networkLogs} must be "true" or "false", '
        'got "$rawNetworkLogs".',
      );
    }

    // API base URL ----------------------------------------------------------
    final rawBaseUrl = read(ConfigKeys.apiBaseUrl);
    final baseUrl = rawBaseUrl == null ? null : Uri.tryParse(rawBaseUrl);
    if (rawBaseUrl == null) {
      problems.add('${ConfigKeys.apiBaseUrl} is not set.');
    } else if (baseUrl == null || !baseUrl.isAbsolute || baseUrl.host.isEmpty) {
      problems.add(
        '${ConfigKeys.apiBaseUrl} "$rawBaseUrl" is not an absolute URL.',
      );
    } else if (baseUrl.scheme != 'https' &&
        !(baseUrl.scheme == 'http' && environment == AppEnvironment.dev)) {
      problems.add(
        '${ConfigKeys.apiBaseUrl} must use https '
        '(plain http is only accepted in dev).',
      );
    }

    // Production-only rules -------------------------------------------------
    if (environment == AppEnvironment.prod) {
      if (baseUrl != null && _isPlaceholderHost(baseUrl.host)) {
        problems.add(
          '${ConfigKeys.apiBaseUrl} still points to the placeholder host '
          '"${baseUrl.host}". Set the real production API in config/prod.json.',
        );
      }
      if (networkLogs ?? false) {
        problems.add('${ConfigKeys.networkLogs} must be false in prod.');
      }
      if (logLevel == LogLevel.debug) {
        problems.add('${ConfigKeys.logLevel} "debug" is not allowed in prod.');
      }
    }

    if (problems.isNotEmpty) throw ConfigException(problems);

    return AppConfig(
      environment: environment!,
      apiBaseUrl: baseUrl!,
      logLevel: logLevel!,
      networkLogs: networkLogs!,
    );
  }

  final AppEnvironment environment;

  /// Base URL for the example API, always absolute.
  final Uri apiBaseUrl;
  final LogLevel logLevel;

  /// Whether HTTP traffic is logged (redacted). Always `false` in prod.
  final bool networkLogs;

  static final String _envNames = AppEnvironment.values
      .map((e) => e.name)
      .join(', ');

  static bool _isPlaceholderHost(String host) {
    final h = host.toLowerCase();
    const reserved = ['example.com', 'example.org', 'example.net'];
    return reserved.any((r) => h == r || h.endsWith('.$r')) ||
        h.endsWith('.example') ||
        h.endsWith('.invalid') ||
        h.endsWith('.test') ||
        h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '10.0.2.2';
  }

  @override
  String toString() =>
      'AppConfig(environment: ${environment.name}, apiBaseUrl: $apiBaseUrl, '
      'logLevel: ${logLevel.name}, networkLogs: $networkLogs)';
}
