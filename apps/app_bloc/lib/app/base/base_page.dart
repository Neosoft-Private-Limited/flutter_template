import 'dart:async';

import 'package:app_bloc/app/base/async_cubit.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// A screen with its own view model (a Bloc or Cubit).
///
/// Extend it instead of wiring `BlocProvider` and `BlocBuilder` by hand: the
/// page creates its view model, starts it in [onInit], rebuilds on state
/// changes and closes the view model when the page is removed. Scaffold,
/// app bar and lifecycle hooks come from [PageLayout].
///
/// ```dart
/// class PostsPage extends BasePage<PostsBloc, PostsState> {
///   const new({super.key});
///
///   @override
///   PostsBloc createViewModel(BuildContext context) =>
///       PostsBloc(context.read<PostsRepository>());
///
///   @override
///   void onInit(PostsBloc viewModel) => viewModel.add(const PostsRequested());
///
///   @override
///   Widget buildView(BuildContext context, PostsState state,
///       PostsBloc viewModel) => ...;
/// }
/// ```
abstract class BasePage<VM extends StateStreamableSource<S>, S>
    extends StatefulWidget
    with PageLayout<VM> {
  const new({super.key});

  /// Creates the page's view model. Read dependencies with
  /// `context.read<T>()` (provided by `RepositoryProvider`s in `App`).
  VM createViewModel(BuildContext context);

  /// Builds the page body from the current [state]; call intents on
  /// [viewModel].
  Widget buildView(BuildContext context, S state, VM viewModel);

  /// Rebuild only when this returns `true` (defaults to every change).
  bool buildWhen(S previous, S current) => true;

  /// One-off reactions to state changes (snackbars, navigation). Runs
  /// before the rebuild for the same state.
  void onStateChanged(BuildContext context, S state, VM viewModel) {}

  @override
  State<BasePage<VM, S>> createState() => _BasePageState<VM, S>();
}

class _BasePageState<VM extends StateStreamableSource<S>, S>
    extends State<BasePage<VM, S>> {
  late final PageLifecycle<VM> _lifecycle = PageLifecycle(
    page: () => widget,
    viewModel: () => _viewModel,
  );
  late VM _viewModel;

  @override
  void initState() {
    super.initState();
    _lifecycle.start();
  }

  @override
  void dispose() {
    // BlocProvider closes the view model; onDispose may see it closed.
    _lifecycle.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<VM>(
    lazy: false,
    create: (context) => _viewModel = widget.createViewModel(context),
    child: BlocConsumer<VM, S>(
      listener: (context, state) =>
          widget.onStateChanged(context, state, _viewModel),
      buildWhen: widget.buildWhen,
      builder: (context, state) => widget.buildScaffold(
        context,
        _viewModel,
        widget.buildView(context, state, _viewModel),
      ),
    ),
  );
}

/// A screen backed by an [AsyncCubit]: loading and error states are handled
/// here and [AsyncCubit.fetch] runs automatically in [onInit], so the page
/// only builds the data view.
abstract class BaseAsyncPage<VM extends AsyncCubit<T>, T>
    extends BasePage<VM, ViewState<T>> {
  const new({super.key});

  /// Builds the page body from loaded [data]. A failed refresh is available
  /// as [refreshError].
  Widget buildData(
    BuildContext context,
    T data,
    VM viewModel, {
    AppFailure? refreshError,
  });

  Widget buildLoading(BuildContext context) =>
      AppLoadingView(semanticLabel: context.l10n.loadingLabel);

  Widget buildError(BuildContext context, AppFailure error, VM viewModel) =>
      FailureView(error: error, onRetry: viewModel.fetch);

  @override
  void onInit(VM viewModel) => unawaited(viewModel.fetch());

  @override
  Widget buildView(BuildContext context, ViewState<T> state, VM viewModel) =>
      switch (state) {
        ViewLoading() => buildLoading(context),
        ViewFailure(:final error) => buildError(context, error, viewModel),
        ViewData(:final data, :final refreshError) => buildData(
          context,
          data,
          viewModel,
          refreshError: refreshError,
        ),
      };
}
