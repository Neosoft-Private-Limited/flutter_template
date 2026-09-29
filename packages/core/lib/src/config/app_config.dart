import 'package:core/src/config/app_environment.dart';
import 'package:core/src/logging/log_level.dart';
import 'package:meta/meta.dart';

/// Keys read from `--dart-define` / `--dart-define-from-file`.
abstract final class ConfigKeys {
  /// Target environment: `dev`, `staging` or `prod`. Required unless a
  /// build flavor supplies it.
  static const environment = 'APP_ENV';

  /// Absolute base URL for REST calls. Required; must be https outside dev.
  static const apiBaseUrl = 'API_BASE_URL';

  /// Minimum [LogLevel] name to emit. Defaults to `info`; `debug` is
  /// rejected in prod.
  static const logLevel = 'LOG_LEVEL';

  /// `true` or `false`: whether HTTP traffic is logged. Defaults to `false`
  /// and must be `false` in prod.
  static const networkLogs = 'NETWORK_LOGS';

  /// Optional absolute GraphQL endpoint. Omit it when the app does not use
  /// GraphQL.
  static const graphQLUrl = 'GRAPHQL_URL';
}

/// Thrown when the build configuration is missing or invalid.
///
/// [problems] lists every issue found, so a developer can fix them in one go.
final class ConfigException implements Exception {
  /// Creates an exception reporting every entry in [problems].
  const new(this.problems);

  /// Human-readable descriptions of each invalid or missing value, in the
  /// order they were found. Never empty when thrown by [AppConfig.fromMap].
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
  /// Creates a configuration from already-validated values.
  ///
  /// No checks are performed; prefer [AppConfig.fromMap] for raw input.
  /// Useful in tests.
  const new({
    required this.environment,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.networkLogs,
    this.graphQLUrl,
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

    // URLs -------------------------------------------------------------------
    Uri? parseUrl(String key, {required bool required}) {
      final raw = read(key);
      if (raw == null) {
        if (required) problems.add('$key is not set.');
        return null;
      }
      final url = Uri.tryParse(raw);
      if (url == null || !url.isAbsolute || url.host.isEmpty) {
        problems.add('$key "$raw" is not an absolute URL.');
        return null;
      }
      if (url.scheme != 'https' &&
          !(url.scheme == 'http' && environment == AppEnvironment.dev)) {
        problems.add(
          '$key must use https (plain http is only accepted in dev).',
        );
      }
      if (environment == AppEnvironment.prod && _isPlaceholderHost(url.host)) {
        problems.add(
          '$key still points to the placeholder host "${url.host}". '
          'Set the real production value in config/prod.json.',
        );
      }
      return url;
    }

    final baseUrl = parseUrl(ConfigKeys.apiBaseUrl, required: true);
    final graphQLUrl = parseUrl(ConfigKeys.graphQLUrl, required: false);

    // Production-only rules -------------------------------------------------
    if (environment == AppEnvironment.prod) {
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
      graphQLUrl: graphQLUrl,
      logLevel: logLevel!,
      networkLogs: networkLogs!,
    );
  }

  /// The environment this build targets, resolved from the flavor or
  /// `APP_ENV`.
  final AppEnvironment environment;

  /// Base URL for REST calls, always absolute.
  final Uri apiBaseUrl;

  /// GraphQL endpoint, or `null` when the app does not use GraphQL.
  final Uri? graphQLUrl;

  /// Minimum severity that is logged. Never [LogLevel.debug] in prod.
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
      'graphQLUrl: $graphQLUrl, logLevel: ${logLevel.name}, '
      'networkLogs: $networkLogs)';
}
