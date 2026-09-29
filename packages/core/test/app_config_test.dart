import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, String> values({
    String? env = 'dev',
    String? url = 'https://api.dev.example.com',
    String? logLevel,
    String? networkLogs,
  }) => {
    'APP_ENV': ?env,
    'API_BASE_URL': ?url,
    'LOG_LEVEL': ?logLevel,
    'NETWORK_LOGS': ?networkLogs,
  };

  List<String> problemsOf(void Function() body) {
    try {
      body();
    } on ConfigException catch (e) {
      return e.problems;
    }
    fail('Expected a ConfigException');
  }

  group('AppConfig.fromMap', () {
    test('parses a valid dev configuration with defaults', () {
      final config = AppConfig.fromMap(values());

      expect(config.environment, AppEnvironment.dev);
      expect(config.apiBaseUrl, Uri.parse('https://api.dev.example.com'));
      expect(config.logLevel, LogLevel.info);
      expect(config.networkLogs, isFalse);
    });

    test('parses explicit log level and network logs', () {
      final config = AppConfig.fromMap(
        values(logLevel: 'DEBUG', networkLogs: 'true'),
      );

      expect(config.logLevel, LogLevel.debug);
      expect(config.networkLogs, isTrue);
    });

    test('uses the flavor when APP_ENV is absent', () {
      final config = AppConfig.fromMap(values(env: null), flavor: 'staging');

      expect(config.environment, AppEnvironment.staging);
    });

    test('rejects a flavor that disagrees with APP_ENV', () {
      final problems = problemsOf(
        () => AppConfig.fromMap(values(), flavor: 'prod'),
      );

      expect(problems, contains(contains('config/prod.json')));
    });

    test('reports every problem at once', () {
      final problems = problemsOf(
        () => AppConfig.fromMap(const {
          'APP_ENV': 'qa',
          'LOG_LEVEL': 'loud',
          'NETWORK_LOGS': 'yes',
        }),
      );

      expect(problems, hasLength(4));
    });

    test('requires APP_ENV or a flavor', () {
      final problems = problemsOf(() => AppConfig.fromMap(values(env: null)));

      expect(problems.single, contains('APP_ENV is not set'));
    });

    test('rejects relative URLs', () {
      final problems = problemsOf(() => AppConfig.fromMap(values(url: '/v1')));

      expect(problems.single, contains('absolute'));
    });

    test('allows http only in dev', () {
      expect(
        AppConfig.fromMap(values(url: 'http://10.0.2.2:8080')).apiBaseUrl.port,
        8080,
      );
      final problems = problemsOf(
        () => AppConfig.fromMap(
          values(env: 'staging', url: 'http://api.staging.acme.dev'),
        ),
      );
      expect(problems.single, contains('https'));
    });

    test('GRAPHQL_URL is optional and validated like API_BASE_URL', () {
      expect(AppConfig.fromMap(values()).graphQLUrl, isNull);
      expect(
        AppConfig.fromMap({
          ...values(),
          'GRAPHQL_URL': 'https://gql.acme.dev/graphql',
        }).graphQLUrl,
        Uri.parse('https://gql.acme.dev/graphql'),
      );
      final problems = problemsOf(
        () => AppConfig.fromMap({
          ...values(env: 'prod', url: 'https://api.acme.dev'),
          'GRAPHQL_URL': 'https://graphql.example.com',
        }),
      );
      expect(problems.single, contains('GRAPHQL_URL'));
    });

    group('production', () {
      test('accepts a real https host', () {
        final config = AppConfig.fromMap(
          values(env: 'prod', url: 'https://api.acme.dev'),
        );

        expect(config.environment.isProduction, isTrue);
      });

      test('fails fast on placeholder hosts', () {
        for (final url in [
          'https://api.example.com',
          'https://example.org',
          'https://api.invalid',
          'https://localhost',
        ]) {
          final problems = problemsOf(
            () => AppConfig.fromMap(values(env: 'prod', url: url)),
          );
          expect(problems.single, contains('placeholder'), reason: url);
        }
      });

      test('forbids network logs and debug logging', () {
        final problems = problemsOf(
          () => AppConfig.fromMap(
            values(
              env: 'prod',
              url: 'https://api.acme.dev',
              logLevel: 'debug',
              networkLogs: 'true',
            ),
          ),
        );

        expect(problems, hasLength(2));
      });
    });
  });

  group('AppEnvironment.tryParse', () {
    test('is case-insensitive and rejects unknown names', () {
      expect(AppEnvironment.tryParse(' PROD '), AppEnvironment.prod);
      expect(AppEnvironment.tryParse('qa'), isNull);
      expect(AppEnvironment.tryParse(null), isNull);
    });
  });
}
