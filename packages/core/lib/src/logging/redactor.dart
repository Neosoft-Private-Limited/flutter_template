/// Masks sensitive values before they reach logs.
///
/// Key matching is case-insensitive and ignores `-` and `_`, so
/// `Authorization`, `access_token` and `accessToken` are all caught. Extend
/// [sensitiveKeys] for fields specific to your API (national IDs, card
/// numbers, ...).
final class Redactor {
  const new({this.sensitiveKeys = defaultSensitiveKeys});

  static const String mask = '<redacted>';

  /// Normalized (lowercase, no `-`/`_`) keys that are always masked.
  static const Set<String> defaultSensitiveKeys = {
    'authorization',
    'proxyauthorization',
    'cookie',
    'setcookie',
    'xapikey',
    'apikey',
    'password',
    'passcode',
    'pin',
    'secret',
    'clientsecret',
    'token',
    'accesstoken',
    'refreshtoken',
    'idtoken',
    'sessionid',
    'otp',
  };

  final Set<String> sensitiveKeys;

  bool isSensitive(String key) =>
      sensitiveKeys.contains(key.toLowerCase().replaceAll(RegExp('[-_]'), ''));

  /// Returns a copy of [headers] with sensitive values masked.
  Map<String, Object?> headers(Map<String, Object?> headers) => {
    for (final MapEntry(:key, :value) in headers.entries)
      key: isSensitive(key) ? mask : value,
  };

  /// Recursively masks sensitive keys in decoded JSON (maps and lists).
  /// Other values are returned unchanged.
  Object? json(Object? value) => switch (value) {
    Map<Object?, Object?>() => {
      for (final MapEntry(:key, value: nested) in value.entries)
        key: key is String && isSensitive(key) ? mask : json(nested),
    },
    List<Object?>() => [for (final item in value) json(item)],
    _ => value,
  };

  /// Masks sensitive query parameters in [uri].
  Uri uri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final MapEntry(:key, :value) in uri.queryParametersAll.entries)
          key: isSensitive(key) ? [mask] : value,
      },
    );
  }
}
