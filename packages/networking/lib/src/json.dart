/// Helpers for hand-written, validating JSON decoders.
///
/// Decoders use Dart 3 patterns and throw [FormatException] on unexpected
/// shapes, which `ApiClient` turns into a `ParsingFailure`:
///
/// ```dart
/// static Post fromJson(Object? json) => switch (json) {
///   {'id': final int id, 'title': final String title} => Post(id, title),
///   _ => throw FormatException('Invalid post', json),
/// };
/// ```
abstract final class Json {
  /// Decodes a JSON array, applying [item] to every element.
  static List<T> list<T>(Object? json, T Function(Object? item) item) =>
      switch (json) {
        final List<Object?> values => [for (final value in values) item(value)],
        _ => throw FormatException('Expected a JSON array', json),
      };

  /// Ignores the response body (for 204 responses and fire-and-forget calls).
  static void ignore(Object? _) {}
}
