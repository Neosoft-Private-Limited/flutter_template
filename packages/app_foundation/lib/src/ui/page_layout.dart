import 'package:material_ui/material_ui.dart';

/// The page template shared by every app's `BasePage`, independent of the
/// state-management library.
///
/// A page overrides only what it needs: a [title] (or a full [buildAppBar]),
/// a floating action button, back handling, lifecycle hooks. The app's
/// `BasePage` supplies the view model ([VM]) and calls [buildScaffold] with
/// the page body.
mixin PageLayout<VM> on Widget {
  // Scaffold ------------------------------------------------------------------

  /// App bar title. Ignored when [buildAppBar] is overridden.
  String? title(BuildContext context) => null;

  /// Defaults to an [AppBar] showing [title], or no app bar without a title.
  PreferredSizeWidget? buildAppBar(BuildContext context, VM viewModel) {
    final text = title(context);
    return text == null ? null : AppBar(title: Text(text));
  }

  /// The page's floating action button; `null` (the default) shows none.
  Widget? buildFloatingActionButton(BuildContext context, VM viewModel) => null;

  /// The page's bottom navigation bar; `null` (the default) shows none.
  Widget? buildBottomNavigationBar(BuildContext context, VM viewModel) => null;

  /// The page's navigation drawer; `null` (the default) shows none.
  Widget? buildDrawer(BuildContext context, VM viewModel) => null;

  /// `null` uses the theme's scaffold background.
  Color? backgroundColor(BuildContext context) => null;

  /// Whether the body extends behind the app bar, for example under a
  /// transparent app bar. See [Scaffold.extendBodyBehindAppBar].
  bool get extendBodyBehindAppBar => false;

  /// Whether the body shrinks when the on-screen keyboard appears. See
  /// [Scaffold.resizeToAvoidBottomInset].
  bool get resizeToAvoidBottomInset => true;

  // Back navigation -----------------------------------------------------------

  /// Return `false` to block the system back gesture/button, then handle it
  /// in [onPopInvoked] (for example to confirm discarding changes).
  bool canPop(VM viewModel) => true;

  /// Called after a pop attempt; [didPop] is `false` when [canPop] blocked it.
  void onPopInvoked(
    BuildContext context,
    VM viewModel, {
    required bool didPop,
  }) {}

  // Lifecycle -----------------------------------------------------------------

  /// Called once, after the first frame, with the page's view model. Start
  /// loading here (the replacement for the old `onModelReady`).
  void onInit(VM viewModel) {}

  /// The app came back to the foreground while this page was shown.
  void onResume(VM viewModel) {}

  /// The app went to the background while this page was shown.
  void onPause(VM viewModel) {}

  /// The page is being removed.
  void onDispose(VM viewModel) {}

  /// Wraps [body] in the page template. Called by the app's `BasePage`.
  Widget buildScaffold(BuildContext context, VM viewModel, Widget body) =>
      PopScope<Object?>(
        canPop: canPop(viewModel),
        onPopInvokedWithResult: (didPop, _) =>
            onPopInvoked(context, viewModel, didPop: didPop),
        child: Scaffold(
          appBar: buildAppBar(context, viewModel),
          body: body,
          floatingActionButton: buildFloatingActionButton(context, viewModel),
          bottomNavigationBar: buildBottomNavigationBar(context, viewModel),
          drawer: buildDrawer(context, viewModel),
          backgroundColor: backgroundColor(context),
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        ),
      );
}

/// Forwards app lifecycle changes to a page's [PageLayout] hooks. Used by
/// the apps' `BasePage` state classes.
final class PageLifecycle<VM> {
  /// Creates a forwarder. The page and view model getters are called on
  /// every event, so they must return the current widget and view model.
  new({required this._page, required this._viewModel}) : _listener = null;

  final PageLayout<VM> Function() _page;
  final VM Function() _viewModel;
  AppLifecycleListener? _listener;

  /// Starts listening and schedules [PageLayout.onInit] after the first frame.
  void start() {
    _listener = AppLifecycleListener(
      onResume: () => _page().onResume(_viewModel()),
      onPause: () => _page().onPause(_viewModel()),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _page().onInit(_viewModel()),
    );
  }

  /// Stops listening and calls [PageLayout.onDispose]. Call from the
  /// state's `dispose`.
  void stop() {
    _listener?.dispose();
    _page().onDispose(_viewModel());
  }
}
