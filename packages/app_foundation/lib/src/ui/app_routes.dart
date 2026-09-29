/// Route paths. Build locations with these helpers instead of string literals.
abstract final class AppRoutes {
  /// The start page.
  static const home = '/home';

  /// The posts list; post details live under it (see [post]).
  static const posts = '/posts';

  /// The settings screen.
  static const settings = '/settings';

  /// Shown for unknown paths and rejected deep links.
  static const notFound = '/not-found';

  /// Location of the detail page of the post with [id].
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
