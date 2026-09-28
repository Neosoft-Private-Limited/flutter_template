/// Route paths. Build locations with these helpers instead of string literals.
abstract final class AppRoutes {
  static const home = '/home';
  static const posts = '/posts';
  static const settings = '/settings';
  static const notFound = '/not-found';

  static String post(int id) => '$posts/$id';

  /// Parses and validates the `:id` segment of a post deep link.
  ///
  /// Deep links are untrusted input: only positive integers within a sane
  /// range are accepted.
  static int? parsePostId(String? raw) {
    if (raw == null || raw.length > 9) return null;
    final id = int.tryParse(raw);
    return id != null && id > 0 ? id : null;
  }
}
