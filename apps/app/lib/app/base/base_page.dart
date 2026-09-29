import 'package:app/app/base/view_model.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// A screen backed by a synchronous view model (a Riverpod `Notifier`).
///
/// Extend it instead of writing a `ConsumerStatefulWidget`: provide the view
/// model's provider and build the view from its state. Scaffold, app bar and
/// lifecycle hooks come from [PageLayout].
///
/// ```dart
/// class SettingsPage extends BasePage<SettingsViewModel, SettingsState> {
///   const new({super.key});
///
///   @override
///   NotifierProvider<SettingsViewModel, SettingsState>
///       get viewModelProvider => settingsViewModelProvider;
///
///   @override
///   String title(BuildContext context) => context.l10n.settingsTitle;
///
///   @override
///   Widget buildView(BuildContext context, SettingsState state,
///       SettingsViewModel viewModel) => SettingsView(...);
/// }
/// ```
abstract class BasePage<VM extends Notifier<S>, S>
    extends ConsumerStatefulWidget
    with PageLayout<VM> {
  const new({super.key});

  /// The view model's provider (for families: `provider(argument)`).
  NotifierProvider<VM, S> get viewModelProvider;

  /// Builds the page body from the current [state]; call intents on
  /// [viewModel].
  Widget buildView(BuildContext context, S state, VM viewModel);

  @override
  ConsumerState<BasePage<VM, S>> createState() => _BasePageState<VM, S>();
}

class _BasePageState<VM extends Notifier<S>, S>
    extends ConsumerState<BasePage<VM, S>> {
  late final PageLifecycle<VM> _lifecycle = PageLifecycle(
    page: () => widget,
    viewModel: () => _viewModel,
  );
  late VM _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(widget.viewModelProvider.notifier);
    _lifecycle.start();
  }

  @override
  void dispose() {
    _lifecycle.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.viewModelProvider);
    _viewModel = ref.read(widget.viewModelProvider.notifier);
    return widget.buildScaffold(
      context,
      _viewModel,
      widget.buildView(context, state, _viewModel),
    );
  }
}

/// A screen backed by an [AsyncViewModel]: loading and error states are
/// handled here, so the page only builds the data view.
///
/// - First load: [buildLoading] (a spinner by default).
/// - Load failed: [buildError] (localized message + retry by default).
/// - Data available: [buildView]. While refreshing, the previous data stays
///   visible; a failed refresh is available as `viewModel.refreshError`.
abstract class BaseAsyncPage<VM extends AsyncViewModel<T>, T>
    extends ConsumerStatefulWidget
    with PageLayout<VM> {
  const new({super.key});

  /// The view model's provider (for families: `provider(argument)`).
  AsyncNotifierProvider<VM, T> get viewModelProvider;

  /// Builds the page body from loaded [data].
  Widget buildView(BuildContext context, T data, VM viewModel);

  Widget buildLoading(BuildContext context) =>
      AppLoadingView(semanticLabel: context.l10n.loadingLabel);

  Widget buildError(BuildContext context, Object error, VM viewModel) =>
      FailureView(error: error, onRetry: viewModel.retry);

  @override
  ConsumerState<BaseAsyncPage<VM, T>> createState() =>
      _BaseAsyncPageState<VM, T>();
}

class _BaseAsyncPageState<VM extends AsyncViewModel<T>, T>
    extends ConsumerState<BaseAsyncPage<VM, T>> {
  late final PageLifecycle<VM> _lifecycle = PageLifecycle(
    page: () => widget,
    viewModel: () => _viewModel,
  );
  late VM _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(widget.viewModelProvider.notifier);
    _lifecycle.start();
  }

  @override
  void dispose() {
    _lifecycle.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.viewModelProvider);
    _viewModel = ref.read(widget.viewModelProvider.notifier);

    final Widget body;
    if (state.value case final data?) {
      body = widget.buildView(context, data, _viewModel);
    } else if (state.hasError) {
      body = widget.buildError(context, state.error!, _viewModel);
    } else {
      body = widget.buildLoading(context);
    }
    return widget.buildScaffold(context, _viewModel, body);
  }
}
