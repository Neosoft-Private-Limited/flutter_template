import 'package:meta/meta.dart';

/// Example domain entity. Replace with your own models.
@immutable
final class Post {
  /// Creates a post.
  const new({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// Validating decoder; throws [FormatException] for unexpected shapes.
  factory fromJson(Object? json) => switch (json) {
    {
      'id': final int id,
      'userId': final int userId,
      'title': final String title,
      'body': final String body,
    } =>
      Post(id: id, userId: userId, title: title, body: body),
    _ => throw FormatException('Invalid post payload', json),
  };

  /// Unique, positive identifier.
  final int id;

  /// Identifier of the post's author.
  final int userId;

  /// Headline shown in lists and as the detail heading.
  final String title;

  /// Full text of the post.
  final String body;

  /// Encodes the post in the shape [Post.fromJson] accepts.
  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
  };

  @override
  bool operator ==(Object other) =>
      other is Post &&
      other.id == id &&
      other.userId == userId &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, userId, title, body);
}

/// A list of posts and where it came from.
@immutable
final class PostsFeed {
  /// Creates a feed of [posts]; [isFromCache] marks offline data.
  const new(this.posts, {this.isFromCache = false});

  /// The posts, in the order the source returned them.
  final List<Post> posts;

  /// `true` when the network was unavailable and saved data is shown.
  final bool isFromCache;

  @override
  bool operator ==(Object other) {
    if (other is! PostsFeed || other.isFromCache != isFromCache) return false;
    if (other.posts.length != posts.length) return false;
    for (var i = 0; i < posts.length; i++) {
      if (other.posts[i] != posts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(posts), isFromCache);
}
