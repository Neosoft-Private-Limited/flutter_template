import 'package:flutter/foundation.dart';

/// Example domain entity. Replace with your own models.
@immutable
final class Post {
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

  final int id;
  final int userId;
  final String title;
  final String body;

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
  const new(this.posts, {this.isFromCache = false});

  final List<Post> posts;

  /// `true` when the network was unavailable and saved data is shown.
  final bool isFromCache;
}
