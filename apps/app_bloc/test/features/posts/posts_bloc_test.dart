import 'package:app_bloc/app/base/async_cubit.dart';
import 'package:app_bloc/features/posts/bloc/post_detail_cubit.dart';
import 'package:app_bloc/features/posts/bloc/posts_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const offline = NetworkFailure('offline');
  final feed = PostsFeed([testPost(1), testPost(2)]);
  final newer = PostsFeed([testPost(3)]);

  late FakePostsRepository repository;

  setUp(() => repository = FakePostsRepository());

  group('PostsBloc', () {
    test('starts in the loading state', () {
      expect(PostsBloc(repository).state, const PostsLoading());
    });

    blocTest<PostsBloc, PostsState>(
      'loads posts',
      build: () => PostsBloc(repository..onFetchPosts = () async => Ok(feed)),
      act: (bloc) => bloc.add(const PostsRequested()),
      // Bloc always emits the first state, even if it equals the initial one.
      expect: () => [const PostsLoading(), PostsLoaded(feed)],
    );

    blocTest<PostsBloc, PostsState>(
      'emits a failure when loading fails',
      build: () =>
          PostsBloc(repository..onFetchPosts = () async => const Err(offline)),
      act: (bloc) => bloc.add(const PostsRequested()),
      expect: () => [const PostsLoading(), const PostsFailure(offline)],
    );

    blocTest<PostsBloc, PostsState>(
      'retry shows loading again, then the posts',
      build: () => PostsBloc(repository..onFetchPosts = () async => Ok(feed)),
      seed: () => const PostsFailure(offline),
      act: (bloc) => bloc.add(const PostsRequested()),
      expect: () => [const PostsLoading(), PostsLoaded(feed)],
    );

    blocTest<PostsBloc, PostsState>(
      'refresh keeps the list visible and replaces it on success',
      build: () => PostsBloc(repository..onFetchPosts = () async => Ok(newer)),
      seed: () => PostsLoaded(feed),
      act: (bloc) => bloc.add(const PostsRefreshed()),
      expect: () => [PostsLoaded(feed, isRefreshing: true), PostsLoaded(newer)],
    );

    blocTest<PostsBloc, PostsState>(
      'failed refresh keeps the old list and exposes the error',
      build: () =>
          PostsBloc(repository..onFetchPosts = () async => const Err(offline)),
      seed: () => PostsLoaded(feed),
      act: (bloc) => bloc.add(const PostsRefreshed()),
      expect: () => [
        PostsLoaded(feed, isRefreshing: true),
        PostsLoaded(feed, refreshError: offline),
      ],
    );

    blocTest<PostsBloc, PostsState>(
      'refresh from a failure behaves like a load',
      build: () => PostsBloc(repository..onFetchPosts = () async => Ok(feed)),
      seed: () => const PostsFailure(offline),
      act: (bloc) => bloc.add(const PostsRefreshed()),
      expect: () => [const PostsLoading(), PostsLoaded(feed)],
    );
  });

  group('PostDetailCubit (AsyncCubit)', () {
    blocTest<PostDetailCubit, ViewState<Post>>(
      'fetch loads the post',
      build: () => PostDetailCubit(repository, 7),
      act: (cubit) => cubit.fetch(),
      expect: () => [const ViewLoading<Post>(), ViewData(testPost(7))],
    );

    blocTest<PostDetailCubit, ViewState<Post>>(
      'fetch emits a failure for unknown posts',
      build: () => PostDetailCubit(
        repository..onFetchPost = (_) async => const Err(NotFoundFailure('x')),
        9,
      ),
      act: (cubit) => cubit.fetch(),
      expect: () => [const ViewLoading<Post>(), isA<ViewFailure<Post>>()],
    );

    blocTest<PostDetailCubit, ViewState<Post>>(
      'refresh keeps the data visible and replaces it',
      build: () => PostDetailCubit(repository, 7),
      seed: () => ViewData(testPost(1)),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        ViewData(testPost(1), isRefreshing: true),
        ViewData(testPost(7)),
      ],
    );

    blocTest<PostDetailCubit, ViewState<Post>>(
      'failed refresh keeps the data and exposes the error',
      build: () => PostDetailCubit(
        repository..onFetchPost = (_) async => const Err(offline),
        7,
      ),
      seed: () => ViewData(testPost(1)),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        ViewData(testPost(1), isRefreshing: true),
        ViewData(testPost(1), refreshError: offline),
      ],
    );
  });
}
