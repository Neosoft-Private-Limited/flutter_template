import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Validators.email', () {
    test('accepts common addresses', () {
      for (final email in [
        'a@b.co',
        'first.last+tag@sub.domain.dev',
        '  padded@acme.io  ',
      ]) {
        expect(Validators.email(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      for (final email in ['plain', 'a@b', '@b.co', 'a b@c.co', 'a@b..co']) {
        expect(
          Validators.email(email),
          ValidationError.invalidEmail,
          reason: email,
        );
      }
    });

    test('reports empty input as required', () {
      expect(Validators.email('  '), ValidationError.required);
      expect(Validators.email(null), ValidationError.required);
    });
  });

  test('Validators.required trims whitespace', () {
    expect(Validators.required(' '), ValidationError.required);
    expect(Validators.required('x'), isNull);
  });

  test('Validators.minLength', () {
    expect(Validators.minLength('', 3), ValidationError.required);
    expect(Validators.minLength('ab', 3), ValidationError.tooShort);
    expect(Validators.minLength('abc', 3), isNull);
  });
}
