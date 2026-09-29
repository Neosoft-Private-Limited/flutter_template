import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  const failure = NetworkFailure('offline');

  group('Result', () {
    test('Ok exposes its value', () {
      const Result<int> result = Ok(1);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 1);
      expect(result.failureOrNull, isNull);
      expect(result.getOrThrow(), 1);
    });

    test('Err exposes its failure and throws it from getOrThrow', () {
      const Result<int> result = Err(failure);

      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.getOrThrow, throwsA(same(failure)));
    });

    test('map transforms Ok and passes Err through', () {
      expect(const Result<int>.ok(2).map((v) => v * 2), const Ok(4));
      expect(
        const Result<int>.err(failure).map((v) => v * 2).failureOrNull,
        same(failure),
      );
    });
  });

  group('AppFailure.isTransient', () {
    test('classifies retryable failures', () {
      expect(const NetworkFailure('x').isTransient, isTrue);
      expect(const TimeoutFailure('x').isTransient, isTrue);
      expect(const ServerFailure('x', statusCode: 503).isTransient, isTrue);
      expect(const ServerFailure('x', statusCode: 429).isTransient, isTrue);
      expect(const ServerFailure('x', statusCode: 400).isTransient, isFalse);
      expect(const NotFoundFailure('x').isTransient, isFalse);
      expect(const GraphQLFailure('x').isTransient, isFalse);
      expect(const UnauthorizedFailure('x').isTransient, isFalse);
      expect(const ParsingFailure('x').isTransient, isFalse);
    });
  });
}
