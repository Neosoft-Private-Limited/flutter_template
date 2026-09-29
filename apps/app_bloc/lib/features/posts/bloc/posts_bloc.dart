import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter/foundation.dart';

// Events ---------------------------------------------------------------------

@immutable
sealed class PostsEvent {
  const new();
}

/// Load the list, showing the loading state (first load and retry).
final class PostsRequested extends PostsEvent {
  const new();
}

/// Reload while keeping the current list visible (pull to refresh).
final class PostsRefreshed extends PostsEvent {
  const new();
}

// States ---------------------------------------------------------------------

@immutable
sealed class PostsState {
  const new();

  /// `true` while a request is in flight.
  bool get isBusy;
}

final class PostsLoading extends PostsState {
  const new();

  @override
  bool get isBusy => true;

  @override
  bool operator ==(Object other) => other is PostsLoading;

  @override
  int get hashCode => (PostsLoading).hashCode;
}

final class PostsLoaded extends PostsState {
  const new(this.feed, {this.isRefreshing = false, this.refreshError});

  final PostsFeed feed;
  final bool isRefreshing;

  /// Set when a refresh failed while the previous list is still shown.
  final AppFailure? refreshError;

  @override
  bool get isBusy => isRefreshing;

  @override
  bool operator ==(Object other) =>
      other is PostsLoaded &&
      other.feed == feed &&
      other.isRefreshing == isRefreshing &&
      other.refreshError == refreshError;

  @override
  int get hashCode => Object.hash(feed, isRefreshing, refreshError);
}

final class PostsFailure extends PostsState {
  const new(this.error);

  final AppFailure error;

  @override
  bool get isBusy => false;

  @override
  bool operator ==(Object other) =>
      other is PostsFailure && identical(other.error, error);

  @override
  int get hashCode => error.hashCode;
}

// Bloc -----------------------------------------------------------------------

/// The posts list. Business rules (caching, offline fallback) stay in the
/// repository; the bloc only maps results to UI states.
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  new(this._repository) : super(const PostsLoading()) {
    on<PostsRequested>(_onRequested);
    on<PostsRefreshed>(_onRefreshed);
  }

  final PostsRepository _repository;

  Future<void> _onRequested(
    PostsRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(const PostsLoading());
    emit(switch (await _repository.fetchPosts()) {
      Ok(:final value) => PostsLoaded(value),
      Err(:final failure) => PostsFailure(failure),
    });
  }

  Future<void> _onRefreshed(
    PostsRefreshed event,
    Emitter<PostsState> emit,
  ) async {
    final current = state;
    if (current is! PostsLoaded || current.isRefreshing) {
      // Nothing shown yet (or already refreshing): behave like a load.
      if (!current.isBusy) add(const PostsRequested());
      return;
    }
    emit(PostsLoaded(current.feed, isRefreshing: true));
    emit(switch (await _repository.fetchPosts()) {
      Ok(:final value) => PostsLoaded(value),
      Err(:final failure) => PostsLoaded(current.feed, refreshError: failure),
    });
  }
}
